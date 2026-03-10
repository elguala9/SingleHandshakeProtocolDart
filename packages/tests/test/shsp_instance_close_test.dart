import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/src/impl/instance/shsp_instance.dart';
import 'package:shsp/src/impl/socket/shsp_socket.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('ShspInstance handshake and open flag', () {
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

    test('Initial handshake and open flags are false', () {
      expect(instanceA.handshake,
          isFalse); // handshake deve essere false all'inizio per A
      expect(
          instanceA.open, isFalse); // open deve essere false all'inizio per A
      expect(instanceB.handshake,
          isFalse); // handshake deve essere false all'inizio per B
      expect(
          instanceB.open, isFalse); // open deve essere false all'inizio per B
    });

    test('Closing flag is true after closing message and cannot send message',
        () async {
      instanceB.sendHandshake();
      instanceA.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));
      instanceB.sendHandshake();
      instanceA.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));
      expect(instanceA.open, isTrue); // open deve essere true dopo handshake
      instanceB.sendClosing();
      await Future.delayed(const Duration(milliseconds: 500));
      expect(instanceB.closing, isTrue);
      expect(instanceA.open, isTrue);

      expect(() => instanceA.sendMessage([1, 2, 3]), throwsException);
      expect(() => instanceB.sendMessage([1, 2, 3]), throwsException);
    });

    test('Open flag is false after closed message', () async {
      instanceB.sendHandshake();
      instanceA.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));
      instanceB.sendHandshake();
      instanceA.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));
      expect(instanceA.open, isTrue); // open deve essere true dopo handshake
      instanceB.sendClosed();
      await Future.delayed(const Duration(milliseconds: 500));
      expect(instanceB.open, isFalse); // open deve tornare false dopo closed
      expect(instanceA.open, isFalse); // open deve tornare false dopo closed
      // if closed i can send message to recreate the connection
      instanceB.sendHandshake();
      instanceA.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));
      instanceB.sendHandshake();
      instanceA.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));
      expect(instanceA.open, isTrue); // open deve essere true dopo handshake
    });
  });
}
