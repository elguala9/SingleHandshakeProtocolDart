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
    MessageCallback? onMessageCallback
  }) {
    if(onMessageCallback != null) setMessageCallback(onMessageCallback);
    _setupMessageCallback();
  }

  /// Factory constructor - creates a ShspPeer with a remote peer and socket
  /// 
  /// This factory method:
  /// - Creates a new ShspPeer instance
  /// - Automatically registers message callbacks with the socket
  /// - Sets up routing for messages from the remote peer
  /// 
  /// Parameters:
  ///   - [remotePeer]: Information about the remote peer (address and port)
  ///   - [socket]: The underlying SHSP socket for communication
  /// 
  /// Returns: A new ShspPeer instance ready to send/receive messages
  /// 
  /// Example:
  /// ```dart
  /// final remotePeer = PeerInfo(
  ///   address: InternetAddress('192.168.1.100'),
  ///   port: 9000,
  /// );
  /// final peer = ShspPeer.create(
  ///   remotePeer: remotePeer,
  ///   socket: mySocket,
  /// );
  /// ```
  factory ShspPeer.create({
    required PeerInfo remotePeer,
    required IShspSocket socket,
  }) {
    return ShspPeer(
      remotePeer: remotePeer,
      socket: socket,
    );
  }

  /// Setup message callback in the socket
  void _setupMessageCallback() {
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

  @override
  String serializedObject() {
    return 'ShspPeer{remotePeer: ${remotePeer.address.address}:${remotePeer.port}}';
  }

  @override
  void sendMessage(List<int> message) {
    // Note: sendTo is synchronous in Dart (UDP is non-blocking)
    int bytes = socket.sendTo(message, remotePeer.address, remotePeer.port);
    if(bytes == 0) throw Exception('Failed to send message to ${remotePeer.address.address}:${remotePeer.port}, the block is too big');
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
