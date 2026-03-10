/// SHSP with Socket Singleton and Compression Example
///
/// This example demonstrates:
/// - Using ShspSocketSingleton for global socket management
/// - Automatic compression for data
/// - Multiple peers sharing the same socket

import 'dart:io';
import 'dart:typed_data';
import 'package:shsp/shsp.dart';

void main() async {
  print('=== Socket Singleton with Compression Example ===\n');

  // Initialize the global singleton socket
  print('Initializing global socket...');
  final singleton = await ShspSocketSingleton.getInstance(
    address: InternetAddress.anyIPv4,
    port: 0, // Use ephemeral port
  );
  print('✓ Global socket bound to port ${singleton.socket.localPort}\n');

  // Create first peer with GZip compression
  final remotePeer1 = PeerInfo(
    address: InternetAddress('127.0.0.1'),
    port: 9001,
  );

  final peer1 = await AutoShspPeer.create(
    remotePeer: remotePeer1,
    compressionCodec: GZipCodec(),
  );
  print('✓ Peer1 created (GZip compression)');

  // Create second peer with Zstd compression
  final remotePeer2 = PeerInfo(
    address: InternetAddress('127.0.0.1'),
    port: 9002,
  );

  final peer2 = await AutoShspPeer.create(
    remotePeer: remotePeer2,
    compressionCodec: ZstdCodec(),
  );
  print('✓ Peer2 created (Zstd compression)');

  print('\nBoth peers automatically use the singleton socket\n');

  // Send large data (compression will be applied automatically)
  final largeData = Uint8List.fromList(List.generate(1000, (i) => i % 256));

  print('Sending data with compression...');
  peer1.sendMessage(largeData);
  print('✓ Peer1 sent ${largeData.length} bytes (compressed with GZip)');

  peer2.sendMessage(largeData);
  print('✓ Peer2 sent ${largeData.length} bytes (compressed with Zstd)\n');

  // Keep alive briefly
  await Future.delayed(Duration(seconds: 2));

  // Clean up
  print('Cleaning up...');
  peer1.close();
  peer2.close();
  print('✓ All peers closed');
}
