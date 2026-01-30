// ...existing code...
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:test/test.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket_singleton.dart';
import 'package:shsp_implementations/utility/message_callback_map_singleton.dart';
import 'package:shsp_implementations/utility/shsp_socket_info_singleton.dart';

void main() {
  group('ShspSocketSingleton', () {
    setUp(() {
      ShspSocketSingleton.destroy();
      MessageCallbackMapSingleton.destroy();
      ShspSocketInfoSingleton.destroy();
    });

    test('bind returns a singleton instance', () async {
      final info = ShspSocketInfoSingleton();
      final callbacks = MessageCallbackMapSingleton();
      final s1 =
          await ShspSocketSingleton.bind(info: info, callbacks: callbacks);
      final s2 =
          await ShspSocketSingleton.bind(info: info, callbacks: callbacks);
      expect(s1, same(s2),
          reason: 'bind deve restituire sempre la stessa istanza');
    });

    test('instance getter returns the singleton', () async {
      final info = ShspSocketInfoSingleton();
      final callbacks = MessageCallbackMapSingleton();
      await ShspSocketSingleton.bind(info: info, callbacks: callbacks);
      final instance = ShspSocketSingleton.instance;
      expect(instance, isNotNull,
          reason: 'instance deve restituire la singleton creata');
    });

    test('destroy resets the singleton', () async {
      final info = ShspSocketInfoSingleton();
      final callbacks = MessageCallbackMapSingleton();
      await ShspSocketSingleton.bind(info: info, callbacks: callbacks);
      ShspSocketSingleton.destroy();
      expect(ShspSocketSingleton.instance, isNull,
          reason: 'destroy deve azzerare la singleton');
    });

    test('can use as ShspSocket', () async {
      final info = ShspSocketInfoSingleton();
      final callbacks = MessageCallbackMapSingleton();
      final singleton =
          await ShspSocketSingleton.bind(info: info, callbacks: callbacks);
      expect(singleton, isA<ShspSocket>(),
          reason: 'ShspSocketSingleton deve essere usabile come ShspSocket');
    });
  });
}
