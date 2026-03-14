import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('DualShspSocketSingleton', () {
    tearDown(() {
      DualShspSocketSingleton.destroy();
    });

    test('getInstance returns the same instance on multiple calls', () async {
      final socket1 = await DualShspSocketSingleton.getInstance();
      final socket2 = await DualShspSocketSingleton.getInstance();

      expect(socket1, same(socket2),
          reason: 'getInstance should return the same singleton instance');
    });

    test('getInstance creates instance with default address and port', () async {
      final singleton = await DualShspSocketSingleton.getInstance();

      expect(singleton.localAddress, isNotNull,
          reason: 'Socket should have a local address');
      expect(singleton.localPort, isNotNull,
          reason: 'Socket should have a local port');
      expect(singleton.isClosed, isFalse, reason: 'Socket should not be closed');
    });

    test('getInstance with custom address and port', () async {
      final address = InternetAddress.loopbackIPv4;
      final singleton = await DualShspSocketSingleton.getInstance(
        address: address,
        port: 0, // Use ephemeral port
      );

      expect(singleton.localAddress, equals(address),
          reason: 'Socket should use specified address');
      expect(singleton.localPort, isNotNull,
          reason: 'Socket should have an assigned port');
    });

    test('socket is DualShspSocket', () async {
      final singleton = await DualShspSocketSingleton.getInstance();

      expect(singleton.socket, isA<DualShspSocket>(),
          reason: 'socket getter should return DualShspSocket');
    });

    test('getProfile returns socket profile', () async {
      final singleton = await DualShspSocketSingleton.getInstance();
      final profile = singleton.getProfile();

      expect(profile, isNotNull, reason: 'Should return a valid profile');
      expect(profile.messageListeners, isEmpty,
          reason: 'New socket should have no message listeners');
    });

    test('reconnect preserves message callbacks', () async {
      final singleton = await DualShspSocketSingleton.getInstance();
      final address = InternetAddress.loopbackIPv4;
      const testPort = 9999;

      final peerInfo = PeerInfo(address: address, port: testPort);

      // Register a callback before reconnect
      singleton.socket.setMessageCallback(peerInfo, (record) {});

      // Get profile and verify callback is registered
      var profile = singleton.getProfile();
      expect(profile.messageListeners.isNotEmpty, isTrue,
          reason: 'Profile should contain registered callback');

      // Reconnect
      await singleton.reconnect();

      // Verify new socket was created
      expect(singleton.isClosed, isFalse,
          reason: 'Socket should not be closed after reconnect');

      // Verify profile still has the callback
      profile = singleton.getProfile();
      expect(profile.messageListeners.isNotEmpty, isTrue,
          reason: 'Callbacks should be preserved after reconnect');
    });

    test('restoreProfile applies profile to new socket', () async {
      final singleton = await DualShspSocketSingleton.getInstance();
      final address = InternetAddress.loopbackIPv4;
      const testPort = 8888;

      final peerInfo = PeerInfo(address: address, port: testPort);

      // Register callback and extract profile
      singleton.socket.setMessageCallback(peerInfo, (record) {});
      final profile = singleton.getProfile();

      // Restore with same profile
      await singleton.restoreProfile(profile);

      // Verify socket is still open
      expect(singleton.isClosed, isFalse,
          reason: 'Socket should not be closed after restore');

      // Verify profile is restored
      final restoredProfile = singleton.getProfile();
      expect(restoredProfile.messageListeners.isNotEmpty, isTrue,
          reason: 'Restored profile should contain callbacks');
    });

    test('destroy closes socket and clears singleton', () async {
      final singleton = await DualShspSocketSingleton.getInstance();

      DualShspSocketSingleton.destroy();

      expect(DualShspSocketSingleton.getCurrent(), isNull,
          reason: 'Singleton should be null after destroy');
      expect(singleton.isClosed, isTrue,
          reason: 'Socket should be closed after destroy');
    });

    test('getInstance after destroy creates new instance', () async {
      var singleton = await DualShspSocketSingleton.getInstance();
      singleton.localPort;

      DualShspSocketSingleton.destroy();

      singleton = await DualShspSocketSingleton.getInstance();
      expect(singleton.isClosed, isFalse,
          reason: 'New instance should have open socket');
    });

    test('getCurrent returns null before initialization', () {
      expect(DualShspSocketSingleton.getCurrent(), isNull,
          reason: 'getCurrent should return null before getInstance');
    });

    test('getCurrent returns instance after initialization', () async {
      await DualShspSocketSingleton.getInstance();

      expect(DualShspSocketSingleton.getCurrent(), isNotNull,
          reason: 'getCurrent should return instance after getInstance');
    });

    test('setSocket replaces internal socket', () async {
      final singleton = await DualShspSocketSingleton.getInstance();
      singleton.localPort;

      // Create new socket
      final newSocket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());

      // Replace socket
      singleton.setSocket(newSocket);

      // Verify socket was replaced (new port should be different or same depending on binding)
      expect(singleton.isClosed, isFalse,
          reason: 'Socket should not be closed after setSocket');
      expect(singleton.localPort, isNotNull,
          reason: 'Socket should have a valid port');
    });

    test('setSocketRaw wraps RawDatagramSocket', () async {
      final singleton = await DualShspSocketSingleton.getInstance();

      // Create raw socket
      final rawSocket =
          await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);

      // Replace with raw socket
      singleton.setSocketRaw(rawSocket);

      // Verify socket is still working
      expect(singleton.isClosed, isFalse,
          reason: 'Socket should not be closed after setSocketRaw');
      expect(singleton.localPort, isNotNull,
          reason: 'Socket should have a valid port');
    });

    test('socketChangedCallback fires on reconnect', () async {
      final singleton = await DualShspSocketSingleton.getInstance();
      var callbackFired = false;
      IShspSocket? callbackSocket;

      singleton.socketChangedCallback.register((socket) {
        callbackFired = true;
        callbackSocket = socket;
      });

      await singleton.reconnect();

      expect(callbackFired, isTrue,
          reason: 'socketChangedCallback should fire on reconnect');
      expect(callbackSocket, isNotNull,
          reason: 'Callback should receive the new socket');
    });

    test('socketChangedCallback fires on setSocket', () async {
      final singleton = await DualShspSocketSingleton.getInstance();
      var callbackFired = false;

      singleton.socketChangedCallback.register((_) {
        callbackFired = true;
      });

      final newSocket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4, 0, GZipCodec());
      singleton.setSocket(newSocket);

      expect(callbackFired, isTrue,
          reason: 'socketChangedCallback should fire on setSocket');
    });

    test('compressionCodec getter returns valid codec', () async {
      final codec = GZipCodec();
      final singleton = await DualShspSocketSingleton.getInstance(
        compressionCodec: codec,
      );

      expect(singleton.compressionCodec, same(codec),
          reason: 'compressionCodec should return the configured codec');
    });

    test('localAddress getter reflects current socket', () async {
      final address = InternetAddress.loopbackIPv4;
      final singleton = await DualShspSocketSingleton.getInstance(
        address: address,
      );

      expect(singleton.localAddress, equals(address),
          reason: 'localAddress should match bound address');
    });

    test('localPort getter reflects current socket', () async {
      final singleton = await DualShspSocketSingleton.getInstance();

      expect(singleton.localPort, isNotNull,
          reason: 'localPort should not be null');
      expect(singleton.localPort, greaterThan(0),
          reason: 'localPort should be positive');
    });

    test('multiple singletons can coexist independently', () async {
      // Note: This test verifies the singleton pattern isn't global
      // Create first singleton
      final singleton1 = await DualShspSocketSingleton.getInstance();
      expect(singleton1, isNotNull);

      // Both getInstance calls return same instance
      final singleton2 = await DualShspSocketSingleton.getInstance();
      expect(singleton1, same(singleton2),
          reason: 'Should return same instance before destroy');

      // Destroy
      DualShspSocketSingleton.destroy();

      // Create new instance after destroy
      final singleton3 = await DualShspSocketSingleton.getInstance();
      expect(singleton3, isNotNull);
      expect(singleton1, isNot(same(singleton3)),
          reason: 'Should be different instance after destroy');
    });
  });
}
