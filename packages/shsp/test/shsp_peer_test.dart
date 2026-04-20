import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('ShspPeer', () {
    group('construction', () {
      late ShspSocket socket;

      tearDown(() {
        if (!socket.isClosed) socket.close();
      });

      test('ShspPeer.create sets remotePeer and socket', () async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
        final shspPeer = ShspPeer.create(remotePeer: peer, socket: socket);
        expect(shspPeer.remotePeer, equals(peer));
        expect(shspPeer.socket, equals(socket));
      });

      test('construction registers message callback on socket for the remote peer key', () async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
        final shspPeer = ShspPeer.create(remotePeer: peer, socket: socket);

        // After construction, the profile should contain the peer callback
        final profile = socket.extractProfile();
        expect(profile.messageListeners.isNotEmpty, isTrue);
      });
    });

    group('sendMessage — validation errors', () {
      late ShspSocket socket;
      late ShspPeer peer;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final remotePeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
        peer = ShspPeer.create(remotePeer: remotePeer, socket: socket);
      });

      tearDown(() {
        if (!socket.isClosed) socket.close();
      });

      test('sendMessage throws ShspValidationException when message is empty', () {
        expect(
          () => peer.sendMessage([]),
          throwsA(isA<ShspValidationException>()),
        );
      });

      test('sendMessage throws ShspValidationException when message exceeds maxMessageSize (65507 bytes)', () {
        final oversized = List<int>.filled(65508, 0x41);
        expect(
          () => peer.sendMessage(oversized),
          throwsA(isA<ShspValidationException>()),
        );
      });

      test('exception field is "message" for empty message', () {
        try {
          peer.sendMessage([]);
        } on ShspValidationException catch (e) {
          expect(e.field, equals('message'));
        }
      });

      test('exception field is "message.length" for oversized message', () {
        final oversized = List<int>.filled(65508, 0x41);
        try {
          peer.sendMessage(oversized);
        } on ShspValidationException catch (e) {
          expect(e.field, equals('message.length'));
        }
      });
    });

    group('sendMessage — peer closed', () {
      late ShspSocket socket;
      late ShspPeer peer;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final remotePeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
        peer = ShspPeer.create(remotePeer: remotePeer, socket: socket);
      });

      tearDown(() {
        if (!socket.isClosed) socket.close();
      });

      test('sendMessage throws ShspNetworkException when peer is closed', () {
        peer.close();
        expect(
          () => peer.sendMessage([0x41]),
          throwsA(isA<ShspNetworkException>()),
        );
      });
    });

    group('sendMessage — successful delivery', () {
      late ShspSocket senderSocket;
      late ShspSocket receiverSocket;
      late ShspPeer sender;
      late ShspPeer receiver;

      setUp(() async {
        senderSocket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        receiverSocket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);

        final senderPeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: senderSocket.localPort!);
        final receiverPeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: receiverSocket.localPort!);

        sender = ShspPeer.create(remotePeer: receiverPeer, socket: senderSocket);
        receiver = ShspPeer.create(remotePeer: senderPeer, socket: receiverSocket);
      });

      tearDown(() {
        if (!senderSocket.isClosed) senderSocket.close();
        if (!receiverSocket.isClosed) receiverSocket.close();
      });

      test('sendMessage delivers data to the remote peer over loopback', () async {
        var callbackFired = false;
        receiver.messageCallback.register((info) {
          callbackFired = true;
        });

        sender.sendMessage([0x41, 0x42]);
        await Future.delayed(Duration(milliseconds: 50));

        expect(callbackFired, isTrue);
      });
    });

    group('close', () {
      late ShspSocket socket;
      late ShspPeer peer;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final remotePeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
        peer = ShspPeer.create(remotePeer: remotePeer, socket: socket);
      });

      tearDown(() {
        if (!socket.isClosed) socket.close();
      });

      test('close() sets no further messages delivered to callback', () async {
        var callbackFired = false;
        peer.messageCallback.register((info) {
          callbackFired = true;
        });

        peer.close();

        // Attempting sendMessage after close should throw, not call callback
        expect(
          () => peer.sendMessage([0x41]),
          throwsA(isA<ShspNetworkException>()),
        );
      });

      test('close() is idempotent — calling twice does not throw', () {
        peer.close();
        expect(() {
          peer.close();
        }, returnsNormally);
      });

      test('close() removes message callback from socket (extractProfile is empty)', () {
        final profileBefore = socket.extractProfile();
        expect(profileBefore.messageListeners.isNotEmpty, isTrue);

        peer.close();

        final profileAfter = socket.extractProfile();
        expect(profileAfter.messageListeners.isEmpty, isTrue);
      });
    });
  });
}
