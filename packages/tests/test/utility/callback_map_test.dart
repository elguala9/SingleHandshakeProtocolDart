import 'package:test/test.dart';
import 'package:shsp_implementations/utility/callback_map.dart';

void main() {
  group('CallbackMap', () {
    late CallbackMap<String> callbackMap;

    setUp(() {
      callbackMap = CallbackMap<String>();
    });

    test('should start empty', () {
      expect(callbackMap.keys, isEmpty);
      expect(callbackMap.values, isEmpty);
      expect(callbackMap.length, equals(0));
    });

    test('add should store callback correctly', () {
      void testCallback(String arg) {}

      callbackMap.add('key1', testCallback);

      expect(callbackMap.has('key1'), isTrue);
      expect(callbackMap.get('key1'), equals(testCallback));
      expect(callbackMap.length, equals(1));
    });

    test('get should return null for non-existent key', () {
      expect(callbackMap.get('non-existent'), isNull);
    });

    test('update should only update existing keys', () {
      void callback1(String arg) {}
      void callback2(String arg) {}

      // Add initial callback
      callbackMap.add('key1', callback1);
      expect(callbackMap.get('key1'), equals(callback1));

      // Update existing key
      callbackMap.update('key1', callback2);
      expect(callbackMap.get('key1'), equals(callback2));

      // Try to update non-existent key (should not add it)
      callbackMap.update('non-existent', callback1);
      expect(callbackMap.has('non-existent'), isFalse);
      expect(callbackMap.length, equals(1));
    });

    test('remove should remove existing callback and return true', () {
      void testCallback(String arg) {}

      callbackMap.add('key1', testCallback);
      expect(callbackMap.has('key1'), isTrue);

      final removed = callbackMap.remove('key1');
      expect(removed, isTrue);
      expect(callbackMap.has('key1'), isFalse);
      expect(callbackMap.length, equals(0));
    });

    test('remove should return false for non-existent key', () {
      final removed = callbackMap.remove('non-existent');
      expect(removed, isFalse);
    });

    test('clear should remove all callbacks', () {
      void callback1(String arg) {}
      void callback2(String arg) {}
      void callback3(String arg) {}

      callbackMap.add('key1', callback1);
      callbackMap.add('key2', callback2);
      callbackMap.add('key3', callback3);
      expect(callbackMap.length, equals(3));

      callbackMap.clear();
      expect(callbackMap.length, equals(0));
      expect(callbackMap.keys, isEmpty);
    });

    test('has should correctly identify existing keys', () {
      void testCallback(String arg) {}

      expect(callbackMap.has('key1'), isFalse);

      callbackMap.add('key1', testCallback);
      expect(callbackMap.has('key1'), isTrue);

      callbackMap.remove('key1');
      expect(callbackMap.has('key1'), isFalse);
    });

    test('keys should return all keys', () {
      void callback1(String arg) {}
      void callback2(String arg) {}
      void callback3(String arg) {}

      callbackMap.add('key1', callback1);
      callbackMap.add('key2', callback2);
      callbackMap.add('key3', callback3);

      final keys = callbackMap.keys.toList();
      expect(keys, hasLength(3));
      expect(keys, containsAll(['key1', 'key2', 'key3']));
    });

    test('values should return all callbacks', () {
      void callback1(String arg) {}
      void callback2(String arg) {}
      void callback3(String arg) {}

      callbackMap.add('key1', callback1);
      callbackMap.add('key2', callback2);
      callbackMap.add('key3', callback3);

      final values = callbackMap.values.toList();
      expect(values, hasLength(3));
      expect(values, containsAll([callback1, callback2, callback3]));
    });

    test('multiple keys with same callback should work', () {
      void sharedCallback(String arg) {}

      callbackMap.add('key1', sharedCallback);
      callbackMap.add('key2', sharedCallback);

      expect(callbackMap.get('key1'), equals(sharedCallback));
      expect(callbackMap.get('key2'), equals(sharedCallback));
      expect(callbackMap.length, equals(2));
    });

    test('overwriting existing key with add should replace callback', () {
      void callback1(String arg) {}
      void callback2(String arg) {}

      callbackMap.add('key1', callback1);
      expect(callbackMap.get('key1'), equals(callback1));

      callbackMap.add('key1', callback2);
      expect(callbackMap.get('key1'), equals(callback2));
      expect(callbackMap.length, equals(1));
    });

    test('should handle special key names', () {
      void testCallback(String arg) {}

      final specialKeys = ['', ' ', '\t', '\n', '特殊字符', '🔑', '127.0.0.1:8080'];

      for (final key in specialKeys) {
        callbackMap.add(key, testCallback);
        expect(callbackMap.has(key), isTrue);
        expect(callbackMap.get(key), equals(testCallback));
      }

      expect(callbackMap.length, equals(specialKeys.length));
    });

    test('serializedObject should return JSON representation', () {
      void callback1(String arg) {}
      void callback2(String arg) {}

      callbackMap.add('peer1', callback1);
      callbackMap.add('peer2', callback2);

      final serialized = callbackMap.serializedObject();

      expect(serialized, isA<String>());
      expect(serialized, contains('peer1'));
      expect(serialized, contains('peer2'));
      // The actual implementation returns a simple JSON map
      expect(serialized, contains('true'));
    });

    test('serializedObject should handle empty map', () {
      final serialized = callbackMap.serializedObject();

      expect(serialized, isA<String>());
      // Empty map returns '{}'
      expect(serialized, equals('{}'));
    });

    group('with different types', () {
      test('should work with int callbacks', () {
        final intMap = CallbackMap<int>();
        void intCallback(int value) {}

        intMap.add('numbers', intCallback);
        expect(intMap.get('numbers'), equals(intCallback));
      });

      test('should work with complex object callbacks', () {
        final objMap = CallbackMap<Map<String, dynamic>>();
        void objCallback(Map<String, dynamic> obj) {}

        objMap.add('objects', objCallback);
        expect(objMap.get('objects'), equals(objCallback));
      });
    });
  });
}
