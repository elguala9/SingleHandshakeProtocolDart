import 'package:shsp_implementations/shsp_implementations.dart';

/// Backend entry point
/// Run this with: dart run bin/backend_main.dart
void main() async {
  print('=== Single HandShake Protocol - Backend Demo ===\n');

  final protocol = HandshakeProtocol();

  // Example 1: Perform handshake
  print('Example 1: Performing handshake with server...');
  final result1 = await protocol.initiateHandshake('server-01');
  print('Result: $result1\n');

  // Example 2: Validate token
  print('Example 2: Validating tokens...');
  final validToken = 'valid-token-12345';
  final invalidToken = 'short';
  
  print('Token "$validToken" is valid: ${protocol.validateHandshake(validToken)}');
  print('Token "$invalidToken" is valid: ${protocol.validateHandshake(invalidToken)}\n');

  // Example 3: Multiple handshakes
  print('Example 3: Multiple handshakes...');
  final peers = ['server-02', 'server-03', 'server-04'];
  
  for (final peer in peers) {
    final result = await protocol.initiateHandshake(peer);
    print('Handshake with $peer: ${result.success ? "SUCCESS" : "FAILED"}');
  }

  print('\n=== Backend Demo Complete ===');
}
