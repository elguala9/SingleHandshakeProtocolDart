// ...existing code...
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';
import '../utility/message_callback_map.dart';

/// SHSP Peer implementation
class ShspPeer implements IShspPeer {
  /// Maximum UDP message size (65507 = 65535 - 8 bytes UDP header - 20 bytes IP header)
  static const int maxMessageSize = 65507;

  final PeerInfo remotePeer;
  final IShspSocket socket;
  MessageCallback? _onMessageCallback;
  MessageCallbackFunction? _socketCallback;
  bool _closed = false;

  ShspPeer(
      {required this.remotePeer,
      required this.socket,
      MessageCallback? onMessageCallback}) {
    if (onMessageCallback != null) setMessageCallback(onMessageCallback);
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
    final key =
        MessageCallbackMap.formatKey(remotePeer.address, remotePeer.port);
    _socketCallback = (record) {
      onMessage(
          record.msg,
          PeerInfo(
            address: record.rinfo.address,
            port: record.rinfo.port,
          ));
    };
    socket.setMessageCallback(key, _socketCallback!);
  }

  @override
  void close() {
    // Make close() idempotent - can be called multiple times safely
    if (_closed) return;
    _closed = true;

    // Remove the message callback to prevent memory leaks
    if (_socketCallback != null) {
      try {
        final key =
            MessageCallbackMap.formatKey(remotePeer.address, remotePeer.port);
        socket.removeMessageCallback(key, _socketCallback!);
      } catch (e) {
        // Log error but continue with close
        // In production, you might want to use a proper logger here
      }
    }

    // Note: We don't close the socket itself as it may be shared with other peers
    // The socket should be closed by the owner (ShspSocket or ShspInstance)
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
    try {
      int bytes = socket.sendTo(message, remotePeer.address, remotePeer.port);
      if (bytes == 0) {
        throw ShspNetworkException(
          'Failed to send message - socket buffer may be full',
          address: remotePeer.address.address,
          port: remotePeer.port,
        );
      }
    } on ShspNetworkException {
      rethrow;
    } catch (e) {
      throw ShspNetworkException(
        'Failed to send message',
        address: remotePeer.address.address,
        port: remotePeer.port,
        cause: e,
      );
    }
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
