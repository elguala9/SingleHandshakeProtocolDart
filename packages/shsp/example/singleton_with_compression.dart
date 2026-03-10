/// SHSP with Socket Singleton and Compression Example
///
/// This example demonstrates:
/// - Using ShspSocketSingleton for global socket management
/// - Automatic compression for data
/// - Multiple peers sharing the same socket
/// - Socket switching and reconnection

import 'dart:io';
import 'dart:typed_data';
import 'package:shsp/shsp.dart';

void main() async {
  // Initialize the global singleton socket
  final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
  ShspSocketSingleton.instance = socket;
  print('Global socket bound to port ${socket.localPort}');

  // Create first peer with compression
  final peer1 = await AutoShspPeer.create(
    remoteInfo: RemoteInfo.fromString('127.0.0.1:9001')!,
    compressionCodec: GZipCodec(), // Enable GZip compression
  );

  // Create second peer with different compression
  final peer2 = await AutoShspPeer.create(
    remoteInfo: RemoteInfo.fromString('127.0.0.1:9002')!,
    compressionCodec: ZstdCodec(), // Use Zstd compression
  );

  print('Created peer1 and peer2 with compression');

  // Both peers automatically use the singleton socket
  peer1.onMessage((msg) {
    print('Peer1 received from ${msg.remotePeer.address.address}:${msg.remotePeer.port}');
  });

  peer2.onMessage((msg) {
    print('Peer2 received from ${msg.remotePeer.address.address}:${msg.remotePeer.port}');
  });

  // Send large data (compression will be applied)
  final largeData = Uint8List.fromList(List.generate(1000, (i) => i % 256));

  await peer1.sendData(largeData);
  print('Peer1 sent ${largeData.length} bytes (compressed)');

  await peer2.sendData(largeData);
  print('Peer2 sent ${largeData.length} bytes (compressed)');

  // Example: Switch to a different socket
  print('\nSwitching socket...');
  final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
  ShspSocketSingleton.instance = newSocket;
  print('Socket switched to port ${newSocket.localPort}');
  print('Both peers automatically reconnected to new socket');

  // Clean up
  await peer1.close();
  await peer2.close();
  await socket.close();
  await newSocket.close();
  print('All peers and sockets closed');
}
