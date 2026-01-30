import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:shsp_implementations/shsp_base/shsp_peer.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:shsp_types/shsp_types.dart';

void main() {
  group('SHSPSocket + SHSPPeer callback integration', () {
    late ShspSocket principalSocket;
    late ShspSocket peerSocket1;
    late ShspSocket peerSocket2;
    late ShspSocket peerSocket3;
    late ShspSocket peerSocket4;
    late PeerInfo principalInfo;
    late PeerInfo peerInfo1;
    late PeerInfo peerInfo2;
    late PeerInfo peerInfo3;
    late PeerInfo peerInfo4;
    late ShspPeer principalPeer1;
    late ShspPeer principalPeer2;
    late ShspPeer principalPeer3;
    late ShspPeer principalPeer4;
    late ShspPeer peer1;
    late ShspPeer peer2;
    late ShspPeer peer3;
    late ShspPeer peer4;

    const principalPort = 9500;
    const peerPort1 = 9601;
    const peerPort2 = 9602;
    const peerPort3 = 9603;
    const peerPort4 = 9604;

    const message1 = 'msg_from_peer_1';
    const message2 = 'msg_from_peer_2';
    const message3 = 'msg_from_peer_3';
    const message4 = 'msg_from_peer_4';

    setUp(() async {
      final address = InternetAddress.loopbackIPv4;
      principalSocket = await ShspSocket.bind(address, principalPort);
      peerSocket1 = await ShspSocket.bind(address, peerPort1);
      peerSocket2 = await ShspSocket.bind(address, peerPort2);
      peerSocket3 = await ShspSocket.bind(address, peerPort3);
      peerSocket4 = await ShspSocket.bind(address, peerPort4);
      principalInfo = PeerInfo(address: address, port: principalPort);
      peerInfo1 = PeerInfo(address: address, port: peerPort1);
      peerInfo2 = PeerInfo(address: address, port: peerPort2);
      peerInfo3 = PeerInfo(address: address, port: peerPort3);
      peerInfo4 = PeerInfo(address: address, port: peerPort4);
      principalPeer1 = ShspPeer(remotePeer: peerInfo1, socket: principalSocket);
      principalPeer2 = ShspPeer(remotePeer: peerInfo2, socket: principalSocket);
      principalPeer3 = ShspPeer(remotePeer: peerInfo3, socket: principalSocket);
      principalPeer4 = ShspPeer(remotePeer: peerInfo4, socket: principalSocket);
      peer1 = ShspPeer(remotePeer: principalInfo, socket: peerSocket1);
      peer2 = ShspPeer(remotePeer: principalInfo, socket: peerSocket2);
      peer3 = ShspPeer(remotePeer: principalInfo, socket: peerSocket3);
      peer4 = ShspPeer(remotePeer: principalInfo, socket: peerSocket4);
    });

    test(
        'Secondary peers send messages to both principals, both receive correctly',
        () async {
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();
      final completer3 = Completer<void>();
      final completer4 = Completer<void>();

      principalPeer1.setMessageCallback((msg, info) {
        print(
            'principalPeer1 callback: msg=${String.fromCharCodes(msg)} from port=${info.port}');
        if (message1 == String.fromCharCodes(msg)) {
          expect(info.address, principalInfo.address);
          expect(info.port, peerPort1);
          if (!completer1.isCompleted) completer1.complete();
        } else {
          fail(
              'PrincipalPeer1 received unexpected message: ${String.fromCharCodes(msg)}');
        }
      });
      principalPeer2.setMessageCallback((msg, info) {
        print(
            'principalPeer2 callback: msg=${String.fromCharCodes(msg)} from port=${info.port}');
        if (message2 == String.fromCharCodes(msg)) {
          expect(info.address, principalInfo.address);
          expect(info.port, peerPort2);
          if (!completer2.isCompleted) completer2.complete();
        } else {
          fail(
              'PrincipalPeer2 received unexpected message: ${String.fromCharCodes(msg)}');
        }
      });
      principalPeer3.setMessageCallback((msg, info) {
        print(
            'principalPeer3 callback: msg=${String.fromCharCodes(msg)} from port=${info.port}');
        if (message3 == String.fromCharCodes(msg)) {
          expect(info.address, principalInfo.address);
          expect(info.port, peerPort3);
          if (!completer3.isCompleted) completer3.complete();
        } else {
          fail(
              'PrincipalPeer3 received unexpected message: ${String.fromCharCodes(msg)}');
        }
      });
      principalPeer4.setMessageCallback((msg, info) {
        print(
            'principalPeer4 callback: msg=${String.fromCharCodes(msg)} from port=${info.port}');
        if (message4 == String.fromCharCodes(msg)) {
          expect(info.address, principalInfo.address);
          expect(info.port, peerPort4);
          if (!completer4.isCompleted) completer4.complete();
        } else {
          fail(
              'PrincipalPeer4 received unexpected message: ${String.fromCharCodes(msg)}');
        }
      });

      // Invio dei messaggi dai peer secondari
      peer1.sendMessage(message1.codeUnits);
      peer2.sendMessage(message2.codeUnits);
      peer3.sendMessage(message3.codeUnits);
      peer4.sendMessage(message4.codeUnits);

      // Attendi che tutte le callback siano chiamate (o timeout)
      await Future.wait([
        completer1.future.timeout(const Duration(seconds: 5),
            onTimeout: () => fail('Timeout attesa callback 1')),
        completer2.future.timeout(const Duration(seconds: 5),
            onTimeout: () => fail('Timeout attesa callback 2')),
        completer3.future.timeout(const Duration(seconds: 5),
            onTimeout: () => fail('Timeout attesa callback 3')),
        completer4.future.timeout(const Duration(seconds: 5),
            onTimeout: () => fail('Timeout attesa callback 4')),
      ]);

      peer1.sendMessage(message1.codeUnits);
      peer2.sendMessage(message2.codeUnits);
      peer3.sendMessage(message3.codeUnits);
      peer4.sendMessage(message4.codeUnits);
    });
  });
}
