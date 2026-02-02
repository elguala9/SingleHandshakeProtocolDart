import 'package:test/test.dart';
import 'package:shsp_implementations/shsp_instance/shsp_handshake_handler.dart';
import 'package:shsp_implementations/shsp_instance/shsp_instance.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:shsp_types/shsp_types.dart';
import 'dart:io';

void main() {
  group('ShspHandshakeHandler', () {
    late ShspSocket socketA;
    late ShspSocket socketB;
    late PeerInfo peerInfoA;
    late PeerInfo peerInfoB;
    late ShspInstance instanceA;
    late ShspInstance instanceB;

    setUp(() async {
      final address = InternetAddress.loopbackIPv4;
      socketA = await ShspSocket.bind(address, 9400);
      socketB = await ShspSocket.bind(address, 9401);
      peerInfoA = PeerInfo(address: address, port: 9400);
      peerInfoB = PeerInfo(address: address, port: 9401);
      instanceA = ShspInstance(remotePeer: peerInfoB, socket: socketA);
      instanceB = ShspInstance(remotePeer: peerInfoA, socket: socketB);
    });

    tearDown(() async {
      socketA.close();
      socketB.close();
    });

    test('handshakeInstance opens connection', () async {
      // Avvia handshake su entrambi
      final futureA = ShspHandshakeHandler.handshakeInstance(
          instanceA,
          const ShspHandshakeHandlerOptions(
              timeoutMs: 2000, intervalOfSendingHandshakeMs: 200),
          null);
      final futureB = ShspHandshakeHandler.handshakeInstance(
          instanceB,
          const ShspHandshakeHandlerOptions(
              timeoutMs: 2000, intervalOfSendingHandshakeMs: 200),
          null);
      final resultA = await futureA;
      final resultB = await futureB;
      expect(resultA.open, isTrue);
      expect(resultB.open, isTrue);
    });

    test('handshakeInstance chiama onOpen', () async {
      bool calledA = false;
      bool calledB = false;
      final futureA = ShspHandshakeHandler.handshakeInstance(
        instanceA,
        const ShspHandshakeHandlerOptions(
            timeoutMs: 2000, intervalOfSendingHandshakeMs: 200),
        (_) => calledA = true,
      );
      final futureB = ShspHandshakeHandler.handshakeInstance(
        instanceB,
        const ShspHandshakeHandlerOptions(
            timeoutMs: 2000, intervalOfSendingHandshakeMs: 200),
        (_) => calledB = true,
      );
      await futureA;
      await futureB;
      expect(calledA, isTrue);
      expect(calledB, isTrue);
    });

    test('handshakeInstance timeout se non risponde', () async {
      // Solo uno fa handshake, l'altro no
      final futureA = ShspHandshakeHandler.handshakeInstance(
          instanceA,
          const ShspHandshakeHandlerOptions(
              timeoutMs: 1000, intervalOfSendingHandshakeMs: 200),
          null);
      final resultA = await futureA;
      expect(resultA.open, isFalse);
    });
  });
}
