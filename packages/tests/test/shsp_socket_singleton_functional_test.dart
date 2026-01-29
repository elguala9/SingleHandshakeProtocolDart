import 'dart:io';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:test/test.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket_singleton.dart';
import 'package:shsp_implementations/utility/message_callback_map.dart';

void main() {
  group('ShspSocketSingleton handshake e funzionalità', () {
    setUp(() {
      ShspSocketSingleton.destroy();
    });

    test('può inviare e ricevere messaggi handshake', () async {
      // Setup una singleton e una socket normale
      final rawSingleton = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final rawOther = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final callbacksSingleton = MessageCallbackMap();
      final callbacksOther = MessageCallbackMap();
      final singleton = await ShspSocketSingleton.bind(rawSingleton, callbacksSingleton);
      final other = ShspSocket.internal(rawOther, callbacksOther);
      // Registra una callback handshake su other
      bool received = false;
      other.setMessageCallback(
        '${rawSingleton.address.address}:${rawSingleton.port}',
        (msg, rinfo) {
          if (msg.isNotEmpty && msg[0] == 0x01) received = true;
        },
      );
      // Invia handshake dalla singleton alla socket normale
      singleton.sendTo([0x01], rawOther.address, rawOther.port);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(received, isTrue, reason: 'Il messaggio handshake deve essere ricevuto dalla socket normale');
    });

    test('può inviare e ricevere messaggi dati', () async {
      final rawSingleton = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final rawOther = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final callbacksSingleton = MessageCallbackMap();
      final callbacksOther = MessageCallbackMap();
      final singleton = await ShspSocketSingleton.bind(rawSingleton, callbacksSingleton);
      final other = ShspSocket.internal(rawOther, callbacksOther);
      bool received = false;
      other.setMessageCallback(
        '${rawSingleton.address.address}:${rawSingleton.port}',
        (msg, rinfo) {
          if (msg.isNotEmpty && msg[0] == 0x00 && msg[1] == 42) received = true;
        },
      );
      singleton.sendTo([0x00, 42], rawOther.address, rawOther.port);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(received, isTrue, reason: 'Il messaggio dati deve essere ricevuto dalla socket normale');
    });
  });
}
