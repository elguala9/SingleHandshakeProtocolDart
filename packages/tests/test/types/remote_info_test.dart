import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('RemoteInfo', () {
    test('should create RemoteInfo with IPv4 address', () {
      final address = InternetAddress('192.168.1.100');
      const port = 8080;

      final rinfo = RemoteInfo(address: address, port: port);

      expect(rinfo.address, equals(address));
      expect(rinfo.port, equals(port));
      expect(rinfo.address.type, equals(InternetAddressType.IPv4));
    });

    test('should create RemoteInfo with IPv6 address', () {
      final address = InternetAddress('2001:db8::1');
      const port = 8443;

      final rinfo = RemoteInfo(address: address, port: port);

      expect(rinfo.address, equals(address));
      expect(rinfo.port, equals(port));
      expect(rinfo.address.type, equals(InternetAddressType.IPv6));
    });

    test('should handle port 0', () {
      final rinfo = RemoteInfo(address: InternetAddress.loopbackIPv4, port: 0);

      expect(rinfo.port, equals(0));
    });

    test('should handle maximum port number', () {
      final rinfo = RemoteInfo(
        address: InternetAddress.loopbackIPv4,
        port: 65535,
      );

      expect(rinfo.port, equals(65535));
    });

    test('should handle loopback addresses', () {
      final ipv4Rinfo = RemoteInfo(
        address: InternetAddress.loopbackIPv4,
        port: 8080,
      );
      final ipv6Rinfo = RemoteInfo(
        address: InternetAddress.loopbackIPv6,
        port: 8080,
      );

      expect(ipv4Rinfo.address.isLoopback, isTrue);
      expect(ipv6Rinfo.address.isLoopback, isTrue);
    });

    test('should serialize to JSON correctly', () {
      final rinfo = RemoteInfo(
        address: InternetAddress('10.0.0.1'),
        port: 9090,
      );

      final json = rinfo.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['address'], equals('10.0.0.1'));
      expect(json['port'], equals(9090));
    });

    test('should deserialize from JSON correctly', () {
      final json = {'address': '172.16.0.1', 'port': 3000};

      final rinfo = RemoteInfo.fromJson(json);

      expect(rinfo.address.address, equals('172.16.0.1'));
      expect(rinfo.port, equals(3000));
      expect(rinfo.address.type, equals(InternetAddressType.IPv4));
    });

    test('should handle round-trip JSON serialization IPv4', () {
      final original = RemoteInfo(
        address: InternetAddress('203.0.113.42'),
        port: 54321,
      );

      final json = original.toJson();
      final restored = RemoteInfo.fromJson(json);

      expect(restored.address.address, equals(original.address.address));
      expect(restored.port, equals(original.port));
      expect(restored.address.type, equals(original.address.type));
    });

    test('should handle round-trip JSON serialization IPv6', () {
      final original = RemoteInfo(
        address: InternetAddress('2001:db8::8a2e:370:7334'),
        port: 12345,
      );

      final json = original.toJson();
      final restored = RemoteInfo.fromJson(json);

      expect(restored.address.address, equals(original.address.address));
      expect(restored.port, equals(original.port));
      expect(restored.address.type, equals(original.address.type));
    });

    test('should handle private IP ranges', () {
      final privateIPs = [
        '192.168.1.1', // Class C private
        '10.0.0.1', // Class A private
        '172.16.0.1', // Class B private
      ];

      for (final ip in privateIPs) {
        final rinfo = RemoteInfo(address: InternetAddress(ip), port: 8080);

        expect(rinfo.address.address, equals(ip));
        expect(rinfo.address.type, equals(InternetAddressType.IPv4));
      }
    });

    test('should differentiate between same IP different ports', () {
      final address = InternetAddress('10.0.0.1');
      final rinfo1 = RemoteInfo(address: address, port: 8080);
      final rinfo2 = RemoteInfo(address: address, port: 8081);

      expect(rinfo1.address, equals(rinfo2.address));
      expect(rinfo1.port, isNot(equals(rinfo2.port)));
    });

    test('should differentiate between different IPs same port', () {
      const port = 8080;
      final rinfo1 = RemoteInfo(
        address: InternetAddress('10.0.0.1'),
        port: port,
      );
      final rinfo2 = RemoteInfo(
        address: InternetAddress('10.0.0.2'),
        port: port,
      );

      expect(rinfo1.port, equals(rinfo2.port));
      expect(rinfo1.address.address, isNot(equals(rinfo2.address.address)));
    });
  });
}
