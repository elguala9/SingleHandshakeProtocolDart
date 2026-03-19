import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

void main() {
  group('initializePointDualShsp Tests', () {
    tearDown(() {
      // Clean up singletons after each test
      DualShspSocketSingleton.destroy();
    });

    test('successfully creates and registers dual socket in DI', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      expect(
        dualSocket,
        isNotNull,
        reason: 'DualShspSocket should be registered in DI',
      );
      expect(
        dualSocket,
        isA<DualShspSocket>(),
        reason: 'Should be DualShspSocket',
      );
    });

    test('registered socket is open and usable', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      expect(dualSocket.isClosed, isFalse, reason: 'Socket should be open');
      expect(
        dualSocket.localPort,
        greaterThan(0),
        reason: 'Should have valid port',
      );
    });

    test('dual socket contains both IPv4 and IPv6 support', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      expect(
        dualSocket,
        isA<DualShspSocket>(),
        reason: 'Should support dual stack',
      );
    });

    test('socket has valid local address', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      expect(
        dualSocket.localAddress,
        isNotNull,
        reason: 'Should have local address',
      );
    });

    test('socket has compression codec', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      expect(
        dualSocket.compressionCodec,
        isNotNull,
        reason: 'Should have compression codec',
      );
    });

    test('registry singleton is registered in DI', () async {
      await initializePointDualShsp();

      final registry = SingletonDIAccess.get<RegistrySingletonShspSocket>();
      expect(
        registry,
        isNotNull,
        reason: 'RegistrySingletonShspSocket should be registered',
      );
      expect(
        registry,
        isA<RegistrySingletonShspSocket>(),
        reason: 'Should be RegistrySingletonShspSocket instance',
      );
    });

    test('socket can set and retrieve message callbacks', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      final peerInfo = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 8888,
      );

      expect(
        () => dualSocket.setMessageCallback(peerInfo, (_) {}),
        returnsNormally,
        reason: 'Should accept message callbacks',
      );
    });

    test('socket can send data to peer', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      final peerInfo = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 9999,
      );
      final testData = [1, 2, 3, 4, 5];

      expect(
        () => dualSocket.sendTo(testData, peerInfo),
        returnsNormally,
        reason: 'Should be able to send data',
      );
    });

    test('socket profile can be extracted', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      final profile = dualSocket.extractProfile();

      expect(profile, isNotNull, reason: 'Profile should be extractable');
      expect(
        profile,
        isA<ShspSocketProfile>(),
        reason: 'Should be ShspSocketProfile',
      );
    });

    test('socket can apply profile', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      final profile = dualSocket.extractProfile();

      expect(
        () => dualSocket.applyProfile(profile),
        returnsNormally,
        reason: 'Should accept profile application',
      );
    });

    test('socket callbacks are properly set up for listening', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();

      expect(
        () => dualSocket.onListening.register((_) {}),
        returnsNormally,
        reason: 'Should accept listening callback',
      );
    });

    test('socket callbacks are properly set up for errors', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();

      expect(
        () => dualSocket.onError.register((_) {}),
        returnsNormally,
        reason: 'Should accept error callback',
      );
    });

    test('socket callbacks are properly set up for close', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();

      expect(
        () => dualSocket.onClose.register((_) {}),
        returnsNormally,
        reason: 'Should accept close callback',
      );
    });

    test('can close initialized socket', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      expect(dualSocket.isClosed, isFalse);

      dualSocket.close();
      expect(dualSocket.isClosed, isTrue, reason: 'Socket should be closed');
    });

    test(
      'can retrieve socket multiple times from DI (same instance)',
      () async {
        await initializePointDualShsp();

        final socket1 = SingletonDIAccess.get<IDualShspSocket>();
        final socket2 = SingletonDIAccess.get<IDualShspSocket>();

        expect(
          identical(socket1, socket2),
          isTrue,
          reason: 'DI should return same instance',
        );
      },
    );

    test('registry singleton is properly initialized', () async {
      await initializePointDualShsp();

      final registry = SingletonDIAccess.get<RegistrySingletonShspSocket>();
      expect(
        registry,
        isA<RegistrySingletonShspSocket>(),
        reason: 'Registry should be a RegistrySingletonShspSocket instance',
      );
    });

    test('initialization handles IPv6 availability gracefully', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();

      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      expect(dualSocket, isNotNull);

      // Should work regardless of IPv6 availability
      if (hasIPv6) {
        expect(
          dualSocket,
          isA<DualShspSocket>(),
          reason: 'Should have dual socket when IPv6 is available',
        );
      }
    });

    test('socket implements all required interfaces', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();

      expect(
        dualSocket,
        isA<IDualShspSocket>(),
        reason: 'Should implement IDualShspSocket',
      );
    });

    test('socket has IPv4 socket accessible', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      expect(dualSocket, isA<DualShspSocket>());

      final typedSocket = dualSocket as DualShspSocket;
      expect(
        typedSocket.ipv4Socket,
        isNotNull,
        reason: 'IPv4 socket should exist',
      );
      expect(
        typedSocket.ipv4Socket.isClosed,
        isFalse,
        reason: 'IPv4 socket should be open',
      );
    });

    test('socket has IPv6 socket if available', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      final typedSocket = dualSocket as DualShspSocket;

      if (hasIPv6) {
        expect(
          typedSocket.ipv6Socket,
          isNotNull,
          reason: 'IPv6 socket should exist if available',
        );
        if (typedSocket.ipv6Socket != null) {
          expect(
            typedSocket.ipv6Socket!.isClosed,
            isFalse,
            reason: 'IPv6 socket should be open',
          );
        }
      }
    });

    test(
      'multiple peers can register callbacks on initialized socket',
      () async {
        await initializePointDualShsp();

        final dualSocket = SingletonDIAccess.get<IDualShspSocket>();

        final peer1 = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 7001,
        );
        final peer2 = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 7002,
        );
        final peer3 = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 7003,
        );

        expect(
          () {
            dualSocket.setMessageCallback(peer1, (_) {});
            dualSocket.setMessageCallback(peer2, (_) {});
            dualSocket.setMessageCallback(peer3, (_) {});
          },
          returnsNormally,
          reason: 'Should support multiple peer callbacks',
        );
      },
    );

    test('socket state remains consistent after operations', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();

      // Perform multiple operations
      for (int i = 0; i < 10; i++) {
        final peer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 6000 + i,
        );
        dualSocket.setMessageCallback(peer, (_) {});
      }

      expect(
        dualSocket.isClosed,
        isFalse,
        reason: 'Socket should still be open',
      );
      expect(
        dualSocket.localPort,
        greaterThan(0),
        reason: 'Port should be valid',
      );
    });

    test('socket local address is IPV4', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      final address = dualSocket.localAddress;

      expect(address, isNotNull);
      expect(
        address?.type,
        equals(InternetAddressType.IPv4),
        reason: 'Should bind to IPv4 by default',
      );
    });

    test('socket raw datagram socket is accessible', () async {
      await initializePointDualShsp();

      final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
      final rawSocket = dualSocket.socket;

      expect(
        rawSocket,
        isA<RawDatagramSocket>(),
        reason: 'Should provide raw datagram socket',
      );
    });

    test('initialization is repeatable - new sockets each time', () async {
      // First initialization
      await initializePointDualShsp();
      final socket1 = SingletonDIAccess.get<IDualShspSocket>();

      // Clean up
      socket1.close();
      DualShspSocketSingleton.destroy();

      // Second initialization
      await initializePointDualShsp();
      final socket2 = SingletonDIAccess.get<IDualShspSocket>();
      final port2 = socket2.localPort;

      expect(socket2.isClosed, isFalse, reason: 'New socket should be open');
      expect(
        port2,
        greaterThan(0),
        reason: 'New socket should have valid port',
      );
      // Ports might be different due to ephemeral allocation
    });
  });
}
