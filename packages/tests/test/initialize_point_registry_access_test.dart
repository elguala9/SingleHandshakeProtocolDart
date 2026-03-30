import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

void _cleanup(String key) {
  try {
    final socket =
        RegistryAccess.getInstance<IDualShspSocketMigratable>(key);
    if (!socket.isClosed) socket.close();
  } catch (_) {}
  try {
    RegistryAccess.unregister<IDualShspSocketMigratable>(key);
  } catch (_) {}
  try {
    RegistryAccess.unregister<IDualShspSocketWrapper>(key);
  } catch (_) {}
  try {
    RegistryAccess.unregister<IRegistryShspSocket>(key);
  } catch (_) {}
}

void main() {
  const testKey = 'test-key';
  const secondKey = 'test-key-2';

  group('initializePointRegistryAccess Tests', () {
    tearDown(() {
      _cleanup(testKey);
      _cleanup(secondKey);
    });

    test('registers IDualShspSocketMigratable under the key', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(socket, isNotNull,
          reason: 'IDualShspSocketMigratable should be registered');
      expect(socket, isA<IDualShspSocketMigratable>());
    });

    test('registers IDualShspSocketWrapper under the key', () async {
      await initializePointRegistryAccess(testKey);

      final wrapper =
          RegistryAccess.getInstance<IDualShspSocketWrapper>(testKey);
      expect(wrapper, isNotNull,
          reason: 'IDualShspSocketWrapper should be registered');
      expect(wrapper, isA<IDualShspSocketWrapper>());
    });

    test('registers IRegistryShspSocket under the key', () async {
      await initializePointRegistryAccess(testKey);

      final reg = RegistryAccess.getInstance<IRegistryShspSocket>(testKey);
      expect(reg, isNotNull,
          reason: 'IRegistryShspSocket should be registered');
      expect(reg, isA<IRegistryShspSocket>());
    });

    test('registered socket is open', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(socket.isClosed, isFalse, reason: 'Socket should be open');
    });

    test('registered socket has a valid local port', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(socket.localPort, greaterThan(0),
          reason: 'Should have valid port');
    });

    test('registered socket has a valid local address', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(socket.localAddress, isNotNull,
          reason: 'Should have local address');
    });

    test('socket local address is IPv4', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(socket.localAddress?.type, equals(InternetAddressType.IPv4),
          reason: 'Should bind to IPv4 by default');
    });

    test('socket has a compression codec', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(socket.compressionCodec, isNotNull,
          reason: 'Should have compression codec');
    });

    test('RegistryAccess.contains returns true for all registered types',
        () async {
      await initializePointRegistryAccess(testKey);

      expect(
          RegistryAccess.contains<IDualShspSocketMigratable>(testKey), isTrue);
      expect(RegistryAccess.contains<IDualShspSocketWrapper>(testKey), isTrue);
      expect(RegistryAccess.contains<IRegistryShspSocket>(testKey), isTrue);
    });

    test('RegistryAccess.contains returns false for unknown key', () async {
      await initializePointRegistryAccess(testKey);

      expect(
          RegistryAccess.contains<IDualShspSocketMigratable>('unknown-key'),
          isFalse);
    });

    test('wrapper proxies the same socket registered as IDualShspSocketMigratable',
        () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      final wrapper =
          RegistryAccess.getInstance<IDualShspSocketWrapper>(testKey);

      expect(wrapper.localPort, equals(socket.localPort),
          reason: 'Wrapper should proxy the same underlying socket');
      expect(wrapper.localAddress, equals(socket.localAddress));
    });

    test('wrapper implements IDualShspSocket', () async {
      await initializePointRegistryAccess(testKey);

      final wrapper =
          RegistryAccess.getInstance<IDualShspSocketWrapper>(testKey);
      expect(wrapper, isA<IDualShspSocket>());
    });

    test('multiple keys coexist as independent instances', () async {
      await initializePointRegistryAccess(testKey);
      await initializePointRegistryAccess(secondKey);

      final socket1 =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      final socket2 =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(secondKey);

      expect(identical(socket1, socket2), isFalse,
          reason: 'Different keys should yield different instances');
      expect(socket1.isClosed, isFalse);
      expect(socket2.isClosed, isFalse);
    });

    test('multiple keys do not share wrappers', () async {
      await initializePointRegistryAccess(testKey);
      await initializePointRegistryAccess(secondKey);

      final w1 = RegistryAccess.getInstance<IDualShspSocketWrapper>(testKey);
      final w2 = RegistryAccess.getInstance<IDualShspSocketWrapper>(secondKey);

      expect(identical(w1, w2), isFalse,
          reason: 'Different keys should yield different wrapper instances');
    });

    test('multiple keys do not share IRegistryShspSocket', () async {
      await initializePointRegistryAccess(testKey);
      await initializePointRegistryAccess(secondKey);

      final r1 = RegistryAccess.getInstance<IRegistryShspSocket>(testKey);
      final r2 = RegistryAccess.getInstance<IRegistryShspSocket>(secondKey);

      expect(identical(r1, r2), isFalse,
          reason: 'Different keys should yield different registry instances');
    });

    test('socket implements IDualShspSocket', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(socket, isA<IDualShspSocket>());
    });

    test('socket accepts message callbacks', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      final peer =
          PeerInfo(address: InternetAddress.loopbackIPv4, port: 8888);

      expect(
        () => socket.setMessageCallback(peer, (_) {}),
        returnsNormally,
        reason: 'Should accept message callbacks',
      );
    });

    test('socket accepts listening callback', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(
        () => socket.onListening.register((_) {}),
        returnsNormally,
      );
    });

    test('socket accepts error callback', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(
        () => socket.onError.register((_) {}),
        returnsNormally,
      );
    });

    test('socket accepts close callback', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(
        () => socket.onClose.register((_) {}),
        returnsNormally,
      );
    });

    test('socket can send data to a peer', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      final peer =
          PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);

      expect(
        () => socket.sendTo([1, 2, 3, 4, 5], peer),
        returnsNormally,
        reason: 'Should be able to send data',
      );
    });

    test('socket profile can be extracted', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      final profile = socket.extractProfile();

      expect(profile, isNotNull);
      expect(profile, isA<ShspSocketProfile>());
    });

    test('socket can apply profile', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      final profile = socket.extractProfile();

      expect(
        () => socket.applyProfile(profile),
        returnsNormally,
      );
    });

    test('socket can be closed', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(socket.isClosed, isFalse);

      socket.close();
      expect(socket.isClosed, isTrue, reason: 'Socket should be closed');
    });

    test('same instance is returned on repeated gets from RegistryAccess',
        () async {
      await initializePointRegistryAccess(testKey);

      final s1 =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      final s2 =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);

      expect(identical(s1, s2), isTrue,
          reason: 'RegistryAccess should return the same instance');
    });

    test('socket has IPv4 socket accessible', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(socket.ipv4Socket, isNotNull,
          reason: 'IPv4 socket should exist');
      expect(socket.ipv4Socket.isClosed, isFalse,
          reason: 'IPv4 socket should be open');
    });

    test('IPv6 availability is handled gracefully', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();

      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(socket, isNotNull);

      if (hasIPv6) {
        expect(socket.ipv6Socket, isNotNull,
            reason: 'IPv6 socket should exist when IPv6 is available');
      } else {
        expect(socket.ipv6Socket, isNull,
            reason: 'IPv6 socket should be null when IPv6 is unavailable');
      }
    });

    test('IRegistryShspSocket has IPv4 socket registered', () async {
      await initializePointRegistryAccess(testKey);

      final reg = RegistryAccess.getInstance<IRegistryShspSocket>(testKey);
      expect(reg, isA<RegistryShspSocket>());

      final typedReg = reg as RegistryShspSocket;
      final ipv4 = typedReg.getByKey(SocketType.ipv4);
      expect(ipv4, isNotNull, reason: 'Registry should contain IPv4 socket');
    });

    test('IRegistryShspSocket has IPv6 socket registered when available',
        () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();

      await initializePointRegistryAccess(testKey);

      final reg = RegistryAccess.getInstance<IRegistryShspSocket>(testKey)
          as RegistryShspSocket;

      if (hasIPv6) {
        expect(reg.getByKey(SocketType.ipv6), isNotNull,
            reason: 'Registry should contain IPv6 socket when available');
      } else {
        expect(reg.getByKey(SocketType.ipv6), isNull,
            reason: 'Registry should not contain IPv6 when unavailable');
      }
    });

    test('multiple peers can register callbacks', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);

      final peers = List.generate(
        3,
        (i) => PeerInfo(address: InternetAddress.loopbackIPv4, port: 7001 + i),
      );

      expect(
        () {
          for (final peer in peers) {
            socket.setMessageCallback(peer, (_) {});
          }
        },
        returnsNormally,
        reason: 'Should support multiple peer callbacks',
      );
    });

    test('socket state remains consistent after multiple operations', () async {
      await initializePointRegistryAccess(testKey);

      final socket =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);

      for (int i = 0; i < 10; i++) {
        final peer =
            PeerInfo(address: InternetAddress.loopbackIPv4, port: 6000 + i);
        socket.setMessageCallback(peer, (_) {});
      }

      expect(socket.isClosed, isFalse,
          reason: 'Socket should still be open after operations');
      expect(socket.localPort, greaterThan(0));
    });

    test('initialization is repeatable under the same key after cleanup',
        () async {
      await initializePointRegistryAccess(testKey);
      final socket1 =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      socket1.close();
      _cleanup(testKey);

      await initializePointRegistryAccess(testKey);
      final socket2 =
          RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);

      expect(socket2.isClosed, isFalse,
          reason: 'New socket should be open after re-initialization');
      expect(socket2.localPort, greaterThan(0));
    });
  });
}
