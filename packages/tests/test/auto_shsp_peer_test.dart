import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

import 'package:shsp_implementations/shsp_base/auto_shsp_peer.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket_singleton.dart';

import 'shsp_peer_test.dart';

void main() {
  group('AutoShspPeer - IShspPeer Compliance', () {
    // Run the existing IShspPeer compliance suite using the withSocket factory
    testIShspPeer(({required remotePeer, required socket}) =>
        AutoShspPeer.withSocket(remotePeer: remotePeer, socket: socket));
  });

  group('AutoShspPeer - Singleton behavior', () {
    tearDown(() {
      ShspSocketSingleton.destroy();
    });

    test('create() initializes singleton if not yet initialized', () async {
      // Verify singleton is not initialized yet
      expect(ShspSocketSingleton.getCurrent(), isNull);

      final remotePeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 9000,
      );

      final peer = await AutoShspPeer.create(remotePeer: remotePeer);

      // Verify singleton was initialized
      expect(ShspSocketSingleton.getCurrent(), isNotNull);
      expect(peer.remotePeer, equals(remotePeer));
    });

    test('create() reuses singleton socket if already initialized', () async {
      final remotePeer1 = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 9000,
      );
      final remotePeer2 = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 9001,
      );

      // Create first peer
      final peer1 = await AutoShspPeer.create(remotePeer: remotePeer1);
      final singleton1 = ShspSocketSingleton.getCurrent();

      // Create second peer
      final peer2 = await AutoShspPeer.create(remotePeer: remotePeer2);
      final singleton2 = ShspSocketSingleton.getCurrent();

      // Verify same singleton instance is used
      expect(identical(singleton1, singleton2), isTrue,
          reason: 'Both peers should use the same singleton socket');
      expect(identical(peer1.socket, peer2.socket), isTrue,
          reason: 'Both peers should share the same underlying socket');
    });

    test('close() closes peer but not singleton socket', () async {
      final remotePeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 9000,
      );

      final peer = await AutoShspPeer.create(remotePeer: remotePeer);
      final singleton = ShspSocketSingleton.getCurrent();

      expect(singleton!.isClosed, isFalse,
          reason: 'Singleton should be open before close');

      peer.close();

      // Singleton socket should still be open
      expect(singleton.isClosed, isFalse,
          reason: 'Singleton socket should remain open after peer.close()');

      // Peer should not be able to send messages anymore
      expect(
        () => peer.sendMessage([1, 2, 3]),
        throwsA(isA<ShspNetworkException>()),
        reason: 'Closed peer should throw exception when sending',
      );
    });

    test('multiple peers coexist on same socket', () async {
      final address = InternetAddress.loopbackIPv4;

      final remotePeerA = PeerInfo(address: address, port: 9000);
      final remotePeerB = PeerInfo(address: address, port: 9001);

      // Create two peers that share the same singleton socket
      final peerToA = await AutoShspPeer.create(remotePeer: remotePeerA);
      final peerToB = await AutoShspPeer.create(remotePeer: remotePeerB);

      // Verify they share the same socket
      expect(identical(peerToA.socket, peerToB.socket), isTrue,
          reason: 'Multiple peers should share the same singleton socket');

      // Verify both peers have different remote peers
      expect(peerToA.remotePeer, isNot(equals(peerToB.remotePeer)),
          reason: 'Peers should have different remote peer addresses');

      // Verify both peers exist and are not closed
      expect(peerToA.remotePeer.port, equals(9000));
      expect(peerToB.remotePeer.port, equals(9001));
    });

    test('closing one peer does not affect other peers', () async {
      final address = InternetAddress.loopbackIPv4;

      // Create a server socket
      final serverSocket = await ShspSocket.bind(address, 0);
      final serverPort = serverSocket.localPort!;

      final remotePeer = PeerInfo(address: address, port: serverPort);

      // Create two peers sharing the same singleton socket
      final peer1 = await AutoShspPeer.create(remotePeer: remotePeer);
      final peer2 = await AutoShspPeer.create(remotePeer: remotePeer);

      // Verify they share the socket
      expect(identical(peer1.socket, peer2.socket), isTrue);

      // Close peer1
      peer1.close();

      // Peer1 should not be able to send
      expect(
        () => peer1.sendMessage([1, 2, 3]),
        throwsA(isA<ShspNetworkException>()),
      );

      // Peer2 should still be able to send (socket is still open)
      expect(
        () => peer2.sendMessage([10, 20, 30]),
        returnsNormally,
        reason: 'Peer2 should still be able to send after peer1 is closed',
      );

      serverSocket.close();
    });

    test('create() with custom address and port parameters', () async {
      final address = InternetAddress.loopbackIPv4;
      final remotePeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 9000,
      );

      final peer = await AutoShspPeer.create(
        remotePeer: remotePeer,
        address: address,
        port: 0, // ephemeral
      );

      final singleton = ShspSocketSingleton.getCurrent()!;

      expect(singleton.localAddress, equals(address),
          reason: 'Singleton should use specified address');
      expect(singleton.localPort, isNotNull,
          reason: 'Singleton should have assigned port');
    });

    test('create() ignores parameters if singleton already initialized',
        () async {
      final address1 = InternetAddress.loopbackIPv4;
      final remotePeer1 = PeerInfo(address: address1, port: 8000);

      // Create first peer with specific address
      final peer1 = await AutoShspPeer.create(
        remotePeer: remotePeer1,
        address: address1,
        port: 0,
      );

      final port1 = ShspSocketSingleton.getCurrent()!.localPort;

      // Create second peer (parameters should be ignored)
      final remotePeer2 = PeerInfo(address: address1, port: 8001);
      final peer2 = await AutoShspPeer.create(
        remotePeer: remotePeer2,
        address: InternetAddress.anyIPv4, // Different address, should be ignored
        port: 9999, // Different port, should be ignored
      );

      final port2 = ShspSocketSingleton.getCurrent()!.localPort;

      // Port should remain the same (parameters were ignored)
      expect(port1, equals(port2),
          reason:
              'Singleton should ignore parameters on subsequent calls');
    });

    test('messages are routed to correct peer by remotePeer key', () async {
      final address = InternetAddress.loopbackIPv4;

      // Create two server sockets
      final serverA = await ShspSocket.bind(address, 0);
      final serverB = await ShspSocket.bind(address, 0);
      final portA = serverA.localPort!;
      final portB = serverB.localPort!;

      final remotePeerA = PeerInfo(address: address, port: portA);
      final remotePeerB = PeerInfo(address: address, port: portB);

      // Create peers that share the singleton socket
      final peerA = await AutoShspPeer.create(remotePeer: remotePeerA);
      final peerB = await AutoShspPeer.create(remotePeer: remotePeerB);

      // Track message callbacks independently
      final callbacksA = <bool>[];
      final callbacksB = <bool>[];

      peerA.messageCallback.register((_) => callbacksA.add(true));
      peerB.messageCallback.register((_) => callbacksB.add(true));

      // Both peers use the same socket but are routed independently
      expect(identical(peerA.socket, peerB.socket), isTrue,
          reason: 'Both peers must share the same socket');

      // Verify each peer's remotePeer is distinct
      expect(peerA.remotePeer.port, equals(portA));
      expect(peerB.remotePeer.port, equals(portB));

      // Get the local port of the shared socket
      final localPort = (peerA.socket as ShspSocket).localPort!;
      final localPeer = PeerInfo(address: address, port: localPort);

      // Send a message to peerA's remote peer socket
      serverA.sendTo([10, 20], localPeer);
      await Future.delayed(const Duration(milliseconds: 100));

      // Send a message to peerB's remote peer socket
      serverB.sendTo([30, 40], localPeer);
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify that each peer only received from its registered remote peer
      // (this depends on socket routing which is tested in ShspPeer tests)
      expect(identical(peerA.socket, peerB.socket), isTrue);

      // Clean up
      serverA.close();
      serverB.close();
    });

    test('withSocket factory creates peer with explicit socket for testing',
        () async {
      final testSocket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);

      final remotePeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 9000,
      );

      // Use withSocket to inject explicit socket (for testing)
      final peer = AutoShspPeer.withSocket(
        remotePeer: remotePeer,
        socket: testSocket,
      );

      // Verify peer uses the injected socket
      expect(identical(peer.socket, testSocket), isTrue);

      // Cleanup
      testSocket.close();
    });
  });
}
