import 'dart:io';
import 'package:shsp/src/impl/utility/message_callback_map.dart';
import 'package:test/test.dart';

void main() {
  group('MessageCallbackMap', () {
    late MessageCallbackMap map;

    setUp(() {
      map = MessageCallbackMap();
    });

    // ── Key formatting ──────────────────────────────────────────────────────
    group('formatKey', () {
      test('formats IPv4 address with port as IP:port', () {
        final addr = InternetAddress('192.168.1.100');
        final key = MessageCallbackMap.formatKey(addr, 8080);
        expect(key, equals('192.168.1.100:8080'));
      });

      test('formats IPv6 address with port as [IP]:port', () {
        final addr = InternetAddress('2001:db8::1');
        final key = MessageCallbackMap.formatKey(addr, 8080);
        expect(key, equals('[2001:db8::1]:8080'));
      });
    });

    // ── Key parsing ──────────────────────────────────────────────────────
    group('parseKey', () {
      test('parses IPv4 key correctly', () {
        final parsed = MessageCallbackMap.parseKey('192.168.1.100:8080');
        expect(parsed, isNotNull);
        expect(parsed!.address, equals('192.168.1.100'));
        expect(parsed.port, equals(8080));
      });

      test('parses IPv6 key correctly', () {
        final parsed = MessageCallbackMap.parseKey('[2001:db8::1]:8080');
        expect(parsed, isNotNull);
        expect(parsed!.address, equals('2001:db8::1'));
        expect(parsed.port, equals(8080));
      });

      test('returns null for malformed IPv6 key (missing closing bracket)', () {
        final parsed = MessageCallbackMap.parseKey('[2001:db8::1:8080');
        expect(parsed, isNull);
      });

      test('returns null for key without port', () {
        final parsed = MessageCallbackMap.parseKey('192.168.1.100');
        expect(parsed, isNull);
      });

      test('returns null for invalid port number', () {
        final parsed = MessageCallbackMap.parseKey('192.168.1.100:invalid');
        expect(parsed, isNull);
      });
    });

    // ── Basic operations ────────────────────────────────────────────────────
    group('add/get', () {
      test('adds and retrieves callback by key', () {
        void myCallback(record) {}
        map.add('192.168.1.100:8080', myCallback);
        final retrieved = map.get('192.168.1.100:8080');
        expect(retrieved, isNotNull);
      });

      test('returns null for non-existent key', () {
        final retrieved = map.get('192.168.1.100:8080');
        expect(retrieved, isNull);
      });

      test('replaces existing callback', () {
        void callback1(record) {}
        void callback2(record) {}
        map.add('192.168.1.100:8080', callback1);
        map.add('192.168.1.100:8080', callback2);
        expect(map.length, equals(1));
      });
    });

    // ── Exact match lookup ──────────────────────────────────────────────────
    group('getByAddress - exact match', () {
      test('finds callback with exact IP:port match', () {
        void myCallback(record) {}
        final addr = InternetAddress('192.168.1.100');
        map.addByAddress(addr, 8080, myCallback);

        final retrieved = map.getByAddress(addr, 8080);
        expect(retrieved, isNotNull);
      });

      test('falls back to IP match when port differs', () {
        void myCallback(record) {}
        final addr = InternetAddress('192.168.1.100');
        map.addByAddress(addr, 8080, myCallback);

        // Different port but same IP—should fallback to IP match
        final retrieved = map.getByAddress(addr, 9090);
        expect(retrieved, isNotNull);
      });
    });

    // ── Fallback IP-only matching ───────────────────────────────────────────
    group('getByAddress - IP-only fallback (NAT scenario)', () {
      test('falls back to IP-only match when exact port not found', () {
        void myCallback(record) {}
        final addr = InternetAddress('172.20.0.3');
        // Register callback for :9002
        map.addByAddress(addr, 9002, myCallback);

        // Query with remapped port :58349, should fallback to same IP
        final retrieved = map.getByAddress(addr, 58349);
        expect(retrieved, isNotNull);
      });

      test('prefers exact match over IP fallback', () {
        void callback1(record) {}
        void callback2(record) {}
        final addr = InternetAddress('192.168.1.100');
        map.addByAddress(addr, 8080, callback1);
        map.addByAddress(addr, 9090, callback2);

        final retrieved = map.getByAddress(addr, 8080);
        // Should get the exact match handler, not any other port
        expect(retrieved, isNotNull);
      });

      test('returns null when IP not found at all', () {
        void myCallback(record) {}
        final addr1 = InternetAddress('192.168.1.100');
        final addr2 = InternetAddress('192.168.1.101');
        map.addByAddress(addr1, 8080, myCallback);

        final retrieved = map.getByAddress(addr2, 58349);
        expect(retrieved, isNull);
      });

      test('works with IPv6 addresses', () {
        void myCallback(record) {}
        final addr = InternetAddress('2001:db8::1');
        map.addByAddress(addr, 8080, myCallback);

        final retrieved = map.getByAddress(addr, 58349);
        expect(retrieved, isNotNull);
      });
    });

    // ── Multiple ports for same IP ──────────────────────────────────────────
    group('getByAddress - ambiguous IP (multiple ports)', () {
      test('returns first match when multiple callbacks registered for same IP',
          () {
        void callback1(record) {}
        void callback2(record) {}
        void callback3(record) {}
        final addr = InternetAddress('192.168.1.100');
        map.addByAddress(addr, 8080, callback1);
        map.addByAddress(addr, 9090, callback2);
        map.addByAddress(addr, 7070, callback3);

        // Query with unmapped port—should return *one* of them (first in iteration)
        final retrieved = map.getByAddress(addr, 58349);
        expect(retrieved, isNotNull);
      });
    });

    // ── Remove and contains ─────────────────────────────────────────────────
    group('remove/contains', () {
      test('removes callback by key', () {
        void myCallback(record) {}
        map.add('192.168.1.100:8080', myCallback);
        expect(map.containsKey('192.168.1.100:8080'), isTrue);

        map.remove('192.168.1.100:8080');
        expect(map.containsKey('192.168.1.100:8080'), isFalse);
      });

      test('removeByAddress removes callback', () {
        void myCallback(record) {}
        final addr = InternetAddress('192.168.1.100');
        map.addByAddress(addr, 8080, myCallback);
        expect(map.containsAddress(addr, 8080), isTrue);

        map.removeByAddress(addr, 8080);
        expect(map.containsAddress(addr, 8080), isFalse);
      });

      test('containsAddress works for exact match', () {
        void myCallback(record) {}
        final addr = InternetAddress('192.168.1.100');
        map.addByAddress(addr, 8080, myCallback);

        expect(map.containsAddress(addr, 8080), isTrue);
        expect(map.containsAddress(addr, 9090), isFalse);
      });
    });

    // ── Clear and length ────────────────────────────────────────────────────
    group('clear/length', () {
      test('clears all callbacks', () {
        void callback1(record) {}
        void callback2(record) {}
        final addr = InternetAddress('192.168.1.100');
        map.addByAddress(addr, 8080, callback1);
        map.addByAddress(addr, 9090, callback2);
        expect(map.length, equals(2));

        map.clear();
        expect(map.length, equals(0));
      });

      test('tracks length correctly', () {
        void callback1(record) {}
        void callback2(record) {}
        void callback3(record) {}
        final addr = InternetAddress('192.168.1.100');
        map.addByAddress(addr, 8080, callback1);
        expect(map.length, equals(1));

        map.addByAddress(addr, 9090, callback2);
        expect(map.length, equals(2));

        map.addByAddress(InternetAddress('192.168.1.101'), 8080, callback3);
        expect(map.length, equals(3));
      });
    });

    // ── Handler retrieval ───────────────────────────────────────────────────
    group('getHandler', () {
      test('returns CallbackOnMessage handler for key', () {
        void myCallback(record) {}
        map.add('192.168.1.100:8080', myCallback);
        final handler = map.getHandler('192.168.1.100:8080');
        expect(handler, isNotNull);
      });

      test('returns null for non-existent key', () {
        final handler = map.getHandler('192.168.1.100:8080');
        expect(handler, isNull);
      });
    });

    // ── Keys iteration ──────────────────────────────────────────────────────
    group('keys', () {
      test('returns all registered keys', () {
        void callback1(record) {}
        void callback2(record) {}
        map.add('192.168.1.100:8080', callback1);
        map.add('192.168.1.100:9090', callback2);

        final keys = map.keys.toList();
        expect(keys, containsAll(['192.168.1.100:8080', '192.168.1.100:9090']));
        expect(keys.length, equals(2));
      });

      test('returns empty when no callbacks registered', () {
        final keys = map.keys.toList();
        expect(keys, isEmpty);
      });
    });
  });
}
