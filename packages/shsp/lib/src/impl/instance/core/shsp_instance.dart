import 'dart:async';
import 'dart:developer';

import '../../../../shsp.dart';

const int dataPrefix = 0x00;
const int keepAlivePrefix = 0x05;

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
      livenessTimeoutSeconds: profile.livenessTimeoutSeconds,
    )
      ..closingRetransmitInterval = profile.closingRetransmitInterval
      ..closingTimeout = profile.closingTimeout;
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

  /// Liveness timeout in seconds (Section 7), applied while OPEN or CLOSING:
  /// if no message is received from the peer within this duration, the
  /// session is closed locally (abortive close), without waiting for a peer response. `null` disables
  /// this behavior entirely.
  final int? livenessTimeoutSeconds;

  /// Timer backing the liveness timeout. Reuses [KeepAliveTimer] as a generic
  /// resettable periodic timer; it is unrelated to the outgoing keep-alive
  /// timer managed by [ShspInstanceKeepAliveMixin].
  KeepAliveTimer? _livenessTimerValue;

  /// Interval between Closing retransmissions while CLOSING (Section 8).
  Duration closingRetransmitInterval = const Duration(milliseconds: 500);

  /// Maximum time spent in CLOSING waiting for the peer's Closed (Section 8).
  Duration closingTimeout = const Duration(seconds: 3);

  Timer? _closingRetransmitTimer;
  Timer? _closingTimeoutTimer;

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
    // Section 3: a zero-byte datagram is never a valid SHSP message.
    if (msg.isEmpty) return;

    // Section 5 (CLOSED): no further incoming message may be processed.
    if (_connectionState == ShspConnectionState.closed) return;

    final prefix = msg[0];

    // Section 5 (CREATED): only a Handshake probe (0x01) can legitimately be
    // received while still in this state; anything else MUST be discarded.
    if (_connectionState == ShspConnectionState.created &&
        prefix != handshakePrefix) {
      return;
    }

    switch (prefix) {
      case handshakePrefix:
        // Section 6 step 2: every well-formed probe received in CREATED,
        // HANDSHAKING or OPEN MUST be acknowledged, including duplicates and
        // probes received after OPEN. Probes received in CLOSING are not.
        if (_connectionState == ShspConnectionState.closing) return;
        if (!isHandshake(msg)) return;
        _resetLiveness();
        // The ack is best-effort: its loss is already covered by probe
        // retransmission and implicit confirmation, so a transient send
        // failure must not propagate out of the receive path.
        try {
          sendHandshakeAck();
        } catch (e) {
          log('Error sending handshake ack: $e', name: 'ShspInstance');
        }
        return;
      case handshakeAckPrefix:
        _resetLiveness();
        final wasHandshaking =
            _connectionState == ShspConnectionState.handshaking;
        isHandshakeAck(msg);
        // Only fire onOpen on the OPEN transition, not on every subsequent ack.
        if (wasHandshaking) _onOpened();
        return;
      case closingPrefix:
        _onClosingReceived();
        return;
      case closedPrefix:
        // Section 8: Closed received -> CLOSED, no reply; release resources.
        _teardown(sendClosedMessage: false);
        return;
      case keepAlivePrefix:
      case dataPrefix:
        // Section 7: only well-formed messages reset the liveness timeout.
        _resetLiveness();
        // Section 6 step 6: Data or Keep-alive received while HANDSHAKING is
        // an implicit handshake confirmation.
        if (_connectionState == ShspConnectionState.handshaking) {
          _connectionState = ShspConnectionState.open;
          _onOpened();
        }
        if (prefix == dataPrefix) super.onMessage(msg, info);
        return;
      default:
        // Section 4: unknown prefixes are discarded without affecting state.
        log(
          'Discarded message with unknown prefix 0x${prefix.toRadixString(16)}',
          name: 'ShspInstance',
        );
    }
  }

  /// Section 8 (responder / simultaneous close): reply with Closed and move
  /// to CLOSED, surfacing the closing notification first.
  void _onClosingReceived() {
    // In a simultaneous close the local side initiated the close itself and
    // already knows the session is closing: do not surface it again.
    if (_connectionState != ShspConnectionState.closing) {
      onClosing.call(null);
    }
    // close() sends the mandatory Closed reply and releases resources.
    close();
  }

  /// Common OPEN-transition side effects: starts the periodic keep-alive
  /// (Section 7) and notifies listeners.
  void _onOpened() {
    startKeepAlive();
    _startLiveness();
    // Section 6 step 7: send one keep-alive promptly so the peer can confirm
    // the handshake implicitly even if all our acknowledgments were lost.
    try {
      keepAlive();
    } catch (e) {
      log('Error sending initial keep-alive: $e', name: 'ShspInstance');
    }
    onOpen.call(null);
  }

  @override
  void keepAlive() {
    if (closing || !open) return; // do not send keep-alive if closing or closed
    sendMessageInternal([keepAlivePrefix]);
  }

  @override
  void sendMessage(List<int> message) {
    final instanceId = '${remotePeer.address.address}:${remotePeer.port}';
    if (_connectionState == ShspConnectionState.closed) {
      throw ShspInstanceException(
        'Cannot send message: connection is closed',
        instanceId: instanceId,
      );
    }
    if (!open) {
      throw ShspInstanceException(
        'Cannot send message: connection is not open',
        instanceId: instanceId,
      );
    }
    // Section 3: the application payload of a Data message MUST NOT be empty.
    if (message.isEmpty) {
      throw ShspValidationException(
        'Application payload cannot be empty',
        field: 'message',
        value: message,
      );
    }
    // Do not mutate the caller's list.
    sendMessageInternal([dataPrefix, ...message]);
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

  /// Graceful close (Section 8, initiator): sends Closing, enters CLOSING and
  /// retransmits Closing every [closingRetransmitInterval] until the peer's
  /// Closed is received or [closingTimeout] expires, after which a
  /// best-effort Closed is sent and the session moves to CLOSED.
  /// A no-op unless the session is OPEN.
  ///
  /// A failure to transmit the first Closing is tolerated (Section 8): it is
  /// logged, the session still enters CLOSING and relies on retransmissions
  /// and the closing timeout. No error is raised to the caller.
  @override
  void sendClosing() {
    if (_connectionState != ShspConnectionState.open) return;
    try {
      super.sendClosing();
    } catch (e) {
      log('Error sending closing: $e', name: 'ShspInstance');
      _connectionState = ShspConnectionState.closing;
    }
    stopKeepAlive();
    _closingRetransmitTimer = Timer.periodic(closingRetransmitInterval, (_) {
      if (_connectionState != ShspConnectionState.closing) return;
      try {
        sendMessageUnchecked([closingPrefix]);
      } catch (_) {
        // Tolerated (Section 8).
      }
    });
    _closingTimeoutTimer = Timer(closingTimeout, close);
  }

  void _stopClosingTimers() {
    _closingRetransmitTimer?.cancel();
    _closingRetransmitTimer = null;
    _closingTimeoutTimer?.cancel();
    _closingTimeoutTimer = null;
  }

  /// Abortive close (Section 8): sends a best-effort Closed if the session
  /// was HANDSHAKING, OPEN or CLOSING, then moves to CLOSED and releases
  /// resources. Idempotent: on a CLOSED session no message is sent and
  /// [onClose] is not fired again.
  @override
  void close() => _teardown(sendClosedMessage: true);

  /// Single CLOSED transition used by every close path (local close, Closing
  /// or Closed received, closing timeout, liveness timeout, handshake retry
  /// exhaustion). Fires [onClose] exactly once, after resources are released.
  void _teardown({required bool sendClosedMessage}) {
    final previous = _connectionState;
    if (previous == ShspConnectionState.closed) {
      super.close();
      return;
    }
    try {
      if (sendClosedMessage && previous != ShspConnectionState.created) {
        sendClosed();
      }
    } catch (_) {
      // Ignore send errors during close (e.g. socket already closed)
    } finally {
      _stopClosingTimers();
      stopKeepAlive();
      _stopLiveness();
      _connectionState = ShspConnectionState.closed;
      super.close();
    }
    onClose.call(null);
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
    livenessTimeoutSeconds: livenessTimeoutSeconds,
    closingRetransmitInterval: closingRetransmitInterval,
    closingTimeout: closingTimeout,
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
