import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:shsp_types/shsp_types.dart';

void main() {
  group('StunResponse', () {
    test('should create StunResponse with all fields', () {
      const publicIp = '203.0.113.42';
      const publicPort = 54723;
      final transactionId = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      final rawData = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
      final attrs = {'server': 'Google STUN', 'version': '1.0'};
      
      final response = StunResponse(
        publicIp: publicIp,
        publicPort: publicPort,
        transactionId: transactionId,
        raw: rawData,
        attrs: attrs,
      );
      
      expect(response.publicIp, equals(publicIp));
      expect(response.publicPort, equals(publicPort));
      expect(response.transactionId, equals(transactionId));
      expect(response.raw, equals(rawData));
      expect(response.attrs, equals(attrs));
    });

    test('should create StunResponse without optional attributes', () {
      const publicIp = '192.0.2.100';
      const publicPort = 12345;
      final transactionId = Uint8List(12);
      final rawData = Uint8List(4);
      
      final response = StunResponse(
        publicIp: publicIp,
        publicPort: publicPort,
        transactionId: transactionId,
        raw: rawData,
      );
      
      expect(response.publicIp, equals(publicIp));
      expect(response.publicPort, equals(publicPort));
      expect(response.transactionId, equals(transactionId));
      expect(response.raw, equals(rawData));
      expect(response.attrs, isNull);
    });

    test('should handle IPv6 public IP', () {
      const publicIp = '2001:db8::42';
      const publicPort = 8080;
      final response = StunResponse(
        publicIp: publicIp,
        publicPort: publicPort,
        transactionId: Uint8List(12),
        raw: Uint8List(0),
      );
      
      expect(response.publicIp, equals(publicIp));
    });

    test('should handle port 0', () {
      final response = StunResponse(
        publicIp: '10.0.0.1',
        publicPort: 0,
        transactionId: Uint8List(12),
        raw: Uint8List(0),
      );
      
      expect(response.publicPort, equals(0));
    });

    test('should handle maximum port number', () {
      final response = StunResponse(
        publicIp: '10.0.0.1',
        publicPort: 65535,
        transactionId: Uint8List(12),
        raw: Uint8List(0),
      );
      
      expect(response.publicPort, equals(65535));
    });

    test('should handle empty raw data', () {
      final response = StunResponse(
        publicIp: '10.0.0.1',
        publicPort: 8080,
        transactionId: Uint8List(12),
        raw: Uint8List(0),
      );
      
      expect(response.raw.length, equals(0));
    });

    test('should handle large raw data', () {
      final largeData = Uint8List(1024);
      for (int i = 0; i < largeData.length; i++) {
        largeData[i] = i % 256;
      }
      
      final response = StunResponse(
        publicIp: '10.0.0.1',
        publicPort: 8080,
        transactionId: Uint8List(12),
        raw: largeData,
      );
      
      expect(response.raw.length, equals(1024));
      expect(response.raw[0], equals(0));
      expect(response.raw[255], equals(255));
      expect(response.raw[256], equals(0)); // wraps around
    });

    test('should handle 12-byte transaction ID correctly', () {
      final transactionId = Uint8List.fromList([
        0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0, 0x11, 0x22, 0x33, 0x44
      ]);
      
      final response = StunResponse(
        publicIp: '10.0.0.1',
        publicPort: 8080,
        transactionId: transactionId,
        raw: Uint8List(0),
      );
      
      expect(response.transactionId.length, equals(12));
      expect(response.transactionId[0], equals(0x12));
      expect(response.transactionId[11], equals(0x44));
    });

    test('should serialize to JSON correctly', () {
      final response = StunResponse(
        publicIp: '198.51.100.123',
        publicPort: 9876,
        transactionId: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
        raw: Uint8List.fromList([0x01, 0x02, 0x03]),
        attrs: {'test': 'value'},
      );
      
      final json = response.toJson();
      
      expect(json, isA<Map<String, dynamic>>());
      expect(json['publicIp'], equals('198.51.100.123'));
      expect(json['publicPort'], equals(9876));
      expect(json['transactionId'], equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]));
      expect(json['raw'], equals([0x01, 0x02, 0x03]));
      expect(json['attrs'], equals({'test': 'value'}));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'publicIp': '172.16.123.45',
        'publicPort': 5678,
        'transactionId': [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
        'raw': [0xFF, 0xFE, 0xFD],
        'attrs': {'server': 'Test STUN'},
      };
      
      final response = StunResponse.fromJson(json);
      
      expect(response.publicIp, equals('172.16.123.45'));
      expect(response.publicPort, equals(5678));
      expect(response.transactionId, equals(Uint8List.fromList([12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1])));
      expect(response.raw, equals(Uint8List.fromList([0xFF, 0xFE, 0xFD])));
      expect(response.attrs, equals({'server': 'Test STUN'}));
    });

    test('should handle round-trip JSON serialization', () {
      final original = StunResponse(
        publicIp: '10.1.2.3',
        publicPort: 4567,
        transactionId: Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00, 0x11, 0x22, 0x33, 0x44, 0x55]),
        raw: Uint8List.fromList([0x10, 0x20, 0x30, 0x40]),
        attrs: {'roundtrip': 'test'},
      );
      
      final json = original.toJson();
      final restored = StunResponse.fromJson(json);
      
      expect(restored.publicIp, equals(original.publicIp));
      expect(restored.publicPort, equals(original.publicPort));
      expect(restored.transactionId, equals(original.transactionId));
      expect(restored.raw, equals(original.raw));
      expect(restored.attrs, equals(original.attrs));
    });

    test('should handle JSON serialization without attrs', () {
      final response = StunResponse(
        publicIp: '127.0.0.1',
        publicPort: 3478,
        transactionId: Uint8List(12),
        raw: Uint8List(0),
      );
      
      final json = response.toJson();
      final restored = StunResponse.fromJson(json);
      
      expect(restored.attrs, isNull);
    });

    test('should handle complex attrs object', () {
      final complexAttrs = {
        'strings': 'value',
        'numbers': 42,
        'booleans': true,
        'nested': {
          'inner': 'value',
          'count': 123,
        },
        'list': [1, 2, 3, 'mixed', true],
      };
      
      final response = StunResponse(
        publicIp: '10.0.0.1',
        publicPort: 8080,
        transactionId: Uint8List(12),
        raw: Uint8List(0),
        attrs: complexAttrs,
      );
      
      expect(response.attrs, equals(complexAttrs));
      
      final json = response.toJson();
      final restored = StunResponse.fromJson(json);
      expect(restored.attrs, equals(complexAttrs));
    });
  });

  group('LocalInfo', () {
    test('should create LocalInfo with IPv4', () {
      const localIp = '192.168.1.100';
      const localPort = 12345;
      
      final localInfo = LocalInfo(
        localIp: localIp,
        localPort: localPort,
      );
      
      expect(localInfo.localIp, equals(localIp));
      expect(localInfo.localPort, equals(localPort));
    });

    test('should create LocalInfo with IPv6', () {
      const localIp = 'fe80::1';
      const localPort = 8080;
      
      final localInfo = LocalInfo(
        localIp: localIp,
        localPort: localPort,
      );
      
      expect(localInfo.localIp, equals(localIp));
      expect(localInfo.localPort, equals(localPort));
    });

    test('should handle port 0', () {
      final localInfo = LocalInfo(
        localIp: '127.0.0.1',
        localPort: 0,
      );
      
      expect(localInfo.localPort, equals(0));
    });

    test('should handle maximum port', () {
      final localInfo = LocalInfo(
        localIp: '127.0.0.1',
        localPort: 65535,
      );
      
      expect(localInfo.localPort, equals(65535));
    });

    test('should handle loopback addresses', () {
      final ipv4Local = LocalInfo(
        localIp: '127.0.0.1',
        localPort: 8080,
      );
      
      final ipv6Local = LocalInfo(
        localIp: '::1',
        localPort: 8080,
      );
      
      expect(ipv4Local.localIp, equals('127.0.0.1'));
      expect(ipv6Local.localIp, equals('::1'));
    });

    test('should handle private IP ranges', () {
      final privateRanges = [
        '192.168.1.50',   // Class C
        '10.0.0.100',     // Class A
        '172.16.0.200',   // Class B
      ];
      
      for (final ip in privateRanges) {
        final localInfo = LocalInfo(localIp: ip, localPort: 8080);
        expect(localInfo.localIp, equals(ip));
      }
    });

    test('should serialize to JSON correctly', () {
      final localInfo = LocalInfo(
        localIp: '10.0.0.50',
        localPort: 9999,
      );
      
      final json = localInfo.toJson();
      
      expect(json, isA<Map<String, dynamic>>());
      expect(json['localIp'], equals('10.0.0.50'));
      expect(json['localPort'], equals(9999));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'localIp': '172.16.1.100',
        'localPort': 5555,
      };
      
      final localInfo = LocalInfo.fromJson(json);
      
      expect(localInfo.localIp, equals('172.16.1.100'));
      expect(localInfo.localPort, equals(5555));
    });

    test('should handle round-trip JSON serialization', () {
      final original = LocalInfo(
        localIp: '2001:db8::cafe:beef',
        localPort: 31415,
      );
      
      final json = original.toJson();
      final restored = LocalInfo.fromJson(json);
      
      expect(restored.localIp, equals(original.localIp));
      expect(restored.localPort, equals(original.localPort));
    });

    test('should handle empty IP string', () {
      final localInfo = LocalInfo(
        localIp: '',
        localPort: 8080,
      );
      
      expect(localInfo.localIp, equals(''));
    });

    test('should differentiate instances with same IP different ports', () {
      final info1 = LocalInfo(localIp: '10.0.0.1', localPort: 8080);
      final info2 = LocalInfo(localIp: '10.0.0.1', localPort: 8081);
      
      expect(info1.localIp, equals(info2.localIp));
      expect(info1.localPort, isNot(equals(info2.localPort)));
    });

    test('should differentiate instances with different IPs same port', () {
      final info1 = LocalInfo(localIp: '10.0.0.1', localPort: 8080);
      final info2 = LocalInfo(localIp: '10.0.0.2', localPort: 8080);
      
      expect(info1.localPort, equals(info2.localPort));
      expect(info1.localIp, isNot(equals(info2.localIp)));
    });
  });
}