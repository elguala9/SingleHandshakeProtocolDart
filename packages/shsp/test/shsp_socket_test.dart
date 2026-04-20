import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('ShspSocket', () {
    group('bind', () {
      late ShspSocket socket;

      tearDown(() {
        if (!socket.isClosed) socket.close();
      });

      test('bind returns a ShspSocket instance', () async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        expect(socket, isA<ShspSocket>());
      });

      test('localPort is non-null and > 0 after bind', () async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        expect(socket.localPort, isNotNull);
        expect(socket.localPort, greaterThan(0));
      });

      test('localAddress is non-null after bind', () async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        expect(socket.localAddress, isNotNull);
      });

      test('isClosed is false after bind', () async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        expect(socket.isClosed, isFalse);
      });

      test('bind throws ShspValidationException for port -1', () async {
        expect(
          () async => ShspSocket.bind(InternetAddress.anyIPv4, -1),
          throwsA(isA<ShspValidationException>()),
        );
      });

      test('bind throws ShspValidationException for port 65536', () async {
        expect(
          () async => ShspSocket.bind(InternetAddress.anyIPv4, 65536),
          throwsA(isA<ShspValidationException>()),
        );
      });

      test('bindDefault(ipv6: false) returns IPv4 socket with non-null localPort', () async {
        socket = await ShspSocket.bindDefault(ipv6: false);
        expect(socket, isA<ShspSocket>());
        expect(socket.localPort, isNotNull);
        expect(socket.localPort, greaterThan(0));
      });
    });

    group('fromRaw', () {
      late ShspSocket socket;

      tearDown(() {
        if (!socket.isClosed) socket.close();
      });

      test('fromRaw wraps existing RawDatagramSocket', () async {
        final rawSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(rawSocket.close);

        socket = ShspSocket.fromRaw(rawSocket);
        expect(socket, isA<ShspSocket>());
      });

      test('localPort matches the raw socket port', () async {
        final rawSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(rawSocket.close);

        socket = ShspSocket.fromRaw(rawSocket);
        expect(socket.localPort, equals(rawSocket.port));
      });

      test('localAddress matches the raw socket address', () async {
        final rawSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(rawSocket.close);

        socket = ShspSocket.fromRaw(rawSocket);
        expect(socket.localAddress.address, equals(rawSocket.address.address));
      });

      test('isClosed is false', () async {
        final rawSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(rawSocket.close);

        socket = ShspSocket.fromRaw(rawSocket);
        expect(socket.isClosed, isFalse);
      });
    });

    group('close / isClosed', () {
      test('isClosed becomes true after close()', () async {
        final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        socket.close();
        expect(socket.isClosed, isTrue);
      });

      test('close() is idempotent — calling twice does not throw', () async {
        final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        socket.close();
        expect(socket.close, returnsNormally);
      });
    });

    group('sendTo / message delivery', () {
      late ShspSocket sender;
      late ShspSocket receiver;

      tearDown(() {
        if (!sender.isClosed) sender.close();
        if (!receiver.isClosed) receiver.close();
      });

      test('sendTo delivers datagram to a second socket on loopback', () async {
        sender = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        receiver = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);

        var callbackFired = false;
        final senderPeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: sender.localPort!);
        final receiverPeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: receiver.localPort!);

        receiver.setMessageCallback(senderPeer, (record) {
          callbackFired = true;
        });

        sender.sendTo([0x00, 0x41], receiverPeer);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(callbackFired, isTrue);
      });
    });

    group('extractProfile / applyProfile round-trip', () {
      late ShspSocket socket;

      tearDown(() {
        if (!socket.isClosed) socket.close();
      });

      test('extractProfile on empty socket returns empty messageListeners', () async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final profile = socket.extractProfile();
        expect(profile.messageListeners, isEmpty);
      });

      test('after setMessageCallback, extractProfile contains that key', () async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
        socket.setMessageCallback(peer, (record) {});

        final profile = socket.extractProfile();
        expect(profile.messageListeners, isNotEmpty);
      });

      test('applyProfile adds listeners to a fresh socket', () async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
        socket.setMessageCallback(peer, (record) {});

        final profile = socket.extractProfile();
        final socket2 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(socket2.close);

        socket2.applyProfile(profile);
        expect(socket2.extractProfile().messageListeners, isNotEmpty);
      });

      test('applyProfile is additive, does not overwrite existing callbacks', () async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final peer1 = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
        socket.setMessageCallback(peer1, (record) {});

        final profile = socket.extractProfile();
        final peer2 = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8081);
        socket.setMessageCallback(peer2, (record) {});

        socket.applyProfile(profile);
        // After apply, both callbacks should be present
        expect(socket.extractProfile().messageListeners, isNotEmpty);
      });
    });
  });
}
