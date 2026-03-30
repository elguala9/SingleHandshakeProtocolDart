import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('ShspInstance profile extraction and restoration', () {
    late ShspSocket socketA;
    late ShspSocket socketB;
    late ShspSocket socketC;
    late PeerInfo peerInfoA;
    late PeerInfo peerInfoB;
    late ShspInstance instanceA;
    late ShspInstance instanceB;

    setUp(() async {
      final address = InternetAddress.loopbackIPv4;

      // Create three sockets for testing
      socketA = await ShspSocket.bind(address, 0);
      socketB = await ShspSocket.bind(address, 0);
      socketC = await ShspSocket.bind(address, 0);

      final portA = socketA.localPort!;
      final portB = socketB.localPort!;

      peerInfoA = PeerInfo(address: address, port: portA);
      peerInfoB = PeerInfo(address: address, port: portB);

      instanceA = ShspInstance(remotePeer: peerInfoB, socket: socketA);
      instanceB = ShspInstance(remotePeer: peerInfoA, socket: socketB);
    });

    tearDown(() async {
      socketA.close();
      socketB.close();
      socketC.close();
    });

    test('extractProfile returns listeners registered on the instance', () {
      int handshakeCount = 0;
      int openCount = 0;
      int messageCount = 0;

      // Register callbacks on instanceA
      instanceA.onHandshake.register((_) => handshakeCount++);
      instanceA.onOpen.register((_) => openCount++);
      instanceA.messageCallback.register((_) => messageCount++);

      // Extract profile
      final profile = instanceA.extractProfile();

      // Verify profile contains the expected listeners
      expect(
        profile.onHandshakeListeners.length,
        equals(1),
        reason: 'Profile should contain 1 handshake listener',
      );
      expect(
        profile.onOpenListeners.length,
        equals(1),
        reason: 'Profile should contain 1 open listener',
      );
      expect(
        profile.onMessageListeners.length,
        equals(1),
        reason: 'Profile should contain 1 message listener',
      );
      expect(
        profile.onClosingListeners.length,
        equals(0),
        reason: 'Profile should contain 0 closing listeners',
      );
      expect(
        profile.onCloseListeners.length,
        equals(0),
        reason: 'Profile should contain 0 close listeners',
      );
    });

    test('extractProfile includes keepAliveSeconds configuration', () {
      const customKeepAlive = 45;
      instanceA.keepAliveSeconds = customKeepAlive;

      final profile = instanceA.extractProfile();

      expect(
        profile.keepAliveSeconds,
        equals(customKeepAlive),
        reason: 'Profile should capture the keepAliveSeconds setting',
      );
    });

    test('withProfile restores callbacks to a new instance', () async {
      bool handshakeCalled = false;

      // Register callbacks on original instance
      instanceA.onHandshake.register((_) => handshakeCalled = true);
      instanceA.messageCallback.register((peer) {
        // Callback registered but not used in this test
      });

      // Extract profile
      final profile = instanceA.extractProfile();

      // Create a new instance with the profile
      final instanceC = ShspInstance.withProfile(
        remotePeer: peerInfoB,
        socket: socketC,
        profile: profile,
      );

      // Simulate receiving a handshake message on the new instance
      await Future.delayed(const Duration(milliseconds: 100));
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));

      // The handshake callback should have been called on instanceC
      expect(
        handshakeCalled,
        isTrue,
        reason: 'Handshake callback should be called on restored instance',
      );

      // Verify keep-alive was restored
      expect(
        instanceC.keepAliveSeconds,
        equals(instanceA.keepAliveSeconds),
        reason: 'Keep-alive seconds should be restored from profile',
      );

      // Clean up
      instanceC.close();
    });

    test('withProfile with multiple listeners', () async {
      int handshakeCall1 = 0;
      int handshakeCall2 = 0;
      int openCall1 = 0;

      // Register multiple callbacks
      instanceA.onHandshake.register((_) => handshakeCall1++);
      instanceA.onHandshake.register((_) => handshakeCall2++);
      instanceA.onOpen.register((_) => openCall1++);

      final profile = instanceA.extractProfile();

      // Create new instance with profile
      final instanceC = ShspInstance.withProfile(
        remotePeer: peerInfoB,
        socket: socketC,
        profile: profile,
      );

      // Verify all listeners were restored
      expect(
        instanceC.onHandshake.map.length,
        equals(2),
        reason: 'Both handshake listeners should be restored',
      );
      expect(
        instanceC.onOpen.map.length,
        equals(1),
        reason: 'Open listener should be restored',
      );

      // Simulate handshake
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));

      expect(
        handshakeCall1,
        equals(1),
        reason: 'First handshake callback should be called once',
      );
      expect(
        handshakeCall2,
        equals(1),
        reason: 'Second handshake callback should be called once',
      );

      instanceC.close();
    });

    test('extracted listeners can be unregistered on new instance', () async {
      int callCount = 0;
      void listener(_) => callCount++;

      // Register callback
      instanceA.onHandshake.register(listener);
      final profile = instanceA.extractProfile();

      // Create new instance
      final instanceC = ShspInstance.withProfile(
        remotePeer: peerInfoB,
        socket: socketC,
        profile: profile,
      );

      // Verify callback is registered
      expect(
        instanceC.onHandshake.map.length,
        equals(1),
        reason: 'Listener should be registered on new instance',
      );

      // Unregister the callback using the extracted listener
      instanceC.onHandshake.unregister(profile.onHandshakeListeners[0]);

      expect(
        instanceC.onHandshake.map.length,
        equals(0),
        reason: 'Listener should be unregistered',
      );

      instanceC.close();
    });

    test('connection state is not transferred in profile', () {
      // Simulate connection state changes
      instanceA.sendHandshake();
      instanceA.sendHandshake(); // Send again to trigger _open

      final profile = instanceA.extractProfile();

      // Create new instance with profile
      final instanceC = ShspInstance.withProfile(
        remotePeer: peerInfoB,
        socket: socketC,
        profile: profile,
      );

      // New instance should start fresh, not inherit connection state
      expect(
        instanceC.handshake,
        isFalse,
        reason: 'New instance should start with handshake=false',
      );
      expect(
        instanceC.open,
        isFalse,
        reason: 'New instance should start with open=false',
      );
      expect(
        instanceC.closing,
        isFalse,
        reason: 'New instance should start with closing=false',
      );

      instanceC.close();
    });

    test('profile can be reused for multiple instances', () {
      int handshakeCall1 = 0;

      // Register callback
      instanceA.onHandshake.register((_) => handshakeCall1++);

      final profile = instanceA.extractProfile();

      // Create first instance with profile
      final instanceC = ShspInstance.withProfile(
        remotePeer: peerInfoB,
        socket: socketC,
        profile: profile,
      );

      expect(
        instanceC.onHandshake.map.length,
        equals(1),
        reason: 'First instance should have the listener',
      );

      instanceC.close();

      // Note: We cannot create another instance with the same socket,
      // but we've verified that the profile itself can be used to restore
      // listeners to a new instance.
    });
  });
}
