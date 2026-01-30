import 'package:test/test.dart';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'dart:io';

void main() {
  group('Singletons', () {
    test('MessageCallbackMapSingleton returns always the same instance', () {
      final a = MessageCallbackMapSingleton();
      final b = MessageCallbackMapSingleton();
      expect(a, same(b));
    });

    test('ShspSocketInfoSingleton returns always the same instance and loads config', () {
      final a = ShspSocketInfoSingleton();
      final b = ShspSocketInfoSingleton();
      expect(a, same(b));
      expect(a.address, isNotEmpty);
      expect(a.port, isNonZero);
    });

    test('ShspInstanceHandlerSingleton returns always the same instance', () {
      final a = ShspInstanceHandlerSingleton();
      final b = ShspInstanceHandlerSingleton();
      expect(a, same(b));
    });
  });
}
