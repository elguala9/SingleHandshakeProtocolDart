import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('PeerInfo', () {
    test('should create PeerInfo with IPv4 address', () {
      final address = InternetAddress('192.168.1.100');
      const port = 8080;

      final peerInfo = PeerInfo(address: address, port: port);

      expect(peerInfo.address, equals(address));
      expect(peerInfo.port, equals(port));
      expect(peerInfo.address.type, equals(InternetAddressType.IPv4));
    });

    test('should create PeerInfo with IPv6 address', () {
      final address = InternetAddress('2001:db8::1');
      const port = 8443;

      final peerInfo = PeerInfo(address: address, port: port);

      expect(peerInfo.address, equals(address));
      expect(peerInfo.port, equals(port));
      expect(peerInfo.address.type, equals(InternetAddressType.IPv6));
    });

    test('should handle port 0', () {
      final peerInfo = PeerInfo(address: InternetAddress.loopbackIPv4, port: 0);

      expect(peerInfo.port, equals(0));
    });

    test('should handle maximum port number', () {
      final peerInfo = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 65535,
      );

      expect(peerInfo.port, equals(65535));
    });

    test('should handle loopback addresses', () {
      final ipv4Peer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 8080,
      );
      final ipv6Peer = PeerInfo(
        address: InternetAddress.loopbackIPv6,
        port: 8080,
      );

      expect(ipv4Peer.address.isLoopback, isTrue);
      expect(ipv6Peer.address.isLoopback, isTrue);
    });

    test('should serialize to JSON correctly', () {
      final peerInfo = PeerInfo(
        address: InternetAddress('10.0.0.1'),
        port: 9090,
      );

      final json = peerInfo.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['address'], equals('10.0.0.1'));
      expect(json['port'], equals(9090));
    });

    test('should deserialize from JSON correctly', () {
      final json = {'address': '172.16.0.1', 'port': 3000};

      final peerInfo = PeerInfo.fromJson(json);

      expect(peerInfo.address.address, equals('172.16.0.1'));
      expect(peerInfo.port, equals(3000));
      expect(peerInfo.address.type, equals(InternetAddressType.IPv4));
    });

    test('should handle round-trip JSON serialization', () {
      final original = PeerInfo(
        address: InternetAddress('2001:db8::8a2e:370:7334'),
        port: 12345,
      );

      final json = original.toJson();
      final restored = PeerInfo.fromJson(json);

      expect(restored.address.address, equals(original.address.address));
      expect(restored.port, equals(original.port));
      expect(restored.address.type, equals(original.address.type));
    });

    test('equality should work by reference', () {
      final address = InternetAddress('10.0.0.1');
      final peerInfo1 = PeerInfo(address: address, port: 8080);
      final peerInfo2 = PeerInfo(address: address, port: 8080);

      // Objects are different instances
      expect(identical(peerInfo1, peerInfo2), isFalse);

      // But have same data
      expect(peerInfo1.address, equals(peerInfo2.address));
      expect(peerInfo1.port, equals(peerInfo2.port));
    });
  });
}
