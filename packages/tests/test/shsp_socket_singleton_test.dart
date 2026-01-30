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
      final s1 = await ShspSocketSingleton.bind();
      final s2 = await ShspSocketSingleton.bind();
      expect(s1, same(s2),
          reason: 'bind deve restituire sempre la stessa istanza');
    });

    test('instance getter returns the singleton', () async {
      await ShspSocketSingleton.bind();
      final instance = ShspSocketSingleton.instance;
      expect(instance, isNotNull,
          reason: 'instance deve restituire la singleton creata');
    });

    test('destroy resets the singleton', () async {
      await ShspSocketSingleton.bind();
      ShspSocketSingleton.destroy();
      expect(ShspSocketSingleton.instance, isNull,
          reason: 'destroy deve azzerare la singleton');
    });

    test('can use as ShspSocket', () async {
      final singleton = await ShspSocketSingleton.bind();
      expect(singleton, isA<ShspSocket>(),
          reason: 'ShspSocketSingleton deve essere usabile come ShspSocket');
    });
  });
}
