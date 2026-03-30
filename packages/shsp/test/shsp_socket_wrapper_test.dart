import 'dart:io';
import 'package:shsp/shsp.dart';
import 'package:test/test.dart';

void main() {
  group('ShspSocketWrapper', () {
    late ShspSocket innerSocket;
    late ShspSocketWrapper wrapper;

    setUp(() async {
      innerSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      wrapper = ShspSocketWrapper(innerSocket);
    });

    tearDown(() {
      if (!wrapper.isClosed) wrapper.close();
    });

    // ── Construction ─────────────────────────────────────────────────────────

    test('throws ArgumentError when wrapping another ShspSocketWrapper', () {
      expect(
        () => ShspSocketWrapper(wrapper),
        throwsArgumentError,
      );
    });

    test('implements IShspSocketWrapper', () {
      expect(wrapper, isA<IShspSocketWrapper>());
    });

    // ── Delegation ───────────────────────────────────────────────────────────

    test('localPort delegates to inner socket', () {
      expect(wrapper.localPort, equals(innerSocket.localPort));
    });

    test('localAddress delegates to inner socket', () {
      expect(wrapper.localAddress, equals(innerSocket.localAddress));
    });

    test('isClosed is false initially', () {
      expect(wrapper.isClosed, isFalse);
    });

    test('isClosed is true after close', () {
      wrapper.close();
      expect(wrapper.isClosed, isTrue);
    });

    test('socket getter returns underlying RawDatagramSocket', () {
      expect(wrapper.socket, isA<RawDatagramSocket>());
      expect(wrapper.socket, same(innerSocket.socket));
    });

    test('address delegates to inner socket', () {
      expect(wrapper.address, equals(innerSocket.address));
    });

    test('port delegates to inner socket', () {
      expect(wrapper.port, equals(innerSocket.port));
    });

    test('compressionCodec delegates to inner socket', () {
      expect(wrapper.compressionCodec, same(innerSocket.compressionCodec));
    });

    test('extractProfile delegates to inner socket', () {
      final profile = wrapper.extractProfile();
      expect(profile, isA<ShspSocketProfile>());
    });

    // ── Callback storage and forwarding ──────────────────────────────────────

    test('setListeningCallback is applied to inner socket and fires', () async {
      var count = 0;
      wrapper.setListeningCallback(() => count++);
      innerSocket.onListening.call(null);
      await Future.microtask(() {});
      expect(count, equals(1));
    });

    test('setCloseCallback is applied to inner socket and fires', () async {
      var called = false;
      wrapper.setCloseCallback(() => called = true);
      innerSocket.onClose.call(null);
      await Future.microtask(() {});
      expect(called, isTrue);
    });

    test('setErrorCallback is applied to inner socket and fires', () async {
      dynamic captured;
      wrapper.setErrorCallback((err) => captured = err);
      innerSocket.onError.call('test-error');
      await Future.microtask(() {});
      expect(captured, equals('test-error'));
    });

    // ── migrateSocket ────────────────────────────────────────────────────────

    test('migrateSocket switches delegation to new socket (localPort)', () async {
      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });

      expect(wrapper.localPort, equals(innerSocket.localPort));
      wrapper.migrateSocket(newSocket);
      expect(wrapper.localPort, equals(newSocket.localPort));
    });

    test('migrateSocket: new socket has different port from old (sanity)', () async {
      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });
      expect(innerSocket.localPort, isNot(equals(newSocket.localPort)));
    });

    test('migrateSocket re-applies stored listeningCallback to new socket', () async {
      var count = 0;
      wrapper.setListeningCallback(() => count++);

      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });

      wrapper.migrateSocket(newSocket);

      // After migration, firing onListening on the new socket should invoke the callback
      newSocket.onListening.call(null);
      await Future.microtask(() {});
      expect(count, equals(1));
    });

    test('migrateSocket re-applies stored closeCallback to new socket', () async {
      var called = false;
      wrapper.setCloseCallback(() => called = true);

      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });

      wrapper.migrateSocket(newSocket);

      newSocket.onClose.call(null);
      await Future.microtask(() {});
      expect(called, isTrue);
    });

    test('migrateSocket re-applies stored errorCallback to new socket', () async {
      dynamic captured;
      wrapper.setErrorCallback((err) => captured = err);

      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });

      wrapper.migrateSocket(newSocket);

      newSocket.onError.call('migrated-error');
      await Future.microtask(() {});
      expect(captured, equals('migrated-error'));
    });

    test('migrateSocket transfers message callbacks (profile) to new socket', () async {
      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
      wrapper.setMessageCallback(peer, (_) {});

      final profileBefore = innerSocket.extractProfile();
      expect(profileBefore.messageListeners, isNotEmpty);

      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });

      wrapper.migrateSocket(newSocket);

      final profileAfter = newSocket.extractProfile();
      expect(profileAfter.messageListeners, isNotEmpty);
    });

    test('migrateSocket: no callbacks stored — does not crash', () async {
      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() { if (!newSocket.isClosed) newSocket.close(); });
      expect(() => wrapper.migrateSocket(newSocket), returnsNormally);
    });

    // ── setMessageCallback / removeMessageCallback ────────────────────────────

    test('setMessageCallback delegates to inner socket', () {
      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 1234);
      wrapper.setMessageCallback(peer, (_) {});
      final profile = innerSocket.extractProfile();
      expect(profile.messageListeners, isNotEmpty);
    });

    test('removeMessageCallback delegates to inner socket', () {
      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 5678);
      void cb(MessageRecord _) {}
      wrapper.setMessageCallback(peer, cb);
      final removed = wrapper.removeMessageCallback(peer, cb);
      expect(removed, isTrue);
    });
  });
}
