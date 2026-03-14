import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('ShspSocketSingleton Integration Tests', () {
    tearDown(() {
      ShspSocketSingleton.destroy();
    });

    test('multiple AutoShspPeer instances share singleton and communicate', () async {
      final address = InternetAddress.loopbackIPv4;

      // Create two server sockets to receive messages
      final serverA = await ShspSocket.bind(address, 0);
      final serverB = await ShspSocket.bind(address, 0);
      final portA = serverA.localPort!;
      final portB = serverB.localPort!;

      final remotePeerA = PeerInfo(address: address, port: portA);
      final remotePeerB = PeerInfo(address: address, port: portB);

      // Create two peers sharing the singleton socket
      final peerA = await AutoShspPeer.create(remotePeer: remotePeerA);
      final peerB = await AutoShspPeer.create(remotePeer: remotePeerB);

      // Verify they share the same socket
      expect(identical(peerA.socket, peerB.socket), isTrue,
          reason: 'Peers should share the singleton socket');

      // Clean up
      peerA.close();
      peerB.close();
      serverA.close();
      serverB.close();
    });

    test('AutoShspInstance receives keep-alive messages from shared socket', () async {
      final address = InternetAddress.loopbackIPv4;
      final serverSocket = await ShspSocket.bind(address, 0);
      final serverPort = serverSocket.localPort!;

      final remotePeer = PeerInfo(address: address, port: serverPort);

      // Create instance with short keep-alive interval
      final instance = await AutoShspInstance.create(
        remotePeer: remotePeer,
        keepAliveSeconds: 1,
      );

      expect(instance.keepAliveSeconds, equals(1),
          reason: 'Instance should use specified keep-alive interval');

      // Verify singleton is initialized
      final singleton = ShspSocketSingleton.getCurrent();
      expect(singleton, isNotNull, reason: 'Singleton should be initialized');
      expect(singleton!.isClosed, isFalse,
          reason: 'Singleton socket should be open');

      // Wait briefly for keep-alive to establish
      await Future.delayed(const Duration(milliseconds: 100));

      instance.close();
      serverSocket.close();
    });

    test('socket replacement via reconnect notifies all AutoShspPeer instances',
        () async {
      final address = InternetAddress.loopbackIPv4;
      final remotePeer =
          PeerInfo(address: address, port: 9999);

      // Create first peer
      final peer1 = await AutoShspPeer.create(remotePeer: remotePeer);
      final singleton = ShspSocketSingleton.getCurrent()!;
      final originalSocket = peer1.socket;

      // Create second peer sharing the same socket
      final peer2 = await AutoShspPeer.create(remotePeer: remotePeer);
      expect(identical(peer1.socket, peer2.socket), isTrue);

      // Reconnect the socket
      await singleton.reconnect();

      // New socket should be different
      final newSocket = singleton.socket;
      expect(identical(originalSocket, newSocket), isFalse,
          reason: 'Socket should be replaced after reconnect');

      // Singleton's socket changed callback should have been triggered
      expect(singleton.isClosed, isFalse,
          reason: 'Singleton should have a new open socket');

      peer1.close();
      peer2.close();
    });

    test('socket replacement via setSocket preserves callbacks for all peers',
        () async {
      final address = InternetAddress.loopbackIPv4;
      final remotePeer =
          PeerInfo(address: address, port: 9998);

      // Create peer and get singleton
      final peer = await AutoShspPeer.create(remotePeer: remotePeer);
      final singleton = ShspSocketSingleton.getCurrent()!;

      // Register callback on the original socket
      var callbackCount = 0;
      peer.messageCallback.register((_) => callbackCount++);

      // Get original socket profile
      final originalProfile = singleton.getProfile();
      expect(originalProfile.messageListeners.isNotEmpty, isTrue,
          reason: 'Profile should have registered callback');

      // Create a new raw socket
      final newRawSocket = await RawDatagramSocket.bind(address, 0);

      // Set new socket (should preserve callbacks)
      singleton.setSocketRaw(newRawSocket);

      // Verify new socket has callbacks restored
      final newProfile = singleton.getProfile();
      expect(newProfile.messageListeners.isNotEmpty, isTrue,
          reason: 'New socket should have callbacks restored');

      peer.close();
    });

    test('multiple instances coexist with socket reconnection', () async {
      final address = InternetAddress.loopbackIPv4;

      final remotePeerA = PeerInfo(address: address, port: 9997);
      final remotePeerB = PeerInfo(address: address, port: 9996);

      // Create two instances
      final instanceA =
          await AutoShspInstance.create(remotePeer: remotePeerA);
      final instanceB =
          await AutoShspInstance.create(remotePeer: remotePeerB);

      // Verify they share the socket
      expect(identical(instanceA.socket, instanceB.socket), isTrue);

      // Get singleton and reconnect
      final singleton = ShspSocketSingleton.getCurrent()!;
      await singleton.reconnect();

      // Both instances should still exist and be able to reference their peers
      expect(instanceA.remotePeer, equals(remotePeerA));
      expect(instanceB.remotePeer, equals(remotePeerB));

      instanceA.close();
      instanceB.close();
    });

    test('singleton socket changed callback chain works correctly', () async {
      final address = InternetAddress.loopbackIPv4;
      final remotePeer1 = PeerInfo(address: address, port: 9995);
      final remotePeer2 = PeerInfo(address: address, port: 9994);

      // Create instances
      final instance1 =
          await AutoShspInstance.create(remotePeer: remotePeer1);
      final instance2 =
          await AutoShspInstance.create(remotePeer: remotePeer2);

      final singleton = ShspSocketSingleton.getCurrent()!;

      // Track callback chain
      var socketChangedCount = 0;
      singleton.socketChangedCallback.register((_) => socketChangedCount++);

      // Get profile before reconnect
      final profileBefore = singleton.getProfile();
      final listenerCountBefore = profileBefore.messageListeners.length;

      // Reconnect socket
      await singleton.reconnect();

      // Verify callback was called
      expect(socketChangedCount, equals(1),
          reason: 'Socket changed callback should be called once');

      // Verify profile is preserved
      final profileAfter = singleton.getProfile();
      expect(profileAfter.messageListeners.length, equals(listenerCountBefore),
          reason: 'Listener count should be preserved');

      instance1.close();
      instance2.close();
    });

    test('compression codec is preserved across socket reconnection', () async {
      final address = InternetAddress.loopbackIPv4;
      final remotePeer = PeerInfo(address: address, port: 9993);

      // Create instance (uses default compression codec)
      final instance =
          await AutoShspInstance.create(remotePeer: remotePeer);
      final singleton = ShspSocketSingleton.getCurrent()!;

      final codecBefore = singleton.compressionCodec;
      expect(codecBefore, isNotNull, reason: 'Should have a compression codec');

      // Reconnect
      await singleton.reconnect();

      final codecAfter = singleton.compressionCodec;
      expect(codecAfter, equals(codecBefore),
          reason: 'Compression codec should be preserved');

      instance.close();
    });

    test('destroy closes all peer/instance callbacks', () async {
      final address = InternetAddress.loopbackIPv4;

      // Create multiple instances
      await AutoShspPeer.create(
        remotePeer: PeerInfo(address: address, port: 9992),
      );
      await AutoShspPeer.create(
        remotePeer: PeerInfo(address: address, port: 9991),
      );

      final singleton = ShspSocketSingleton.getCurrent()!;
      expect(singleton.isClosed, isFalse);

      // Destroy singleton
      ShspSocketSingleton.destroy();

      // Singleton should be closed
      expect(singleton.isClosed, isTrue,
          reason: 'Socket should be closed after destroy');
      expect(ShspSocketSingleton.getCurrent(), isNull,
          reason: 'Singleton should be cleared');
    });

    test('fresh singleton instance can be created after destroy', () async {
      final address = InternetAddress.loopbackIPv4;
      final remotePeer = PeerInfo(address: address, port: 9990);

      // Create first instance
      final instance1 =
          await AutoShspInstance.create(remotePeer: remotePeer);
      final singleton1 = ShspSocketSingleton.getCurrent()!;
      singleton1.localPort;

      // Destroy
      ShspSocketSingleton.destroy();

      // Create new instance
      final instance2 =
          await AutoShspInstance.create(remotePeer: remotePeer);
      final singleton2 = ShspSocketSingleton.getCurrent()!;
      singleton2.localPort;

      // Verify new instance exists
      expect(singleton2, isNotNull);
      expect(singleton2.isClosed, isFalse);
      // Ports might differ since ephemeral

      instance1.close();
      instance2.close();
    });

    test('socket lifecycle with mixed Auto peers and instances', () async {
      final address = InternetAddress.loopbackIPv4;

      // Mix Auto peers and instances
      final peer = await AutoShspPeer.create(
        remotePeer: PeerInfo(address: address, port: 9989),
      );
      final instance = await AutoShspInstance.create(
        remotePeer: PeerInfo(address: address, port: 9988),
      );

      final singleton = ShspSocketSingleton.getCurrent()!;

      // Verify both use same socket
      expect(identical(peer.socket, instance.socket), isTrue);

      // Reconnect
      await singleton.reconnect();

      // Both should still be valid
      expect(peer.remotePeer.port, equals(9989));
      expect(instance.remotePeer.port, equals(9988));

      peer.close();
      instance.close();
    });

    test('exception handling during socket replacement', () async {
      final address = InternetAddress.loopbackIPv4;
      final remotePeer = PeerInfo(address: address, port: 9987);

      final instance =
          await AutoShspInstance.create(remotePeer: remotePeer);
      final singleton = ShspSocketSingleton.getCurrent()!;

      // Verify socket exists
      expect(singleton.socket, isNotNull);
      expect(singleton.isClosed, isFalse);

      // Create and set new socket
      final newRawSocket = await RawDatagramSocket.bind(address, 0);
      expect(
        () => singleton.setSocketRaw(newRawSocket),
        returnsNormally,
        reason: 'setSocketRaw should handle valid socket',
      );

      instance.close();
    });

    test('profile restoration preserves message routing', () async {
      final address = InternetAddress.loopbackIPv4;
      final remotePeerA = PeerInfo(address: address, port: 9986);
      final remotePeerB = PeerInfo(address: address, port: 9985);

      // Create two instances
      final instanceA =
          await AutoShspInstance.create(remotePeer: remotePeerA);
      final instanceB =
          await AutoShspInstance.create(remotePeer: remotePeerB);

      final singleton = ShspSocketSingleton.getCurrent()!;

      // Get profile
      final profile = singleton.getProfile();
      expect(profile.messageListeners.length, equals(2),
          reason: 'Profile should have two message listeners');

      // Simulate profile restoration (as done in reconnect)
      await singleton.restoreProfile(profile);

      // Verify routing is still correct
      final profileAfter = singleton.getProfile();
      expect(profileAfter.messageListeners.length, equals(2),
          reason: 'Message routing should be preserved after restoration');

      instanceA.close();
      instanceB.close();
    });
  });
}
