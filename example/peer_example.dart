// import 'dart:typed_data';
// import 'package:shsp_implementations/shsp_implementations.dart';
// import 'package:shsp_interfaces/shsp_interfaces.dart';
// import 'package:shsp_types/shsp_types.dart';

/// Example usage of ShspPeer
void main() async {
  // This example shows how to use ShspPeer to communicate with a remote endpoint

  // Note: You need to create a ShspSocket first (see socket_example.dart)
  // For this example, we'll assume you have a socket instance

  print('ShspPeer example - see the inline documentation below');

  // Example: Creating a peer for a remote endpoint
  //
  // final socket = await createShspSocket(); // See socket_example.dart
  //
  // // Create a peer representing the remote endpoint
  // final peer = ShspPeer(
  //   remoteIp: '192.168.1.100',
  //   remotePort: 8081,
  //   socket: socket,
  // );
  //
  // // Register a callback to receive messages from this peer
  // peer.setMessageCallback((msg, info) {
  //   print('Received message from ${info.address}:${info.port}');
  //   print('Message: ${String.fromCharCodes(msg)}');
  // });
  //
  // // Send a message to the peer
  // final message = Uint8List.fromList('Hello, peer!'.codeUnits);
  // peer.sendMessage(message);
  //
  // // Get peer information as JSON
  // ...existing code...
  //
  // // Close the peer (this closes the underlying socket)
  // peer.close();
}
