import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_implementations/src/shsp_socket.dart';
import 'package:shsp_types/shsp_types.dart';

/// Factory function type for creating IShspSocket
typedef IShspSocketFactory = Future<IShspSocket> Function(InternetAddress address, int port);

void testIShspSocket(IShspSocketFactory createSocket) {
  group('IShspSocket interface', () {
    late IShspSocket socket;
    late InternetAddress address;
    late int port;

    setUp(() async {
      address = InternetAddress.loopbackIPv4;
      port = 9000;
      socket = await createSocket(address, port);
    });

    tearDown(() {
      socket.close();
    });

    test('should set and call message callback', () async {
      final testMsg = [1, 2, 3];
      final rinfo = RemoteInfo(address: address, port: port);
      bool called = false;
      socket.setMessageCallback(
        '${address.address}:$port',
        (msg, info) {
          called = true;
          expect(msg, equals(testMsg));
          expect(info.address, equals(address));
          expect(info.port, equals(port));
        },
      );
      socket.onMessage(testMsg, rinfo);
      expect(called, isTrue);
    });

    test('should send and receive messages between two sockets', () async {
      final address2 = InternetAddress.loopbackIPv4;
      final port2 = port + 1;
      final socket1 = socket;
      final socket2 = await createSocket(address2, port2);

      final testMsg = [10, 20, 30];
      final completer = Completer<void>();

      final callbackKey = '${address.address}:$port';
      print('DEBUG: callbackKey = $callbackKey');
      print('DEBUG: socket1 port = $port, socket2 port = $port2');

      socket2.setMessageCallback(
        callbackKey,
        (msg, info) {
          print('DEBUG: Ricevuto messaggio: $msg da ${info.address}:${info.port}');
          expect(msg, equals(testMsg));
          expect(info.address, equals(address));
          expect(info.port, equals(port));
          completer.complete();
        },
      );

      print('DEBUG: Invio messaggio da socket1 a socket2');
      socket1.sendTo(testMsg, address2, port2);

      // Attendi la ricezione (fino a 2 secondi)
      await completer.future.timeout(const Duration(seconds: 2), onTimeout: () {
        print('DEBUG: Timeout, messaggio non ricevuto');
        fail('Messaggio non ricevuto entro il timeout');
      });

      print('DEBUG: Chiusura socket2');
      socket2.close();
    });

    test('should set and call close callback', () async {
      bool closed = false;
      socket.setCloseCallback(() {
        closed = true;
      });
      socket.onClose();
      expect(closed, isTrue);
    });

    test('should set and call error callback', () async {
      bool errored = false;
      final error = Exception('Test error');
      socket.setErrorCallback((err) {
        errored = true;
        expect(err, equals(error));
      });
      socket.onError(error);
      expect(errored, isTrue);
    });

  });
}

void main() {
  testIShspSocket((address, port) => ShspSocket.bind(address, port));
}
