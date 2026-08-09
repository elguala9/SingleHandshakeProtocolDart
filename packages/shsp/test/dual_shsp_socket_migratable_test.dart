import 'dart:io';
import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

void main() {
  group('DualShspSocketMigratable', () {
    // ── Construction ─────────────────────────────────────────────────────────

    group('constructor — wraps in ShspSocketMigratable', () {
      late ShspSocket ipv4Socket;
      late DualShspSocketMigratable migratable;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        migratable = DualShspSocketMigratable.fromSockets(Sockets(ipv4SocketImpl: ipv4Socket));
      });

      tearDown(() {
        migratable.close();
      });

      test('implements IDualShspSocketMigratable', () {
        expect(migratable, isA<IDualShspSocketMigratable>());
      });

      test('implements IDualShspSocket', () {
        expect(migratable, isA<IDualShspSocket>());
      });

      test('ipv4SocketImpl is ShspSocketMigratable', () {
        expect(migratable.ipv4SocketImpl, isA<ShspSocketMigratable>());
      });

      test('ipv4Socket exposes the wrapped socket', () {
        expect(migratable.ipv4Socket, isA<ShspSocketMigratable>());
      });

      test('ipv6SocketImpl is null when no ipv6 socket provided', () {
        expect(migratable.ipv6SocketImpl, isNull);
      });
    });

    group('constructor — wraps both IPv4 and IPv6 in ShspSocketMigratable', () {
      late ShspSocket ipv4Socket;
      late ShspSocket? ipv6Socket;
      late DualShspSocketMigratable migratable;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        ipv6Socket = await ShspSocket.bindIfPossible(InternetAddress.anyIPv6, 0);
        migratable = DualShspSocketMigratable.fromSockets(Sockets(
          ipv4SocketImpl: ipv4Socket,
          ipv6SocketImpl: ipv6Socket,
        ));
      });

      tearDown(() {
        migratable.close();
      });

      test('ipv4SocketImpl is ShspSocketMigratable', () {
        expect(migratable.ipv4SocketImpl, isA<ShspSocketMigratable>());
      });

      test('ipv6SocketImpl is ShspSocketMigratable when ipv6 available', () {
        if (ipv6Socket == null) return;
        expect(migratable.ipv6SocketImpl, isA<ShspSocketMigratable>());
      });
    });

    group('constructor with migratables — uses them as-is', () {
      late ShspSocket ipv4Socket;
      late ShspSocketMigratable ipv4Migratable;
      late DualShspSocketMigratable migratable;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        ipv4Migratable = ShspSocketMigratable(ipv4Socket);
        migratable = DualShspSocketMigratable(ipv4Migratable: ipv4Migratable);
      });

      tearDown(() {
        migratable.close();
      });

      test('ipv4SocketImpl is the exact wrapper passed in', () {
        expect(migratable.ipv4SocketImpl, same(ipv4Migratable));
      });

      test('ipv6SocketImpl is null when no ipv6 wrapper provided', () {
        expect(migratable.ipv6SocketImpl, isNull);
      });
    });

    group('constructor with migratables — with both provided', () {
      late ShspSocket ipv4Socket;
      late ShspSocket? ipv6Socket;
      late ShspSocketMigratable ipv4Migratable;
      late ShspSocketMigratable? ipv6Migratable;
      late DualShspSocketMigratable migratable;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        ipv6Socket = await ShspSocket.bindIfPossible(InternetAddress.anyIPv6, 0);
        ipv4Migratable = ShspSocketMigratable(ipv4Socket);
        ipv6Migratable = ipv6Socket != null ? ShspSocketMigratable(ipv6Socket!) : null;
        migratable = DualShspSocketMigratable(
          ipv4Migratable: ipv4Migratable,
          ipv6Migratable: ipv6Migratable,
        );
      });

      tearDown(() {
        migratable.close();
      });

      test('ipv4SocketImpl is exact ipv4Migratable', () {
        expect(migratable.ipv4SocketImpl, same(ipv4Migratable));
      });

      test('ipv6SocketImpl is exact ipv6Migratable when ipv6 available', () {
        if (ipv6Socket == null) return;
        expect(migratable.ipv6SocketImpl, same(ipv6Migratable));
      });
    });

    group('dependencyInjectionFactory', () {
      late ShspSocket ipv4Socket;
      late ShspSocketMigratable ipv4Migratable;
      const key = 'dual_shsp_socket_migratable_test';

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        ipv4Migratable = ShspSocketMigratable(ipv4Socket);
        RegistryManager.instance.setInstance<IShspSocketMigratable>(
          ipv4Migratable,
          key: key,
          subkey: 'ipv4',
        );
      });

      tearDown(() {
        ipv4Socket.close();
      });

      test('resolves the ipv4/ipv6 migratables registered under key/subkey', () {
        final migratable = DualShspSocketMigratable.dependencyInjectionFactory(
          key: key,
        );
        addTearDown(migratable.close);

        expect(migratable.ipv4SocketImpl, same(ipv4Migratable));
        expect(migratable.ipv6SocketImpl, isNull);
      });

      test('constructs even when neither migratable is registered', () {
        final migratable = DualShspSocketMigratable.dependencyInjectionFactory(
          key: 'unregistered_key',
        );
        addTearDown(migratable.close);

        expect(migratable.ipv4SocketImpl, isNull);
        expect(migratable.ipv6SocketImpl, isNull);
      });
    });

    // ── migrateSocketIpv4 ────────────────────────────────────────────────────

    group('migrateSocketIpv4', () {
      late ShspSocket originalIpv4;
      late DualShspSocketMigratable migratable;

      setUp(() async {
        originalIpv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        migratable = DualShspSocketMigratable.fromSockets(Sockets(ipv4SocketImpl: originalIpv4));
      });

      tearDown(() {
        if (!migratable.isClosed) migratable.close();
      });

      test('migrates to new IPv4 socket (localPort changes)', () async {
        final oldPort = migratable.ipv4Socket!.localPort;
        final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });

        migratable.migrateSocketIpv4(newSocket);

        expect(migratable.ipv4Socket!.localPort, equals(newSocket.localPort));
        expect(migratable.ipv4Socket!.localPort, isNot(equals(oldPort)));
      });

      test('ipv4SocketImpl remains a ShspSocketMigratable after migration', () async {
        final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });

        migratable.migrateSocketIpv4(newSocket);

        expect(migratable.ipv4SocketImpl, isA<ShspSocketMigratable>());
      });

      test('auto-wraps ipv4SocketImpl if not already a ShspSocketMigratable', () async {
        // Force ipv4SocketImpl to a raw ShspSocket (bypassing the constructor wrapper)
        final rawSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!rawSocket.isClosed) rawSocket.close(); });
        migratable.ipv4SocketImpl = rawSocket;
        expect(migratable.ipv4SocketImpl, isNot(isA<ShspSocketMigratable>()));

        final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });

        // Should auto-wrap and migrate without throwing
        expect(() => migratable.migrateSocketIpv4(newSocket), returnsNormally);
        expect(migratable.ipv4SocketImpl, isA<ShspSocketMigratable>());
      });
    });

    // ── migrateSocketIpv6 ────────────────────────────────────────────────────

    group('migrateSocketIpv6 — ipv6 was null', () {
      late DualShspSocketMigratable migratable;

      setUp(() async {
        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        migratable = DualShspSocketMigratable.fromSockets(Sockets(ipv4SocketImpl: ipv4));
        expect(migratable.ipv6SocketImpl, isNull);
      });

      tearDown(() {
        if (!migratable.isClosed) migratable.close();
      });

      test('creates a ShspSocketMigratable for the new IPv6 socket', () async {
        final newIpv6 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newIpv6.isClosed) newIpv6.close(); });

        migratable.migrateSocketIpv6(newIpv6);

        expect(migratable.ipv6SocketImpl, isNotNull);
        expect(migratable.ipv6SocketImpl, isA<ShspSocketMigratable>());
      });

      test('ipv6Socket is accessible after migration from null', () async {
        final newIpv6 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newIpv6.isClosed) newIpv6.close(); });

        migratable.migrateSocketIpv6(newIpv6);

        expect(migratable.ipv6Socket, isNotNull);
        expect(migratable.ipv6Socket!.localPort, equals(newIpv6.localPort));
      });
    });

    group('migrateSocketIpv6 — ipv6 already exists as wrapper', () {
      late ShspSocket? originalIpv6;
      late DualShspSocketMigratable migratable;

      setUp(() async {
        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        originalIpv6 = await ShspSocket.bindIfPossible(InternetAddress.anyIPv6, 0);
        migratable = DualShspSocketMigratable.fromSockets(Sockets(
          ipv4SocketImpl: ipv4,
          ipv6SocketImpl: originalIpv6,
        ));
      });

      tearDown(() {
        if (!migratable.isClosed) migratable.close();
      });

      test('migrates to new IPv6 socket (localPort changes)', () async {
        if (originalIpv6 == null) return;
        final oldPort = migratable.ipv6Socket!.localPort;
        final newIpv6 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newIpv6.isClosed) newIpv6.close(); });

        migratable.migrateSocketIpv6(newIpv6);

        expect(migratable.ipv6Socket!.localPort, equals(newIpv6.localPort));
        expect(migratable.ipv6Socket!.localPort, isNot(equals(oldPort)));
      });

      test('ipv6SocketImpl remains a ShspSocketMigratable after migration', () async {
        if (originalIpv6 == null) return;
        final newIpv6 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newIpv6.isClosed) newIpv6.close(); });

        migratable.migrateSocketIpv6(newIpv6);

        expect(migratable.ipv6SocketImpl, isA<ShspSocketMigratable>());
      });

      test('auto-wraps ipv6SocketImpl if not already a ShspSocketMigratable', () async {
        if (originalIpv6 == null) return;
        final rawIpv6 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!rawIpv6.isClosed) rawIpv6.close(); });
        migratable.ipv6SocketImpl = rawIpv6;
        expect(migratable.ipv6SocketImpl, isNot(isA<ShspSocketMigratable>()));

        final newIpv6 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newIpv6.isClosed) newIpv6.close(); });

        expect(() => migratable.migrateSocketIpv6(newIpv6), returnsNormally);
        expect(migratable.ipv6SocketImpl, isA<ShspSocketMigratable>());
      });
    });
  });
}
