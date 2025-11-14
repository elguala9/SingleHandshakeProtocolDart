import 'dart:io';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'package:shsp_types/shsp_types.dart';

/// Example demonstrating ShspInstance usage with protocol messages
void main() async {
  print('=== SHSP Instance Example ===\n');

  // Create and bind a socket
  final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 8080);
  print('Socket bound on ${socket.localAddress?.address}:${socket.localPort}\n');

  // Create a remote peer info
  final remotePeer = PeerInfo(
    address: InternetAddress('127.0.0.1'),
    port: 8081,
  );

  // Create an instance for the remote peer
  final instance = ShspInstance(
    remotePeer: remotePeer,
    socket: socket,
  );

  // Register message callback
  instance.setMessageCallback((msg, info) {
    print('User message received from ${info.address.address}:${info.port}');
    print('Message: ${String.fromCharCodes(msg)}\n');
  });

  // Simulate receiving protocol messages
  print('Simulating protocol messages:\n');

  // Handshake message (0x01)
  final handshakeMsg = [0x01];
  instance.onMessage(handshakeMsg, remotePeer);
  print('After handshake: open=${instance.open}, handshake=${instance.handshake}\n');

  // User message (should trigger callback)
  final userMsg = 'Hello World!'.codeUnits.toList();
  instance.onMessage(userMsg, remotePeer);

  // Keep-alive message (0x04) - should be handled silently
  final keepAliveMsg = [0x04];
  instance.onMessage(keepAliveMsg, remotePeer);
  print('After keep-alive: open=${instance.open}\n');

  // Closing message (0x02)
  final closingMsg = [0x02];
  instance.onMessage(closingMsg, remotePeer);
  print('After closing signal: closing=${instance.closing}, open=${instance.open}\n');

  // Closed message (0x03)
  final closedMsg = [0x03];
  instance.onMessage(closedMsg, remotePeer);
  print('After closed signal: open=${instance.open}\n');

  // Send a message to the remote peer
  final sendMsg = 'Response message'.codeUnits.toList();
  instance.sendMessage(sendMsg);
  print('Sent message to ${remotePeer.address.address}:${remotePeer.port}');

  // Cleanup
  socket.close();
  print('\n=== Example Complete ===');
}
