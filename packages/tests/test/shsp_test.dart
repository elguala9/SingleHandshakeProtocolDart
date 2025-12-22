import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_implementations/src/shsp.dart';

void main() {
  group('Shsp', () {
    late RawDatagramSocket socket;
    late Shsp shsp;
    const testRemoteIp = '192.168.1.100';
    const testRemotePort = 8080;

    setUp(() async {
      socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      shsp = Shsp(
        socket: socket,
        remoteIp: testRemoteIp,
        remotePort: testRemotePort,
      );
    });

    tearDown(() {
      shsp.close();
    });

    test('getSignal should return empty string initially', () {
      expect(shsp.getSignal(), equals(''));
    });

    test('setSignal and getSignal should work correctly', () {
      const testSignal = 'test-signal-123';
      shsp.setSignal(testSignal);
      expect(shsp.getSignal(), equals(testSignal));
    });

    test('getSocket should return the provided socket', () {
      expect(shsp.getSocket(), equals(socket));
    });

    test('serializedObject should return correct JSON structure', () {
      const testSignal = 'test-signal-456';
      shsp.setSignal(testSignal);
      
      final serialized = shsp.serializedObject();
      final decoded = jsonDecode(serialized);
      
      expect(decoded, isA<Map<String, dynamic>>());
      expect(decoded['remoteIp'], equals(testRemoteIp));
      expect(decoded['remotePort'], equals(testRemotePort));
      expect(decoded['signal'], equals(testSignal));
    });

    test('serializedObject should handle empty signal', () {
      final serialized = shsp.serializedObject();
      final decoded = jsonDecode(serialized);
      
      expect(decoded['signal'], equals(''));
    });

    test('should implement IShsp interface', () {
      expect(shsp, isA<IShsp>());
    });

    test('setSignal with null-like values should work', () {
      shsp.setSignal('');
      expect(shsp.getSignal(), equals(''));
      
      shsp.setSignal('non-empty');
      expect(shsp.getSignal(), equals('non-empty'));
      
      shsp.setSignal('');
      expect(shsp.getSignal(), equals(''));
    });

    test('multiple signal updates should work', () {
      const signals = ['signal1', 'signal2', 'signal3'];
      
      for (final signal in signals) {
        shsp.setSignal(signal);
        expect(shsp.getSignal(), equals(signal));
      }
    });
  });
}