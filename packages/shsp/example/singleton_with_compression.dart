import 'dart:io';
import 'dart:typed_data';
import 'package:shsp/shsp.dart';

// SHSP spec Section 9: "Compression is not part of SHSP". The socket
// transmits Data message payloads byte-for-byte, opaque to the protocol.
// Any compression/decompression is an application-level concern: compress
// before calling sendMessage()/sendTo(), and decompress after receiving.
//
// This example shows that by wrapping ShspPeer in a small subclass that
// compresses outgoing payloads and decompresses incoming ones, using the
// codecs shipped by the package as plain utilities.

/// A peer that applies compression itself, entirely outside of SHSP.
class CompressingPeer extends ShspPeer {
  CompressingPeer({
    required super.remotePeer,
    required super.socket,
    required this.codec,
  });

  final ICompressionCodec codec;

  /// Compress the payload before handing it to SHSP for sending.
  void sendCompressed(List<int> message) {
    final compressed = codec.encode(message);
    print(
      '  -> compressing ${message.length} bytes to ${compressed.length} bytes (${codec.name}) before sendMessage()',
    );
    sendMessage(compressed);
  }

  @override
  void onMessage(List<int> msg, PeerInfo info) {
    // SHSP handed us the raw, still-compressed bytes; decompress ourselves.
    final decompressed = codec.decode(msg);
    print(
      '  <- received ${msg.length} bytes, decompressed to ${decompressed.length} bytes (${codec.name}) in onMessage()',
    );
    super.onMessage(msg, info);
  }
}

void main() async {
  print('=== Application-Level Compression Example ===\n');

  // Initialize the global singleton socket. SHSP no longer needs (or uses)
  // a compression codec: it never touches the payload bytes.
  print('Initializing global socket...');
  final singleton = await ShspSocketSingleton.getInstance(
    address: InternetAddress.anyIPv4,
    port: 0, // Use ephemeral port
  );
  print('✓ Global socket bound to port ${singleton.socket.localPort}\n');

  final remotePeer1 = PeerInfo(
    address: InternetAddress('127.0.0.1'),
    port: 9001,
  );
  final peer1 = CompressingPeer(
    remotePeer: remotePeer1,
    socket: singleton.socket,
    codec: GZipCodec(),
  );
  print('✓ Peer1 created (application compresses with GZip)');

  final remotePeer2 = PeerInfo(
    address: InternetAddress('127.0.0.1'),
    port: 9002,
  );
  final peer2 = CompressingPeer(
    remotePeer: remotePeer2,
    socket: singleton.socket,
    codec: ZstdCodec(),
  );
  print('✓ Peer2 created (application compresses with Zstd)');

  print('\nBoth peers automatically use the singleton socket\n');

  final largeData = Uint8List.fromList(List.generate(1000, (i) => i % 256));

  print('Sending data with application-level compression...');
  peer1.sendCompressed(largeData);
  peer2.sendCompressed(largeData);

  // Keep alive briefly
  await Future.delayed(const Duration(seconds: 2));

  // Clean up
  print('\nCleaning up...');
  peer1.close();
  peer2.close();
  print('✓ All peers closed');
}
