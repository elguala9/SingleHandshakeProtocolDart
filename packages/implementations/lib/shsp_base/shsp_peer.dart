// ...existing code...
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

/// SHSP Peer implementation
class ShspPeer implements IShspPeer {
  /// Maximum UDP message size (65507 = 65535 - 8 bytes UDP header - 20 bytes IP header)
  static const int maxMessageSize = 65507;

  final PeerInfo remotePeer;
  final IShspSocket socket;
  late final MessageCallback _messageCallback;
  late MessageCallbackFunction _socketCallback;
  bool _closed = false;

  ShspPeer(
      {required this.remotePeer,
      required this.socket,
      MessageCallback? messageCallback}) {

    if (messageCallback != null) {
      _messageCallback = messageCallback;
    } else {
      _messageCallback = MessageCallback();
    }
    _socketCallback = (record) {
      onMessage(
          record.msg,
          PeerInfo(
            address: record.rinfo.address,
            port: record.rinfo.port,
          ));
    };

    // Register this peer with the socket so it receives messages
    socket.setMessageCallback(remotePeer, _socketCallback);
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



  @override
  void close() {
    // Make close() idempotent - can be called multiple times safely
    if (_closed) return;
    _closed = true;

    // Remove the message callback to prevent memory leaks
    socket.removeMessageCallback(remotePeer, _socketCallback);
  }

  @override
  String serializedObject() {
    return 'ShspPeer{remotePeer: ${remotePeer.address.address}:${remotePeer.port}}';
  }

  @override
  void sendMessage(List<int> message) {
    // Check if peer is closed
    if (_closed) {
      throw ShspNetworkException(
        'Cannot send message: peer is closed',
        address: remotePeer.address.address,
        port: remotePeer.port,
      );
    }

    // Validate message is not empty
    if (message.isEmpty) {
      throw ShspValidationException(
        'Message cannot be empty',
        field: 'message',
        value: message,
      );
    }

    // Validate message size (UDP has a maximum packet size)
    if (message.length > maxMessageSize) {
      throw ShspValidationException(
        'Message size ${message.length} exceeds maximum $maxMessageSize bytes',
        field: 'message.length',
        value: message.length,
      );
    }

    // Note: sendTo is synchronous in Dart (UDP is non-blocking)
    int bytes = socket.sendTo(message, remotePeer);
    if (bytes == 0) {
      throw ShspNetworkException(
        'Failed to send message - socket buffer may be full',
        address: remotePeer.address.address,
        port: remotePeer.port,
      );
    }
  }



  @override
  void onMessage(List<int> msg, PeerInfo info) {
    _messageCallback.call(info);
  }
  
  @override
  MessageCallback get messageCallback => _messageCallback;
}
