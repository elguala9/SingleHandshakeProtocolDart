import 'package:meta/meta.dart';
import 'package:shsp_implementations/shsp_implementations.dart';
// ...existing code...
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

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

  @protected
  void Function()? onHandshake;
  @protected
  void Function()? onOpen;
  @protected
  void Function()? onClosing;
  @protected
  void Function()? onClosed;
  @override
  void setCallbacks(InstanceCallbacks callbacks) {
    final (:onHandshake, :onOpen, :onClosing, :onClosed) = callbacks;
    this.onHandshake = onHandshake;
    this.onOpen = onOpen;
    this.onClosing = onClosing;
    this.onClosed = onClosed;
  }

  @override
  InstanceCallbacks getCallbacks(){

      return (
        onHandshake: onHandshake,
        onOpen: onOpen,
        onClosing: onClosing,
        onClosed: onClosed,
      );
  }

  

  ShspInstance({
    required super.remotePeer,
    required super.socket,
    int keepAliveSeconds = 30,
  }) : _keepAliveSeconds = keepAliveSeconds;

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
      if (onHandshake != null) onHandshake!();
      // if [0x01, 0x01] then the other peer got my handshake
      if (msg.length > 1 && msg[1] == handshakePrefix) {
        _open = true;
        if (onOpen != null) onOpen!();
      }
      return true;
    }
    return false;
  }

  /// Check if message is a closing signal (0x02)
  bool _isClosing(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == closingPrefix) {
      _closing = true;
      if (onClosing != null) onClosing!();
      return true;
    }
    return false;
  }

  /// Check if message is a closed signal (0x03)
  bool _isClosed(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == closedPrefix) {
      _closing = false;
      _open = false;
      if (onClosed != null) onClosed!();
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

    // Call parent close() to remove callbacks
    super.close();
  }
}
