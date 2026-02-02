import 'package:test/test.dart';
import 'package:shsp_interfaces/src/connection/i_shsp_handshake.dart';
import 'package:shsp_implementations/connection/handshake_ownership.dart';

void main() {
  group('HandshakeOwnership', () {
    test('constructor with non-null signedNonce should store the value', () {
      const testNonce = 'test-signed-nonce-123';
      final handshake = HandshakeOwnership(testNonce);

      expect(handshake.sign(), equals(testNonce));
    });

    test('constructor with null signedNonce should store null', () {
      final handshake = HandshakeOwnership(null);

      expect(handshake.sign(), isNull);
    });

    test('should implement IHandshakeOwnership interface', () {
      final handshake = HandshakeOwnership('test');
      expect(handshake, isA<IHandshakeOwnership>());
    });

    test('sign() should return the same value as constructor parameter', () {
      const testValues = [
        'simple-nonce',
        'complex-nonce-with-special-chars-!@#\$%^&*()',
        '12345',
        '',
        'very-long-nonce-string-that-might-represent-actual-cryptographic-signature-data-with-lots-of-characters',
      ];

      for (final testValue in testValues) {
        final handshake = HandshakeOwnership(testValue);
        expect(handshake.sign(), equals(testValue));
      }
    });

    test('empty string should be handled correctly', () {
      final handshake = HandshakeOwnership('');
      expect(handshake.sign(), equals(''));
      expect(handshake.sign(), isNotNull);
    });

    test('multiple instances with different values should not interfere', () {
      const nonce1 = 'nonce-1';
      const nonce2 = 'nonce-2';
      const nonce3 = 'nonce-3';

      final handshake1 = HandshakeOwnership(nonce1);
      final handshake2 = HandshakeOwnership(nonce2);
      final handshake3 = HandshakeOwnership(nonce3);

      expect(handshake1.sign(), equals(nonce1));
      expect(handshake2.sign(), equals(nonce2));
      expect(handshake3.sign(), equals(nonce3));
    });

    test('constructor with null should work and sign() should return null', () {
      final handshake = HandshakeOwnership(null);

      expect(handshake.sign(), isNull);
      expect(handshake.sign(), isNot(equals('')));
    });

    test('should handle Unicode characters', () {
      const unicodeNonce = '测试-тест-🔐-नमस्ते';
      final handshake = HandshakeOwnership(unicodeNonce);

      expect(handshake.sign(), equals(unicodeNonce));
    });

    test('should handle special whitespace characters', () {
      const whitespaceNonce = '  \t\n\r  nonce-with-whitespace  \t\n\r  ';
      final handshake = HandshakeOwnership(whitespaceNonce);

      expect(handshake.sign(), equals(whitespaceNonce));
    });

    test('InputHandshakeOwnership record should work with constructor', () {
      const testNonce = 'record-based-nonce';
      final input = (signedNonce: testNonce,);

      // Nota: Il costruttore attuale non usa il record, ma per completezza testiamo che il record funzioni
      expect(input.signedNonce, equals(testNonce));

      final handshake = HandshakeOwnership(input.signedNonce);
      expect(handshake.sign(), equals(testNonce));
    });
  });
}
