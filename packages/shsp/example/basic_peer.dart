/// Basic SHSP Peer Example
///
/// This example demonstrates:
/// - Creating a simple peer connection
/// - Sending and receiving messages
/// - Proper cleanup

import 'dart:typed_data';
import 'package:shsp/shsp.dart';

void main() async {
  // Create a peer for communication with a remote address
  final peer = await AutoShspPeer.create(
    remoteInfo: RemoteInfo.fromString('127.0.0.1:9000')!,
  );

  print('Peer created with address: ${peer.socket.localAddress}:${peer.socket.localPort}');

  // Register a callback to handle incoming messages
  peer.onMessage((message) {
    print('Received message from ${message.remotePeer.address.address}:${message.remotePeer.port}');
    print('Payload: ${message.payload}');
  });

  // Send some data
  final data = Uint8List.fromList([1, 2, 3, 4, 5]);
  await peer.sendData(data);
  print('Sent data: $data');

  // Keep the peer alive for a bit to receive responses
  await Future.delayed(Duration(seconds: 2));

  // Clean up
  await peer.close();
  print('Peer closed');
}
