import 'dart:async';
import 'dart:io';

import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

/// Wires the full dual graph under [key] and resolves it far enough that the
/// ipv4 `IShspSocket`/`IShspSocketMigratable` instances actually exist —
/// `migrateShspSocket` swaps registry entries, so the "old" instances must
/// have been built before it runs for the swap to be observable.
Future<
  ({
    IDualShspSocketMigratable dual,
    IShspSocketMigratable ipv4Wrapper,
    IShspSocket ipv4Socket,
  })
>
_wireGraph(String key) async {
  await const DualShspInjector().registerAllSingletonsShspAsync(key: key);

  final registry = RegistryManager.instance;
  final ipv4Socket = registry.getInstance<IShspSocket>(
    key: key,
    subkey: 'ipv4',
  );
  final ipv4Wrapper = registry.getInstance<IShspSocketMigratable>(
    key: key,
    subkey: 'ipv4',
  );
  final dual = registry.getInstance<IDualShspSocketMigratable>(key: key);

  return (dual: dual, ipv4Wrapper: ipv4Wrapper, ipv4Socket: ipv4Socket);
}

/// Resolves the ipv6 slot, or null when the host has no IPv6 available
/// (`connectDualShspSockets` leaves the subkey unregistered in that case).
IShspSocket? _ipv6SocketOrNull(String key) => RegistryManager.instance
    .getInstanceNullable<IShspSocket>(key: key, subkey: 'ipv6');

void main() {
  group('shspSocketSubkeyFor', () {
    test('maps IPv4 to the ipv4 subkey', () {
      expect(shspSocketSubkeyFor(InternetAddressType.IPv4), 'ipv4');
    });

    test('maps IPv6 to the ipv6 subkey', () {
      expect(shspSocketSubkeyFor(InternetAddressType.IPv6), 'ipv6');
    });

    test('maps every non-IPv4 family to the ipv6 subkey', () {
      // Only two subkeys exist, so anything that is not IPv4 lands on 'ipv6'.
      expect(shspSocketSubkeyFor(InternetAddressType.unix), 'ipv6');
      expect(shspSocketSubkeyFor(InternetAddressType.any), 'ipv6');
    });
  });

  group('migrateShspSocket', () {
    test('returns a socket bound to the raw socket that was passed in', () async {
      const key = 'migration_returns_new_socket';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final migrated = await migrateShspSocket(raw, key: key);

      expect(migrated.localPort, raw.port);
      expect(migrated.isClosed, isFalse);
    });

    test('overwrites the IShspSocket registry entry for the resolved subkey', () async {
      const key = 'migration_replaces_ishspsocket';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final migrated = await migrateShspSocket(raw, key: key);

      expect(
        RegistryManager.instance.getInstance<IShspSocket>(
          key: key,
          subkey: 'ipv4',
        ),
        same(migrated),
      );
      expect(
        RegistryManager.instance.getInstance<IShspSocket>(
          key: key,
          subkey: 'ipv4',
        ),
        isNot(same(graph.ipv4Socket)),
      );
    });

    test('overwrites the RawDatagramSocket registry entry for the resolved subkey', () async {
      const key = 'migration_replaces_raw_socket';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      await migrateShspSocket(raw, key: key);

      expect(
        RegistryManager.instance.getInstance<RawDatagramSocket>(
          key: key,
          subkey: 'ipv4',
        ),
        same(raw),
      );
    });

    test('keeps the registered migratable wrapper and repoints its delegate', () async {
      const key = 'migration_keeps_wrapper';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final migrated = await migrateShspSocket(raw, key: key);

      // The wrapper is the live router: same instance before and after, only
      // its delegate moved.
      expect(
        RegistryManager.instance.getInstance<IShspSocketMigratable>(
          key: key,
          subkey: 'ipv4',
        ),
        same(graph.ipv4Wrapper),
      );
      expect(
        (graph.ipv4Wrapper as ShspSocketMigratable).delegateSocket,
        same(migrated),
      );
    });

    test('the dual migratable observes the new port without being replaced', () async {
      const key = 'migration_dual_observes';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final oldPort = graph.dual.getSocket(InternetAddressType.IPv4)!.localPort;

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      await migrateShspSocket(raw, key: key);

      expect(
        RegistryManager.instance.getInstance<IDualShspSocketMigratable>(
          key: key,
        ),
        same(graph.dual),
      );
      expect(
        graph.dual.getSocket(InternetAddressType.IPv4)!.localPort,
        raw.port,
      );
      expect(
        graph.dual.getSocket(InternetAddressType.IPv4)!.localPort,
        isNot(oldPort),
      );
    });

    test('closes the socket that was migrated away from', () async {
      const key = 'migration_closes_old';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      expect(graph.ipv4Socket.isClosed, isFalse);

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      await migrateShspSocket(raw, key: key);

      expect(graph.ipv4Socket.isClosed, isTrue);
      expect(graph.ipv4Wrapper.isClosed, isFalse);
    });

    test('carries the old socket message callbacks over to the new socket', () async {
      const key = 'migration_carries_profile';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9401);
      graph.ipv4Socket.setMessageCallback(peer, (_) {});
      final peerKey = MessageCallbackMap.formatKey(peer.address, peer.port);
      expect(graph.ipv4Socket.extractProfile().messageListeners.keys, [peerKey]);

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final migrated = await migrateShspSocket(raw, key: key);

      expect(migrated.extractProfile().messageListeners.keys, [peerKey]);
    });

    test('the migrated socket really receives datagrams for a transferred callback', () async {
      const key = 'migration_receives_after_migration';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final sender = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(sender.close);

      final received = Completer<List<int>>();
      final senderPeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: sender.port,
      );
      // Registered on the pre-migration socket only — it must survive the swap.
      graph.ipv4Socket.setMessageCallback(senderPeer, (record) {
        if (!received.isCompleted) received.complete(record.msg);
      });

      final raw = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final migrated = await migrateShspSocket(raw, key: key);

      sender.send([7, 8, 9], InternetAddress.loopbackIPv4, migrated.localPort!);

      expect(
        await received.future.timeout(const Duration(seconds: 5)),
        [7, 8, 9],
      );
    });

    test('an IPv6 socket migrates the ipv6 slot and leaves ipv4 untouched', () async {
      const key = 'migration_ipv6_slot';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final oldIpv6 = _ipv6SocketOrNull(key);
      if (oldIpv6 == null) return; // host without IPv6
      final ipv4PortBefore =
          graph.dual.getSocket(InternetAddressType.IPv4)!.localPort;

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv6, 0);
      final migrated = await migrateShspSocket(raw, key: key);

      expect(
        RegistryManager.instance.getInstance<IShspSocket>(
          key: key,
          subkey: 'ipv6',
        ),
        same(migrated),
      );
      expect(
        graph.dual.getSocket(InternetAddressType.IPv6)!.localPort,
        raw.port,
      );
      expect(oldIpv6.isClosed, isTrue);
      // ipv4 side is a different registry slot: nothing about it moved.
      expect(
        RegistryManager.instance.getInstance<IShspSocket>(
          key: key,
          subkey: 'ipv4',
        ),
        same(graph.ipv4Socket),
      );
      expect(
        graph.dual.getSocket(InternetAddressType.IPv4)!.localPort,
        ipv4PortBefore,
      );
    });

    test('keys are independent — migrating one key leaves the other alone', () async {
      const keyA = 'migration_key_isolation_a';
      const keyB = 'migration_key_isolation_b';
      final graphA = await _wireGraph(keyA);
      final graphB = await _wireGraph(keyB);
      addTearDown(graphA.dual.close);
      addTearDown(graphB.dual.close);

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      await migrateShspSocket(raw, key: keyA);

      expect(
        RegistryManager.instance.getInstance<IShspSocket>(
          key: keyB,
          subkey: 'ipv4',
        ),
        same(graphB.ipv4Socket),
      );
      expect(graphB.ipv4Socket.isClosed, isFalse);
    });

    test('migrating twice in a row keeps the wrapper on the newest socket', () async {
      const key = 'migration_twice';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final firstRaw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final first = await migrateShspSocket(firstRaw, key: key);
      final secondRaw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final second = await migrateShspSocket(secondRaw, key: key);

      expect(first.isClosed, isTrue);
      expect(second.isClosed, isFalse);
      expect(
        (graph.ipv4Wrapper as ShspSocketMigratable).delegateSocket,
        same(second),
      );
      expect(graph.dual.getSocket(InternetAddressType.IPv4)!.localPort,
          secondRaw.port);
    });

    test('throws when nothing is wired under the key', () async {
      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(raw.close);

      expect(
        () => migrateShspSocket(raw, key: 'migration_unwired_key'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });
  });

  group('migrateShspSocketIpv4 / migrateShspSocketIpv6', () {
    test('migrateShspSocketIpv4 binds its own ipv4 socket and migrates it', () async {
      const key = 'migration_helper_ipv4';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final migrated = await migrateShspSocketIpv4(key: key);

      expect(migrated.localPort, isNot(0));
      expect(
        RegistryManager.instance
            .getInstance<RawDatagramSocket>(key: key, subkey: 'ipv4')
            .address
            .type,
        InternetAddressType.IPv4,
      );
      expect(
        (graph.ipv4Wrapper as ShspSocketMigratable).delegateSocket,
        same(migrated),
      );
      expect(graph.ipv4Socket.isClosed, isTrue);
    });

    test('migrateShspSocketIpv6 binds its own ipv6 socket and migrates it', () async {
      const key = 'migration_helper_ipv6';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final oldIpv6 = _ipv6SocketOrNull(key);
      if (oldIpv6 == null) return; // host without IPv6

      final migrated = await migrateShspSocketIpv6(key: key);

      expect(
        RegistryManager.instance
            .getInstance<RawDatagramSocket>(key: key, subkey: 'ipv6')
            .address
            .type,
        InternetAddressType.IPv6,
      );
      expect(
        RegistryManager.instance
            .getInstance<IShspSocket>(key: key, subkey: 'ipv6'),
        same(migrated),
      );
      expect(oldIpv6.isClosed, isTrue);
    });
  });

  group('migrateDualShspSockets', () {
    test('throws when neither socket is provided', () async {
      const key = 'migration_dual_no_socket';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      expect(
        () => migrateDualShspSockets(key: key),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when ipv4Socket is not bound to an IPv4 address', () async {
      const key = 'migration_dual_wrong_family_ipv4';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      RawDatagramSocket ipv6Raw;
      try {
        ipv6Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv6, 0);
      } catch (_) {
        return; // host without IPv6
      }
      addTearDown(ipv6Raw.close);

      expect(
        () => migrateDualShspSockets(ipv4Socket: ipv6Raw, key: key),
        throwsA(isA<ArgumentError>()),
      );
      // The bad argument was rejected before anything was migrated.
      expect(graph.ipv4Socket.isClosed, isFalse);
      expect(
        RegistryManager.instance
            .getInstance<IShspSocket>(key: key, subkey: 'ipv4'),
        same(graph.ipv4Socket),
      );
    });

    test('throws when ipv6Socket is not bound to an IPv6 address', () async {
      const key = 'migration_dual_wrong_family_ipv6';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final ipv4Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(ipv4Raw.close);

      expect(
        () => migrateDualShspSockets(ipv6Socket: ipv4Raw, key: key),
        throwsA(isA<ArgumentError>()),
      );
      expect(graph.ipv4Socket.isClosed, isFalse);
    });

    test('throws when no dual migratable is registered under the key', () async {
      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(raw.close);

      expect(
        () => migrateDualShspSockets(
          ipv4Socket: raw,
          key: 'migration_dual_unwired_key',
        ),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('migrates only the ipv4 slot when ipv6Socket is omitted', () async {
      const key = 'migration_dual_ipv4_only';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final oldIpv6 = _ipv6SocketOrNull(key);
      final ipv4Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      final result = await migrateDualShspSockets(
        ipv4Socket: ipv4Raw,
        key: key,
      );

      expect(result.ipv6, isNull);
      expect(result.ipv4, isNotNull);
      expect(result.ipv4!.localPort, ipv4Raw.port);
      expect(graph.ipv4Socket.isClosed, isTrue);
      if (oldIpv6 != null) {
        expect(oldIpv6.isClosed, isFalse);
        expect(
          RegistryManager.instance
              .getInstance<IShspSocket>(key: key, subkey: 'ipv6'),
          same(oldIpv6),
        );
      }
    });

    test('migrates both slots in one call', () async {
      const key = 'migration_dual_both';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final oldIpv6 = _ipv6SocketOrNull(key);
      if (oldIpv6 == null) return; // host without IPv6

      final ipv4Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final ipv6Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv6, 0);

      final result = await migrateDualShspSockets(
        ipv4Socket: ipv4Raw,
        ipv6Socket: ipv6Raw,
        key: key,
      );

      expect(result.ipv4!.localPort, ipv4Raw.port);
      expect(result.ipv6!.localPort, ipv6Raw.port);
      expect(graph.ipv4Socket.isClosed, isTrue);
      expect(oldIpv6.isClosed, isTrue);
      expect(
        graph.dual.getSocket(InternetAddressType.IPv4)!.localPort,
        ipv4Raw.port,
      );
      expect(
        graph.dual.getSocket(InternetAddressType.IPv6)!.localPort,
        ipv6Raw.port,
      );
      // The router itself was never replaced.
      expect(
        RegistryManager.instance.getInstance<IDualShspSocketMigratable>(
          key: key,
        ),
        same(graph.dual),
      );
    });

    test('migrates only the ipv6 slot when ipv4Socket is omitted', () async {
      const key = 'migration_dual_ipv6_only';
      final graph = await _wireGraph(key);
      addTearDown(graph.dual.close);

      final oldIpv6 = _ipv6SocketOrNull(key);
      if (oldIpv6 == null) return; // host without IPv6

      final ipv6Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv6, 0);

      final result = await migrateDualShspSockets(
        ipv6Socket: ipv6Raw,
        key: key,
      );

      expect(result.ipv4, isNull);
      expect(result.ipv6!.localPort, ipv6Raw.port);
      expect(oldIpv6.isClosed, isTrue);
      expect(graph.ipv4Socket.isClosed, isFalse);
      expect(
        RegistryManager.instance
            .getInstance<IShspSocket>(key: key, subkey: 'ipv4'),
        same(graph.ipv4Socket),
      );
    });
  });
}
