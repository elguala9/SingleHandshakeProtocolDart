import 'dart:io';
import 'package:shsp/shsp.dart';

/// Example demonstrating ShspPeer usage
void main() async {
  print('=== SHSP Peer Example ===\n');

  // Step 1: Create and bind a socket
  final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 8080);
  print('Socket bound on ${socket.localAddress?.address}:${socket.localPort}\n');

  // Step 2: Create a peer representing a remote endpoint
  final remotePeerInfo = PeerInfo(
    address: InternetAddress('127.0.0.1'),
    port: 8081,
  );

  final peer = ShspPeer.create(
    remotePeer: remotePeerInfo,
    socket: socket,
  );
  print('Peer created for ${remotePeerInfo.address.address}:${remotePeerInfo.port}\n');

  // Step 3: Register a callback to receive messages from this peer
  peer.messageCallback.register((peerInfo) {
    print('Received message from ${peerInfo.address.address}:${peerInfo.port}');
  });

  // Step 4: Send a message to the peer
  final message = 'Hello, peer!'.codeUnits.toList();
  peer.sendMessage(message);
  print('Sent message: Hello, peer!\n');

  // Step 5: Get peer information
  print('Peer remote address: ${peer.remotePeer.address.address}');
  print('Peer remote port: ${peer.remotePeer.port}\n');

  // Step 6: Simulate receiving a message from the peer
  print('Simulating incoming message from peer...\n');
  final incomingMessage = 'Hello from peer!'.codeUnits.toList();
  peer.onMessage(incomingMessage, remotePeerInfo);

  // Step 7: Close the peer
  peer.close();
  socket.close();
  print('=== Example Complete ===');
}
