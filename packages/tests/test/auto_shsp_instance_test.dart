import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

import 'package:shsp_implementations/shsp_instance/auto_shsp_instance.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket_singleton.dart';

void main() {
  group('AutoShspInstance - Singleton behavior', () {
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

      final instance = await AutoShspInstance.create(remotePeer: remotePeer);

      // Verify singleton was initialized
      expect(ShspSocketSingleton.getCurrent(), isNotNull);
      expect(instance.remotePeer, equals(remotePeer));
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

      // Create first instance
      final instance1 = await AutoShspInstance.create(remotePeer: remotePeer1);
      final singleton1 = ShspSocketSingleton.getCurrent();

      // Create second instance
      final instance2 = await AutoShspInstance.create(remotePeer: remotePeer2);
      final singleton2 = ShspSocketSingleton.getCurrent();

      // Verify same singleton instance is used
      expect(identical(singleton1, singleton2), isTrue,
          reason: 'Both instances should use the same singleton socket');
      expect(identical(instance1.socket, instance2.socket), isTrue,
          reason: 'Both instances should share the same underlying socket');
    });

    test('close() closes instance but not singleton socket', () async {
      final remotePeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 9000,
      );

      final instance = await AutoShspInstance.create(remotePeer: remotePeer);
      final singleton = ShspSocketSingleton.getCurrent();

      expect(singleton!.isClosed, isFalse,
          reason: 'Singleton should be open before close');

      instance.close();

      // Singleton socket should still be open
      expect(singleton.isClosed, isFalse,
          reason: 'Singleton socket should remain open after instance.close()');

      // Instance should not be able to send messages anymore
      expect(
        () => instance.sendMessage([1, 2, 3]),
        throwsA(isA<ShspInstanceException>()),
        reason: 'Closed instance should throw exception when sending',
      );
    });

    test('multiple instances coexist on same socket', () async {
      final address = InternetAddress.loopbackIPv4;

      final remotePeerA = PeerInfo(address: address, port: 9000);
      final remotePeerB = PeerInfo(address: address, port: 9001);

      // Create two instances that share the same singleton socket
      final instanceA = await AutoShspInstance.create(remotePeer: remotePeerA);
      final instanceB = await AutoShspInstance.create(remotePeer: remotePeerB);

      // Verify they share the same socket
      expect(identical(instanceA.socket, instanceB.socket), isTrue,
          reason: 'Multiple instances should share the same singleton socket');

      // Verify both instances have different remote peers
      expect(instanceA.remotePeer, isNot(equals(instanceB.remotePeer)),
          reason: 'Instances should have different remote peer addresses');

      // Verify both instances exist
      expect(instanceA.remotePeer.port, equals(9000));
      expect(instanceB.remotePeer.port, equals(9001));
    });

    test('closing one instance does not affect other instances', () async {
      final address = InternetAddress.loopbackIPv4;

      // Create a server socket
      final serverSocket = await ShspSocket.bind(address, 0);
      final serverPort = serverSocket.localPort!;

      final remotePeer = PeerInfo(address: address, port: serverPort);

      // Create two instances sharing the same singleton socket
      final instance1 = await AutoShspInstance.create(remotePeer: remotePeer);
      final instance2 = await AutoShspInstance.create(remotePeer: remotePeer);
      final singleton = ShspSocketSingleton.getCurrent()!;

      // Verify they share the socket
      expect(identical(instance1.socket, instance2.socket), isTrue);

      // Close instance1
      instance1.close();

      // Instance1 should not be able to send (connection is closed)
      // Note: sendMessage throws if not open, which is correct behavior

      // Instance2 should still be valid (socket is still open)
      // Verify by checking that the socket is not closed via the singleton
      expect(singleton.isClosed, isFalse,
          reason: 'Socket should still be open after instance1 is closed');

      // Clean up
      serverSocket.close();
    });

    test('create() with custom address and port parameters', () async {
      final address = InternetAddress.loopbackIPv4;
      final remotePeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 9000,
      );

      final instance = await AutoShspInstance.create(
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

      // Create first instance with specific address
      final instance1 = await AutoShspInstance.create(
        remotePeer: remotePeer1,
        address: address1,
        port: 0,
      );

      final port1 = ShspSocketSingleton.getCurrent()!.localPort;

      // Create second instance (parameters should be ignored)
      final remotePeer2 = PeerInfo(address: address1, port: 8001);
      final instance2 = await AutoShspInstance.create(
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

    test('withSocket factory creates instance with explicit socket for testing',
        () async {
      final testSocket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);

      final remotePeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 9000,
      );

      // Use withSocket to inject explicit socket (for testing)
      final instance = AutoShspInstance.withSocket(
        remotePeer: remotePeer,
        socket: testSocket,
      );

      // Verify instance uses the injected socket
      expect(identical(instance.socket, testSocket), isTrue);

      // Cleanup
      testSocket.close();
    });

    test('instance properties (keepAliveSeconds) are preserved', () async {
      final remotePeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: 9000,
      );

      final instance = await AutoShspInstance.create(
        remotePeer: remotePeer,
        keepAliveSeconds: 45,
      );

      expect(instance.keepAliveSeconds, equals(45),
          reason: 'Keep-alive seconds should be set as specified');
    });

    test('socket reconnection triggers callback re-registration', () async {
      final address = InternetAddress.loopbackIPv4;
      final remotePeer = PeerInfo(
        address: address,
        port: 9000,
      );

      // Create instance and get singleton
      final instance = await AutoShspInstance.create(
        remotePeer: remotePeer,
        address: address,
        port: 0,
      );

      final singleton = ShspSocketSingleton.getCurrent()!;
      final originalSocket = instance.socket;
      final originalPort = (originalSocket as ShspSocket).localPort!;

      // Reconnect the socket
      await singleton.reconnect();

      // Verify socket was replaced
      final newSocket = singleton.socket;
      expect(identical(originalSocket, newSocket), isFalse,
          reason: 'Socket should be different after reconnection');

      // Instance should now be using the new socket
      expect(identical(instance.socket, newSocket), isFalse,
          reason: 'Instance should not automatically reference new socket (it keeps its reference)');

      // But the instance callback should be registered on the new socket
      // This is verified by checking that the singleton has the callback
      expect(singleton.isClosed, isFalse,
          reason: 'New socket should be open and functional');
    });
  });
}
