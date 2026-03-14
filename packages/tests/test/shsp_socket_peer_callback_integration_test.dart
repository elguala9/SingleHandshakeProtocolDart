import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

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

    // Port variables (will be assigned by OS)
    late int principalPort;
    late int peerPort1;
    late int peerPort2;
    late int peerPort3;
    late int peerPort4;

    const message1 = 'msg_from_peer_1';
    const message2 = 'msg_from_peer_2';
    const message3 = 'msg_from_peer_3';
    const message4 = 'msg_from_peer_4';

    setUp(() async {
      final address = InternetAddress.loopbackIPv4;

      // Use ephemeral ports (0) to avoid conflicts when tests run in parallel
      principalSocket = await ShspSocket.bind(address, 0);
      peerSocket1 = await ShspSocket.bind(address, 0);
      peerSocket2 = await ShspSocket.bind(address, 0);
      peerSocket3 = await ShspSocket.bind(address, 0);
      peerSocket4 = await ShspSocket.bind(address, 0);

      // Read actual ports assigned by OS
      principalPort = principalSocket.localPort!;
      peerPort1 = peerSocket1.localPort!;
      peerPort2 = peerSocket2.localPort!;
      peerPort3 = peerSocket3.localPort!;
      peerPort4 = peerSocket4.localPort!;

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

      principalPeer1.messageCallback.register((info) {
        print(
            'principalPeer1 callback: from port=${info.port}');
        expect(info.address, principalInfo.address);
        expect(info.port, peerPort1);
        if (!completer1.isCompleted) completer1.complete();
      });
      principalPeer2.messageCallback.register((info) {
        print(
            'principalPeer2 callback: from port=${info.port}');
        expect(info.address, principalInfo.address);
        expect(info.port, peerPort2);
        if (!completer2.isCompleted) completer2.complete();
      });
      principalPeer3.messageCallback.register((info) {
        print(
            'principalPeer3 callback: from port=${info.port}');
        expect(info.address, principalInfo.address);
        expect(info.port, peerPort3);
        if (!completer3.isCompleted) completer3.complete();
      });
      principalPeer4.messageCallback.register((info) {
        print(
            'principalPeer4 callback: from port=${info.port}');
        expect(info.address, principalInfo.address);
        expect(info.port, peerPort4);
        if (!completer4.isCompleted) completer4.complete();
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
