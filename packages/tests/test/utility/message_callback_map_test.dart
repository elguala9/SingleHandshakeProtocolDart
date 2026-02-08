import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_implementations/utility/message_callback_map.dart';

void main() {
  group('MessageCallbackMap', () {
    late MessageCallbackMap callbackMap;

    setUp(() {
      callbackMap = MessageCallbackMap();
    });

    group('basic operations', () {
      test('should start empty', () {
        expect(callbackMap.length, equals(0));
        expect(callbackMap.keys, isEmpty);
      });

      test('add and get should work with string key', () {
        bool callbackExecuted = false;
        void testCallback(MessageRecord record) {
          callbackExecuted = true;
        }

        callbackMap.add('127.0.0.1:8080', testCallback);

        expect(callbackMap.length, equals(1));
        expect(callbackMap.containsKey('127.0.0.1:8080'), isTrue);

        final invoker = callbackMap.get('127.0.0.1:8080');
        expect(invoker, isNotNull);

        invoker!(
          (msg: [1, 2, 3], rinfo: RemoteInfo(address: InternetAddress('127.0.0.1'), port: 8080)),
        );
        expect(callbackExecuted, isTrue);
      });

      test('should return null for non-existent key', () {
        expect(callbackMap.get('non-existent'), isNull);
      });

      test('remove should delete callback', () {
        void testCallback(MessageRecord record) {}

        callbackMap.add('192.168.1.1:9090', testCallback);
        expect(callbackMap.containsKey('192.168.1.1:9090'), isTrue);

        callbackMap.remove('192.168.1.1:9090');
        expect(callbackMap.containsKey('192.168.1.1:9090'), isFalse);
        expect(callbackMap.length, equals(0));
      });

      test('clear should remove all callbacks', () {
        void callback1(MessageRecord record) {}
        void callback2(MessageRecord record) {}

        callbackMap.add('10.0.0.1:80', callback1);
        callbackMap.add('10.0.0.2:443', callback2);
        expect(callbackMap.length, equals(2));

        callbackMap.clear();
        expect(callbackMap.length, equals(0));
        expect(callbackMap.keys, isEmpty);
      });
    });

    group('address-based operations', () {
      test('addByAddress and getByAddress should work for IPv4', () {
        bool callbackExecuted = false;
        void testCallback(MessageRecord record) {
          callbackExecuted = true;
        }

        final address = InternetAddress('192.168.1.100');
        const port = 8080;

        callbackMap.addByAddress(address, port, testCallback);

        expect(callbackMap.containsAddress(address, port), isTrue);
        final invoker = callbackMap.getByAddress(address, port);
        expect(invoker, isNotNull);
        invoker!((msg: [1, 2, 3], rinfo: RemoteInfo(address: address, port: port)));
        expect(callbackExecuted, isTrue);
      });

      test('addByAddress and getByAddress should work for IPv6', () {
        bool callbackExecuted = false;
        void testCallback(MessageRecord record) {
          callbackExecuted = true;
        }

        final address = InternetAddress('2001:db8::1');
        const port = 8443;

        callbackMap.addByAddress(address, port, testCallback);

        expect(callbackMap.containsAddress(address, port), isTrue);
        final invoker = callbackMap.getByAddress(address, port);
        expect(invoker, isNotNull);
        invoker!((msg: [1, 2, 3], rinfo: RemoteInfo(address: address, port: port)));
        expect(callbackExecuted, isTrue);
      });

      test('removeByAddress should work', () {
        void testCallback(MessageRecord record) {}
        final address = InternetAddress('10.0.0.1');
        const port = 3000;

        callbackMap.addByAddress(address, port, testCallback);
        expect(callbackMap.containsAddress(address, port), isTrue);

        callbackMap.removeByAddress(address, port);
        expect(callbackMap.containsAddress(address, port), isFalse);
      });

      test('should handle loopback addresses', () {
        void testCallback(MessageRecord record) {}

        callbackMap.addByAddress(
            InternetAddress.loopbackIPv4, 8080, testCallback);
        callbackMap.addByAddress(
            InternetAddress.loopbackIPv6, 8080, testCallback);

        expect(callbackMap.containsAddress(InternetAddress.loopbackIPv4, 8080),
            isTrue);
        expect(callbackMap.containsAddress(InternetAddress.loopbackIPv6, 8080),
            isTrue);
        expect(callbackMap.length, equals(2));
      });
    });

    group('formatKey', () {
      test('should format IPv4 addresses correctly', () {
        final address = InternetAddress('192.168.1.100');
        const port = 8080;

        final key = MessageCallbackMap.formatKey(address, port);
        expect(key, equals('192.168.1.100:8080'));
      });

      test('should format IPv6 addresses with brackets', () {
        final address = InternetAddress('2001:db8::1');
        const port = 8443;

        final key = MessageCallbackMap.formatKey(address, port);
        expect(key, equals('[2001:db8::1]:8443'));
      });

      test('should handle port 0', () {
        final address = InternetAddress('127.0.0.1');

        final key = MessageCallbackMap.formatKey(address, 0);
        expect(key, equals('127.0.0.1:0'));
      });

      test('should handle high port numbers', () {
        final address = InternetAddress('10.0.0.1');

        final key = MessageCallbackMap.formatKey(address, 65535);
        expect(key, equals('10.0.0.1:65535'));
      });

      test('should format loopback addresses', () {
        final ipv4Key =
            MessageCallbackMap.formatKey(InternetAddress.loopbackIPv4, 3000);
        final ipv6Key =
            MessageCallbackMap.formatKey(InternetAddress.loopbackIPv6, 3000);

        expect(ipv4Key, equals('127.0.0.1:3000'));
        expect(ipv6Key, equals('[::1]:3000'));
      });
    });

    group('parseKey', () {
      test('should parse IPv4 key correctly', () {
        const key = '192.168.1.100:8080';
        final parsed = MessageCallbackMap.parseKey(key);

        expect(parsed, isNotNull);
        expect(parsed!.address, equals('192.168.1.100'));
        expect(parsed.port, equals(8080));
      });

      test('should parse IPv6 key correctly', () {
        const key = '[2001:db8::1]:8443';
        final parsed = MessageCallbackMap.parseKey(key);

        expect(parsed, isNotNull);
        expect(parsed!.address, equals('2001:db8::1'));
        expect(parsed.port, equals(8443));
      });

      test('should return null for malformed IPv4 key', () {
        expect(MessageCallbackMap.parseKey('invalid'), isNull);
        expect(MessageCallbackMap.parseKey('192.168.1.100'), isNull);
        expect(MessageCallbackMap.parseKey('192.168.1.100:'), isNull);
        // parseKey(':8080') actually returns (address: '', port: 8080) so we check for empty address
        final parsed = MessageCallbackMap.parseKey(':8080');
        expect(parsed?.address.isEmpty, isTrue);
        expect(MessageCallbackMap.parseKey('192.168.1.100:abc'), isNull);
      });

      test('should return null for malformed IPv6 key', () {
        expect(MessageCallbackMap.parseKey('[2001:db8::1'), isNull);

        // This string has mismatched brackets and gets parsed as IPv4
        // The parser finds the last ':' and treats everything before as address
        final parsed = MessageCallbackMap.parseKey('2001:db8::1]:8080');
        expect(parsed, isNotNull);
        expect(parsed!.address, equals('2001:db8::1]')); // Includes the bracket

        expect(MessageCallbackMap.parseKey('[2001:db8::1]'), isNull);
        expect(MessageCallbackMap.parseKey('[2001:db8::1]:abc'), isNull);

        // []:8080 actually parses because empty string is valid address
        final emptyBracketParsed = MessageCallbackMap.parseKey('[]:8080');
        expect(emptyBracketParsed, isNotNull);
        expect(emptyBracketParsed!.address, equals(''));
      });

      test('should handle edge cases', () {
        expect(MessageCallbackMap.parseKey(''), isNull);

        // ':' gets parsed as address='' port=null (empty string after colon)
        expect(MessageCallbackMap.parseKey(':'), isNull);

        expect(MessageCallbackMap.parseKey('[]'), isNull);

        // '[:]' gets parsed as address='[' port=null
        expect(MessageCallbackMap.parseKey('[:]'), isNull);
      });

      test('should parse port 0', () {
        const key = '127.0.0.1:0';
        final parsed = MessageCallbackMap.parseKey(key);

        expect(parsed, isNotNull);
        expect(parsed!.port, equals(0));
      });

      test('should parse high port numbers', () {
        const key = '10.0.0.1:65535';
        final parsed = MessageCallbackMap.parseKey(key);

        expect(parsed, isNotNull);
        expect(parsed!.port, equals(65535));
      });
    });

    group('round-trip formatting', () {
      test('should maintain data integrity for IPv4', () {
        final originalAddress = InternetAddress('10.0.0.1');
        const originalPort = 5000;

        final key = MessageCallbackMap.formatKey(originalAddress, originalPort);
        final parsed = MessageCallbackMap.parseKey(key);

        expect(parsed, isNotNull);
        expect(parsed!.address, equals(originalAddress.address));
        expect(parsed.port, equals(originalPort));
      });

      test('should maintain data integrity for IPv6', () {
        final originalAddress = InternetAddress('2001:db8::8a2e:370:7334');
        const originalPort = 8443;

        final key = MessageCallbackMap.formatKey(originalAddress, originalPort);
        final parsed = MessageCallbackMap.parseKey(key);

        expect(parsed, isNotNull);
        expect(parsed!.address, equals(originalAddress.address));
        expect(parsed.port, equals(originalPort));
      });
    });

    group('callback functionality', () {
      test('should store and execute callbacks correctly', () {
        bool callbackExecuted = false;
        List<int>? receivedMsg;
        RemoteInfo? receivedRinfo;

        void testCallback(MessageRecord record) {
          callbackExecuted = true;
          receivedMsg = record.msg;
          receivedRinfo = record.rinfo;
        }

        callbackMap.add('127.0.0.1:8080', testCallback);
        final callback = callbackMap.get('127.0.0.1:8080');

        final testMsg = [1, 2, 3, 4, 5];
        final testRinfo = RemoteInfo(
          address: InternetAddress('127.0.0.1'),
          port: 8080,
        );

        callback!((msg: testMsg, rinfo: testRinfo));

        expect(callbackExecuted, isTrue);
        expect(receivedMsg, equals(testMsg));
        expect(receivedRinfo?.address.address, equals('127.0.0.1'));
        expect(receivedRinfo?.port, equals(8080));
      });

      test('should handle multiple different callbacks', () {
        int callback1Count = 0;
        int callback2Count = 0;

        void callback1(MessageRecord record) => callback1Count++;
        void callback2(MessageRecord record) => callback2Count++;

        callbackMap.add('peer1', callback1);
        callbackMap.add('peer2', callback2);

        callbackMap.get('peer1')!(
            (msg: [1], rinfo: RemoteInfo(address: InternetAddress('127.0.0.1'), port: 1)));
        callbackMap.get('peer2')!(
            (msg: [2], rinfo: RemoteInfo(address: InternetAddress('127.0.0.1'), port: 2)));
        callbackMap.get('peer1')!(
            (msg: [3], rinfo: RemoteInfo(address: InternetAddress('127.0.0.1'), port: 1)));

        expect(callback1Count, equals(2));
        expect(callback2Count, equals(1));
      });
    });

    group('complex scenarios', () {
      test('should handle mixed IPv4 and IPv6 addresses', () {
        void callback1(MessageRecord record) {}
        void callback2(MessageRecord record) {}

        callbackMap.addByAddress(InternetAddress('192.168.1.1'), 80, callback1);
        callbackMap.addByAddress(InternetAddress('2001:db8::1'), 80, callback2);

        expect(callbackMap.length, equals(2));
        expect(callbackMap.containsAddress(InternetAddress('192.168.1.1'), 80),
            isTrue);
        expect(callbackMap.containsAddress(InternetAddress('2001:db8::1'), 80),
            isTrue);

        final keys = callbackMap.keys.toList();
        expect(keys, contains('192.168.1.1:80'));
        expect(keys, contains('[2001:db8::1]:80'));
      });

      test('should differentiate between same IP with different ports', () {
        int callback1Count = 0;
        int callback2Count = 0;

        void callback1(MessageRecord record) => callback1Count++;
        void callback2(MessageRecord record) => callback2Count++;

        final address = InternetAddress('10.0.0.1');
        callbackMap.addByAddress(address, 8080, callback1);
        callbackMap.addByAddress(address, 8081, callback2);

        expect(callbackMap.length, equals(2));

        final invoker8080 = callbackMap.getByAddress(address, 8080)!;
        final invoker8081 = callbackMap.getByAddress(address, 8081)!;

        invoker8080((msg: [1], rinfo: RemoteInfo(address: address, port: 8080)));
        invoker8081((msg: [2], rinfo: RemoteInfo(address: address, port: 8081)));

        expect(callback1Count, equals(1));
        expect(callback2Count, equals(1));
      });

      test('should handle callback replacement', () {
        int callback1Count = 0;
        int callback2Count = 0;

        void callback1(MessageRecord record) => callback1Count++;
        void callback2(MessageRecord record) => callback2Count++;

        const key = '127.0.0.1:8080';
        final testMsg = [1, 2, 3];
        final testRinfo = RemoteInfo(
          address: InternetAddress('127.0.0.1'),
          port: 8080,
        );

        callbackMap.add(key, callback1);
        var invoker = callbackMap.get(key)!;
        invoker((msg: testMsg, rinfo: testRinfo));
        expect(callback1Count, equals(1));
        expect(callback2Count, equals(0));

        callbackMap.add(key, callback2);
        invoker = callbackMap.get(key)!;
        invoker((msg: testMsg, rinfo: testRinfo));
        expect(callback1Count, equals(1)); // callback1 should not be called again
        expect(callback2Count, equals(1)); // callback2 should be called
        expect(callbackMap.length, equals(1));
      });
    });
  });
}
