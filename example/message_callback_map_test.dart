import 'dart:io';
import 'package:shsp_implementations/shsp_implementations.dart';

/// Test to verify MessageCallbackMap handles both IPv4 and IPv6
void main() {
  print('=== MessageCallbackMap IPv4/IPv6 Test ===\n');

  // Test IPv4
  final ipv4 = InternetAddress('192.168.1.100');
  final ipv4Key = MessageCallbackMap.formatKey(ipv4, 8080);
  print('IPv4 Key: $ipv4Key');

  final ipv4Parsed = MessageCallbackMap.parseKey(ipv4Key);
  print(
    'IPv4 Parsed: address=${ipv4Parsed?.address}, port=${ipv4Parsed?.port}',
  );
  assert(ipv4Parsed?.address == '192.168.1.100');
  assert(ipv4Parsed?.port == 8080);
  print('✓ IPv4 test passed\n');

  // Test IPv6
  final ipv6 = InternetAddress('2001:db8::1');
  final ipv6Key = MessageCallbackMap.formatKey(ipv6, 8080);
  print('IPv6 Key: $ipv6Key');

  final ipv6Parsed = MessageCallbackMap.parseKey(ipv6Key);
  print(
    'IPv6 Parsed: address=${ipv6Parsed?.address}, port=${ipv6Parsed?.port}',
  );
  assert(ipv6Parsed?.address == '2001:db8::1');
  assert(ipv6Parsed?.port == 8080);
  print('✓ IPv6 test passed\n');

  // Test IPv6 loopback
  final ipv6Loopback = InternetAddress('::1');
  final ipv6LoopbackKey = MessageCallbackMap.formatKey(ipv6Loopback, 9090);
  print('IPv6 Loopback Key: $ipv6LoopbackKey');

  final ipv6LoopbackParsed = MessageCallbackMap.parseKey(ipv6LoopbackKey);
  print(
    'IPv6 Loopback Parsed: address=${ipv6LoopbackParsed?.address}, port=${ipv6LoopbackParsed?.port}',
  );
  assert(ipv6LoopbackParsed?.address == '::1');
  assert(ipv6LoopbackParsed?.port == 9090);
  print('✓ IPv6 loopback test passed\n');

  // Test with MessageCallbackMap
  final map = MessageCallbackMap();

  map.addByAddress(ipv4, 8080, (record) {
    print('IPv4 callback triggered: ${String.fromCharCodes(record.msg)}');
  });

  map.addByAddress(ipv6, 8080, (record) {
    print('IPv6 callback triggered: ${String.fromCharCodes(record.msg)}');
  });

  print('Map contains IPv4: ${map.containsAddress(ipv4, 8080)}');
  print('Map contains IPv6: ${map.containsAddress(ipv6, 8080)}');
  assert(map.containsAddress(ipv4, 8080));
  assert(map.containsAddress(ipv6, 8080));
  print('✓ Map storage test passed\n');

  print('All keys in map:');
  for (final key in map.keys) {
    print('  - $key');
  }

  print('\n=== All Tests Passed! ===');
}
