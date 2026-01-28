import 'dart:io';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:test/test.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket_singleton.dart';
import 'package:shsp_implementations/utility/message_callback_map.dart';

void main() {
  group('ShspSocketSingleton', () {
    setUp(() {
      ShspSocketSingleton.destroy();
    });

    test('bind returns a singleton instance', () async {
      final rawSocket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final callbacks = MessageCallbackMap();
      final s1 = await ShspSocketSingleton.bind(rawSocket, callbacks);
      final s2 = await ShspSocketSingleton.bind(rawSocket, callbacks);
      expect(s1, same(s2), reason: 'bind deve restituire sempre la stessa istanza');
    });

    test('instance getter returns the singleton', () async {
      final rawSocket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final callbacks = MessageCallbackMap();
      await ShspSocketSingleton.bind(rawSocket, callbacks);
      final instance = ShspSocketSingleton.instance;
      expect(instance, isNotNull, reason: 'instance deve restituire la singleton creata');
    });

    test('destroy resets the singleton', () async {
      final rawSocket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final callbacks = MessageCallbackMap();
      await ShspSocketSingleton.bind(rawSocket, callbacks);
      ShspSocketSingleton.destroy();
      expect(ShspSocketSingleton.instance, isNull, reason: 'destroy deve azzerare la singleton');
    });

    test('can use as ShspSocket', () async {
      final rawSocket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final callbacks = MessageCallbackMap();
      final singleton = await ShspSocketSingleton.bind(rawSocket, callbacks);
      expect(singleton, isA<ShspSocket>(), reason: 'ShspSocketSingleton deve essere usabile come ShspSocket');
    });
  });
}
