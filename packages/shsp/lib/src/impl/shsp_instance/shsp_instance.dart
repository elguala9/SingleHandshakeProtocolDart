import 'package:meta/meta.dart';
// ...existing code...
import '../../interfaces/connection/i_shsp_handshake.dart';
import '../../interfaces/exceptions/shsp_exceptions.dart';
import '../../interfaces/i_compression_codec.dart';
import '../../interfaces/i_shsp_instance.dart';
import '../../interfaces/i_shsp_instance_handler.dart';
import '../../interfaces/i_shsp_peer.dart';
import '../../interfaces/i_shsp_socket.dart';
import '../../types/callback_types.dart';
import '../../types/instance_profile.dart';
import '../../types/internet_address_converter.dart';
import '../../types/peer_types.dart';
import '../../types/remote_info.dart';
import '../../types/socket_profile.dart';
import '../shsp_base/shsp_peer.dart';
import '../utility/keep_alive_timer.dart';

const int dataPrefix = 0x00;
const int handshakePrefix = 0x01;
const int closingPrefix = 0x02;
const int closedPrefix = 0x03;
const int keepAlivePrefix = 0x04;

// TO DO (Extension) : Add callback for extra data after prefixes (eg. handshake with data)

/// SHSP Instance: manages handshake, closure, keep-alive and data messages.
class ShspInstance extends ShspPeer implements IShspInstance {
  bool _handshake = false;
  bool _closing = false;
  bool _open = false;
  int _keepAliveSeconds;
  @protected
  KeepAliveTimer? keepAliveTimer;

  @override
  late CallbackOn onHandshake;
  @override
  late CallbackOn onOpen;
  @override
  late CallbackOn onClosing;
  @override
  late CallbackOn onClose;

  ShspInstance({
    required super.remotePeer,
    required super.socket,
    int keepAliveSeconds = 30,
  }) : _keepAliveSeconds = keepAliveSeconds {
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
  }) {
    return ShspInstance(
      remotePeer: remotePeer,
      socket: socket,
      keepAliveSeconds: keepAliveSeconds,
    );
  }

  /// Factory: creates a new SHSP instance from an existing ShspPeer.
  factory ShspInstance.fromPeer(
    ShspPeer peer, {
    int keepAliveSeconds = 30,
  }) {
    return ShspInstance(
      remotePeer: peer.remotePeer,
      socket: peer.socket,
      keepAliveSeconds: keepAliveSeconds,
    );
  }

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
    for (final cb in profile.onHandshakeListeners) {
      instance.onHandshake.register(cb);
    }
    for (final cb in profile.onOpenListeners) {
      instance.onOpen.register(cb);
    }
    for (final cb in profile.onClosingListeners) {
      instance.onClosing.register(cb);
    }
    for (final cb in profile.onCloseListeners) {
      instance.onClose.register(cb);
    }
    for (final cb in profile.onMessageListeners) {
      instance.messageCallback.register(cb);
    }
    return instance;
  }

  @override
  void onMessage(List<int> msg, PeerInfo info) {
    // Check protocol messages first
    if (_isHandshake(msg)) return;
    if (_isClosing(msg)) return;
    if (_isClosed(msg)) return;
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

  /// Check if message is a handshake (0x01)
  bool _isHandshake(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == handshakePrefix) {
      _handshake = true; // i got the handshake of the other peer
      onHandshake.call(null);
      // if [0x01, 0x01] then the other peer got my handshake
      if (msg.length > 1 && msg[1] == handshakePrefix) {
        _open = true;
        onOpen.call(null);
      }
      return true;
    }
    return false;
  }

  /// Check if message is a closing signal (0x02)
  bool _isClosing(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == closingPrefix) {
      _closing = true;
      onClosing.call(null);
      return true;
    }
    return false;
  }

  /// Check if message is a closed signal (0x03)
  bool _isClosed(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == closedPrefix) {
      _closing = false;
      _open = false;
      onClose.call(null);
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
  bool get handshake => _handshake;

  @override
  bool get closing => _closing;

  @override
  bool get open => _open;

  @override
  int get keepAliveSeconds => _keepAliveSeconds;

  @override
  set keepAliveSeconds(int seconds) {
    _keepAliveSeconds = seconds;
    stopKeepAlive();
    startKeepAlive();
  }

  @override
  void sendHandshake() {
    List<int> msg = [handshakePrefix];
    if (_handshake) {
      // if i got the handshake i add a 0x01 to inform the other peer
      msg.add(handshakePrefix);
    }
    _sendMessage(msg);
  }

  @override
  void keepAlive() {
    if (closing || !open) return; // do not send keep-alive if closing or closed
    _sendMessage([keepAlivePrefix]);
  }

  @override
  void sendClosing() {
    _sendMessage([closingPrefix]);
    _closing = true;
  }

  @override
  void sendClosed() {
    _sendMessageNoCheck([closedPrefix]);
    _closing = false;
    _open = false;
  }

  /// Starts periodic keep-alive sending.
  @override
  void startKeepAlive() {
    if (keepAliveTimer != null && keepAliveTimer!.isActive) {
      return; // Already running
    }
    keepAliveTimer = KeepAliveTimer.periodic(
      Duration(seconds: keepAliveSeconds),
      (_) {
        try {
          keepAlive();
        } catch (e, stackTrace) {
          // Log error but don't crash the timer
          // In production, use a proper logger
          print('Error in keep-alive callback: $e\n$stackTrace');
          // Optionally close the connection on repeated errors
        }
      },
    );
  }

  /// Stops periodic keep-alive sending.
  @override
  void stopKeepAlive() {
    if (keepAliveTimer != null) {
      try {
        keepAliveTimer!.cancel();
      } catch (e) {
        // Log error but continue cleanup
        print('Error canceling keep-alive timer: $e');
      } finally {
        keepAliveTimer = null;
      }
    }
  }

  /// Resets the keep-alive timer (postpones the next sending).
  void resetKeepAlive() {
    keepAliveTimer?.resetTick();
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
    _sendMessage(message);
  }

  void _sendMessage(List<int> message) {
    if (closing == true) {
      throw ShspInstanceException(
        'Cannot send message: connection is closing',
        instanceId: '${remotePeer.address.address}:${remotePeer.port}',
      );
    }

    _sendMessageNoCheck(message);
    // Reset keep-alive timer on any outgoing message
    resetKeepAlive();
  }

  void _sendMessageNoCheck(List<int> message) {
    super.sendMessage(message);
  }

  /// Override close() to ensure keep-alive timer is stopped
  @override
  void close() {
    // Stop keep-alive timer to prevent resource leak
    stopKeepAlive();
    // only if already not send the close i send it
    if(open) sendClosed();

    // Call parent close() to remove callbacks
    super.close();
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
  ShspInstanceProfile extractProfile() {
    List<T> listeners<T>(dynamic handler) {
      final result = <T>[];
      for (var i = 0; i < handler.map.length; i++) {
        result.add(handler.map.getByIndex(i) as T);
      }
      return result;
    }

    return ShspInstanceProfile(
      keepAliveSeconds: _keepAliveSeconds,
      onHandshakeListeners: listeners<OnVoidListener>(onHandshake),
      onOpenListeners: listeners<OnVoidListener>(onOpen),
      onClosingListeners: listeners<OnVoidListener>(onClosing),
      onCloseListeners: listeners<OnVoidListener>(onClose),
      onMessageListeners: listeners<OnPeerListener>(messageCallback),
    );
  }
}
