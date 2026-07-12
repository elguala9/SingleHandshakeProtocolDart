import 'dart:io';

import 'package:shsp/shsp.dart';
import 'package:test/test.dart';

void main() {
  group('DualShspSocketAuto', () {
    group('construction', () {
      late ShspSocket ipv4Socket;
      late DualShspSocketAuto autoSocket;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        autoSocket = DualShspSocketAuto(Sockets(ipv4SocketImpl: ipv4Socket));
      });

      tearDown(() {
        autoSocket.close();
      });

      test('implements IDualShspSocketAuto', () {
        expect(autoSocket, isA<IDualShspSocketAuto>());
      });

      test('implements IDualShspSocketMigratable', () {
        expect(autoSocket, isA<IDualShspSocketMigratable>());
      });

      test('implements IDualShspSocket', () {
        expect(autoSocket, isA<IDualShspSocket>());
      });

      test('ipv4SocketImpl is ShspSocketWrapper', () {
        expect(autoSocket.ipv4SocketImpl, isA<ShspSocketWrapper>());
      });

      test('ipv6SocketImpl is null when no ipv6 socket provided', () {
        expect(autoSocket.ipv6SocketImpl, isNull);
      });

      test('construction with empty Sockets', () {
        final empty = DualShspSocketAuto(Sockets());
        expect(empty.ipv4SocketImpl, isNull);
        expect(empty.ipv6SocketImpl, isNull);
      });
    });

    group('create', () {
      test('creates a DualShspSocketAuto with at least one socket', () async {
        final auto = await DualShspSocketAuto.create();
        addTearDown(auto.close);

        expect(auto, isA<DualShspSocketAuto>());
        expect(auto.ipv4Socket, isA<IShspSocket>());
        expect(auto.ipv4Socket!.isClosed, isFalse);
      });
    });

    group('construction with ipv6', () {
      late ShspSocket ipv4Socket;
      late ShspSocket? ipv6Socket;
      late DualShspSocketAuto autoSocket;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        ipv6Socket = await ShspSocket.bindIfPossible(InternetAddress.anyIPv6, 0);
        autoSocket = DualShspSocketAuto(Sockets(ipv4SocketImpl: ipv4Socket));
        if (ipv6Socket != null) {
          autoSocket.ipv6SocketImpl = ShspSocketWrapper(ipv6Socket!);
        }
      });

      tearDown(() {
        autoSocket.close();
      });

      test('ipv4SocketImpl is ShspSocketWrapper', () {
        expect(autoSocket.ipv4SocketImpl, isA<ShspSocketWrapper>());
      });

      test('ipv6SocketImpl is ShspSocketWrapper when ipv6 is available', () {
        if (ipv6Socket == null) return;
        expect(autoSocket.ipv6SocketImpl, isA<ShspSocketWrapper>());
      });
    });

    group('fromWrappers', () {
      late ShspSocket ipv4Socket;
      late ShspSocketWrapper ipv4Wrapper;
      late DualShspSocketAuto autoSocket;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        ipv4Wrapper = ShspSocketWrapper(ipv4Socket);
        autoSocket = DualShspSocketAuto.fromWrappers(ipv4Wrapper: ipv4Wrapper);
      });

      tearDown(() {
        autoSocket.close();
      });

      test('ipv4SocketImpl is the exact wrapper passed in', () {
        expect(autoSocket.ipv4SocketImpl, same(ipv4Wrapper));
      });
    });

    group('refreshSocketIpv4', () {
      late ShspSocket ipv4Socket;
      late DualShspSocketAuto autoSocket;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        autoSocket = DualShspSocketAuto(Sockets(ipv4SocketImpl: ipv4Socket));
      });

      tearDown(() {
        autoSocket.close();
      });

      test('returns current ipv4 socket synchronously', () {
        final result = autoSocket.refreshSocketIpv4();
        expect(result, isA<IShspSocket>());
      });

      test('socket is still open after async refresh completes', () async {
        autoSocket.refreshSocketIpv4();

        await Future<void>.delayed(const Duration(seconds: 1));

        expect(autoSocket.ipv4Socket!.isClosed, isFalse);
        expect(autoSocket.isClosed, isFalse);
      });

      test('socket port changes after async refresh completes', () async {
        final oldPort = autoSocket.ipv4Socket!.localPort;
        autoSocket.refreshSocketIpv4();

        await Future<void>.delayed(const Duration(seconds: 1));

        expect(autoSocket.ipv4Socket!.isClosed, isFalse);
        expect(autoSocket.ipv4Socket!.localPort, isNot(equals(oldPort)));
      });

      test('throws StateError when no ipv4 socket bound', () {
        final empty = DualShspSocketAuto(Sockets());
        addTearDown(empty.close);
        expect(empty.refreshSocketIpv4, throwsStateError);
      });
    });

    group('refreshSocketIpv6', () {
      late ShspSocket ipv4Socket;
      late ShspSocket? ipv6Socket;
      late DualShspSocketAuto autoSocket;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        ipv6Socket = await ShspSocket.bindIfPossible(InternetAddress.anyIPv6, 0);
        autoSocket = DualShspSocketAuto(Sockets(ipv4SocketImpl: ipv4Socket));
        if (ipv6Socket != null) {
          autoSocket.ipv6SocketImpl = ShspSocketWrapper(ipv6Socket!);
        }
      });

      tearDown(() {
        autoSocket.close();
      });

      test('returns current ipv6 socket synchronously when available', () {
        if (ipv6Socket == null) return;
        final result = autoSocket.refreshSocketIpv6();
        expect(result, isA<IShspSocket>());
      });

      test('socket is still open after async refresh completes when ipv6 available', () async {
        if (ipv6Socket == null) return;
        autoSocket.refreshSocketIpv6();

        await Future<void>.delayed(const Duration(seconds: 1));

        expect(autoSocket.ipv6Socket!.isClosed, isFalse);
      });

      test('socket port changes after async refresh completes when ipv6 available', () async {
        if (ipv6Socket == null) return;
        final oldPort = autoSocket.ipv6Socket!.localPort;
        autoSocket.refreshSocketIpv6();

        await Future<void>.delayed(const Duration(seconds: 1));

        expect(autoSocket.ipv6Socket!.isClosed, isFalse);
        expect(autoSocket.ipv6Socket!.localPort, isNot(equals(oldPort)));
      });

      test('throws StateError when no ipv6 socket bound', () async {
        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final noIpv6 = DualShspSocketAuto(Sockets(ipv4SocketImpl: ipv4));
        addTearDown(noIpv6.close);
        expect(noIpv6.refreshSocketIpv6, throwsStateError);
      });
    });

    group('refreshSockets', () {
      late ShspSocket ipv4Socket;
      late DualShspSocketAuto autoSocket;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        autoSocket = DualShspSocketAuto(Sockets(ipv4SocketImpl: ipv4Socket));
      });

      tearDown(() {
        autoSocket.close();
      });

      test('returns Sockets with ipv4 socket', () {
        final sockets = autoSocket.refreshSockets();
        expect(sockets, isA<Sockets>());
        expect(sockets.ipv4SocketImpl, isA<IShspSocket>());
      });

      test('sockets are still open after async refresh completes', () async {
        autoSocket.refreshSockets();

        await Future<void>.delayed(const Duration(seconds: 1));

        expect(autoSocket.ipv4Socket!.isClosed, isFalse);
        expect(autoSocket.isClosed, isFalse);
      });

      test('socket port changes after async refresh completes', () async {
        final oldPort = autoSocket.ipv4Socket!.localPort;
        autoSocket.refreshSockets();

        await Future<void>.delayed(const Duration(seconds: 1));

        expect(autoSocket.ipv4Socket!.isClosed, isFalse);
        expect(autoSocket.ipv4Socket!.localPort, isNot(equals(oldPort)));
      });

      test('refreshSockets with both sockets', () async {
        final ipv6 = await ShspSocket.bindIfPossible(InternetAddress.anyIPv6, 0);
        if (ipv6 == null) return;
        addTearDown(() {
          if (!ipv6.isClosed) ipv6.close();
        });
        autoSocket.ipv6SocketImpl = ShspSocketWrapper(ipv6);

        autoSocket.refreshSockets();

        await Future<void>.delayed(const Duration(seconds: 1));

        expect(autoSocket.ipv4Socket!.isClosed, isFalse);
        expect(autoSocket.ipv6Socket!.isClosed, isFalse);
      });
    });

    group('inherited migration', () {
      late ShspSocket ipv4Socket;
      late DualShspSocketAuto autoSocket;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        autoSocket = DualShspSocketAuto(Sockets(ipv4SocketImpl: ipv4Socket));
      });

      tearDown(() {
        autoSocket.close();
      });

      test('migrateSocketIpv4 from parent works', () async {
        final oldPort = autoSocket.ipv4Socket!.localPort;
        final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!newSocket.isClosed) newSocket.close();
        });

        autoSocket.migrateSocketIpv4(newSocket);

        expect(autoSocket.ipv4Socket!.localPort, equals(newSocket.localPort));
        expect(autoSocket.ipv4Socket!.localPort, isNot(equals(oldPort)));
      });

      test('old socket is closed after migration', () async {
        final oldWrapper = autoSocket.ipv4SocketImpl;
        final oldPort = autoSocket.ipv4Socket!.localPort;
        final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final newPort = newSocket.localPort;
        addTearDown(() {
          if (!newSocket.isClosed) newSocket.close();
        });

        autoSocket.migrateSocketIpv4(newSocket);

        expect(autoSocket.ipv4Socket!.localPort, equals(newPort));
        expect(autoSocket.ipv4Socket!.localPort, isNot(equals(oldPort)));
        if (oldWrapper is ShspSocketWrapper) {
          expect(newSocket.isClosed, isFalse);
        }
      });
    });
  });
}
