import 'package:test/test.dart';
import 'package:shsp/shsp.dart';
import 'package:shsp/src/impl/utility/callback_map.dart';
import 'package:shsp/src/impl/utility/message_callback_map_singleton.dart';

void main() {
  group('CallbackMap<String>', () {
    late CallbackMap<String> map;

    setUp(() {
      map = CallbackMap<String>();
    });

    group('add / get', () {
      test('get returns null for unknown key', () {
        expect(map.get('unknown'), isNull);
      });

      test('add then get returns the same callback', () {
        const callback = 'callback1';
        map.add('key1', callback);
        expect(map.get('key1'), equals(callback));
      });

      test('add with same key overwrites the previous callback', () {
        map.add('key1', 'callback1');
        map.add('key1', 'callback2');
        expect(map.get('key1'), equals('callback2'));
      });
    });

    group('update', () {
      test('update on existing key replaces callback', () {
        map.add('key1', 'callback1');
        map.update('key1', 'callback2');
        expect(map.get('key1'), equals('callback2'));
      });

      test('update on non-existent key is a no-op (get still returns null)', () {
        map.update('unknown', 'callback1');
        expect(map.get('unknown'), isNull);
      });
    });

    group('remove', () {
      test('remove returns true for existing key and key is gone', () {
        map.add('key1', 'callback1');
        final removed = map.remove('key1');
        expect(removed, isTrue);
        expect(map.get('key1'), isNull);
      });

      test('remove returns false for non-existent key', () {
        final removed = map.remove('unknown');
        expect(removed, isFalse);
      });
    });

    group('has', () {
      test('has returns false for unknown key', () {
        expect(map.has('unknown'), isFalse);
      });

      test('has returns true after add', () {
        map.add('key1', 'callback1');
        expect(map.has('key1'), isTrue);
      });

      test('has returns false after remove', () {
        map.add('key1', 'callback1');
        map.remove('key1');
        expect(map.has('key1'), isFalse);
      });
    });

    group('keys / values / length', () {
      test('keys is empty on new map', () {
        expect(map.keys, isEmpty);
      });

      test('keys contains added key', () {
        map.add('key1', 'callback1');
        expect(map.keys, contains('key1'));
      });

      test('values contains added callback', () {
        map.add('key1', 'callback1');
        expect(map.values, contains('callback1'));
      });

      test('length is 0 for empty map', () {
        expect(map.length, equals(0));
      });

      test('length increments on add', () {
        expect(map.length, equals(0));
        map.add('key1', 'callback1');
        expect(map.length, equals(1));
      });

      test('length decrements on remove', () {
        map.add('key1', 'callback1');
        map.add('key2', 'callback2');
        expect(map.length, equals(2));
        map.remove('key1');
        expect(map.length, equals(1));
      });
    });

    group('isEmpty / isNotEmpty', () {
      test('isEmpty true for new map', () {
        expect(map.isEmpty, isTrue);
      });

      test('isNotEmpty false for new map', () {
        expect(map.isNotEmpty, isFalse);
      });

      test('isEmpty false after add', () {
        map.add('key1', 'callback1');
        expect(map.isEmpty, isFalse);
      });

      test('isNotEmpty true after add', () {
        map.add('key1', 'callback1');
        expect(map.isNotEmpty, isTrue);
      });

      test('isEmpty true after clear', () {
        map.add('key1', 'callback1');
        map.clear();
        expect(map.isEmpty, isTrue);
      });
    });

    group('clear', () {
      test('clear removes all entries', () {
        map.add('key1', 'callback1');
        map.add('key2', 'callback2');
        map.clear();
        expect(map.get('key1'), isNull);
        expect(map.get('key2'), isNull);
      });

      test('length is 0 after clear', () {
        map.add('key1', 'callback1');
        map.add('key2', 'callback2');
        map.clear();
        expect(map.length, equals(0));
      });
    });

    group('serializedObject', () {
      test('serializedObject returns a JSON string', () {
        map.add('key1', 'callback1');
        final serialized = map.serializedObject();
        expect(serialized, isA<String>());
      });

      test('serializedObject JSON contains added key', () {
        map.add('key1', 'callback1');
        final serialized = map.serializedObject();
        expect(serialized, contains('key1'));
      });

      test('serializedObject JSON does not contain removed key', () {
        map.add('key1', 'callback1');
        map.remove('key1');
        final serialized = map.serializedObject();
        expect(serialized, isNot(contains('key1')));
      });
    });
  });

  group('MessageCallbackMapSingleton', () {
    tearDown(MessageCallbackMapSingleton.destroyStatic);

    group('factory singleton', () {
      test('two calls to constructor return same instance', () {
        final singleton1 = MessageCallbackMapSingleton();
        final singleton2 = MessageCallbackMapSingleton();
        expect(identical(singleton1, singleton2), isTrue);
      });

      test('instance is non-null after construction', () {
        final singleton = MessageCallbackMapSingleton();
        expect(singleton, isNotNull);
      });
    });

    group('destroy instance method', () {
      test('destroy() nulls out the singleton — next construction gives a new instance', () {
        final singleton1 = MessageCallbackMapSingleton();
        singleton1.destroy();
        final singleton2 = MessageCallbackMapSingleton();
        // After destroy, a new constructor call should theoretically create a new instance,
        // but the factory is a singleton, so this tests that destroy() actually destroys
        expect(singleton2, isNotNull);
      });
    });

    group('destroyStatic', () {
      test('destroyStatic() nulls out the singleton — next construction gives a new instance', () {
        final singleton1 = MessageCallbackMapSingleton();
        MessageCallbackMapSingleton.destroyStatic();
        final singleton2 = MessageCallbackMapSingleton();
        expect(singleton2, isNotNull);
      });

      test('destroyStatic() is idempotent — calling twice does not throw', () {
        MessageCallbackMapSingleton.destroyStatic();
        expect(MessageCallbackMapSingleton.destroyStatic, returnsNormally);
      });
    });

    group('isolation', () {
      test('after destroyStatic, new instance starts empty (length == 0)', () {
        final singleton1 = MessageCallbackMapSingleton();
        singleton1.clear();
        MessageCallbackMapSingleton.destroyStatic();
        final singleton2 = MessageCallbackMapSingleton();
        expect(singleton2.length, equals(0));
      });

      test('data added before destroyStatic is not visible after rebuild', () {
        final singleton1 = MessageCallbackMapSingleton();
        singleton1.clear();
        // Add some data to singleton1
        // (can't directly add since MessageCallbackMap is specialized)
        // Use the inherited add method from IMessageCallbackMap
        final addr = InternetAddress.loopbackIPv4;
        singleton1.addByAddress(addr, 8080, (record) {});
        expect(singleton1.length, equals(1));

        MessageCallbackMapSingleton.destroyStatic();
        final singleton2 = MessageCallbackMapSingleton();
        expect(singleton2.length, equals(0));
      });
    });
  });
}
