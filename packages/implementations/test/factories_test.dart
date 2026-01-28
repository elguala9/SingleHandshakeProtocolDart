import 'dart:io';

import 'package:test/test.dart';
import 'package:shsp_implementations/factory/shsp_factories.dart';
import 'package:shsp_implementations/factory/factory_inputs.dart';
import 'package:shsp_implementations/utility/utility_factories.dart';
import 'package:shsp_types/shsp_types.dart';

void main() {
  group('Factories', () {
    final sockets = <RawDatagramSocket>[];

    setUp(() async {
      sockets.clear();
    });

    tearDown(() {
      for (final s in sockets) {
        try {
          s.close();
        } catch (_) {}
      }
      sockets.clear();
    });

    test('ShspSocketFactory.createFromSocket and createFromConfig', () async {
      final raw1 = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      sockets.add(raw1);
      final msgMap = MessageCallbackMapFactory.create();
      final socket = ShspSocketFactory.create(raw1, msgMap);
      expect(socket, isNotNull);
      final raw2 = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      sockets.add(raw2);
      final input = ShspSocketInput(socket: raw2, messageCallbacks: msgMap);
      final socket2 = ShspSocketFactory.createFromConfig(input);
      expect(socket2, isNotNull);
    });

    test('ShspPeerFactory create from inputs', () async {
      final peerInfo = PeerInfo(address: InternetAddress.loopbackIPv4, port: 12345);
      final rawA = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      sockets.add(rawA);
      final peer = ShspPeerFactory.create(remotePeer: peerInfo, socket: ShspSocketFactory.createFromSocket(rawA));
      expect(peer, isNotNull);
      final rawB = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      sockets.add(rawB);
      final peerInput = ShspPeerInput(remotePeer: peerInfo, rawSocket: rawB);
      final peer2 = ShspPeerFactory.createFromConfig(peerInput);
      expect(peer2, isNotNull);
    });

    test('ShspInstanceFactory create from inputs', () async {
      final peerInfo = PeerInfo(address: InternetAddress.loopbackIPv4, port: 12345);
      final raw1 = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      sockets.add(raw1);
      final instance = ShspInstanceFactory.createFromSocket(remotePeer: peerInfo, rawSocket: raw1, keepAliveSeconds: 5);
      expect(instance, isNotNull);
      final raw2 = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      sockets.add(raw2);
      final instanceInput = ShspInstanceInput(remotePeer: peerInfo, rawSocket: raw2, keepAliveSeconds: 5);
      final instance2 = ShspInstanceFactory.createFromConfig(instanceInput);
      expect(instance2, isNotNull);
    });

    test('ShspFactory createFromConfig', () async {
      final peerInfo = PeerInfo(address: InternetAddress.loopbackIPv4, port: 54321);
      final raw = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      sockets.add(raw);
      final cfg = ShspInput(socket: raw, peerInfo: peerInfo);
      final shsp = ShspFactory.createFromConfig(cfg);
      expect(shsp, isNotNull);
    });
  });
}
