import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';
import 'shsp_peer.dart';

/// SHSP Instance implementation
/// Handles protocol messages (handshake, closing, closed, keep-alive)
class ShspInstance extends ShspPeer implements IShspInstance {
  bool _handshake = false;
  bool _closing = false;
  bool _open = false;

  ShspInstance({
    required super.remotePeer,
    required super.socket,
  });

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
}
