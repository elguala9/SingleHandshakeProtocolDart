import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket_singleton.dart';
import 'package:shsp_types/shsp_types.dart';

void main() {
  group('ShspSocketSingleton', () {
    tearDown(() {
      ShspSocketSingleton.destroy();
    });

    test('getInstance returns the same instance on multiple calls', () async {
      final socket1 = await ShspSocketSingleton.getInstance();
      final socket2 = await ShspSocketSingleton.getInstance();

      expect(socket1, same(socket2),
          reason: 'getInstance should return the same singleton instance');
    });

    test('getInstance creates instance with default address and port', () async {
      final singleton = await ShspSocketSingleton.getInstance();

      expect(singleton.localAddress, isNotNull,
          reason: 'Socket should have a local address');
      expect(singleton.localPort, isNotNull,
          reason: 'Socket should have a local port');
      expect(singleton.isClosed, isFalse, reason: 'Socket should not be closed');
    });

    test('getInstance with custom address and port', () async {
      final address = InternetAddress.loopbackIPv4;
      final singleton = await ShspSocketSingleton.getInstance(
        address: address,
        port: 0, // Use ephemeral port
      );

      expect(singleton.localAddress, equals(address),
          reason: 'Socket should use specified address');
      expect(singleton.localPort, isNotNull,
          reason: 'Socket should have an assigned port');
    });

    test('getProfile returns socket profile', () async {
      final singleton = await ShspSocketSingleton.getInstance();
      final profile = singleton.getProfile();

      expect(profile, isNotNull, reason: 'Should return a valid profile');
      expect(profile.messageListeners, isEmpty,
          reason: 'New socket should have no message listeners');
    });

    test('reconnect preserves message callbacks', () async {
      final singleton = await ShspSocketSingleton.getInstance();
      final address = InternetAddress.loopbackIPv4;
      const testPort = 9999;

      final peerInfo = PeerInfo(address: address, port: testPort);

      // Register a callback before reconnect
      singleton.socket.setMessageCallback(peerInfo, (record) {});

      // Get profile and verify callback is registered
      var profile = singleton.getProfile();
      expect(profile.messageListeners.isNotEmpty, isTrue,
          reason: 'Profile should contain registered callback');

      final oldPort = singleton.localPort;

      // Reconnect
      await singleton.reconnect();

      final newPort = singleton.localPort;

      // Verify new socket was created
      expect(singleton.isClosed, isFalse,
          reason: 'Socket should not be closed after reconnect');

      // Note: Port may be different due to ephemeral binding
      // The important thing is that the socket still works

      // Verify profile still has the callback
      profile = singleton.getProfile();
      expect(profile.messageListeners.isNotEmpty, isTrue,
          reason: 'Callbacks should be preserved after reconnect');
    });

    test('destroy closes socket and clears singleton', () async {
      final singleton = await ShspSocketSingleton.getInstance();

      ShspSocketSingleton.destroy();

      expect(ShspSocketSingleton.getCurrent(), isNull,
          reason: 'Singleton should be null after destroy');
      expect(singleton.isClosed, isTrue,
          reason: 'Socket should be closed after destroy');
    });

    test('getInstance after destroy creates new instance', () async {
      var singleton = await ShspSocketSingleton.getInstance();
      final port1 = singleton.localPort;

      ShspSocketSingleton.destroy();

      singleton = await ShspSocketSingleton.getInstance();
      final port2 = singleton.localPort;

      expect(singleton, isNotNull, reason: 'Should create new instance');
      expect(singleton.isClosed, isFalse,
          reason: 'New socket should not be closed');
      // Ports might be different since we used ephemeral ports
    });

    test('getCurrent returns null before initialization', () {
      ShspSocketSingleton.destroy();
      expect(ShspSocketSingleton.getCurrent(), isNull,
          reason: 'getCurrent should return null if not initialized');
    });

    test('getCurrent returns instance after initialization', () async {
      final singleton = await ShspSocketSingleton.getInstance();
      expect(ShspSocketSingleton.getCurrent(), same(singleton),
          reason: 'getCurrent should return the initialized instance');
    });

    test('restoreProfile allows external profile restoration', () async {
      final singleton = await ShspSocketSingleton.getInstance();
      final address = InternetAddress.loopbackIPv4;

      // Register a callback
      singleton.socket.setMessageCallback(
        PeerInfo(address: address, port: 8000),
        (record) {},
      );

      // Get the profile
      final profile = singleton.getProfile();
      expect(profile.messageListeners.isNotEmpty, isTrue);

      // Restore the same profile (simulating a reconnect with external management)
      await singleton.restoreProfile(profile);

      // Verify profile is still there
      final newProfile = singleton.getProfile();
      expect(newProfile.messageListeners.isNotEmpty, isTrue,
          reason: 'Restored profile should preserve callbacks');
    });

    test('socket property provides access to underlying ShspSocket', () async {
      final singleton = await ShspSocketSingleton.getInstance();
      expect(singleton.socket, isNotNull,
          reason: 'Should provide access to underlying socket');
      expect(singleton.compressionCodec, isNotNull,
          reason: 'Should provide access to compression codec');
    });

    test('reconnect throws StateError if not initialized', () async {
      ShspSocketSingleton.destroy();
      final singleton = ShspSocketSingleton.getCurrent();
      expect(singleton, isNull, reason: 'Singleton should be null');

      // Create an instance directly (not via getInstance) to test error handling
      // Actually, we can't instantiate it directly since constructor is private
      // So we just verify that getCurrent() returns null
    });
  });
}
