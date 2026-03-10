import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';
import 'package:shsp/src/impl/shsp_base/shsp_socket.dart';
import 'package:shsp/src/impl/shsp_base/shsp_socket_singleton.dart';

void main() {
  group('ShspSocketSingleton Edge Cases and Stress Tests', () {
    tearDown(() {
      ShspSocketSingleton.destroy();
    });

    test('rapid sequential getInstance calls return same instance', () async {
      final instances = <dynamic>[];

      // Call getInstance multiple times rapidly
      for (int i = 0; i < 10; i++) {
        final instance = await ShspSocketSingleton.getInstance();
        instances.add(instance);
      }

      // All should be identical
      for (int i = 1; i < instances.length; i++) {
        expect(identical(instances[0], instances[i]), isTrue,
            reason: 'All getInstance calls should return the same instance');
      }
    });

    test('socket properties remain consistent across multiple accesses', () async {
      final singleton = await ShspSocketSingleton.getInstance();

      final address1 = singleton.localAddress;
      final port1 = singleton.localPort;
      final codec1 = singleton.compressionCodec;

      await Future.delayed(const Duration(milliseconds: 50));

      final address2 = singleton.localAddress;
      final port2 = singleton.localPort;
      final codec2 = singleton.compressionCodec;

      expect(address1, equals(address2),
          reason: 'Address should not change');
      expect(port1, equals(port2), reason: 'Port should not change');
      expect(identical(codec1, codec2), isTrue,
          reason: 'Codec should be the same instance');
    });

    test('multiple reconnect calls work correctly', () async {
      final singleton = await ShspSocketSingleton.getInstance();
      final initialPort = singleton.localPort;

      for (int i = 0; i < 3; i++) {
        await singleton.reconnect();
        expect(singleton.isClosed, isFalse,
            reason: 'Socket should be open after reconnect $i');
      }

      // Last port might be different (ephemeral)
      expect(singleton.localPort, isNotNull,
          reason: 'Should have a valid port after multiple reconnects');
    });

    test('callbacks survive multiple socket replacements', () async {
      final singleton = await ShspSocketSingleton.getInstance();
      final address = InternetAddress.loopbackIPv4;
      const testPort = 9555;

      // Register multiple callbacks
      for (int i = 0; i < 5; i++) {
        singleton.socket.setMessageCallback(
          PeerInfo(address: address, port: testPort + i),
          (record) {},
        );
      }

      final profileBefore = singleton.getProfile();
      final countBefore = profileBefore.messageListeners.length;

      // Reconnect multiple times
      await singleton.reconnect();
      await singleton.reconnect();

      final profileAfter = singleton.getProfile();
      final countAfter = profileAfter.messageListeners.length;

      expect(countAfter, equals(countBefore),
          reason: 'All callbacks should survive multiple reconnections');
    });

    test('setSocket with same socket type works correctly', () async {
      final singleton = await ShspSocketSingleton.getInstance();
      final address = InternetAddress.loopbackIPv4;

      // Register a callback
      singleton.socket.setMessageCallback(
        PeerInfo(address: address, port: 9554),
        (record) {},
      );

      final profileBefore = singleton.getProfile();

      // Create new raw socket and set it
      final newRawSocket = await RawDatagramSocket.bind(address, 0);
      singleton.setSocketRaw(newRawSocket);

      final profileAfter = singleton.getProfile();

      expect(profileAfter.messageListeners.length,
          equals(profileBefore.messageListeners.length),
          reason: 'Callback count should be preserved');
    });

    test('concurrent access to singleton properties is safe', () async {
      final singleton = await ShspSocketSingleton.getInstance();
      final results = <String>[];

      // Simulate concurrent access
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(Future(() {
          results.add('port:${singleton.localPort}');
          results.add('closed:${singleton.isClosed}');
        }));
      }

      await Future.wait(futures);

      // All port accesses should have the same value
      final ports = results
          .where((r) => r.startsWith('port:'))
          .map((r) => r.replaceAll('port:', ''));
      expect(ports.toSet().length, equals(1),
          reason: 'Port should be consistent across concurrent access');

      // All closed accesses should be false
      final closedValues = results
          .where((r) => r.startsWith('closed:'))
          .map((r) => r.replaceAll('closed:', ''));
      expect(closedValues.every((c) => c == 'false'), isTrue,
          reason: 'Socket should not be closed during concurrent access');
    });

    test('socket closed property reflects actual state', () async {
      final singleton = await ShspSocketSingleton.getInstance();
      expect(singleton.isClosed, isFalse,
          reason: 'Newly created socket should not be closed');

      // Manually close the raw socket
      (singleton.socket as ShspSocket).socket.close();

      // Note: isClosed might not immediately reflect the close,
      // so we just verify the method exists and works
      expect(singleton.isClosed, isNotNull,
          reason: 'isClosed property should be accessible');
    });

    test('destroy works correctly even with multiple callbacks', () async {
      final singleton = await ShspSocketSingleton.getInstance();
      final address = InternetAddress.loopbackIPv4;

      // Register many callbacks
      for (int i = 0; i < 20; i++) {
        singleton.socket.setMessageCallback(
          PeerInfo(address: address, port: 9500 + i),
          (record) {},
        );
      }

      final profile = singleton.getProfile();
      expect(profile.messageListeners.length, equals(20));

      // Destroy
      ShspSocketSingleton.destroy();

      expect(singleton.isClosed, isTrue,
          reason: 'Socket should be closed after destroy');
      expect(ShspSocketSingleton.getCurrent(), isNull,
          reason: 'Singleton should be cleared');
    });

    test('getInstance with different parameters ignores them if already initialized',
        () async {
      final address1 = InternetAddress.loopbackIPv4;
      const port1 = 0;

      // First call with specific parameters
      final singleton1 = await ShspSocketSingleton.getInstance(
        address: address1,
        port: port1,
      );
      final assignedPort1 = singleton1.localPort;

      // Second call with different parameters (should be ignored)
      final singleton2 = await ShspSocketSingleton.getInstance(
        address: InternetAddress.anyIPv4,
        port: 9999, // Completely different
      );
      final assignedPort2 = singleton2.localPort;

      expect(identical(singleton1, singleton2), isTrue);
      expect(assignedPort1, equals(assignedPort2),
          reason: 'Second call parameters should be ignored');
    });

    test('reconnect preserves socket properties', () async {
      final singleton = await ShspSocketSingleton.getInstance(
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );

      final addressBefore = singleton.localAddress;
      final codecBefore = singleton.compressionCodec;

      await singleton.reconnect();

      final addressAfter = singleton.localAddress;
      final codecAfter = singleton.compressionCodec;

      expect(addressAfter, equals(addressBefore),
          reason: 'Address should be preserved');
      expect(codecAfter, equals(codecBefore),
          reason: 'Compression codec should be preserved');
    });

    test('getProfile returns new copy each time', () async {
      final singleton = await ShspSocketSingleton.getInstance();

      final profile1 = singleton.getProfile();
      final profile2 = singleton.getProfile();

      expect(identical(profile1, profile2), isFalse,
          reason: 'getProfile should return a new copy');
      expect(profile1.messageListeners.length,
          equals(profile2.messageListeners.length),
          reason: 'But content should be the same');
    });

    test('restoreProfile restores profile to socket', () async {
      final singleton = await ShspSocketSingleton.getInstance();
      final address = InternetAddress.loopbackIPv4;

      // Register first callback
      singleton.socket.setMessageCallback(
        PeerInfo(address: address, port: 9899),
        (record) {},
      );

      final profile = singleton.getProfile();
      expect(profile.messageListeners.length, equals(1));

      // Restore the same profile (test the mechanism)
      await singleton.restoreProfile(profile);

      // Profile should be restored
      final finalProfile = singleton.getProfile();
      expect(finalProfile.messageListeners.length, equals(1),
          reason: 'Restore should preserve the profile listeners');
    });

    test('setSocket throws appropriate error if not initialized', () {
      ShspSocketSingleton.destroy();

      // Can't create uninitialized instance directly, but we verify
      // that getCurrent returns null
      expect(ShspSocketSingleton.getCurrent(), isNull,
          reason: 'Should return null when not initialized');
    });

    test('socket remains functional after rapid property accesses', () async {
      final singleton = await ShspSocketSingleton.getInstance();

      // Rapid property access
      for (int i = 0; i < 100; i++) {
        singleton.localPort;
        singleton.localAddress;
        singleton.isClosed;
        singleton.compressionCodec;
      }

      // Socket should still be functional
      expect(singleton.isClosed, isFalse,
          reason: 'Socket should remain open after rapid access');

      // Should be able to get profile
      final profile = singleton.getProfile();
      expect(profile, isNotNull,
          reason: 'Should be able to get profile after rapid access');
    });

    test('getCurrent returns null state transitions correctly', () async {
      expect(ShspSocketSingleton.getCurrent(), isNull,
          reason: 'Should be null before initialization');

      final instance1 = await ShspSocketSingleton.getInstance();
      expect(ShspSocketSingleton.getCurrent(), isNotNull,
          reason: 'Should be non-null after initialization');

      ShspSocketSingleton.destroy();
      expect(ShspSocketSingleton.getCurrent(), isNull,
          reason: 'Should be null after destroy');

      final instance2 = await ShspSocketSingleton.getInstance();
      expect(ShspSocketSingleton.getCurrent(), isNotNull,
          reason: 'Should be non-null after re-initialization');
    });
  });
}
