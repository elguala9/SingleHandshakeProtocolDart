import 'package:test/test.dart';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'dart:io';

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
      expect(a.port, equals(9000));
    });

    test('ShspSocketInfoSingleton can use custom defaults', () {
      ShspSocketInfoSingleton.destroy();
      final instance = ShspSocketInfoSingleton(
        defaultAddress: '0.0.0.0',
        defaultPort: 8080,
      );
      expect(instance.address, equals('0.0.0.0'));
      expect(instance.port, equals(8080));
    });

    test('ShspInstanceHandlerSingleton returns always the same instance', () {
      final a = ShspInstanceHandlerSingleton();
      final b = ShspInstanceHandlerSingleton();
      expect(a, same(b));
    });
  });
}
