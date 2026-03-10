import 'package:test/test.dart';
import 'package:shsp/src/impl/utility/message_callback_map_singleton.dart';
import 'package:shsp/src/impl/utility/shsp_socket_info_singleton.dart';
import 'package:shsp/src/impl/shsp_instance/shsp_instance_handler_singleton.dart';

void main() {
  group('Singletons', () {
    setUp(() {
      MessageCallbackMapSingleton.destroy();
      ShspSocketInfoSingleton.destroy();
      ShspInstanceHandlerSingleton.destroy();
    });

    test('MessageCallbackMapSingleton returns always the same instance', () {
      final a = MessageCallbackMapSingleton();
      final b = MessageCallbackMapSingleton();
      expect(a, same(b));
    });

    test(
        'ShspSocketInfoSingleton returns always the same instance with defaults',
        () {
      final a = ShspSocketInfoSingleton();
      final b = ShspSocketInfoSingleton();
      expect(a, same(b));
      expect(a.address, equals('127.0.0.1'));
      expect(a.port, equals(6969));
    });

    test('ShspInstanceHandlerSingleton returns always the same instance', () {
      final a = ShspInstanceHandlerSingleton();
      final b = ShspInstanceHandlerSingleton();
      expect(a, same(b));
    });
  });
}
