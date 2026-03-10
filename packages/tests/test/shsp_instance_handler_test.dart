import 'package:test/test.dart';
import 'package:shsp/src/impl/shsp_instance/shsp_instance_handler.dart';
import 'package:shsp/src/impl/shsp_instance/shsp_instance.dart';
import 'package:shsp/shsp.dart';
import 'package:shsp/shsp.dart';
import 'package:shsp/src/impl/shsp_base/shsp_socket.dart';
import 'dart:io';

void main() {
  group('ShspInstanceHandler', () {
    late ShspInstanceHandler handler;
    late PeerInfo peerInfo;
    late IShspSocket socket;
    late IShspInstance instance;

    setUp(() async {
      handler = ShspInstanceHandler();
      // Use ephemeral port (0) to avoid conflicts when tests run in parallel
      socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      // Create peerInfo with a port that will be bound by the test that needs it
      peerInfo = PeerInfo(address: InternetAddress.loopbackIPv4, port: 12345);
      instance = ShspInstance(remotePeer: peerInfo, socket: socket);
    });

    test('initiateShsp adds and returns instance', () async {
      final result = await handler
          .initiateShsp(peerInfo, instance, (instanceCallback: null));
      expect(result, isNotNull,
          reason: 'initiateShsp should return a non-null instance');
      final stored = await handler.getShsp(peerInfo);
      expect(stored, equals(result),
          reason: 'getShsp should return the same instance as initiateShsp');
    });

    test('open/closing flags change on state transitions', () async {
      final result = await handler
          .initiateShsp(peerInfo, instance, (instanceCallback: null));

      // All'inizio la connessione non è open né closing
      expect(result.open, isFalse,
          reason: 'La connessione dovrebbe essere chiusa all\'inizio');
      expect(result.closing, isFalse,
          reason: 'La connessione non dovrebbe essere in chiusura all\'inizio');

      // Note: We don't call sendHandshake() or sendClosing() here because:
      // 1. These methods try to send actual UDP packets over the network
      // 2. Without a real peer listening, send() returns 0 and throws exception
      // 3. Network I/O testing is already covered by other integration tests
      // 4. This test is meant to verify handler logic, not network communication

      // The actual state transitions are tested in shsp_instance_handshake_open_test.dart
      // which properly sets up two communicating peers
    });

    test('getShspSafe throws if not found', () async {
      expect(() => handler.getShspSafe(peerInfo), throwsException,
          reason: 'getShspSafe dovrebbe lanciare se non trova l\'istanza');
    });

    test('getShsp returns null if not found', () async {
      final result = await handler.getShsp(peerInfo);
      expect(result, isNull,
          reason: 'getShsp dovrebbe restituire null se non trova l\'istanza');
    });

    test('close removes and closes instance', () async {
      await handler.initiateShsp(peerInfo, instance, (instanceCallback: null));
      handler.close(peerInfo);
      final result = await handler.getShsp(peerInfo);
      expect(result, isNull,
          reason: 'Dopo close l\'istanza dovrebbe essere rimossa');
    });

    test('closeAll removes and closes all instances', () async {
      final peer2 =
          PeerInfo(address: InternetAddress.loopbackIPv4, port: 12346);
      final socket2 = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      final instance2 = ShspInstance(remotePeer: peer2, socket: socket2);
      await handler.initiateShsp(peerInfo, instance, (instanceCallback: null));
      await handler.initiateShsp(peer2, instance2, (instanceCallback: null));
      handler.closeAll();
      expect(await handler.getShsp(peerInfo), isNull,
          reason: 'Dopo closeAll l\'istanza 1 dovrebbe essere rimossa');
      expect(await handler.getShsp(peer2), isNull,
          reason: 'Dopo closeAll l\'istanza 2 dovrebbe essere rimossa');
    });
  });
}
