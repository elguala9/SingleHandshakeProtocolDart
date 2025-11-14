import 'dart:io';
import 'package:shsp_implementations/shsp_implementations.dart';

/// Example demonstrating ShspSocket usage
void main() async {
  print('=== SHSP Socket Example ===\n');

  // Create and bind a new SHSP socket
  final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 8080);
  print('Socket bound on ${socket.localAddress?.address}:${socket.localPort}\n');

  // Set up callbacks
  socket.setErrorCallback((error) {
    print('Socket error: $error');
  });

  socket.setCloseCallback(() {
    print('Socket closed');
  });

  // Set message callback for a specific peer
  socket.setMessageCallback('127.0.0.1:8081', (msg, rinfo) {
    print('Received message from ${rinfo.address.address}:${rinfo.port}');
    print('Message: ${String.fromCharCodes(msg)}');
  });


  // Simulate sending a message
  final message = 'Hello from Dart!'.codeUnits.toList();
  final bytesSent = socket.sendTo(message, InternetAddress('127.0.0.1'), 8081);
  print('Sent $bytesSent bytes to 127.0.0.1:8081\n');

  // Keep the socket open for a few seconds to receive messages
  print('Waiting for incoming messages (5 seconds)...');
  await Future.delayed(const Duration(seconds: 5));

  // Close the socket
  socket.close();
  print('\n=== Example Complete ===');
}
