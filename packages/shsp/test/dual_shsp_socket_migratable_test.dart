import 'dart:io';
import 'package:shsp/shsp.dart';
import 'package:test/test.dart';

void main() {
  group('DualShspSocketMigratable', () {
    // ── Construction ─────────────────────────────────────────────────────────

    group('constructor — wraps in ShspSocketWrapper', () {
      late ShspSocket ipv4Socket;
      late DualShspSocketMigratable migratable;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        migratable = DualShspSocketMigratable(ipv4Socket);
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

      test('ipv4SocketImpl is ShspSocketWrapper', () {
        expect(migratable.ipv4SocketImpl, isA<ShspSocketWrapper>());
      });

      test('ipv4Socket exposes the wrapped socket', () {
        expect(migratable.ipv4Socket, isA<ShspSocketWrapper>());
      });

      test('ipv6SocketImpl is null when no ipv6 socket provided', () {
        expect(migratable.ipv6SocketImpl, isNull);
      });
    });

    group('constructor — wraps both IPv4 and IPv6 in ShspSocketWrapper', () {
      late ShspSocket ipv4Socket;
      late ShspSocket ipv6Socket;
      late DualShspSocketMigratable migratable;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        try {
          ipv6Socket = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
        } catch (_) {
          ipv6Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        }
        migratable = DualShspSocketMigratable(ipv4Socket, ipv6Socket);
      });

      tearDown(() {
        migratable.close();
      });

      test('ipv4SocketImpl is ShspSocketWrapper', () {
        expect(migratable.ipv4SocketImpl, isA<ShspSocketWrapper>());
      });

      test('ipv6SocketImpl is ShspSocketWrapper', () {
        expect(migratable.ipv6SocketImpl, isA<ShspSocketWrapper>());
      });
    });

    group('fromWrappers constructor — uses wrappers as-is', () {
      late ShspSocket ipv4Socket;
      late ShspSocketWrapper ipv4Wrapper;
      late DualShspSocketMigratable migratable;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        ipv4Wrapper = ShspSocketWrapper(ipv4Socket);
        migratable = DualShspSocketMigratable.fromWrappers(ipv4Wrapper);
      });

      tearDown(() {
        migratable.close();
      });

      test('ipv4SocketImpl is the exact wrapper passed in', () {
        expect(migratable.ipv4SocketImpl, same(ipv4Wrapper));
      });

      test('ipv6SocketImpl is null when no ipv6 wrapper provided', () {
        expect(migratable.ipv6SocketImpl, isNull);
      });
    });

    group('fromWrappers constructor — with both wrappers', () {
      late ShspSocket ipv4Socket;
      late ShspSocket ipv6Socket;
      late ShspSocketWrapper ipv4Wrapper;
      late ShspSocketWrapper ipv6Wrapper;
      late DualShspSocketMigratable migratable;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        ipv6Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        ipv4Wrapper = ShspSocketWrapper(ipv4Socket);
        ipv6Wrapper = ShspSocketWrapper(ipv6Socket);
        migratable = DualShspSocketMigratable.fromWrappers(ipv4Wrapper, ipv6Wrapper);
      });

      tearDown(() {
        migratable.close();
      });

      test('ipv4SocketImpl is exact ipv4Wrapper', () {
        expect(migratable.ipv4SocketImpl, same(ipv4Wrapper));
      });

      test('ipv6SocketImpl is exact ipv6Wrapper', () {
        expect(migratable.ipv6SocketImpl, same(ipv6Wrapper));
      });
    });

    // ── migrateSocketIpv4 ────────────────────────────────────────────────────

    group('migrateSocketIpv4', () {
      late ShspSocket originalIpv4;
      late DualShspSocketMigratable migratable;

      setUp(() async {
        originalIpv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        migratable = DualShspSocketMigratable(originalIpv4);
      });

      tearDown(() {
        if (!migratable.isClosed) migratable.close();
      });

      test('migrates to new IPv4 socket (localPort changes)', () async {
        final oldPort = migratable.ipv4Socket.localPort;
        final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });

        migratable.migrateSocketIpv4(newSocket);

        expect(migratable.ipv4Socket.localPort, equals(newSocket.localPort));
        expect(migratable.ipv4Socket.localPort, isNot(equals(oldPort)));
      });

      test('ipv4SocketImpl remains a ShspSocketWrapper after migration', () async {
        final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });

        migratable.migrateSocketIpv4(newSocket);

        expect(migratable.ipv4SocketImpl, isA<ShspSocketWrapper>());
      });

      test('auto-wraps ipv4SocketImpl if not already a ShspSocketWrapper', () async {
        // Force ipv4SocketImpl to a raw ShspSocket (bypassing the constructor wrapper)
        final rawSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!rawSocket.isClosed) rawSocket.close(); });
        migratable.ipv4SocketImpl = rawSocket;
        expect(migratable.ipv4SocketImpl, isNot(isA<ShspSocketWrapper>()));

        final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });

        // Should auto-wrap and migrate without throwing
        expect(() => migratable.migrateSocketIpv4(newSocket), returnsNormally);
        expect(migratable.ipv4SocketImpl, isA<ShspSocketWrapper>());
      });
    });

    // ── migrateSocketIpv6 ────────────────────────────────────────────────────

    group('migrateSocketIpv6 — ipv6 was null', () {
      late DualShspSocketMigratable migratable;

      setUp(() async {
        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        migratable = DualShspSocketMigratable(ipv4);
        expect(migratable.ipv6SocketImpl, isNull);
      });

      tearDown(() {
        if (!migratable.isClosed) migratable.close();
      });

      test('creates a ShspSocketWrapper for the new IPv6 socket', () async {
        final newIpv6 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newIpv6.isClosed) newIpv6.close(); });

        migratable.migrateSocketIpv6(newIpv6);

        expect(migratable.ipv6SocketImpl, isNotNull);
        expect(migratable.ipv6SocketImpl, isA<ShspSocketWrapper>());
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
      late ShspSocket originalIpv6;
      late DualShspSocketMigratable migratable;

      setUp(() async {
        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        originalIpv6 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        migratable = DualShspSocketMigratable(ipv4, originalIpv6);
      });

      tearDown(() {
        if (!migratable.isClosed) migratable.close();
      });

      test('migrates to new IPv6 socket (localPort changes)', () async {
        final oldPort = migratable.ipv6Socket!.localPort;
        final newIpv6 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newIpv6.isClosed) newIpv6.close(); });

        migratable.migrateSocketIpv6(newIpv6);

        expect(migratable.ipv6Socket!.localPort, equals(newIpv6.localPort));
        expect(migratable.ipv6Socket!.localPort, isNot(equals(oldPort)));
      });

      test('ipv6SocketImpl remains a ShspSocketWrapper after migration', () async {
        final newIpv6 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newIpv6.isClosed) newIpv6.close(); });

        migratable.migrateSocketIpv6(newIpv6);

        expect(migratable.ipv6SocketImpl, isA<ShspSocketWrapper>());
      });

      test('auto-wraps ipv6SocketImpl if not already a ShspSocketWrapper', () async {
        // Force ipv6SocketImpl to a raw ShspSocket
        final rawIpv6 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!rawIpv6.isClosed) rawIpv6.close(); });
        migratable.ipv6SocketImpl = rawIpv6;
        expect(migratable.ipv6SocketImpl, isNot(isA<ShspSocketWrapper>()));

        final newIpv6 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() { if (!newIpv6.isClosed) newIpv6.close(); });

        expect(() => migratable.migrateSocketIpv6(newIpv6), returnsNormally);
        expect(migratable.ipv6SocketImpl, isA<ShspSocketWrapper>());
      });
    });
  });
}
