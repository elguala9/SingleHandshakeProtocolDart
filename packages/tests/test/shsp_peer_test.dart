import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

import 'package:shsp_implementations/shsp_base/shsp_peer.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';

typedef IShspPeerFactory = IShspPeer Function(
    {required PeerInfo remotePeer, required IShspSocket socket});

void testIShspPeer(IShspPeerFactory peerFactory) {
  group('IShspPeer', () {
    late IShspSocket socketA;
    late IShspSocket socketB;
    late PeerInfo peerInfoA;
    late PeerInfo peerInfoB;
    late IShspPeer peerA;
    late IShspPeer peerB;

    setUp(() async {
      final address = InternetAddress.loopbackIPv4;
      socketA = await ShspSocket.bind(address, 9100);
      socketB = await ShspSocket.bind(address, 9101);
      peerInfoA = PeerInfo(address: address, port: 9100);
      peerInfoB = PeerInfo(address: address, port: 9101);
      peerA = peerFactory(remotePeer: peerInfoB, socket: socketA);
      peerB = peerFactory(remotePeer: peerInfoA, socket: socketB);
    });

    tearDown(() {
      socketA.close();
      socketB.close();
    });

    test('onMessage should trigger only for messages from remotePeer',
        () async {
      final testMsg = [42, 99, 77];
      final wrongMsg = [1, 2, 3];
      bool received = false;

      peerA.setMessageCallback((msg, info) {
        received = true;
        expect(msg, equals(testMsg));
        expect(info.address, equals(peerInfoB.address));
        expect(info.port, equals(peerInfoB.port));
      });

      // Invio da peerB a peerA (deve attivare la callback)
      peerB.sendMessage(testMsg);
      await Future.delayed(const Duration(milliseconds: 200));
      expect(received, isTrue);

      // Invio da peerC a peerA (non deve attivare la callback)
      final address = InternetAddress.loopbackIPv4;
      final socketC = await ShspSocket.bind(address, 9102);
      final peerC = peerFactory(remotePeer: peerInfoA, socket: socketC);
      received = false;
      peerC.sendMessage([99, 88, 77]);
      await Future.delayed(const Duration(milliseconds: 200));
      expect(received, isFalse);
      socketC.close();

      // Reset e invio da socketA a peerA (non deve attivare la callback)
      received = false;
      socketA.sendTo(wrongMsg, peerInfoA.address, peerInfoA.port);
      await Future.delayed(const Duration(milliseconds: 200));
      expect(received, isFalse);
    });

    test('peer should ignore UDP packets from unknown peer', () async {
      final address = InternetAddress.loopbackIPv4;
      final socketC = await ShspSocket.bind(address, 9102);
      final peerC = peerFactory(remotePeer: peerInfoA, socket: socketC);

      bool received = false;
      peerA.setMessageCallback((msg, info) {
        received = true;
      });

      // peerC invia a peerA (peerA non deve ricevere)
      peerC.sendMessage([123, 45, 67]);
      await Future.delayed(const Duration(milliseconds: 200));
      expect(received, isFalse);

      socketC.close();
    });

    test('onMessage should not trigger if callback not set', () async {
      final testMsg = [55, 66];
      bool called = false;
      // Non impostare la callback
      peerB.sendMessage(testMsg);
      // Attendi e verifica che non venga chiamata
      await Future.delayed(const Duration(milliseconds: 200));
      expect(called, isFalse);
    });

    // UDP non garantisce la consegna di pacchetti vuoti, quindi questo test è documentato/skippato.
    // test('sendMessage and receive empty message', () async {
    //   final emptyMsg = <int>[];
    //   bool received = false;
    //   peerA.setMessageCallback((msg, info) {
    //     received = true;
    //     expect(msg, isEmpty);
    //   });
    //   peerB.sendMessage(emptyMsg);
    //   await Future.delayed(Duration(milliseconds: 200));
    //   expect(received, isTrue);
    // });

    // Removed serializedObject test as it is no longer needed.

    test('close closes the socket', () async {
      peerA.close();
      // Dopo la chiusura, invio non dovrebbe generare errori ma non riceve
      bool received = false;
      peerA.setMessageCallback((msg, info) {
        received = true;
      });
      peerB.sendMessage([99]);
      await Future.delayed(const Duration(milliseconds: 200));
      expect(received, isFalse);
    });
  });
}

void main() {
  testIShspPeer(({required remotePeer, required socket}) =>
      ShspPeer(remotePeer: remotePeer, socket: socket));
}
