import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('AddressUtility', () {
    group('formatAddress', () {
      test('formats IPv4 RemoteInfo as address:port', () {
        final rinfo = RemoteInfo(
          address: InternetAddress('192.168.1.100'),
          port: 8080,
        );
        final formatted = AddressUtility.formatAddress(rinfo);
        expect(formatted, equals('192.168.1.100:8080'));
      });

      test('formats address with port 0', () {
        final rinfo = RemoteInfo(
          address: InternetAddress.anyIPv4,
          port: 0,
        );
        final formatted = AddressUtility.formatAddress(rinfo);
        expect(formatted, contains(':0'));
      });
    });

    group('formatAddressParts', () {
      test('formats IPv4 PeerInfo as address:port', () {
        final peer = PeerInfo(
          address: InternetAddress('192.168.1.100'),
          port: 8080,
        );
        final formatted = AddressUtility.formatAddressParts(peer);
        expect(formatted, equals('192.168.1.100:8080'));
      });
    });

    group('parseAddress', () {
      test('parses valid "1.2.3.4:8080" into address and port components', () {
        final result = AddressUtility.parseAddress('1.2.3.4:8080');
        expect(result, isNotNull);
        expect(result!['address'], equals('1.2.3.4'));
        expect(result['port'], equals('8080'));
      });

      test('returns null when no colon present', () {
        final result = AddressUtility.parseAddress('192.168.1.100');
        expect(result, isNull);
      });

      test('returns null when port is not a number', () {
        final result = AddressUtility.parseAddress('192.168.1.100:abc');
        expect(result, isNull);
      });

      test('returns null when input has more than one colon (IPv6 without brackets)', () {
        final result = AddressUtility.parseAddress('::1:8080');
        expect(result, isNull);
      });
    });

    group('fromString', () {
      test('returns RemoteInfo for valid "1.2.3.4:9000"', () {
        final result = AddressUtility.fromString('1.2.3.4:9000');
        expect(result, isNotNull);
        expect(result!.address.address, equals('1.2.3.4'));
        expect(result.port, equals(9000));
      });

      test('returns null for malformed string without colon', () {
        final result = AddressUtility.fromString('192.168.1.100');
        expect(result, isNull);
      });

      test('returns null for port out-of-range (65536)', () {
        final result = AddressUtility.fromString('192.168.1.100:65536');
        expect(result, isNull);
      });

      test('returns null for negative port', () {
        final result = AddressUtility.fromString('192.168.1.100:-1');
        expect(result, isNull);
      });

      test('returns null for non-numeric port', () {
        final result = AddressUtility.fromString('192.168.1.100:abc');
        expect(result, isNull);
      });

      test('returns null for invalid IP address string', () {
        final result = AddressUtility.fromString('999.999.999.999:8080');
        expect(result, isNull);
      });

      test('RemoteInfo.port matches the string port', () {
        final result = AddressUtility.fromString('192.168.1.100:9000');
        expect(result!.port, equals(9000));
      });

      test('RemoteInfo.address matches the string IP', () {
        final result = AddressUtility.fromString('192.168.1.100:9000');
        expect(result!.address.address, equals('192.168.1.100'));
      });
    });

    group('getLocalIp', () {
      test('returns a non-null non-empty string', () async {
        try {
          final ip = AddressUtility.getLocalIp();
          expect(ip, isNotNull);
          expect(ip, isNotEmpty);
        } on ShspNetworkException {
          markTestSkipped('No non-loopback network interface available');
        }
      });

      test('returned string is a valid IPv4 dotted-quad format', () async {
        try {
          final ip = AddressUtility.getLocalIp();
          final parts = ip.split('.');
          expect(parts.length, equals(4));
          for (final part in parts) {
            final num = int.tryParse(part);
            expect(num, isNotNull);
            expect(num, greaterThanOrEqualTo(0));
            expect(num, lessThanOrEqualTo(255));
          }
        } on ShspNetworkException {
          markTestSkipped('No non-loopback network interface available');
        }
      });

      test('returned IP is not the loopback address 127.0.0.1', () async {
        try {
          final ip = AddressUtility.getLocalIp();
          expect(ip, isNot(equals('127.0.0.1')));
        } on ShspNetworkException {
          markTestSkipped('No non-loopback network interface available');
        }
      });
    });

    group('canCreateIPv6Socket', () {
      test('returns a bool (true or false, both acceptable — just does not throw)', () async {
        final canCreate = AddressUtility.canCreateIPv6Socket();
        expect(canCreate, isA<bool>());
      });
    });
  });
}
