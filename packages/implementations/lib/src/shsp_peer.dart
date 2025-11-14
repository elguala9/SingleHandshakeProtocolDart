// ...existing code...
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

/// SHSP Peer implementation
class ShspPeer implements IShspPeer {
  final PeerInfo remotePeer;
  final IShspSocket socket;
  MessageCallback? _onMessageCallback;

  ShspPeer({
    required this.remotePeer,
    required this.socket,
  }) {
    // Initialize the local callback in the socket
    final key = '${remotePeer.address.address}:${remotePeer.port}';
    socket.setMessageCallback(
      key,
      (msg, rinfo) {
        onMessage(msg, PeerInfo(
          address: rinfo.address,
          port: rinfo.port,
        ));
      },
    );
  }

  @override
  void close() {
    socket.close();
  }

  // ...existing code...

  @override
  void sendMessage(List<int> message) {
    // Note: sendTo is synchronous in Dart (UDP is non-blocking)
    socket.sendTo(message, remotePeer.address, remotePeer.port);
  }

  @override
  void setMessageCallback(MessageCallback cb) {
    _onMessageCallback = cb;
  }

  @override
  void onMessage(List<int> msg, PeerInfo info) {
    if (_onMessageCallback != null) {
      _onMessageCallback!(msg, info);
    }
  }
}
