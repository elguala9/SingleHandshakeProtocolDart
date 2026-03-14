import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('ShspSocket Profile Transfer', () {
    test('extractProfile captures all message listeners', () async {
      final address = InternetAddress.loopbackIPv4;
      final socket = await ShspSocket.bind(address, 0);

      // Register callbacks for different peers
      for (int i = 0; i < 5; i++) {
        socket.setMessageCallback(
          PeerInfo(address: address, port: 9000 + i),
          (record) {},
        );
      }

      final profile = socket.extractProfile();

      expect(profile.messageListeners.length, equals(5),
          reason: 'Profile should capture all registered callbacks');

      socket.close();
    });

    test('applyProfile restores all message listeners to new socket', () async {
      final address = InternetAddress.loopbackIPv4;

      // Create first socket and register callbacks
      final socket1 = await ShspSocket.bind(address, 0);
      for (int i = 0; i < 3; i++) {
        socket1.setMessageCallback(
          PeerInfo(address: address, port: 8000 + i),
          (record) {},
        );
      }

      final profile = socket1.extractProfile();
      expect(profile.messageListeners.length, equals(3));

      // Create second socket
      final rawSocket2 = await RawDatagramSocket.bind(address, 0);
      final socket2 = ShspSocket.fromRaw(rawSocket2);

      // Verify it starts empty
      var profile2 = socket2.extractProfile();
      expect(profile2.messageListeners.isEmpty, isTrue,
          reason: 'New socket should have no callbacks');

      // Apply profile
      socket2.applyProfile(profile);

      // Verify callbacks were restored
      profile2 = socket2.extractProfile();
      expect(profile2.messageListeners.length, equals(3),
          reason: 'Applied profile should restore all callbacks');

      socket1.close();
      socket2.close();
    });

    test('fromRaw creates functional socket from RawDatagramSocket', () async {
      final address = InternetAddress.loopbackIPv4;
      final rawSocket = await RawDatagramSocket.bind(address, 0);

      final socket = ShspSocket.fromRaw(rawSocket);

      expect(socket.socket, same(rawSocket),
          reason: 'Should wrap the provided raw socket');
      expect(socket.localPort, isNotNull,
          reason: 'Should have a local port');
      expect(socket.localAddress, equals(address),
          reason: 'Should have correct address');
      expect(socket.isClosed, isFalse, reason: 'Should not be closed');

      socket.close();
    });

    test('profile is independent of socket state', () async {
      final address = InternetAddress.loopbackIPv4;
      final socket = await ShspSocket.bind(address, 0);

      // Register callbacks
      socket.setMessageCallback(
        PeerInfo(address: address, port: 8888),
        (record) {},
      );

      final profile1 = socket.extractProfile();
      expect(profile1.messageListeners.length, equals(1));

      // Register more callbacks
      socket.setMessageCallback(
        PeerInfo(address: address, port: 8889),
        (record) {},
      );

      // First profile should still have only 1
      expect(profile1.messageListeners.length, equals(1),
          reason: 'Profile snapshot should not change after extraction');

      final profile2 = socket.extractProfile();
      expect(profile2.messageListeners.length, equals(2),
          reason: 'New profile should reflect current state');

      socket.close();
    });

    test('multiple profiles can coexist and be applied independently', () async {
      final address = InternetAddress.loopbackIPv4;

      // Create socket A with profile A
      final socketA = await ShspSocket.bind(address, 0);
      socketA.setMessageCallback(
        PeerInfo(address: address, port: 7000),
        (record) {},
      );
      socketA.setMessageCallback(
        PeerInfo(address: address, port: 7001),
        (record) {},
      );
      final profileA = socketA.extractProfile();
      expect(profileA.messageListeners.length, equals(2));

      // Create socket B with profile B
      final socketB = await ShspSocket.bind(address, 0);
      socketB.setMessageCallback(
        PeerInfo(address: address, port: 6000),
        (record) {},
      );
      final profileB = socketB.extractProfile();
      expect(profileB.messageListeners.length, equals(1));

      // Create fresh socket and apply profile A
      final rawSocketC = await RawDatagramSocket.bind(address, 0);
      final socketC = ShspSocket.fromRaw(rawSocketC);
      socketC.applyProfile(profileA);

      var profileC = socketC.extractProfile();
      expect(profileC.messageListeners.length, equals(2),
          reason: 'Socket C should have profile A listeners');

      // Now apply profile B to socket C
      socketC.applyProfile(profileB);

      profileC = socketC.extractProfile();
      expect(profileC.messageListeners.length, equals(3),
          reason: 'Applying profile B should add its listeners to existing ones');

      socketA.close();
      socketB.close();
      socketC.close();
    });

    test('profile application adds to existing callbacks', () async {
      final address = InternetAddress.loopbackIPv4;

      // Create socket with initial callback
      final socket = await ShspSocket.bind(address, 0);
      socket.setMessageCallback(
        PeerInfo(address: address, port: 6500),
        (record) {},
      );

      expect(socket.extractProfile().messageListeners.length, equals(1));

      // Create second socket and extract its profile
      final socket2 = await ShspSocket.bind(address, 0);
      socket2.setMessageCallback(
        PeerInfo(address: address, port: 6501),
        (record) {},
      );
      socket2.setMessageCallback(
        PeerInfo(address: address, port: 6502),
        (record) {},
      );
      final profile2 = socket2.extractProfile();
      expect(profile2.messageListeners.length, equals(2));

      // Apply profile2 to socket
      socket.applyProfile(profile2);

      // Socket should now have 3 listeners total
      final finalProfile = socket.extractProfile();
      expect(finalProfile.messageListeners.length, equals(3),
          reason: 'Should accumulate listeners from both sources');

      socket.close();
      socket2.close();
    });

    test('empty profile can be applied without issues', () async {
      final address = InternetAddress.loopbackIPv4;
      final socket = await ShspSocket.bind(address, 0);

      socket.setMessageCallback(
        PeerInfo(address: address, port: 6400),
        (record) {},
      );

      // Create and apply empty profile
      final socket2 = await ShspSocket.bind(address, 0);
      final emptyProfile = socket2.extractProfile();
      expect(emptyProfile.messageListeners.isEmpty, isTrue);

      socket.applyProfile(emptyProfile);

      // Socket should still have its original callback
      expect(socket.extractProfile().messageListeners.length, equals(1),
          reason: 'Applying empty profile should not remove existing callbacks');

      socket.close();
      socket2.close();
    });

    test('profile persists across close and recreate', () async {
      final address = InternetAddress.loopbackIPv4;

      // Create socket and register callbacks
      final socket1 = await ShspSocket.bind(address, 0);
      socket1.setMessageCallback(
        PeerInfo(address: address, port: 6300),
        (record) {},
      );
      socket1.setMessageCallback(
        PeerInfo(address: address, port: 6301),
        (record) {},
      );

      final profile = socket1.extractProfile();
      expect(profile.messageListeners.length, equals(2));

      // Close original socket
      socket1.close();

      // Create new socket and apply profile
      final rawSocket2 = await RawDatagramSocket.bind(address, 0);
      final socket2 = ShspSocket.fromRaw(rawSocket2);
      socket2.applyProfile(profile);

      // Profile should be fully restored
      expect(socket2.extractProfile().messageListeners.length, equals(2),
          reason: 'Profile should be restored to new socket');

      socket2.close();
    });

    test('profile works with compression codec transfer', () async {
      final address = InternetAddress.loopbackIPv4;

      // Note: Profile currently captures message listeners, not compression codec
      // This test verifies the profile mechanism works correctly for future extension

      final socket = await ShspSocket.bind(address, 0);

      // Register multiple listeners
      for (int i = 0; i < 3; i++) {
        socket.setMessageCallback(
          PeerInfo(address: address, port: 6200 + i),
          (record) {},
        );
      }

      final profile = socket.extractProfile();

      // Create new socket and transfer profile
      final rawSocket2 = await RawDatagramSocket.bind(address, 0);
      final socket2 = ShspSocket.fromRaw(rawSocket2);
      socket2.applyProfile(profile);

      // All listeners should be restored
      expect(socket2.extractProfile().messageListeners.length, equals(3),
          reason: 'Profile transfer should preserve all listeners');

      socket.close();
      socket2.close();
    });

    test('extractProfile handles many listeners efficiently', () async {
      final address = InternetAddress.loopbackIPv4;
      final socket = await ShspSocket.bind(address, 0);

      // Register many callbacks
      const listenerCount = 100;
      for (int i = 0; i < listenerCount; i++) {
        socket.setMessageCallback(
          PeerInfo(address: address, port: 5000 + i),
          (record) {},
        );
      }

      // Extract profile
      final profile = socket.extractProfile();

      expect(profile.messageListeners.length, equals(listenerCount),
          reason: 'Should handle many listeners efficiently');

      // Apply to new socket
      final rawSocket2 = await RawDatagramSocket.bind(address, 0);
      final socket2 = ShspSocket.fromRaw(rawSocket2);
      socket2.applyProfile(profile);

      expect(socket2.extractProfile().messageListeners.length, equals(listenerCount),
          reason: 'Should restore many listeners correctly');

      socket.close();
      socket2.close();
    });

    test('profile application with many peers works correctly', () async {
      final address = InternetAddress.loopbackIPv4;

      // Create socket with specific callback order
      final socket1 = await ShspSocket.bind(address, 0);
      final peerCount = 10;
      for (int i = 0; i < peerCount; i++) {
        socket1.setMessageCallback(
          PeerInfo(address: address, port: 5100 + i),
          (record) {},
        );
      }

      final profile = socket1.extractProfile();
      expect(profile.messageListeners.length, equals(peerCount),
          reason: 'Profile should have all registered listeners');

      // Apply to new socket
      final socket2 = await ShspSocket.bind(address, 0);
      socket2.applyProfile(profile);

      final profile2 = socket2.extractProfile();
      expect(profile2.messageListeners.length, equals(peerCount),
          reason: 'Applied profile should restore all listeners');

      socket1.close();
      socket2.close();
    });
  });
}
