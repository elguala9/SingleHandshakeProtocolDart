import 'dart:io';
import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

void main() {
  group('connectDualShspSockets', () {
    test('binds and registers a real ipv4 RawDatagramSocket under the key', () async {
      const key = 'wiring_raw_ipv4_only';
      await connectDualShspSockets(key: key);

      final ipv4 = RegistryManager.instance
          .getInstance<RawDatagramSocket>(key: key, subkey: 'ipv4');
      addTearDown(ipv4.close);

      expect(ipv4.address.type, InternetAddressType.IPv4);
    });

    test('registers ipv6 too when the host supports it', () async {
      const key = 'wiring_raw_ipv6';
      await connectDualShspSockets(key: key);

      final ipv4 = RegistryManager.instance
          .getInstance<RawDatagramSocket>(key: key, subkey: 'ipv4');
      addTearDown(ipv4.close);

      final ipv6 = RegistryManager.instance
          .getInstanceNullable<RawDatagramSocket>(key: key, subkey: 'ipv6');
      if (ipv6 == null) return;
      addTearDown(ipv6.close);
      expect(ipv6.address.type, InternetAddressType.IPv6);
    });
  });

  group('connectShspSocketMigratableSubkeys', () {
    test('IShspSocketMigratable wraps the IShspSocket registered under the same subkey', () async {
      const key = 'wiring_migratable_subkeys';
      await connectDualShspSockets(key: key);
      RegistryManager.instance.connectInstance<IShspSocket, ShspSocket>(
        () => ShspSocket.dependencyInjectionFactory(key: key, subkey: 'ipv4'),
        key: key,
        subkey: 'ipv4',
      );
      connectShspSocketMigratableSubkeys(key: key);

      final ipv4Socket =
          RegistryManager.instance.getInstance<IShspSocket>(key: key, subkey: 'ipv4');
      addTearDown(() {
        if (!ipv4Socket.isClosed) ipv4Socket.close();
      });

      final ipv4Migratable = RegistryManager.instance
          .getInstance<IShspSocketMigratable>(key: key, subkey: 'ipv4');

      expect(ipv4Migratable, isA<ShspSocketMigratable>());
      expect(
        (ipv4Migratable as ShspSocketMigratable).delegateSocket,
        same(ipv4Socket),
      );
    });
  });

  group('DualShspInjector — full tree resolution', () {
    test('resolves IShspSocket -> IShspSocketMigratable -> IDualShspSocketAuto / IDualShspSocketMigratable end-to-end', () async {
      const key = 'wiring_full_tree';
      await const DualShspInjector().registerAllSingletonsShspAsync(key: key);

      final ipv4Socket =
          RegistryManager.instance.getInstance<IShspSocket>(key: key, subkey: 'ipv4');
      final ipv4Migratable = RegistryManager.instance
          .getInstance<IShspSocketMigratable>(key: key, subkey: 'ipv4');

      final auto = RegistryManager.instance
          .getInstance<IDualShspSocketAuto>(key: key);
      final migratable = RegistryManager.instance
          .getInstance<IDualShspSocketMigratable>(key: key);
      addTearDown(auto.close);
      // auto and migratable share the same underlying ipv4/ipv6 IShspSocketMigratable
      // instances (see assertions below), so closing `auto` already closes them —
      // closing `migratable` too would double-close.

      // The dual views are two distinct objects...
      expect(auto, isNot(same(migratable)));
      // ...but resolve down to the exact same underlying single-socket instances,
      // proving the registry graph shares state instead of duplicating it.
      expect(auto.ipv4SocketImpl, same(ipv4Migratable));
      expect(migratable.ipv4SocketImpl, same(ipv4Migratable));
      expect(auto.ipv4SocketImpl, same(migratable.ipv4SocketImpl));

      expect(
        (ipv4Migratable as ShspSocketMigratable).delegateSocket,
        same(ipv4Socket),
      );

      final ipv6Socket = RegistryManager.instance
          .getInstanceNullable<IShspSocket>(key: key, subkey: 'ipv6');
      if (ipv6Socket != null) {
        final ipv6Migratable = RegistryManager.instance
            .getInstance<IShspSocketMigratable>(key: key, subkey: 'ipv6');
        expect(auto.ipv6SocketImpl, same(ipv6Migratable));
        expect(migratable.ipv6SocketImpl, same(ipv6Migratable));
      }
    });

    test('IRegistryShspSocket resolves from the same IShspSocket instances', () async {
      const key = 'wiring_registry_shsp_socket';
      await const DualShspInjector().registerAllSingletonsShspAsync(key: key);

      final ipv4Socket =
          RegistryManager.instance.getInstance<IShspSocket>(key: key, subkey: 'ipv4');
      addTearDown(() {
        if (!ipv4Socket.isClosed) ipv4Socket.close();
      });

      final registry = RegistryManager.instance
          .getInstance<IRegistryShspSocket>(key: key) as RegistryShspSocket;

      expect(registry.getByKey(SocketType.ipv4), same(ipv4Socket));
    });
  });

  group('migration through DI-resolved instances', () {
    test('migrateSocket via the DI-resolved IDualShspSocketAuto updates the shared ipv4 slot', () async {
      const key = 'wiring_migration_auto';
      await const DualShspInjector().registerAllSingletonsShspAsync(key: key);

      final auto = RegistryManager.instance
          .getInstance<IDualShspSocketAuto>(key: key);
      final migratable = RegistryManager.instance
          .getInstance<IDualShspSocketMigratable>(key: key);
      addTearDown(auto.close);

      final oldPort = auto.getSocket(InternetAddressType.IPv4)!.localPort;
      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() {
        if (!newSocket.isClosed) newSocket.close();
      });

      auto.migrateSocket(newSocket, InternetAddressType.IPv4);

      expect(
        auto.getSocket(InternetAddressType.IPv4)!.localPort,
        equals(newSocket.localPort),
      );
      expect(
        auto.getSocket(InternetAddressType.IPv4)!.localPort,
        isNot(equals(oldPort)),
      );
      // migrateSocket mutated the shared IShspSocketMigratable instance in
      // place, so the independently-resolved `migratable` view observes the
      // same migration without any explicit propagation code.
      expect(
        migratable.getSocket(InternetAddressType.IPv4)!.localPort,
        equals(newSocket.localPort),
      );
    });

    test('migrateSocket via the DI-resolved IDualShspSocketMigratable updates the shared ipv4 slot', () async {
      const key = 'wiring_migration_migratable';
      await const DualShspInjector().registerAllSingletonsShspAsync(key: key);

      final auto = RegistryManager.instance
          .getInstance<IDualShspSocketAuto>(key: key);
      final migratable = RegistryManager.instance
          .getInstance<IDualShspSocketMigratable>(key: key);
      addTearDown(auto.close);

      final oldPort = migratable.getSocket(InternetAddressType.IPv4)!.localPort;
      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() {
        if (!newSocket.isClosed) newSocket.close();
      });

      migratable.migrateSocket(newSocket, InternetAddressType.IPv4);

      expect(
        migratable.getSocket(InternetAddressType.IPv4)!.localPort,
        equals(newSocket.localPort),
      );
      expect(
        migratable.getSocket(InternetAddressType.IPv4)!.localPort,
        isNot(equals(oldPort)),
      );
      expect(
        auto.getSocket(InternetAddressType.IPv4)!.localPort,
        equals(newSocket.localPort),
      );
    });

    test('migrateSocket via ipv6 works end-to-end when the host supports ipv6', () async {
      const key = 'wiring_migration_ipv6';
      await const DualShspInjector().registerAllSingletonsShspAsync(key: key);

      final auto = RegistryManager.instance
          .getInstance<IDualShspSocketAuto>(key: key);
      addTearDown(auto.close);

      final oldIpv6 = auto.getSocket(InternetAddressType.IPv6);
      if (oldIpv6 == null) return;
      final oldPort = oldIpv6.localPort;

      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
      addTearDown(() {
        if (!newSocket.isClosed) newSocket.close();
      });

      auto.migrateSocket(newSocket, InternetAddressType.IPv6);

      expect(
        auto.getSocket(InternetAddressType.IPv6)!.localPort,
        equals(newSocket.localPort),
      );
      expect(
        auto.getSocket(InternetAddressType.IPv6)!.localPort,
        isNot(equals(oldPort)),
      );
    });

    test('the old socket is closed after a DI-resolved migration', () async {
      const key = 'wiring_migration_old_closed';
      await const DualShspInjector().registerAllSingletonsShspAsync(key: key);

      final auto = RegistryManager.instance
          .getInstance<IDualShspSocketAuto>(key: key);
      addTearDown(auto.close);

      // `getSocket()` returns the stable ShspSocketMigratable wrapper, whose
      // identity never changes across a migration — capture the raw delegate
      // it holds *before* migrating to observe that specific socket close.
      final wrapper = auto.getSocket(InternetAddressType.IPv4)!
          as ShspSocketMigratable;
      final oldDelegate = wrapper.delegateSocket;
      expect(oldDelegate.isClosed, isFalse);

      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() {
        if (!newSocket.isClosed) newSocket.close();
      });

      auto.migrateSocket(newSocket, InternetAddressType.IPv4);

      expect(oldDelegate.isClosed, isTrue);
      expect(wrapper.isClosed, isFalse);
    });
  });

  group('missing RawDatagramSocket subkey', () {
    test(
      'DualShspSocketAuto.dependencyInjectionFactory throws instead of degrading to ipv4-only '
      'when only the ipv4 RawDatagramSocket is registered',
      () async {
        // Regression/documentation test: getInstanceNullable<IShspSocketMigratable>
        // is expected to tolerate a missing ipv6 slot, but ShspSocket/ShspSocketMigratable's
        // own factories resolve their dependency with the non-nullable getInstance(),
        // so a missing ipv6 RawDatagramSocket surfaces as a thrown RegistryNotFoundError
        // instead of the ipv6 slot silently resolving to null.
        const key = 'wiring_missing_ipv6_raw_socket';
        final ipv4Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(ipv4Raw.close);
        RegistryManager.instance.connectInstance<RawDatagramSocket, RawDatagramSocket>(
          () => ipv4Raw,
          key: key,
          subkey: 'ipv4',
        );
        // Deliberately not registering the 'ipv6' RawDatagramSocket subkey.

        RegistryManager.instance.connectInstance<IShspSocket, ShspSocket>(
          () => ShspSocket.dependencyInjectionFactory(key: key, subkey: 'ipv4'),
          key: key,
          subkey: 'ipv4',
        );
        RegistryManager.instance.connectInstance<IShspSocket, ShspSocket>(
          () => ShspSocket.dependencyInjectionFactory(key: key, subkey: 'ipv6'),
          key: key,
          subkey: 'ipv6',
        );
        connectShspSocketMigratableSubkeys(key: key);

        expect(
          () => DualShspSocketAuto.dependencyInjectionFactory(key: key),
          throwsA(isA<RegistryNotFoundError>()),
        );
      },
    );
  });
}
