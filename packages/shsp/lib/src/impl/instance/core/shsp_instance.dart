import 'dart:developer';

import '../../../../shsp.dart';

const int dataPrefix = 0x00;
const int keepAlivePrefix = 0x05;

// TO DO (Extension) : Add callback for extra data after prefixes (eg. handshake with data)

/// SHSP Instance: manages handshake, closure, keep-alive and data messages.
class ShspInstance extends ShspPeer
    with ShspInstanceKeepAliveMixin, ShspInstanceHandshakeMixin
    implements IShspInstance {
  ShspInstance({
    required super.remotePeer,
    required super.socket,
    int keepAliveSeconds = 15,
    this.livenessTimeoutSeconds = 60,
  }) {
    _keepAliveSecondsValue = keepAliveSeconds;
    onHandshake = CallbackOn();
    onOpen = CallbackOn();
    onClosing = CallbackOn();
    onClose = CallbackOn();
    _startLiveness();
  }

  /// Factory: creates a new SHSP instance with configurable keep-alive.
  factory ShspInstance.create({
    required PeerInfo remotePeer,
    required IShspSocket socket,
    int keepAliveSeconds = 15,
    int? livenessTimeoutSeconds = 60,
  }) => ShspInstance(
    remotePeer: remotePeer,
    socket: socket,
    keepAliveSeconds: keepAliveSeconds,
    livenessTimeoutSeconds: livenessTimeoutSeconds,
  );

  /// Factory: creates a new SHSP instance from an existing ShspPeer.
  factory ShspInstance.fromPeer(
    ShspPeer peer, {
    int keepAliveSeconds = 15,
    int? livenessTimeoutSeconds = 60,
  }) => ShspInstance(
    remotePeer: peer.remotePeer,
    socket: peer.socket,
    keepAliveSeconds: keepAliveSeconds,
    livenessTimeoutSeconds: livenessTimeoutSeconds,
  );

  /// Factory: creates a new SHSP instance from an existing profile.
  ///
  /// This is useful when reconnecting over a new socket (e.g., UDP reconnection).
  /// The handshake will be redone, but all callbacks and configuration are restored.
  factory ShspInstance.withProfile({
    required PeerInfo remotePeer,
    required IShspSocket socket,
    required ShspInstanceProfile profile,
  }) {
    final instance = ShspInstance(
      remotePeer: remotePeer,
      socket: socket,
      keepAliveSeconds: profile.keepAliveSeconds,
    );
    profile.onHandshakeListeners.forEach(instance.onHandshake.register);
    profile.onOpenListeners.forEach(instance.onOpen.register);
    profile.onClosingListeners.forEach(instance.onClosing.register);
    profile.onCloseListeners.forEach(instance.onClose.register);
    profile.onMessageListeners.forEach(instance.messageCallback.register);
    return instance;
  }

  /// Explicit connection state machine (Section 5): CREATED -> HANDSHAKING ->
  /// OPEN -> CLOSING (optional) -> CLOSED. Single source of truth for the
  /// derived `handshake`/`closing`/`open` getters exposed by
  /// [ShspInstanceHandshakeMixin].
  ShspConnectionState _connectionState = ShspConnectionState.created;
  int _keepAliveSecondsValue = 15;
  KeepAliveTimer? _keepAliveTimerValue;

  /// Liveness timeout in seconds (Section 7): if no message (data, control or
  /// keep-alive) is received from the peer within this duration, the session
  /// is closed locally, without waiting for a peer response. `null` disables
  /// this behavior entirely.
  final int? livenessTimeoutSeconds;

  /// Timer backing the liveness timeout. Reuses [KeepAliveTimer] as a generic
  /// resettable periodic timer; it is unrelated to the outgoing keep-alive
  /// timer managed by [ShspInstanceKeepAliveMixin].
  KeepAliveTimer? _livenessTimerValue;

  @override
  late CallbackOn onOpen;

  /// Getter/setter for the handshake mixin's state machine
  @override
  ShspConnectionState get connectionState => _connectionState;
  @override
  set connectionState(ShspConnectionState value) => _connectionState = value;

  /// Getters for keep-alive mixin
  @override
  int get keepAliveSecondsValue => _keepAliveSecondsValue;
  @override
  set keepAliveSecondsValue(int value) => _keepAliveSecondsValue = value;
  @override
  KeepAliveTimer? get keepAliveTimerValue => _keepAliveTimerValue;
  @override
  set keepAliveTimerValue(KeepAliveTimer? value) =>
      _keepAliveTimerValue = value;

  @override
  void onMessage(List<int> msg, PeerInfo info) {
    // Section 7: any message received from the peer (handshake, ack,
    // closing, closed, keep-alive or data) is proof of liveness and resets
    // the liveness timeout, before any dispatch happens below.
    _resetLiveness();

    // Section 5 (CREATED): no message other than a Handshake probe (0x01)
    // can legitimately be received while still in this state; anything else
    // MUST be discarded. Note this is keyed on the prefix byte alone: a
    // malformed handshake probe (e.g. missing VERSION byte) still reaches
    // the isHandshake()/protocol-error handling below instead of being
    // silently swallowed here.
    if (_connectionState == ShspConnectionState.created &&
        !(msg.isNotEmpty && msg[0] == handshakePrefix)) {
      return;
    }

    // Check protocol messages first
    if (isHandshake(msg)) {
      // Reply with a dedicated handshake acknowledgment (0x02) as required by the spec.
      sendHandshakeAck();
      return;
    }
    if (msg.isNotEmpty && msg[0] == handshakeAckPrefix) {
      final wasOpen = open;
      isHandshakeAck(msg);
      // Only fire onOpen on the OPEN transition, not on every subsequent ack.
      if (!wasOpen) onOpen.call(null);
      return;
    }
    if (isClosingMessage(msg)) return;
    if (isClosedMessage(msg)) return;

    // Section 6, point 7: Data or Keep-alive received while still HANDSHAKING
    // (i.e. our own ack was never received, but the peer's traffic was) is
    // treated as an implicit handshake confirmation: transition to OPEN
    // before processing/forwarding the message itself. Closing/Closed
    // messages are excluded (point 8) via the early returns above.
    if (_isKeepAlive(msg) || _isData(msg)) {
      if (_connectionState == ShspConnectionState.handshaking) {
        _connectionState = ShspConnectionState.open;
        onOpen.call(null);
      }
    }

    if (_isKeepAlive(msg)) return;

    // Pass to parent for user callback
    if (_isData(msg)) {
      super.onMessage(msg, info);
      return;
    }

    throw ShspProtocolException(
      'Message type not recognized by ShspInstance',
      messageType: msg.isNotEmpty ? '0x${msg[0].toRadixString(16)}' : 'empty',
    );
  }

  bool _isData(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == dataPrefix) {
      return true;
    }
    return false;
  }

  /// Check if message is a keep-alive (0x05)
  bool _isKeepAlive(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == keepAlivePrefix) {
      return true;
    }
    return false;
  }

  @override
  void keepAlive() {
    if (closing || !open) return; // do not send keep-alive if closing or closed
    sendMessageInternal([keepAlivePrefix]);
  }

  @override
  void sendMessage(List<int> message) {
    message.insert(0, dataPrefix);
    if (open == false) {
      throw ShspInstanceException(
        'Cannot send message: connection is not open',
        instanceId: '${remotePeer.address.address}:${remotePeer.port}',
      );
    }
    sendMessageInternal(message);
  }

  @override
  void sendMessageInternal(List<int> message) {
    if (closing == true) {
      throw ShspInstanceException(
        'Cannot send message: connection is closing',
        instanceId: '${remotePeer.address.address}:${remotePeer.port}',
      );
    }

    sendMessageUnchecked(message);
    // Reset keep-alive timer on any outgoing message
    resetKeepAlive();
  }

  @override
  void sendMessageUnchecked(List<int> message) {
    super.sendMessage(message);
  }

  /// Override close() to ensure keep-alive and liveness timers are stopped
  @override
  void close() {
    try {
      if (open) sendClosed();
    } catch (_) {
      // Ignore send errors during close (e.g. socket already closed)
    } finally {
      stopKeepAlive();
      _stopLiveness();
      super.close();
    }
  }

  /// Starts the liveness timeout (Section 7), if configured. A no-op when
  /// [livenessTimeoutSeconds] is `null` (feature disabled) or the timer is
  /// already running.
  void _startLiveness() {
    final seconds = livenessTimeoutSeconds;
    if (seconds == null) return;
    if (_livenessTimerValue != null && _livenessTimerValue!.isActive) return;
    _livenessTimerValue = KeepAliveTimer.periodic(Duration(seconds: seconds), (
      _,
    ) {
      // No message (data, control or keep-alive) was received from the peer
      // within the liveness timeout: close the session locally, following
      // the same procedure as a local close(), without waiting for a peer
      // response (Section 7, Section 8).
      close();
    });
  }

  /// Stops the liveness timer, if running. Called from [close] to avoid
  /// leaking a pending timer after the session ends.
  void _stopLiveness() {
    if (_livenessTimerValue != null) {
      try {
        _livenessTimerValue!.cancel();
      } catch (e) {
        log('Error canceling liveness timer: $e', name: 'ShspInstance');
      } finally {
        _livenessTimerValue = null;
      }
    }
  }

  /// Resets the liveness timeout countdown (postpones the timeout), if
  /// configured and running. Called on receipt of any message from the peer.
  void _resetLiveness() {
    _livenessTimerValue?.resetTick();
  }

  /// Extracts all registered listeners and configuration from this instance.
  ///
  /// Returns a [ShspInstanceProfile] containing copies of all callbacks and the
  /// keep-alive configuration. This can be applied to a new instance via
  /// [ShspInstance.withProfile].
  ///
  /// The returned profile does NOT include connection state (_handshake, _open, _closing),
  /// which will be reset on the new instance (as required for reconnection over a new socket).
  @override
  ShspInstanceProfile extractProfile() => ShspInstanceProfile(
    keepAliveSeconds: keepAliveSeconds,
    onHandshakeListeners: _extractListeners<OnVoidListener>(onHandshake),
    onOpenListeners: _extractListeners<OnVoidListener>(onOpen),
    onClosingListeners: _extractListeners<OnVoidListener>(onClosing),
    onCloseListeners: _extractListeners<OnVoidListener>(onClose),
    onMessageListeners: _extractListeners<OnPeerListener>(messageCallback),
  );

  List<T> _extractListeners<T>(dynamic handler) {
    final result = <T>[];
    final map = handler.map as dynamic;
    for (var i = 0; i < (map.length as int); i++) {
      result.add(map.getByIndex(i) as T);
    }
    return result;
  }
}
