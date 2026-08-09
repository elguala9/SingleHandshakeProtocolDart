import 'dart:io';
import 'dart:typed_data';
import 'package:shsp/shsp.dart';

/// A custom message sender built from the public SHSP mixins:
/// - [IdempotentCloseMixin] gives it a safe, idempotent close()/destroy()
/// - [MessageSizeValidationMixin] gives it standard outgoing-message checks
class LoggingSender with IdempotentCloseMixin, MessageSizeValidationMixin {
  LoggingSender({required this.socket, required this.remotePeer});

  final IShspSocketBase socket;
  final PeerInfo remotePeer;

  void send(List<int> message) {
    // Throws ShspNetworkException if closed, ShspValidationException if the
    // message is empty or exceeds MessageSizeValidationMixin.maxMessageSize
    validateOutgoingMessage(
      message,
      isClosed,
      remotePeer.address.address,
      remotePeer.port,
    );

    final bytes = socket.sendTo(message, remotePeer);
    print(
      'Sent ${message.length} bytes ($bytes on wire) to '
      '${remotePeer.address.address}:${remotePeer.port}',
    );
  }

  // Called exactly once by IdempotentCloseMixin.close(), no matter how many
  // times close() or destroy() are invoked
  @override
  void closeImpl() {
    print('LoggingSender closed (closeImpl ran exactly once)');
  }
}

void main() async {
  final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 9200);
  final remotePeer = PeerInfo(
    address: InternetAddress('127.0.0.1'),
    port: 9000,
  );

  final sender = LoggingSender(socket: socket, remotePeer: remotePeer);

  print('Max UDP message size: ${MessageSizeValidationMixin.maxMessageSize}');

  // Valid message
  sender.send(Uint8List.fromList([1, 2, 3, 4, 5]));

  // Empty message is rejected by the validation mixin
  try {
    sender.send(const []);
  } on ShspValidationException catch (e) {
    print('Validation rejected empty message: ${e.message}');
  }

  // close() is idempotent: closeImpl() only runs the first time
  sender.close();
  sender.close();
  sender.destroy();

  // Sending after close is rejected
  try {
    sender.send(Uint8List.fromList([1]));
  } on ShspNetworkException catch (e) {
    print('Send after close rejected: ${e.message}');
  }

  socket.close();
  print('Done');
}
