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
      final peerInfo = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );

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
      final json = {
        'address': '172.16.0.1',
        'port': 3000,
      };

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

  group('HandshakeSignal', () {
    test('should create HandshakeSignal with all fields', () {
      final now = DateTime(2024, 6, 15, 12, 0);
      final endTime = now.add(const Duration(hours: 2));

      final signal = HandshakeSignal(
        publicIPv4:
            PeerInfo(address: InternetAddress('203.0.113.1'), port: 8080),
        publicIPv6:
            PeerInfo(address: InternetAddress('2001:db8::1'), port: 8080),
        localIPv4:
            PeerInfo(address: InternetAddress('192.168.1.100'), port: 9090),
        localIPv6: PeerInfo(address: InternetAddress('fe80::1'), port: 9090),
        publicKey: 'test-public-key',
        expirationPublicKey: DateTime(2025, 1, 1),
        referenceTimestamp: now,
        maxHandshakeDurationSeconds: 60,
        intervalBetweenHandshakesSeconds: 300,
        endHandshakeAvailability: endTime,
      );

      expect(signal.publicIPv4, isNotNull);
      expect(signal.publicIPv4!.address.address, equals('203.0.113.1'));
      expect(signal.publicIPv6, isNotNull);
      expect(signal.localIPv4, isNotNull);
      expect(signal.localIPv6, isNotNull);
      expect(signal.publicKey, equals('test-public-key'));
      expect(signal.expirationPublicKey, equals(DateTime(2025, 1, 1)));
      expect(signal.referenceTimestamp, equals(now));
      expect(signal.maxHandshakeDurationSeconds, equals(60));
      expect(signal.intervalBetweenHandshakesSeconds, equals(300));
      expect(signal.endHandshakeAvailability, equals(endTime));
    });

    test('should create HandshakeSignal with minimal required fields', () {
      final now = DateTime.now();
      final signal = HandshakeSignal(
        referenceTimestamp: now,
        maxHandshakeDurationSeconds: 30,
        intervalBetweenHandshakesSeconds: 120,
        endHandshakeAvailability: now.add(const Duration(hours: 1)),
      );

      expect(signal.publicIPv4, isNull);
      expect(signal.publicIPv6, isNull);
      expect(signal.localIPv4, isNull);
      expect(signal.localIPv6, isNull);
      expect(signal.publicKey, isNull);
      expect(signal.expirationPublicKey, isNull);
      expect(signal.maxHandshakeDurationSeconds, equals(30));
      expect(signal.intervalBetweenHandshakesSeconds, equals(120));
    });

    test('should serialize to JSON correctly', () {
      final now = DateTime(2024, 1, 1, 12, 0);
      final signal = HandshakeSignal(
        publicIPv4: PeerInfo(address: InternetAddress('10.0.0.1'), port: 8080),
        publicKey: 'json-test-key',
        referenceTimestamp: now,
        maxHandshakeDurationSeconds: 45,
        intervalBetweenHandshakesSeconds: 180,
        endHandshakeAvailability: now.add(const Duration(hours: 3)),
      );

      final json = signal.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['publicKey'], equals('json-test-key'));
      expect(json['maxHandshakeDurationSeconds'], equals(45));
      expect(json['intervalBetweenHandshakesSeconds'], equals(180));
    });

    test('should deserialize from JSON correctly', () {
      final now = DateTime(2024, 1, 1, 12, 0);
      final json = {
        'publicIPv4': {'address': '10.0.0.1', 'port': 8080},
        'publicKey': 'deserialized-key',
        'referenceTimestamp': now.toIso8601String(),
        'maxHandshakeDurationSeconds': 90,
        'intervalBetweenHandshakesSeconds': 240,
        'endHandshakeAvailability':
            now.add(const Duration(hours: 4)).toIso8601String(),
      };

      final signal = HandshakeSignal.fromJson(json);

      expect(signal.publicIPv4, isNotNull);
      expect(signal.publicIPv4!.address.address, equals('10.0.0.1'));
      expect(signal.publicIPv4!.port, equals(8080));
      expect(signal.publicKey, equals('deserialized-key'));
      expect(signal.maxHandshakeDurationSeconds, equals(90));
      expect(signal.intervalBetweenHandshakesSeconds, equals(240));
    });

    test('should handle timing calculations', () {
      final start = DateTime(2024, 6, 15, 12, 0, 0);
      final signal = HandshakeSignal(
        referenceTimestamp: start,
        maxHandshakeDurationSeconds: 120,
        intervalBetweenHandshakesSeconds: 600,
        endHandshakeAvailability: start.add(const Duration(hours: 8)),
      );

      // Check duration calculations
      expect(signal.maxHandshakeDurationSeconds, equals(120));
      expect(signal.intervalBetweenHandshakesSeconds, equals(600));

      final totalDuration =
          signal.endHandshakeAvailability.difference(signal.referenceTimestamp);
      expect(totalDuration.inHours, equals(8));

      // Calculate how many handshakes could theoretically fit
      final availableSeconds = totalDuration.inSeconds;
      final possibleHandshakes =
          availableSeconds ~/ signal.intervalBetweenHandshakesSeconds;
      expect(possibleHandshakes,
          equals(48)); // 8 hours * 3600 seconds / 600 seconds interval
    });

    test('should handle null peer info fields gracefully', () {
      final signal = HandshakeSignal(
        publicIPv4: PeerInfo(address: InternetAddress('1.2.3.4'), port: 80),
        publicIPv6: null,
        localIPv4: null,
        localIPv6: PeerInfo(address: InternetAddress('::1'), port: 8080),
        referenceTimestamp: DateTime.now(),
        maxHandshakeDurationSeconds: 15,
        intervalBetweenHandshakesSeconds: 60,
        endHandshakeAvailability:
            DateTime.now().add(const Duration(minutes: 30)),
      );

      expect(signal.publicIPv4, isNotNull);
      expect(signal.publicIPv6, isNull);
      expect(signal.localIPv4, isNull);
      expect(signal.localIPv6, isNotNull);
    });

    test('should handle extreme timing values', () {
      final now = DateTime.now();
      final signal = HandshakeSignal(
        referenceTimestamp: now,
        maxHandshakeDurationSeconds: 1, // Very short handshake
        intervalBetweenHandshakesSeconds: 86400, // One day between handshakes
        endHandshakeAvailability:
            now.add(const Duration(days: 365)), // One year
      );

      expect(signal.maxHandshakeDurationSeconds, equals(1));
      expect(signal.intervalBetweenHandshakesSeconds, equals(86400));

      final duration =
          signal.endHandshakeAvailability.difference(signal.referenceTimestamp);
      expect(duration.inDays, equals(365));
    });
  });

  group('SecuritySignal', () {
    test('should create SecuritySignal with all fields', () {
      final expirationDate = DateTime(2025, 12, 31);
      final signal = SecuritySignal(
        publicKey: 'security-public-key',
        expirationPublicKey: expirationDate,
      );

      expect(signal.publicKey, equals('security-public-key'));
      expect(signal.expirationPublicKey, equals(expirationDate));
    });

    test('should create SecuritySignal with null values', () {
      final signal = SecuritySignal(
        publicKey: null,
        expirationPublicKey: null,
      );

      expect(signal.publicKey, isNull);
      expect(signal.expirationPublicKey, isNull);
    });

    test('should handle empty public key', () {
      final signal = SecuritySignal(
        publicKey: '',
        expirationPublicKey: DateTime.now(),
      );

      expect(signal.publicKey, equals(''));
      expect(signal.expirationPublicKey, isNotNull);
    });

    test('should handle key with expiration in the past', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 30));
      final signal = SecuritySignal(
        publicKey: 'expired-key',
        expirationPublicKey: pastDate,
      );

      expect(signal.publicKey, equals('expired-key'));
      expect(signal.expirationPublicKey!.isBefore(DateTime.now()), isTrue);
    });

    test('should handle key with future expiration', () {
      final futureDate = DateTime.now().add(const Duration(days: 365));
      final signal = SecuritySignal(
        publicKey: 'future-key',
        expirationPublicKey: futureDate,
      );

      expect(signal.publicKey, equals('future-key'));
      expect(signal.expirationPublicKey!.isAfter(DateTime.now()), isTrue);
    });
  });
}
