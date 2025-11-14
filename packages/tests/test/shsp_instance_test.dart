import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_implementations/src/shsp_instance.dart';
import 'package:shsp_implementations/src/shsp_socket.dart';

void main() {
  group('IShspInstance', () {
    late IShspSocket socketA;
    late IShspSocket socketB;
    late PeerInfo peerInfoA;
    late PeerInfo peerInfoB;
    late IShspInstance instanceA;
    late IShspInstance instanceB;

    setUp(() async {
      final address = InternetAddress.loopbackIPv4;
      socketA = await ShspSocket.bind(address, 9200);
      socketB = await ShspSocket.bind(address, 9201);
      peerInfoA = PeerInfo(address: address, port: 9200);
      peerInfoB = PeerInfo(address: address, port: 9201);
      instanceA = ShspInstance(remotePeer: peerInfoB, socket: socketA);
      instanceB = ShspInstance(remotePeer: peerInfoA, socket: socketB);
    });

    tearDown(() {
      socketA.close();
      socketB.close();
    });

    test('handshake message sets handshake and open', () async {
      expect(instanceA.handshake, isFalse);
      expect(instanceA.open, isFalse);
      instanceB.sendMessage([0x01]);
      await Future.delayed(Duration(milliseconds: 200));
      expect(instanceA.handshake, isTrue);
      expect(instanceA.open, isTrue);
    });

    test('closing message sets closing', () async {
      expect(instanceA.closing, isFalse);
      instanceB.sendMessage([0x02]);
      await Future.delayed(Duration(milliseconds: 200));
      expect(instanceA.closing, isTrue);
    });

    test('closed message sets open to false', () async {
      // Simula handshake per portare open a true
      instanceB.sendMessage([0x01]);
      await Future.delayed(Duration(milliseconds: 100));
      expect(instanceA.open, isTrue);
      instanceB.sendMessage([0x03]);
      await Future.delayed(Duration(milliseconds: 100));
      expect(instanceA.open, isFalse);
    });

    test('keep-alive message does not change state', () async {
      final prevHandshake = instanceA.handshake;
      final prevClosing = instanceA.closing;
      final prevOpen = instanceA.open;
      instanceB.sendMessage([0x04]);
      await Future.delayed(Duration(milliseconds: 200));
      expect(instanceA.handshake, equals(prevHandshake));
      expect(instanceA.closing, equals(prevClosing));
      expect(instanceA.open, equals(prevOpen));
    });

    test('user message triggers callback', () async {
      final userMsg = [42, 99];
      bool received = false;
      instanceA.setMessageCallback((msg, info) {
        received = true;
        expect(msg, equals(userMsg));
      });
      instanceB.sendMessage(userMsg);
      await Future.delayed(Duration(milliseconds: 200));
      expect(received, isTrue);
    });
  });
}
