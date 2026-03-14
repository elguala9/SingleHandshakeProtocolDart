import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('ShspSocketSingleton handshake e funzionalità', () {
    setUp(() {
      ShspSocketSingleton.destroy();
      MessageCallbackMapSingleton().destroy();
      ShspSocketInfoSingleton().destroy();
    });

    test('può inviare e ricevere messaggi handshake', () async {
      // Create singleton socket and get its address/port
      final singleton = await ShspSocketSingleton.getInstance();
      final singletonPort = singleton.localPort!;
      final singletonAddr = InternetAddress.loopbackIPv4;

      // Create receiving socket
      final rawOther =
          await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final callbacksOther = MessageCallbackMap();
      final other = ShspSocket.internal(rawOther, callbacksOther);
      final otherPort = rawOther.port;

      // Register callback on receiving socket to listen for singleton's address
      final completer = Completer<void>();
      other.setMessageCallback(
        PeerInfo(address: singletonAddr, port: singletonPort),
        (record) {
          if (record.msg.isNotEmpty && record.msg[0] == 0x01) {
            completer.complete();
          }
        },
      );

      // Send handshake from singleton to other socket
      singleton.socket.sendTo([0x01], PeerInfo(address: InternetAddress.loopbackIPv4, port: otherPort));

      // Wait for message with timeout
      await completer.future.timeout(const Duration(seconds: 2), onTimeout: () {
        throw Exception('Timeout waiting for handshake message');
      });

      other.close();
    });

    test('può inviare e ricevere messaggi dati', () async {
      // Create singleton socket and get its address/port
      final singleton = await ShspSocketSingleton.getInstance();
      final singletonPort = singleton.localPort!;
      final singletonAddr = InternetAddress.loopbackIPv4;

      // Create receiving socket
      final rawOther =
          await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final callbacksOther = MessageCallbackMap();
      final other = ShspSocket.internal(rawOther, callbacksOther);
      final otherPort = rawOther.port;

      // Register callback on receiving socket to listen for singleton's address
      final completer = Completer<void>();
      other.setMessageCallback(
        PeerInfo(address: singletonAddr, port: singletonPort),
        (record) {
          if (record.msg.isNotEmpty &&
              record.msg[0] == 0x00 &&
              record.msg.length > 1 &&
              record.msg[1] == 42) {
            completer.complete();
          }
        },
      );

      // Send data message from singleton to other socket
      singleton.socket.sendTo([0x00, 42], PeerInfo(address: InternetAddress.loopbackIPv4, port: otherPort));

      // Wait for message with timeout
      await completer.future.timeout(const Duration(seconds: 2), onTimeout: () {
        throw Exception('Timeout waiting for data message');
      });

      other.close();
    });
  });
}
