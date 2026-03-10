import 'dart:io';
import 'package:shsp/shsp.dart';

/// Example demonstrating ShspInstance usage with protocol messages
void main() async {
  print('=== SHSP Instance Example ===\n');

  // Create and bind a socket
  final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 8080);
  print(
    'Socket bound on ${socket.localAddress?.address}:${socket.localPort}\n',
  );

  // Create a remote peer info
  final remotePeer = PeerInfo(
    address: InternetAddress('127.0.0.1'),
    port: 8081,
  );

  // Create an instance for the remote peer
  final instance = ShspInstance(remotePeer: remotePeer, socket: socket);

  // Register message callback
  instance.messageCallback.register((peerInfo) {
    print('User message received from ${peerInfo.address.address}:${peerInfo.port}\n');
  });

  // Simulate receiving protocol messages
  print('Simulating protocol messages:\n');

  // Step 1: Receive handshake from peer (0x01)
  final handshakeMsg = [0x01];
  instance.onMessage(handshakeMsg, remotePeer);
  print(
    'After handshake received: open=${instance.open}, handshake=${instance.handshake}\n',
  );

  // Step 2: Send our handshake back
  instance.sendHandshake();
  print('Sent handshake back\n');

  // Step 3: User message from peer (with 0x00 prefix)
  final userMsg = [0x00, ...('Hello World!'.codeUnits)];
  instance.onMessage(userMsg, remotePeer);
  print('After user message received\n');

  // Step 4: Keep-alive message (0x04) - should be handled silently
  final keepAliveMsg = [0x04];
  instance.onMessage(keepAliveMsg, remotePeer);
  print('After keep-alive received: open=${instance.open}\n');

  // Step 5: Send a response message to the remote peer
  try {
    final sendMsg = 'Response message'.codeUnits.toList();
    instance.sendMessage(sendMsg);
    print('Sent message to ${remotePeer.address.address}:${remotePeer.port}\n');
  } catch (e) {
    print('Cannot send message: $e\n');
  }

  // Step 6: Simulate closing sequence
  // Closing message (0x02)
  final closingMsg = [0x02];
  instance.onMessage(closingMsg, remotePeer);
  print(
    'After closing signal received: closing=${instance.closing}, open=${instance.open}\n',
  );

  // Closed message (0x03)
  final closedMsg = [0x03];
  instance.onMessage(closedMsg, remotePeer);
  print('After closed signal received: open=${instance.open}\n');

  // Cleanup
  socket.close();
  print('\n=== Example Complete ===');
}
