import 'package:test/test.dart';
import 'package:shsp_implementations/shsp_instance/shsp_instance_handler.dart';
import 'package:shsp_implementations/shsp_instance/shsp_instance.dart';
import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'dart:io';

void main() {
  group('ShspInstanceHandler', () {
    late ShspInstanceHandler handler;
    late PeerInfo peerInfo;
    late IShspSocket socket;
    late IShspInstance instance;

    setUp(() async {
      handler = ShspInstanceHandler();
      peerInfo = PeerInfo(address: InternetAddress.loopbackIPv4, port: 12345);
      socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      instance = ShspInstance(remotePeer: peerInfo, socket: socket);
    });


    test('initiateShsp adds and returns instance', () async {
      final result = await handler.initiateShsp(peerInfo, instance, (instanceCallback: null));
      expect(result, isNotNull, reason: 'initiateShsp should return a non-null instance');
      final stored = await handler.getShsp(peerInfo);
      expect(stored, equals(result), reason: 'getShsp should return the same instance as initiateShsp');
    });

    test('open/closing flags change on sendHandshake and close', () async {
      final result = await handler.initiateShsp(peerInfo, instance, (instanceCallback: null));
      // All'inizio la connessione non è open né closing
      expect(result.open, isFalse, reason: 'La connessione dovrebbe essere chiusa all\'inizio');
      expect(result.closing, isFalse, reason: 'La connessione non dovrebbe essere in chiusura all\'inizio');
      // Simula handshake completato (flag privato)
      result.sendHandshake();
      // Dopo sendHandshake, la connessione può non essere subito open (dipende dal protocollo),
      // ma qui controlliamo che non sia closing
      expect(result.closing, isFalse, reason: 'Dopo sendHandshake la connessione non dovrebbe essere in chiusura');
      // Simula chiusura
      result.sendClosing();
      expect(result.closing, isTrue, reason: 'Dopo sendClosing la connessione dovrebbe essere in chiusura');
      result.sendClosed();
      expect(result.open, isFalse, reason: 'Dopo sendClosed la connessione dovrebbe essere chiusa');
      expect(result.closing, isFalse, reason: 'Dopo sendClosed la connessione non dovrebbe essere in chiusura');
    });

    test('getShspSafe throws if not found', () async {
      expect(() => handler.getShspSafe(peerInfo), throwsException, reason: 'getShspSafe dovrebbe lanciare se non trova l\'istanza');
    });

    test('getShsp returns null if not found', () async {
      final result = await handler.getShsp(peerInfo);
      expect(result, isNull, reason: 'getShsp dovrebbe restituire null se non trova l\'istanza');
    });

    test('close removes and closes instance', () async {
      await handler.initiateShsp(peerInfo, instance, (instanceCallback: null));
      handler.close(peerInfo);
      final result = await handler.getShsp(peerInfo);
      expect(result, isNull, reason: 'Dopo close l\'istanza dovrebbe essere rimossa');
    });

    test('closeAll removes and closes all instances', () async {
      final peer2 = PeerInfo(address: InternetAddress.loopbackIPv4, port: 12346);
      final socket2 = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      final instance2 = ShspInstance(remotePeer: peer2, socket: socket2);
      await handler.initiateShsp(peerInfo, instance, (instanceCallback: null));
      await handler.initiateShsp(peer2, instance2, (instanceCallback: null));
      handler.closeAll();
      expect(await handler.getShsp(peerInfo), isNull, reason: 'Dopo closeAll l\'istanza 1 dovrebbe essere rimossa');
      expect(await handler.getShsp(peer2), isNull, reason: 'Dopo closeAll l\'istanza 2 dovrebbe essere rimossa');
    });
  });
}
