import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('IShspSocket Interface - New Methods', () {
    test('ShspSocket implements isClosed getter', () async {
      final socket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());

      expect(socket.isClosed, isFalse,
          reason: 'New socket should not be closed');

      socket.close();
      expect(socket.isClosed, isTrue,
          reason: 'Closed socket should report isClosed=true');
    });

    test('DualShspSocket implements isClosed getter', () async {
      final ipv4 = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());
      final dual = DualShspSocket(ipv4, null);

      expect(dual.isClosed, isFalse,
          reason: 'New dual socket should not be closed');

      dual.close();
      expect(dual.isClosed, isTrue,
          reason: 'Closed dual socket should report isClosed=true');
    });

    test('ShspSocket implements extractProfile method', () async {
      final socket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());

      final profile = socket.extractProfile();

      expect(profile, isA<ShspSocketProfile>(),
          reason: 'Should return ShspSocketProfile');
      expect(profile.messageListeners, isEmpty,
          reason: 'New socket should have no listeners');

      socket.close();
    });

    test('DualShspSocket implements extractProfile method', () async {
      final ipv4 = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());
      final dual = DualShspSocket(ipv4, null);

      final profile = dual.extractProfile();

      expect(profile, isA<ShspSocketProfile>(),
          reason: 'Should return ShspSocketProfile');
      expect(profile.messageListeners, isEmpty,
          reason: 'New socket should have no listeners');

      dual.close();
    });

    test('ShspSocket implements applyProfile method', () async {
      final socket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());

      // Create a profile with a callback
      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 1234);
      socket.setMessageCallback(peer, (record) {});
      final profile = socket.extractProfile();

      // Apply to another socket
      final socket2 = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());
      socket2.applyProfile(profile);

      // Verify callback was applied
      final appliedProfile = socket2.extractProfile();
      expect(appliedProfile.messageListeners.isNotEmpty, isTrue,
          reason: 'Applied profile should contain callbacks');

      socket.close();
      socket2.close();
    });

    test('DualShspSocket implements applyProfile method', () async {
      final ipv4 = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());
      final dual = DualShspSocket(ipv4, null);

      // Create a profile with a callback
      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 1234);
      dual.setMessageCallback(peer, (record) {});
      final profile = dual.extractProfile();

      // Apply to another dual socket
      final ipv4b = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());
      final dual2 = DualShspSocket(ipv4b, null);
      dual2.applyProfile(profile);

      // Verify callback was applied
      final appliedProfile = dual2.extractProfile();
      expect(appliedProfile.messageListeners.isNotEmpty, isTrue,
          reason: 'Applied profile should contain callbacks');

      dual.close();
      dual2.close();
    });

    test('extractProfile with multiple callbacks', () async {
      final socket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());

      // Register multiple callbacks
      final peer1 = PeerInfo(address: InternetAddress.loopbackIPv4, port: 1111);
      final peer2 = PeerInfo(address: InternetAddress.loopbackIPv4, port: 2222);
      final peer3 = PeerInfo(address: InternetAddress.loopbackIPv4, port: 3333);

      socket.setMessageCallback(peer1, (record) {});
      socket.setMessageCallback(peer2, (record) {});
      socket.setMessageCallback(peer3, (record) {});

      // Extract profile
      final profile = socket.extractProfile();

      expect(profile.messageListeners.length, equals(3),
          reason: 'Profile should contain 3 message listeners');

      socket.close();
    });

    test('applyProfile merges callbacks', () async {
      final socket1 = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());
      final socket2 = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());

      // Add callback to socket1
      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 1234);
      socket1.setMessageCallback(peer, (record) {});

      // Extract and apply to socket2
      final profile = socket1.extractProfile();
      socket2.applyProfile(profile);

      // Verify socket2 now has the callback
      final socket2Profile = socket2.extractProfile();
      expect(socket2Profile.messageListeners.isNotEmpty, isTrue,
          reason: 'Callback should be applied to socket2');

      socket1.close();
      socket2.close();
    });

    test('isClosed is false for both sockets in DualShspSocket', () async {
      final ipv4 = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());
      final ipv6 = await ShspSocket.bind(
          InternetAddress.anyIPv6, 0, GZipCodec());
      final dual = DualShspSocket(ipv4, ipv6);

      expect(dual.isClosed, isFalse,
          reason: 'Dual socket should not be closed if both sockets are open');

      ipv4.close();
      expect(dual.isClosed, isTrue,
          reason: 'Dual socket should be closed if any socket is closed');

      dual.close(); // Clean up remaining socket
    });

    test('extractProfile from DualShspSocket merges both sockets', () async {
      final ipv4 = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());
      final ipv6 = await ShspSocket.bind(
          InternetAddress.anyIPv6, 0, GZipCodec());
      final dual = DualShspSocket(ipv4, ipv6);

      // Add callbacks to both sockets
      final peer4 = PeerInfo(address: InternetAddress.loopbackIPv4, port: 4444);
      final peer6 =
          PeerInfo(address: InternetAddress.loopbackIPv6, port: 6666);

      ipv4.setMessageCallback(peer4, (record) {});
      ipv6.setMessageCallback(peer6, (record) {});

      // Extract from dual
      final profile = dual.extractProfile();

      expect(profile.messageListeners.length, equals(2),
          reason: 'Merged profile should contain callbacks from both sockets');

      dual.close();
    });

    test('applyProfile to DualShspSocket applies to both internal sockets',
        () async {
      final ipv4a = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());
      final dual1 = DualShspSocket(ipv4a, null);

      // Create profile with callback
      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 5555);
      dual1.setMessageCallback(peer, (record) {});
      final profile = dual1.extractProfile();

      // Apply to another dual socket
      final ipv4b = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());
      final dual2 = DualShspSocket(ipv4b, null);
      dual2.applyProfile(profile);

      // Verify
      final appliedProfile = dual2.extractProfile();
      expect(appliedProfile.messageListeners.isNotEmpty, isTrue,
          reason: 'Profile should be applied to dual socket');

      dual1.close();
      dual2.close();
    });

    test('isClosed property is part of IShspSocket contract', () async {
      // This test verifies that the property is accessible through the interface
      final socket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());

      // Access through interface type
      IShspSocket iface = socket;

      expect(iface.isClosed, isFalse,
          reason: 'isClosed should be accessible through IShspSocket interface');

      socket.close();
      expect(iface.isClosed, isTrue);
    });

    test('extractProfile method is part of IShspSocket contract', () async {
      final socket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());

      // Access through interface type
      IShspSocket iface = socket;

      final profile = iface.extractProfile();
      expect(profile, isA<ShspSocketProfile>(),
          reason: 'extractProfile should be accessible through IShspSocket interface');

      socket.close();
    });

    test('applyProfile method is part of IShspSocket contract', () async {
      final socket1 = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());
      final socket2 = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());

      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 7777);
      socket1.setMessageCallback(peer, (record) {});
      final profile = socket1.extractProfile();

      // Access through interface type
      IShspSocket iface = socket2;
      iface.applyProfile(profile);

      // Verify
      expect(socket2.extractProfile().messageListeners.isNotEmpty, isTrue,
          reason: 'applyProfile should be accessible through IShspSocket interface');

      socket1.close();
      socket2.close();
    });
  });
}
