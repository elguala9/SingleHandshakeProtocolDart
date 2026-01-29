import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp_implementations/shsp_instance/shsp_instance.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:shsp_types/shsp_types.dart';

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
      socketA = await ShspSocket.bind(address, 9300);
      socketB = await ShspSocket.bind(address, 9301);
      peerInfoA = PeerInfo(address: address, port: 9300);
      peerInfoB = PeerInfo(address: address, port: 9301);
      instanceA = ShspInstance(remotePeer: peerInfoB, socket: socketA);
      instanceB = ShspInstance(remotePeer: peerInfoA, socket: socketB);
    });

    tearDown(() async {
      socketA.close();
      socketB.close();
    });

    test('Initial handshake and open flags are false', () {
      expect(instanceA.handshake, isFalse); // handshake deve essere false all'inizio per A
      expect(instanceA.open, isFalse); // open deve essere false all'inizio per A
      expect(instanceB.handshake, isFalse); // handshake deve essere false all'inizio per B
      expect(instanceB.open, isFalse); // open deve essere false all'inizio per B
    });

    test('Handshake sets handshake flags', () async {
      // Simula handshake da B verso A
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));
      expect(instanceA.handshake, isTrue, reason: 'A should have received handshake'); // handshake deve essere true dopo handshake ricevuto
      //expect(instanceA.open, isTrue, reason: 'A should be open after handshake'); // open deve essere true dopo handshake
      // Ora A invia handshake a B
      instanceA.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));
      expect(instanceB.handshake, isTrue, reason: 'B should have received handshake'); // handshake deve essere true dopo handshake ricevuto
      //expect(instanceB.open, isTrue, reason: 'B should be open after handshake'); // open deve essere true dopo handshake
    });

    test('Handshake sets open flags', () async {
      // Simula handshake da B verso A
      instanceA.sendHandshake();
      instanceB.sendHandshake();
      
      await Future.delayed(const Duration(milliseconds: 500));
      instanceA.sendHandshake();
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));
      expect(instanceA.open, isTrue, reason: 'A should be open after handshake'); // open deve essere true dopo handshake
      // Ora A invia handshake a B
      expect(instanceB.open, isTrue, reason: 'B should be open after handshake'); // open deve essere true dopo handshake
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
    });

    test('Closing flag is true after closing message', () async {
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
    });

    test('Open and handshake remain unchanged on keep-alive', () async {
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 100));
      final prevHandshake = instanceA.handshake;
      final prevOpen = instanceA.open;
      instanceB.keepAlive();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(instanceA.handshake, equals(prevHandshake)); // handshake non deve cambiare dopo keep-alive
      expect(instanceA.open, equals(prevOpen)); // open non deve cambiare dopo keep-alive
    });

  });
}
