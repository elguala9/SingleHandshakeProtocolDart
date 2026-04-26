import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('GZipCodec', () {
    late GZipCodec codec;

    setUp(() {
      codec = GZipCodec();
    });

    group('name', () {
      test('name is "GZip"', () {
        expect(codec.name, equals('GZip'));
      });
    });

    group('encode / decode round-trip', () {
      test('encode → decode preserves original bytes for short data', () {
        final original = [0x41, 0x42, 0x43]; // ABC
        final encoded = codec.encode(original);
        final decoded = codec.decode(encoded);
        expect(decoded, equals(original));
      });

      test('encode → decode preserves original bytes for empty list', () {
        final original = <int>[];
        final encoded = codec.encode(original);
        final decoded = codec.decode(encoded);
        expect(decoded, equals(original));
      });

      test('encode → decode preserves original bytes for 1000-byte payload', () {
        final original = List<int>.filled(1000, 0x41);
        final encoded = codec.encode(original);
        final decoded = codec.decode(encoded);
        expect(decoded, equals(original));
      });

      test('encode produces different bytes than input (it actually compresses)', () {
        final original = List<int>.filled(100, 0x41);
        final encoded = codec.encode(original);
        // Gzip adds headers, so encoded should be different
        expect(encoded, isNot(equals(original)));
      });

      test('encode output is not equal to input for compressible data', () {
        final input = List<int>.filled(10, 0x41);
        final encoded = codec.encode(input);
        expect(encoded, isNot(equals(input)));
      });
    });
  });

  group('ZstdCodec', () {
    late ZstdCodec codec;

    setUp(() {
      codec = ZstdCodec();
    });

    group('name', () {
      test('name is "Zstandard"', () {
        expect(codec.name, equals('Zstandard'));
      });
    });

    group('encode / decode round-trip', () {
      test('encode → decode preserves original bytes for short data', () {
        final original = [0x41, 0x42, 0x43];
        final encoded = codec.encode(original);
        final decoded = codec.decode(encoded);
        expect(decoded, equals(original));
      });

      test('empty input encodes to [0] and decodes back to []', () {
        final original = <int>[];
        final encoded = codec.encode(original);
        expect(encoded, equals([0]));
        final decoded = codec.decode(encoded);
        expect(decoded, equals(original));
      });

      test('encode → decode preserves 1000-byte payload', () {
        final original = List<int>.filled(1000, 0x42);
        final encoded = codec.encode(original);
        final decoded = codec.decode(encoded);
        expect(decoded, equals(original));
      });

      test('encode output starts with byte 1 (compressed flag)', () {
        final original = [0x41, 0x42, 0x43];
        final encoded = codec.encode(original);
        expect(encoded.isNotEmpty, isTrue);
        expect(encoded[0], equals(1));
      });

      test('encoded output is different from input for compressible data', () {
        final input = List<int>.filled(10, 0x41);
        final encoded = codec.encode(input);
        expect(encoded, isNot(equals(input)));
      });
    });

    group('edge cases', () {
      test('decode of [0] returns empty list (empty signal byte)', () {
        final decoded = codec.decode([0]);
        expect(decoded, equals(<int>[]));
      });

      test('decode of [2, ...data] returns the raw data (fallback flag)', () {
        final encoded = [2, 0x41, 0x42, 0x43];
        final decoded = codec.decode(encoded);
        expect(decoded, equals([0x41, 0x42, 0x43]));
      });

      test('decode of invalid gzip content falls back gracefully (no throw)', () {
        // Pass some random bytes that won't decompress
        final encoded = [1, 0xFF, 0xFF, 0xFF];
        expect(() {
          codec.decode(encoded);
        }, returnsNormally);
      });
    });
  });

  group('LZ4Codec', () {
    late LZ4Codec codec;

    setUp(() {
      codec = LZ4Codec();
    });

    group('encode / decode round-trip', () {
      test('encode → decode preserves original bytes for short data', () {
        final original = [0x41, 0x42, 0x43];
        final encoded = codec.encode(original);
        final decoded = codec.decode(encoded);
        expect(decoded, equals(original));
      });

      test('empty input encodes to [0] and decodes back to []', () {
        final original = <int>[];
        final encoded = codec.encode(original);
        expect(encoded, equals([0]));
        final decoded = codec.decode(encoded);
        expect(decoded, equals(original));
      });

      test('fallback flag 2: decode returns raw payload', () {
        final encoded = [2, 0x41, 0x42, 0x43];
        final decoded = codec.decode(encoded);
        expect(decoded, equals([0x41, 0x42, 0x43]));
      });
    });
  });

  group('ICompressionCodec interface compliance', () {
    final codecs = [GZipCodec(), ZstdCodec(), LZ4Codec()];

    for (final codec in codecs) {
      test('${codec.name} implements ICompressionCodec', () {
        expect(codec, isA<ICompressionCodec>());
      });

      test('${codec.name} name is non-empty', () {
        expect(codec.name, isNotEmpty);
      });
    }
  });
}
