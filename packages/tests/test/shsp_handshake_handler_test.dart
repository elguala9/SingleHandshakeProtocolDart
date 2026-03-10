import 'package:test/test.dart';
import 'package:shsp/src/impl/instance/shsp_handshake_handler.dart';
import 'package:shsp/src/impl/instance/shsp_instance.dart';
import 'package:shsp/src/impl/socket/shsp_socket.dart';
import 'package:shsp/shsp.dart';
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

      // Use ephemeral ports (0) to avoid conflicts when tests run in parallel
      socketA = await ShspSocket.bind(address, 0);
      socketB = await ShspSocket.bind(address, 0);

      // Read actual ports assigned by OS
      final portA = socketA.localPort!;
      final portB = socketB.localPort!;

      peerInfoA = PeerInfo(address: address, port: portA);
      peerInfoB = PeerInfo(address: address, port: portB);
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
              timeoutMs: 10000, intervalOfSendingHandshakeMs: 50),
          null);
      final futureB = ShspHandshakeHandler.handshakeInstance(
          instanceB,
          const ShspHandshakeHandlerOptions(
              timeoutMs: 10000, intervalOfSendingHandshakeMs: 50),
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
            timeoutMs: 10000, intervalOfSendingHandshakeMs: 50),
        (_) => calledA = true,
      );
      final futureB = ShspHandshakeHandler.handshakeInstance(
        instanceB,
        const ShspHandshakeHandlerOptions(
            timeoutMs: 10000, intervalOfSendingHandshakeMs: 50),
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
