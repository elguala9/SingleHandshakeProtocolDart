/// Basic SHSP Peer Example
///
/// This example demonstrates:
/// - Creating a simple peer connection
/// - Sending and receiving messages
/// - Proper cleanup

import 'dart:io';
import 'dart:typed_data';
import 'package:shsp/shsp.dart';

void main() async {
  // Create a peer for communication with a remote address
  final remotePeer = PeerInfo(
    address: InternetAddress('127.0.0.1'),
    port: 9000,
  );

  final peer = await AutoShspPeer.create(remotePeer: remotePeer);

  print('Peer created with local address: ${peer.socket.localAddress}:${peer.socket.localPort}');
  print('Remote peer: ${remotePeer.address.address}:${remotePeer.port}');

  // Send some data
  final data = Uint8List.fromList([1, 2, 3, 4, 5]);
  peer.sendMessage(data);
  print('Sent data: $data');

  // Keep the peer alive for a bit
  await Future.delayed(Duration(seconds: 2));

  // Clean up
  peer.close();
  print('Peer closed');
}
