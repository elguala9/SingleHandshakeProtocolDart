import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp_interfaces/src/connection/i_shsp_handshake.dart';
import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_implementations/connection/handshake_ip.dart';

void main() {
  group('HandshakeIP', () {
    test('constructor should set all IP values correctly', () {
      final publicIPv4 = PeerInfo(address: InternetAddress('203.0.113.1'), port: 8080);
      final publicIPv6 = PeerInfo(address: InternetAddress('2001:db8::1'), port: 8080);
      final localIPv4 = PeerInfo(address: InternetAddress('192.168.1.100'), port: 9090);
      final localIPv6 = PeerInfo(address: InternetAddress('fe80::1'), port: 9090);

      final handshake = HandshakeIP((
        publicIPv4: publicIPv4,
        publicIPv6: publicIPv6,
        localIPv4: localIPv4,
        localIPv6: localIPv6,
      ));

      expect(handshake.getPublicIPv4(), equals(publicIPv4));
      expect(handshake.getPublicIPv6(), equals(publicIPv6));
      expect(handshake.getLocalIPv4(), equals(localIPv4));
      expect(handshake.getLocalIPv6(), equals(localIPv6));
    });

    test('constructor with null values should work', () {
      final handshake = HandshakeIP((
        publicIPv4: null,
        publicIPv6: null,
        localIPv4: null,
        localIPv6: null,
      ));

      expect(handshake.getPublicIPv4(), isNull);
      expect(handshake.getPublicIPv6(), isNull);
      expect(handshake.getLocalIPv4(), isNull);
      expect(handshake.getLocalIPv6(), isNull);
    });

    test('constructor with mixed null and non-null values should work', () {
      final publicIPv4 = PeerInfo(address: InternetAddress('203.0.113.1'), port: 8080);
      final localIPv4 = PeerInfo(address: InternetAddress('192.168.1.100'), port: 9090);

      final handshake = HandshakeIP((
        publicIPv4: publicIPv4,
        publicIPv6: null,
        localIPv4: localIPv4,
        localIPv6: null,
      ));

      expect(handshake.getPublicIPv4(), equals(publicIPv4));
      expect(handshake.getPublicIPv6(), isNull);
      expect(handshake.getLocalIPv4(), equals(localIPv4));
      expect(handshake.getLocalIPv6(), isNull);
    });

    test('should implement IHandshakeIP interface', () {
      final handshake = HandshakeIP((
        publicIPv4: null,
        publicIPv6: null,
        localIPv4: null,
        localIPv6: null,
      ));
      
      expect(handshake, isA<IHandshakeIP>());
    });

    test('PeerInfo objects should maintain their properties', () {
      final testAddress = InternetAddress('10.0.0.1');
      const testPort = 12345;
      final peerInfo = PeerInfo(address: testAddress, port: testPort);

      final handshake = HandshakeIP((
        publicIPv4: peerInfo,
        publicIPv6: null,
        localIPv4: null,
        localIPv6: null,
      ));

      final retrievedPeerInfo = handshake.getPublicIPv4();
      expect(retrievedPeerInfo, isNotNull);
      expect(retrievedPeerInfo!.address, equals(testAddress));
      expect(retrievedPeerInfo.port, equals(testPort));
    });

    test('IPv4 addresses should be properly handled', () {
      final ipv4Address = InternetAddress('192.168.0.1');
      final peerInfo = PeerInfo(address: ipv4Address, port: 80);

      final handshake = HandshakeIP((
        publicIPv4: peerInfo,
        publicIPv6: null,
        localIPv4: peerInfo,
        localIPv6: null,
      ));

      expect(handshake.getPublicIPv4()?.address.type, equals(InternetAddressType.IPv4));
      expect(handshake.getLocalIPv4()?.address.type, equals(InternetAddressType.IPv4));
    });

    test('IPv6 addresses should be properly handled', () {
      final ipv6Address = InternetAddress('2001:db8::8a2e:370:7334');
      final peerInfo = PeerInfo(address: ipv6Address, port: 443);

      final handshake = HandshakeIP((
        publicIPv4: null,
        publicIPv6: peerInfo,
        localIPv4: null,
        localIPv6: peerInfo,
      ));

      expect(handshake.getPublicIPv6()?.address.type, equals(InternetAddressType.IPv6));
      expect(handshake.getLocalIPv6()?.address.type, equals(InternetAddressType.IPv6));
    });

    // Note: createAsync test è commentato perché richiede dipendenze STUN che potrebbero non essere disponibili in test
    /*
    test('createAsync should create HandshakeIP with STUN data', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      
      try {
        final handshake = await HandshakeIP.createAsync(socket);
        expect(handshake, isA<HandshakeIP>());
        // Note: In un ambiente di test, questi potrebbero essere null se STUN fallisce
        expect(handshake.getLocalIPv4(), isNotNull);
      } catch (e) {
        // STUN potrebbe fallire in ambiente di test, è normale
        expect(e, isA<Exception>());
      } finally {
        socket.close();
      }
    });
    */
  });
}