import 'dart:io';
import 'package:shsp/shsp.dart';

/// Example demonstrating ShspSocket usage
void main() async {
  print('=== SHSP Socket Example ===\n');

  // Create and bind a new SHSP socket
  final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 8080);
  print(
    'Socket bound on ${socket.localAddress?.address}:${socket.localPort}\n',
  );

  // Set up callbacks
  socket.setErrorCallback((error) {
    print('Socket error: $error');
  });

  socket.setCloseCallback(() {
    print('Socket closed');
  });

  // Set message callback for a specific peer
  final remotePeer = PeerInfo(
    address: InternetAddress('127.0.0.1'),
    port: 8081,
  );
  socket.setMessageCallback(remotePeer, (record) {
    print(
      'Received message from ${record.rinfo.address.address}:${record.rinfo.port}',
    );
    print('Message: ${String.fromCharCodes(record.msg)}');
  });

  // Simulate sending a message
  final message = 'Hello from Dart!'.codeUnits.toList();
  final bytesSent = socket.sendTo(message, remotePeer);
  print('Sent $bytesSent bytes to 127.0.0.1:8081\n');

  // Keep the socket open for a few seconds to receive messages
  print('Waiting for incoming messages (5 seconds)...');
  await Future.delayed(const Duration(seconds: 5));

  // Close the socket
  socket.close();
  print('\n=== Example Complete ===');
}
