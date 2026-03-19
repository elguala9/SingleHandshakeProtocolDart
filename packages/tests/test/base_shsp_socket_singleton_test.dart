import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('BaseShspSocketSingleton - Shared Behavior Tests', () {
    tearDown(() {
      ShspSocketSingleton.destroy();
      DualShspSocketSingleton.destroy();
    });

    group('ShspSocketSingleton (IPv4-only implementation)', () {
      test('provides IPv4-only socket', () async {
        final singleton = await ShspSocketSingleton.getInstance();

        expect(
          singleton.socket,
          isA<ShspSocket>(),
          reason: 'Should provide ShspSocket for IPv4-only',
        );
        expect(
          singleton.socket,
          isNot(isA<DualShspSocket>()),
          reason: 'Should not be wrapped in DualShspSocket',
        );
      });

      test('reconnect creates new IPv4 socket', () async {
        final singleton = await ShspSocketSingleton.getInstance();
        singleton.socket;

        await singleton.reconnect();

        final newSocket = singleton.socket;
        expect(newSocket, isNotNull);
        // Note: We can't do identity check as it's a different object
        expect(
          singleton.isClosed,
          isFalse,
          reason: 'Socket should be open after reconnect',
        );
      });

      test('setSocket with ShspSocket stores it directly', () async {
        final singleton = await ShspSocketSingleton.getInstance();

        final newShspSocket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
          GZipCodec(),
        );
        singleton.setSocket(newShspSocket);

        expect(
          singleton.socket,
          isA<ShspSocket>(),
          reason: 'Should be ShspSocket, not wrapped',
        );
      });
    });

    group('DualShspSocketSingleton (IPv4+IPv6 implementation)', () {
      test('provides dual-stack socket', () async {
        final singleton = await DualShspSocketSingleton.getInstance();

        expect(
          singleton.socket,
          isA<DualShspSocket>(),
          reason: 'Should provide DualShspSocket for dual-stack',
        );
      });

      test('reconnect creates new dual socket', () async {
        final singleton = await DualShspSocketSingleton.getInstance();

        await singleton.reconnect();

        expect(
          singleton.socket,
          isA<DualShspSocket>(),
          reason: 'Reconnected socket should be DualShspSocket',
        );
        expect(
          singleton.isClosed,
          isFalse,
          reason: 'Socket should be open after reconnect',
        );
      });

      test('setSocket wraps ShspSocket in DualShspSocket', () async {
        final singleton = await DualShspSocketSingleton.getInstance();

        final newShspSocket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
          GZipCodec(),
        );
        singleton.setSocket(newShspSocket);

        expect(
          singleton.socket,
          isA<DualShspSocket>(),
          reason: 'Should be wrapped in DualShspSocket',
        );
      });
    });

    group('Shared Profile Management', () {
      test('extractProfile works for IPv4-only', () async {
        final singleton = await ShspSocketSingleton.getInstance();
        final address = InternetAddress.loopbackIPv4;
        final peerInfo = PeerInfo(address: address, port: 5555);

        singleton.socket.setMessageCallback(peerInfo, (record) {});

        final profile = singleton.getProfile();
        expect(profile.messageListeners.isNotEmpty, isTrue);
      });

      test('extractProfile works for dual-stack', () async {
        final singleton = await DualShspSocketSingleton.getInstance();
        final address = InternetAddress.loopbackIPv4;
        final peerInfo = PeerInfo(address: address, port: 5555);

        singleton.socket.setMessageCallback(peerInfo, (record) {});

        final profile = singleton.getProfile();
        expect(profile.messageListeners.isNotEmpty, isTrue);
      });

      test('applyProfile restores callbacks for IPv4-only', () async {
        final singleton = await ShspSocketSingleton.getInstance();
        final address = InternetAddress.loopbackIPv4;
        final peerInfo = PeerInfo(address: address, port: 5555);

        // Setup and extract
        singleton.socket.setMessageCallback(peerInfo, (record) {});
        final profile = singleton.getProfile();

        // Reconnect and apply
        await singleton.reconnect();
        singleton.socket.applyProfile(profile);

        // Verify
        final newProfile = singleton.getProfile();
        expect(newProfile.messageListeners.isNotEmpty, isTrue);
      });

      test('applyProfile restores callbacks for dual-stack', () async {
        final singleton = await DualShspSocketSingleton.getInstance();
        final address = InternetAddress.loopbackIPv4;
        final peerInfo = PeerInfo(address: address, port: 5555);

        // Setup and extract
        singleton.socket.setMessageCallback(peerInfo, (record) {});
        final profile = singleton.getProfile();

        // Reconnect and apply
        await singleton.reconnect();
        singleton.socket.applyProfile(profile);

        // Verify
        final newProfile = singleton.getProfile();
        expect(newProfile.messageListeners.isNotEmpty, isTrue);
      });
    });

    group('Shared Socket Replacement', () {
      test('setSocket preserves callbacks for IPv4-only', () async {
        final singleton = await ShspSocketSingleton.getInstance();
        final address = InternetAddress.loopbackIPv4;
        final peerInfo = PeerInfo(address: address, port: 6666);

        // Register callback
        singleton.socket.setMessageCallback(peerInfo, (record) {});
        final profile1 = singleton.getProfile();

        // Replace socket
        final newSocket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
          GZipCodec(),
        );
        singleton.setSocket(newSocket);

        // Verify callbacks preserved
        final profile2 = singleton.getProfile();
        expect(
          profile2.messageListeners.length,
          equals(profile1.messageListeners.length),
        );
      });

      test('setSocket preserves callbacks for dual-stack', () async {
        final singleton = await DualShspSocketSingleton.getInstance();
        final address = InternetAddress.loopbackIPv4;
        final peerInfo = PeerInfo(address: address, port: 6666);

        // Register callback
        singleton.socket.setMessageCallback(peerInfo, (record) {});
        final profile1 = singleton.getProfile();

        // Replace socket
        final newSocket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
          GZipCodec(),
        );
        singleton.setSocket(newSocket);

        // Verify callbacks preserved
        final profile2 = singleton.getProfile();
        expect(
          profile2.messageListeners.length,
          equals(profile1.messageListeners.length),
        );
      });

      test('setSocketRaw preserves callbacks for IPv4-only', () async {
        final singleton = await ShspSocketSingleton.getInstance();
        final address = InternetAddress.loopbackIPv4;
        final peerInfo = PeerInfo(address: address, port: 7777);

        // Register callback
        singleton.socket.setMessageCallback(peerInfo, (record) {});
        final profile1 = singleton.getProfile();

        // Replace with raw socket
        final rawSocket = await RawDatagramSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        singleton.setSocketRaw(rawSocket);

        // Verify callbacks preserved
        final profile2 = singleton.getProfile();
        expect(
          profile2.messageListeners.length,
          equals(profile1.messageListeners.length),
        );
      });

      test('setSocketRaw preserves callbacks for dual-stack', () async {
        final singleton = await DualShspSocketSingleton.getInstance();
        final address = InternetAddress.loopbackIPv4;
        final peerInfo = PeerInfo(address: address, port: 7777);

        // Register callback
        singleton.socket.setMessageCallback(peerInfo, (record) {});
        final profile1 = singleton.getProfile();

        // Replace with raw socket
        final rawSocket = await RawDatagramSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        singleton.setSocketRaw(rawSocket);

        // Verify callbacks preserved
        final profile2 = singleton.getProfile();
        expect(
          profile2.messageListeners.length,
          equals(profile1.messageListeners.length),
        );
      });
    });

    group('Shared Socket State Properties', () {
      test('isClosed reflects current socket state for IPv4-only', () async {
        final singleton = await ShspSocketSingleton.getInstance();

        expect(singleton.isClosed, isFalse);

        singleton.socket.close();
        expect(singleton.isClosed, isTrue);
      });

      test('isClosed reflects current socket state for dual-stack', () async {
        final singleton = await DualShspSocketSingleton.getInstance();

        expect(singleton.isClosed, isFalse);

        singleton.socket.close();
        expect(singleton.isClosed, isTrue);
      });

      test('localAddress getter works for IPv4-only', () async {
        final address = InternetAddress.loopbackIPv4;
        final singleton = await ShspSocketSingleton.getInstance(
          address: address,
        );

        expect(singleton.localAddress, equals(address));
      });

      test('localAddress getter works for dual-stack', () async {
        final address = InternetAddress.loopbackIPv4;
        final singleton = await DualShspSocketSingleton.getInstance(
          address: address,
        );

        expect(singleton.localAddress, equals(address));
      });

      test('localPort getter works for IPv4-only', () async {
        final singleton = await ShspSocketSingleton.getInstance();

        expect(singleton.localPort, isNotNull);
        expect(singleton.localPort, greaterThan(0));
      });

      test('localPort getter works for dual-stack', () async {
        final singleton = await DualShspSocketSingleton.getInstance();

        expect(singleton.localPort, isNotNull);
        expect(singleton.localPort, greaterThan(0));
      });

      test('compressionCodec getter works for IPv4-only', () async {
        final codec = GZipCodec();
        final singleton = await ShspSocketSingleton.getInstance(
          compressionCodec: codec,
        );

        expect(singleton.compressionCodec, same(codec));
      });

      test('compressionCodec getter works for dual-stack', () async {
        final codec = GZipCodec();
        final singleton = await DualShspSocketSingleton.getInstance(
          compressionCodec: codec,
        );

        expect(singleton.compressionCodec, same(codec));
      });
    });

    group('Shared Callback Notifications', () {
      test('socketChangedCallback fires for IPv4-only reconnect', () async {
        final singleton = await ShspSocketSingleton.getInstance();
        var called = false;

        singleton.socketChangedCallback.register((_) {
          called = true;
        });

        await singleton.reconnect();

        expect(called, isTrue);
      });

      test('socketChangedCallback fires for dual-stack reconnect', () async {
        final singleton = await DualShspSocketSingleton.getInstance();
        var called = false;

        singleton.socketChangedCallback.register((_) {
          called = true;
        });

        await singleton.reconnect();

        expect(called, isTrue);
      });

      test('socketChangedCallback fires for IPv4-only setSocket', () async {
        final singleton = await ShspSocketSingleton.getInstance();
        var called = false;

        singleton.socketChangedCallback.register((_) {
          called = true;
        });

        final newSocket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
          GZipCodec(),
        );
        singleton.setSocket(newSocket);

        expect(called, isTrue);
      });

      test('socketChangedCallback fires for dual-stack setSocket', () async {
        final singleton = await DualShspSocketSingleton.getInstance();
        var called = false;

        singleton.socketChangedCallback.register((_) {
          called = true;
        });

        final newSocket = await ShspSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
          GZipCodec(),
        );
        singleton.setSocket(newSocket);

        expect(called, isTrue);
      });

      test(
        'socketChangedCallback fires for IPv4-only restoreProfile',
        () async {
          final singleton = await ShspSocketSingleton.getInstance();
          final profile = singleton.getProfile();
          var called = false;

          singleton.socketChangedCallback.register((_) {
            called = true;
          });

          await singleton.restoreProfile(profile);

          expect(called, isTrue);
        },
      );

      test(
        'socketChangedCallback fires for dual-stack restoreProfile',
        () async {
          final singleton = await DualShspSocketSingleton.getInstance();
          final profile = singleton.getProfile();
          var called = false;

          singleton.socketChangedCallback.register((_) {
            called = true;
          });

          await singleton.restoreProfile(profile);

          expect(called, isTrue);
        },
      );
    });

    group('Singleton Lifecycle', () {
      test('IPv4-only singleton is null before getInstance', () {
        expect(ShspSocketSingleton.getCurrent(), isNull);
      });

      test('dual-stack singleton is null before getInstance', () {
        expect(DualShspSocketSingleton.getCurrent(), isNull);
      });

      test('IPv4-only singleton persists after getInstance', () async {
        await ShspSocketSingleton.getInstance();
        expect(ShspSocketSingleton.getCurrent(), isNotNull);
      });

      test('dual-stack singleton persists after getInstance', () async {
        await DualShspSocketSingleton.getInstance();
        expect(DualShspSocketSingleton.getCurrent(), isNotNull);
      });

      test('IPv4-only singleton is null after destroy', () async {
        await ShspSocketSingleton.getInstance();
        ShspSocketSingleton.destroy();
        expect(ShspSocketSingleton.getCurrent(), isNull);
      });

      test('dual-stack singleton is null after destroy', () async {
        await DualShspSocketSingleton.getInstance();
        DualShspSocketSingleton.destroy();
        expect(DualShspSocketSingleton.getCurrent(), isNull);
      });
    });
  });
}
