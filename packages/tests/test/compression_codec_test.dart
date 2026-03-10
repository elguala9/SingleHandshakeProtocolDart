import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/src/impl/shsp_base/shsp_socket.dart';
import 'package:shsp/src/impl/shsp_base/compression/compression_codecs.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('Compression Codecs', () {
    group('GZipCodec', () {
      final codec = GZipCodec();

      test('encode/decode should preserve data', () {
        final originalData = List<int>.generate(100, (i) => i % 256);
        final compressed = codec.encode(originalData);
        final decompressed = codec.decode(compressed);

        expect(decompressed, equals(originalData));
        expect(codec.name, equals('GZip'));
      });

      test('should achieve high compression for repetitive data', () {
        final repetitiveData = List<int>.generate(500, (i) => 0x41); // 500 'A's
        final compressed = codec.encode(repetitiveData);
        final ratio = ((1 - (compressed.length / repetitiveData.length)) * 100);

        expect(compressed.length, lessThan(500)); // Should be much smaller
        expect(ratio, greaterThan(90)); // Should compress >90%
      });
    });

    group('LZ4Codec', () {
      final codec = LZ4Codec();

      test('encode/decode should preserve data', () {
        final originalData = List<int>.generate(100, (i) => i % 256);
        final compressed = codec.encode(originalData);
        final decompressed = codec.decode(compressed);

        expect(decompressed, equals(originalData));
        expect(codec.name, equals('LZ4'));
      });

      test('should provide good compression for repetitive data', () {
        final repetitiveData = List<int>.generate(500, (i) => 0x41); // 500 'A's
        final compressed = codec.encode(repetitiveData);
        final ratio = ((1 - (compressed.length / repetitiveData.length)) * 100);

        expect(compressed.length, lessThan(repetitiveData.length));
        expect(ratio, greaterThan(50)); // Should compress >50%
        print('LZ4 compression: ${repetitiveData.length} → ${compressed.length} bytes (${ratio.toStringAsFixed(1)}%)');
      });

      test('should handle empty data', () {
        final empty = <int>[];
        final compressed = codec.encode(empty);
        final decompressed = codec.decode(compressed);

        expect(decompressed, equals(empty));
      });

      test('should handle large data', () {
        final largeData = List<int>.generate(10000, (i) => (i * 7) % 256);
        final compressed = codec.encode(largeData);
        final decompressed = codec.decode(compressed);

        expect(decompressed, equals(largeData));
        final ratio = ((1 - (compressed.length / largeData.length)) * 100);
        print('LZ4 large data: ${largeData.length} → ${compressed.length} bytes (${ratio.toStringAsFixed(1)}%)');
      });
    });

    group('ZstdCodec', () {
      final codec = ZstdCodec();

      test('encode/decode should preserve data', () {
        final originalData = List<int>.generate(100, (i) => i % 256);
        final compressed = codec.encode(originalData);
        final decompressed = codec.decode(compressed);

        expect(decompressed, equals(originalData));
        expect(codec.name, equals('Zstandard'));
      });

      test('should provide better compression than LZ4', () {
        final testData = List<int>.generate(500, (i) => 0x41); // 500 'A's
        final compressed = codec.encode(testData);
        final ratio = ((1 - (compressed.length / testData.length)) * 100);

        expect(compressed.length, lessThan(testData.length));
        expect(ratio, greaterThan(60)); // Should compress >60%
        print('ZSTD compression: ${testData.length} → ${compressed.length} bytes (${ratio.toStringAsFixed(1)}%)');
      });

      test('should handle JSON-like data well', () {
        final jsonPattern = '{"id":123,"name":"test","value":456}'.codeUnits;
        final repeatedData = <int>[...jsonPattern, ...jsonPattern, ...jsonPattern];

        final compressed = codec.encode(repeatedData);
        final decompressed = codec.decode(compressed);

        expect(decompressed, equals(repeatedData));
        final ratio = ((1 - (compressed.length / repeatedData.length)) * 100);
        expect(ratio, greaterThan(40)); // Should compress >40%
        print('ZSTD JSON-like: ${repeatedData.length} → ${compressed.length} bytes (${ratio.toStringAsFixed(1)}%)');
      });

      test('should handle large data', () {
        final largeData = List<int>.generate(10000, (i) => (i * 7) % 256);
        final compressed = codec.encode(largeData);
        final decompressed = codec.decode(compressed);

        expect(decompressed, equals(largeData));
        final ratio = ((1 - (compressed.length / largeData.length)) * 100);
        print('ZSTD large data: ${largeData.length} → ${compressed.length} bytes (${ratio.toStringAsFixed(1)}%)');
      });
    });

    group('ShspSocket with different Compression Codecs', () {
      late InternetAddress address;

      setUp(() {
        address = InternetAddress.loopbackIPv4;
      });

      test('should use GZipCodec by default', () async {
        final socket = await ShspSocket.bind(address, 0);

        expect(socket.compressionCodec.name, equals('GZip'));

        socket.close();
      });

      test('should use custom compression codec when provided', () async {
        final customCodec = LZ4Codec();
        final socket = await ShspSocket.bind(address, 0, customCodec);

        expect(socket.compressionCodec.name, equals('LZ4'));

        socket.close();
      });

      test('should support switching between codecs', () async {
        final gzipCodec = GZipCodec();
        final zstdCodec = ZstdCodec();
        final lz4Codec = LZ4Codec();

        final socket1 = await ShspSocket.bind(address, 0, gzipCodec);
        expect(socket1.compressionCodec.name, equals('GZip'));
        socket1.close();

        final socket2 = await ShspSocket.bind(address, 0, zstdCodec);
        expect(socket2.compressionCodec.name, equals('Zstandard'));
        socket2.close();

        final socket3 = await ShspSocket.bind(address, 0, lz4Codec);
        expect(socket3.compressionCodec.name, equals('LZ4'));
        socket3.close();
      });

      test('data messages are compressed with specified codec', () async {
        final codec = GZipCodec();
        final socket1 = await ShspSocket.bind(address, 0, codec);
        final socket2 = await ShspSocket.bind(address, 0, codec);

        final testMessage = List<int>.generate(500, (i) => 0x41); // 500 'A's
        final dataMessage = [0x00, ...testMessage]; // Add data prefix

        var messageReceived = false;

        socket2.setMessageCallback(
          PeerInfo(address: address, port: socket1.localPort!),
          (record) {
            // Should receive decompressed message with original length
            expect(record.msg.length, equals(501)); // 1 prefix + 500
            expect(record.msg[0], equals(0x00)); // Data prefix
            messageReceived = true;
          },
        );

        // Send data message (will be compressed)
        final bytesSent = socket1.sendTo(
          dataMessage,
          PeerInfo(address: address, port: socket2.localPort!),
        );

        // Bytes sent should be much less due to compression
        expect(bytesSent, lessThan(501));

        await Future.delayed(const Duration(milliseconds: 100));
        expect(messageReceived, isTrue);

        socket1.close();
        socket2.close();
      });
    });
  });
}
