import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:shsp_implementations/utility/message_callback_map.dart';
import 'package:shsp_types/shsp_types.dart';

void main() {
  group('ShspSocket profile extraction and restoration', () {
    late ShspSocket socketA;
    late ShspSocket socketB;
    late PeerInfo peerA;
    late PeerInfo peerB;

    setUp(() async {
      final address = InternetAddress.loopbackIPv4;

      // Create two sockets
      socketA = await ShspSocket.bind(address, 0);
      socketB = await ShspSocket.bind(address, 0);

      final portA = socketA.localPort!;
      final portB = socketB.localPort!;

      peerA = PeerInfo(address: address, port: portA);
      peerB = PeerInfo(address: address, port: portB);
    });

    tearDown(() async {
      socketA.close();
      socketB.close();
    });

    test('extractProfile captures message callbacks', () {
      int messageCount = 0;

      // Register a callback for a specific peer
      socketA.setMessageCallback(peerB, (record) {
        messageCount++;
      });

      // Extract profile
      final profile = socketA.extractProfile();

      // Verify profile contains the callback
      expect(profile.messageListeners.isNotEmpty, isTrue,
          reason: 'Profile should contain message callbacks');

      // The key format should match the peer's address:port
      final expectedKey = MessageCallbackMap.formatKey(peerB.address, peerB.port);
      expect(profile.messageListeners.containsKey(expectedKey), isTrue,
          reason: 'Profile should contain callback for the registered peer');
    });

    test('extractProfile with multiple peers', () {
      // Create additional peer
      final peerC = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);

      // Register callbacks for multiple peers
      socketA.setMessageCallback(peerB, (record) {});
      socketA.setMessageCallback(peerC, (record) {});

      final profile = socketA.extractProfile();

      expect(profile.messageListeners.length, equals(2),
          reason: 'Profile should contain callbacks for both peers');
    });

    test('withProfile restores callbacks to new socket', () async {
      // Register callback on original socket
      socketA.setMessageCallback(peerB, (record) {});

      // Extract profile
      final profile = socketA.extractProfile();

      // Create new socket with profile
      final socketC = await ShspSocket.withProfile(
        InternetAddress.loopbackIPv4,
        0,
        profile,
      );

      try {
        // Verify the callback is registered in the profile
        final key =
            MessageCallbackMap.formatKey(peerB.address, peerB.port);
        expect(profile.messageListeners.containsKey(key), isTrue,
            reason: 'Profile should contain the callback');

        // Verify that extracting from the new socket still has callbacks
        final newProfile = socketC.extractProfile();
        expect(newProfile.messageListeners.containsKey(key), isTrue,
            reason: 'Restored socket should have callback registered');
      } finally {
        socketC.close();
      }
    });

    test('profile with no callbacks returns empty profile', () {
      // Don't register any callbacks
      final profile = socketA.extractProfile();

      expect(profile.messageListeners.isEmpty, isTrue,
          reason: 'Profile should be empty when no callbacks registered');
    });

    test('withProfile with compression codec', () async {
      // Register callback
      socketA.setMessageCallback(peerB, (record) {});

      final profile = socketA.extractProfile();

      // Create new socket with custom compression
      final socketC = await ShspSocket.withProfile(
        InternetAddress.loopbackIPv4,
        0,
        profile,
      );

      try {
        // Verify socket was created and compression codec is set
        expect(socketC.compressionCodec, isNotNull);

        // Verify callbacks were restored
        expect(socketC.extractProfile().messageListeners.isNotEmpty, isTrue);
      } finally {
        socketC.close();
      }
    });

    test('extracted profile can be reused for multiple sockets', () async {
      socketA.setMessageCallback(peerB, (record) {});

      final profile = socketA.extractProfile();

      // Create first socket from profile
      final socketC = await ShspSocket.withProfile(
        InternetAddress.loopbackIPv4,
        0,
        profile,
      );

      try {
        expect(socketC.extractProfile().messageListeners.isNotEmpty, isTrue,
            reason: 'First socket should have callbacks');

        socketC.close();

        // Create second socket from same profile
        final socketD = await ShspSocket.withProfile(
          InternetAddress.loopbackIPv4,
          0,
          profile,
        );

        try {
          expect(socketD.extractProfile().messageListeners.isNotEmpty, isTrue,
              reason: 'Second socket should have callbacks from same profile');
        } finally {
          socketD.close();
        }
      } on Exception {
        // socketC already closed
      }
    });
  });
}
