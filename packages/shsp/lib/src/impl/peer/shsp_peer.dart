import '../../../shsp.dart';

/// SHSP Peer implementation
class ShspPeer with IdempotentCloseMixin, MessageSizeValidationMixin implements IShspPeer {
  ShspPeer({
    required this.remotePeer,
    required this.socket,
    MessageCallback? messageCallback,
  }) {
    if (messageCallback != null) {
      _messageCallback = messageCallback;
    } else {
      _messageCallback = MessageCallback();
    }
    _socketCallback = (record) {
      onMessage(
        record.msg,
        PeerInfo(address: record.rinfo.address, port: record.rinfo.port),
      );
    };

    socket.setMessageCallback(remotePeer, _socketCallback);
  }

  factory ShspPeer.create({
    required PeerInfo remotePeer,
    required IShspSocketBase socket,
  }) => ShspPeer(remotePeer: remotePeer, socket: socket);

  final PeerInfo remotePeer;
  final IShspSocketBase socket;
  late final MessageCallback _messageCallback;
  late MessageCallbackFunction _socketCallback;

  MessageCallbackFunction get socketCallbackFunction => _socketCallback;

  @override
  void closeImpl() {
    socket.removeMessageCallback(remotePeer, _socketCallback);
  }

  @override
  String serializedObject() =>
      'ShspPeer{remotePeer: ${remotePeer.address.address}:${remotePeer.port}}';

  @override
  void sendMessage(List<int> message) {
    validateOutgoingMessage(message, isClosed, remotePeer.address.address, remotePeer.port);

    final bytes = socket.sendTo(message, remotePeer);
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
