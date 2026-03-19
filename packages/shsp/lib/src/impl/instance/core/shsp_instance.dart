import '../../../interfaces/exceptions/shsp_exceptions.dart';
import '../../../interfaces/i_shsp_instance.dart';
import '../../../interfaces/i_shsp_socket.dart';
import '../../../types/instance_profile.dart';
import '../../../types/peer_types.dart';
import '../../peer/shsp_peer.dart';
import '../../utility/keep_alive_timer.dart';
import '../features/shsp_instance_keep_alive.dart';
import '../features/shsp_instance_handshake.dart';

const int dataPrefix = 0x00;
const int keepAlivePrefix = 0x04;

// TO DO (Extension) : Add callback for extra data after prefixes (eg. handshake with data)

/// SHSP Instance: manages handshake, closure, keep-alive and data messages.
class ShspInstance extends ShspPeer
    with ShspInstanceKeepAliveMixin, ShspInstanceHandshakeMixin
    implements IShspInstance {
  ShspInstance({
    required super.remotePeer,
    required super.socket,
    int keepAliveSeconds = 30,
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
    int keepAliveSeconds = 30,
  }) => ShspInstance(
    remotePeer: remotePeer,
    socket: socket,
    keepAliveSeconds: keepAliveSeconds,
  );

  /// Factory: creates a new SHSP instance from an existing ShspPeer.
  factory ShspInstance.fromPeer(ShspPeer peer, {int keepAliveSeconds = 30}) =>
      ShspInstance(
        remotePeer: peer.remotePeer,
        socket: peer.socket,
        keepAliveSeconds: keepAliveSeconds,
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

  bool _handshakeState = false;
  bool _closingState = false;
  bool _openState = false;
  int _keepAliveSecondsValue = 30;
  KeepAliveTimer? _keepAliveTimerValue;

  @override
  late CallbackOn onOpen;

  /// Getters/setters for handshake mixin
  @override
  bool get handshakeState => _handshakeState;
  @override
  set handshakeState(bool value) => _handshakeState = value;
  @override
  bool get closingState => _closingState;
  @override
  set closingState(bool value) => _closingState = value;
  @override
  bool get openState => _openState;
  @override
  set openState(bool value) => _openState = value;

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
    // Check protocol messages first
    if (isHandshake(msg)) {
      if (handshake && msg.length > 1 && msg[1] == 0x01) {
        openState = true;
        onOpen.call(null);
      }
      return;
    }
    if (isClosing(msg)) return;
    if (isClosed(msg)) return;
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

  /// Check if message is a keep-alive (0x04)
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

  /// Override close() to ensure keep-alive timer is stopped
  @override
  void close() {
    try {
      if (open) sendClosed();
    } catch (_) {
      // Ignore send errors during close (e.g. socket already closed)
    } finally {
      stopKeepAlive();
      super.close();
    }
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
