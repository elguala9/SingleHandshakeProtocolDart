import 'dart:async';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';
import 'shsp_peer.dart';
import 'utility/keep_alive_timer.dart';

/// SHSP Instance implementation
/// Handles protocol messages (handshake, closing, closed, keep-alive)
class ShspInstance extends ShspPeer implements IShspInstance {
  bool _handshake = false;
  bool _closing = false;
  bool _open = false;
  int _keepAliveSeconds;
  KeepAliveTimer? _keepAliveTimer;

  ShspInstance({
    required super.remotePeer,
    required super.socket,
    int keepAliveSeconds = 30,
  }) : _keepAliveSeconds = keepAliveSeconds;

  @override
  void onMessage(List<int> msg, PeerInfo info) {
    // Check protocol messages first
    if (_isHandshake(msg)) return;
    if (_isClosing(msg)) return;
    if (_isClosed(msg)) return;
    if (_isKeepAlive(msg)) return;

    // Pass to parent for user callback
    super.onMessage(msg, info);
  }

  /// Check if message is a handshake (0x01)
  bool _isHandshake(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == 0x01) {
      _handshake = true;
      _open = true;
      return true;
    }
    return false;
  }

  /// Check if message is a closing signal (0x02)
  bool _isClosing(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == 0x02) {
      _closing = true;
      return true;
    }
    return false;
  }

  /// Check if message is a closed signal (0x03)
  bool _isClosed(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == 0x03) {
      _open = false;
      return true;
    }
    return false;
  }

  /// Check if message is a keep-alive (0x04)
  bool _isKeepAlive(List<int> msg) {
    if (msg.isNotEmpty && msg[0] == 0x04) {
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
    _handshake = true;
    _open = true;
    sendMessage([0x01]);
  }

  @override
  void keepAlive() {
    sendMessage([0x04]);
  }
  
  @override
  void sendClosing() {
    _closing = true;
    sendMessage([0x02]);
  }

  @override
  void sendClosed() {
    _closing = true;
    sendMessage([0x03]);
  }

  /// Start sending keep-alive messages periodically
  @override
  void startKeepAlive() {
    if (_keepAliveTimer != null && _keepAliveTimer!.isActive) {
      return; // Already running
    }
    _keepAliveTimer = KeepAliveTimer.periodic(
      Duration(seconds: keepAliveSeconds),
      (_) {
        keepAlive();
      },
    );
  }

  /// Stop sending keep-alive messages
  @override
  void stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  /// Reset the keep-alive timer countdown
  /// Updates the last activity timestamp, deferring the next keep-alive message
  /// without recreating the timer (more efficient)
  void resetKeepAlive() {
    _keepAliveTimer?.resetTick();
  }

  @override
  void sendMessage(List<int> message) {
    super.sendMessage(message);
    // Reset keep-alive timer on any outgoing message 
    resetKeepAlive();
  }

}
