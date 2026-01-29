import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:shsp_implementations/utility/concat_utility.dart';

void main() {
  group('ConcatUtility', () {
    group('concatStrings', () {
      test('should concatenate multiple strings', () {
        final strings = ['Hello', ' ', 'world', '!'];
        final result = ConcatUtility.concatStrings(strings);
        expect(result, equals('Hello world!'));
      });

      test('should handle empty list', () {
        final result = ConcatUtility.concatStrings([]);
        expect(result, equals(''));
      });

      test('should handle single string', () {
        final result = ConcatUtility.concatStrings(['single']);
        expect(result, equals('single'));
      });

      test('should handle empty strings', () {
        final strings = ['', 'test', '', 'string', ''];
        final result = ConcatUtility.concatStrings(strings);
        expect(result, equals('teststring'));
      });

      test('should handle special characters', () {
        final strings = ['Hello', '\n', 'world', '\t', '🌍'];
        final result = ConcatUtility.concatStrings(strings);
        expect(result, equals('Hello\nworld\t🌍'));
      });
    });

    group('concatBytes', () {
      test('should concatenate multiple Uint8List', () {
        final arrays = [
          Uint8List.fromList([1, 2, 3]),
          Uint8List.fromList([4, 5]),
          Uint8List.fromList([6, 7, 8, 9]),
        ];
        
        final result = ConcatUtility.concatBytes(arrays);
        expect(result, equals(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9])));
      });

      test('should handle empty list', () {
        final result = ConcatUtility.concatBytes([]);
        expect(result, equals(Uint8List(0)));
        expect(result.length, equals(0));
      });

      test('should handle single array', () {
        final arrays = [Uint8List.fromList([10, 20, 30])];
        final result = ConcatUtility.concatBytes(arrays);
        expect(result, equals(Uint8List.fromList([10, 20, 30])));
      });

      test('should handle empty arrays in the list', () {
        final arrays = [
          Uint8List.fromList([1, 2]),
          Uint8List(0), // empty array
          Uint8List.fromList([3, 4]),
        ];
        
        final result = ConcatUtility.concatBytes(arrays);
        expect(result, equals(Uint8List.fromList([1, 2, 3, 4])));
      });

      test('should handle large arrays', () {
        final array1 = Uint8List(1000);
        final array2 = Uint8List(500);
        array1.fillRange(0, 1000, 255);
        array2.fillRange(0, 500, 128);
        
        final result = ConcatUtility.concatBytes([array1, array2]);
        expect(result.length, equals(1500));
        expect(result.sublist(0, 1000), equals(array1));
        expect(result.sublist(1000, 1500), equals(array2));
      });
    });

    group('concatIntLists', () {
      test('should concatenate multiple List<int>', () {
        final lists = [
          [1, 2, 3],
          [4, 5],
          [6, 7, 8, 9],
        ];
        
        final result = ConcatUtility.concatIntLists(lists);
        expect(result, equals([1, 2, 3, 4, 5, 6, 7, 8, 9]));
      });

      test('should handle empty list', () {
        final result = ConcatUtility.concatIntLists([]);
        expect(result, equals(<int>[]));
        expect(result.length, equals(0));
      });

      test('should handle single list', () {
        final lists = [[10, 20, 30]];
        final result = ConcatUtility.concatIntLists(lists);
        expect(result, equals([10, 20, 30]));
      });

      test('should handle empty lists in the collection', () {
        final lists = [
          [1, 2],
          <int>[], // empty list
          [3, 4],
        ];
        
        final result = ConcatUtility.concatIntLists(lists);
        expect(result, equals([1, 2, 3, 4]));
      });

      test('should handle negative and large numbers', () {
        final lists = [
          [-1, 0, 1],
          [255, 256, 65535],
          [2147483647, -2147483648],
        ];
        
        final result = ConcatUtility.concatIntLists(lists);
        expect(result, equals([-1, 0, 1, 255, 256, 65535, 2147483647, -2147483648]));
      });
    });

    group('stringToBytes', () {
      test('should convert ASCII string to bytes', () {
        const input = 'Hello';
        final result = ConcatUtility.stringToBytes(input);
        expect(result, equals(Uint8List.fromList([72, 101, 108, 108, 111])));
      });

      test('should handle empty string', () {
        const input = '';
        final result = ConcatUtility.stringToBytes(input);
        expect(result, equals(Uint8List(0)));
      });

      test('should handle Unicode characters', () {
        const input = 'Hello 🌍';
        final result = ConcatUtility.stringToBytes(input);
        expect(result.length, greaterThan(7)); // UTF-8 encoding of emoji takes multiple bytes
      });

      test('should handle special characters', () {
        const input = '\n\t\r';
        final result = ConcatUtility.stringToBytes(input);
        expect(result, equals(Uint8List.fromList([10, 9, 13])));
      });

      test('should use custom encoding', () {
        const input = 'test';
        final result = ConcatUtility.stringToBytes(input, encoding: ascii);
        expect(result, equals(Uint8List.fromList([116, 101, 115, 116])));
      });
    });

    group('bytesToString', () {
      test('should convert bytes to ASCII string', () {
        final bytes = Uint8List.fromList([72, 101, 108, 108, 111]);
        final result = ConcatUtility.bytesToString(bytes);
        expect(result, equals('Hello'));
      });

      test('should handle empty byte array', () {
        final bytes = Uint8List(0);
        final result = ConcatUtility.bytesToString(bytes);
        expect(result, equals(''));
      });

      test('should handle UTF-8 encoded Unicode', () {
        const originalString = 'Hello 🌍';
        final bytes = ConcatUtility.stringToBytes(originalString);
        final result = ConcatUtility.bytesToString(bytes);
        expect(result, equals(originalString));
      });

      test('should handle special characters', () {
        final bytes = Uint8List.fromList([10, 9, 13]);
        final result = ConcatUtility.bytesToString(bytes);
        expect(result, equals('\n\t\r'));
      });

      test('should use custom encoding', () {
        final bytes = Uint8List.fromList([116, 101, 115, 116]);
        final result = ConcatUtility.bytesToString(bytes, encoding: ascii);
        expect(result, equals('test'));
      });
    });

    group('round-trip conversion', () {
      test('string to bytes and back should preserve data', () {
        const originalStrings = [
          'Hello World',
          'UTF-8: 🌍🚀💻',
          'Special: \n\t\r',
          '',
          '1234567890',
          'Mixed: abc123XYZ',
        ];

        for (final original in originalStrings) {
          final bytes = ConcatUtility.stringToBytes(original);
          final restored = ConcatUtility.bytesToString(bytes);
          expect(restored, equals(original), reason: 'Failed for: "$original"');
        }
      });

      test('bytes concatenation should preserve order', () {
        final original1 = ConcatUtility.stringToBytes('Hello');
        final original2 = ConcatUtility.stringToBytes(' ');
        final original3 = ConcatUtility.stringToBytes('World');

        final concatenated = ConcatUtility.concatBytes([original1, original2, original3]);
        final result = ConcatUtility.bytesToString(concatenated);

        expect(result, equals('Hello World'));
      });
    });

    group('error handling', () {
      test('should handle invalid UTF-8 bytes gracefully', () {
        // Invalid UTF-8 sequence
        final invalidBytes = Uint8List.fromList([0xFF, 0xFE]);
        
        expect(() => ConcatUtility.bytesToString(invalidBytes), 
               throwsA(isA<FormatException>()));
      });
    });

    group('performance considerations', () {
      test('should handle large data efficiently', () {
        // Create large string
        final largeString = 'A' * 10000;
        final bytes = ConcatUtility.stringToBytes(largeString);
        final result = ConcatUtility.bytesToString(bytes);
        
        expect(result, equals(largeString));
        expect(result.length, equals(10000));
      });

      test('should handle many small concatenations', () {
        final manyStrings = List.generate(1000, (i) => 'str$i');
        final result = ConcatUtility.concatStrings(manyStrings);
        
        expect(result.length, greaterThan(3000));
        expect(result, startsWith('str0'));
        expect(result, endsWith('str999'));
      });
    });
  });
}