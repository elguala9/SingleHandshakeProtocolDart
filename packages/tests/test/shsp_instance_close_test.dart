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





    test('Closing flag is true after closing message and cannot send message', () async {
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
