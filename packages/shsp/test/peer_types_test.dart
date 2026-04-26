import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('PeerInfo', () {
    group('construction', () {
      test('stores address and port', () {
        final addr = InternetAddress('192.168.1.100');
        final peer = PeerInfo(address: addr, port: 8080);
        expect(peer.address, equals(addr));
        expect(peer.port, equals(8080));
      });

      test('address is an InternetAddress instance', () {
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
        expect(peer.address, isA<InternetAddress>());
      });
    });

    group('fromJson / toJson', () {
      test('round-trips IPv4 address and port', () {
        final original = PeerInfo(address: InternetAddress('192.168.1.100'), port: 8080);
        final json = original.toJson();
        final restored = PeerInfo.fromJson(json);
        expect(restored.address.address, equals('192.168.1.100'));
        expect(restored.port, equals(8080));
      });

      test('round-trips IPv6 address and port', () {
        final original = PeerInfo(address: InternetAddress('::1'), port: 9000);
        final json = original.toJson();
        final restored = PeerInfo.fromJson(json);
        expect(restored.address.address, equals('::1'));
        expect(restored.port, equals(9000));
      });

      test('toJson produces string address key', () {
        final peer = PeerInfo(address: InternetAddress('192.168.1.100'), port: 8080);
        final json = peer.toJson();
        expect(json['address'], isA<String>());
      });

      test('toJson produces integer port key', () {
        final peer = PeerInfo(address: InternetAddress('192.168.1.100'), port: 8080);
        final json = peer.toJson();
        expect(json['port'], isA<int>());
      });
    });

    group('equality', () {
      test('two PeerInfos with same address+port are equal', () {
        final addr = InternetAddress('192.168.1.100');
        final peer1 = PeerInfo(address: addr, port: 8080);
        final peer2 = PeerInfo(address: InternetAddress('192.168.1.100'), port: 8080);
        expect(peer1, equals(peer2));
      });

      test('different port yields not-equal', () {
        final addr = InternetAddress('192.168.1.100');
        final peer1 = PeerInfo(address: addr, port: 8080);
        final peer2 = PeerInfo(address: InternetAddress('192.168.1.100'), port: 8081);
        expect(peer1, isNot(equals(peer2)));
      });

      test('different address yields not-equal', () {
        final peer1 = PeerInfo(address: InternetAddress('192.168.1.100'), port: 8080);
        final peer2 = PeerInfo(address: InternetAddress('192.168.1.101'), port: 8080);
        expect(peer1, isNot(equals(peer2)));
      });

      test('identical() shortcut returns true for same instance', () {
        final peer = PeerInfo(address: InternetAddress('192.168.1.100'), port: 8080);
        expect(identical(peer, peer), isTrue);
      });
    });

    group('hashCode', () {
      test('equal PeerInfos have equal hashCodes', () {
        final peer1 = PeerInfo(address: InternetAddress('192.168.1.100'), port: 8080);
        final peer2 = PeerInfo(address: InternetAddress('192.168.1.100'), port: 8080);
        expect(peer1.hashCode, equals(peer2.hashCode));
      });

      test('different PeerInfos have different hashCodes (high probability)', () {
        final peer1 = PeerInfo(address: InternetAddress('192.168.1.100'), port: 8080);
        final peer2 = PeerInfo(address: InternetAddress('192.168.1.101'), port: 8081);
        expect(peer1.hashCode, isNot(equals(peer2.hashCode)));
      });
    });
  });

  group('RemoteInfo', () {
    group('construction', () {
      test('stores address and port', () {
        final addr = InternetAddress('192.168.1.100');
        final remote = RemoteInfo(address: addr, port: 8080);
        expect(remote.address, equals(addr));
        expect(remote.port, equals(8080));
      });
    });

    group('fromJson / toJson', () {
      test('round-trips IPv4 address and port', () {
        final original = RemoteInfo(address: InternetAddress('192.168.1.100'), port: 8080);
        final json = original.toJson();
        final restored = RemoteInfo.fromJson(json);
        expect(restored.address.address, equals('192.168.1.100'));
        expect(restored.port, equals(8080));
      });

      test('toJson address key is a string', () {
        final remote = RemoteInfo(address: InternetAddress('192.168.1.100'), port: 8080);
        final json = remote.toJson();
        expect(json['address'], isA<String>());
      });
    });
  });
}
