import 'dart:io';
import 'dart:typed_data';
import 'package:shsp/shsp.dart';

/// Example demonstrating live socket migration (v1.4.0+)
///
/// [ShspSocketWrapper] and [DualShspSocketMigratable] allow the underlying
/// UDP socket to be replaced at runtime without invalidating any peer
/// references or losing registered callbacks.
///
/// This is useful for:
/// - Network interface changes (Wi-Fi ↔ cellular handover)
/// - Port rebinding after a network reset
/// - Testing / fault injection

// ── Example 1: Single-socket migration with ShspSocketWrapper ─────────────

Future<void> singleSocketMigration() async {
  print('\n=== Example 1: ShspSocketWrapper migration ===');

  final original = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
  final wrapper = ShspSocketWrapper(original);

  // Register callbacks on the wrapper — they survive migration
  wrapper.setListeningCallback(() => print('  [wrapper] listening'));
  wrapper.setCloseCallback(() => print('  [wrapper] closed'));

  final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9010);
  wrapper.setMessageCallback(peer, (record) {
    print('  [wrapper] received ${record.msg.length} bytes from $peer');
  });

  print('  Original socket port: ${wrapper.localPort}');

  // Migrate to a new socket — all callbacks are re-applied automatically
  final replacement = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
  wrapper.migrateSocket(replacement);

  print('  After migration port: ${wrapper.localPort}');
  print('  Callbacks still active: true');

  wrapper.close();
  print('  Done.');
}

// ── Example 2: Dual-socket migration with DualShspSocketMigratable ────────

Future<void> dualSocketMigration() async {
  print('\n=== Example 2: DualShspSocketMigratable migration ===');

  final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
  final migratable = DualShspSocketMigratable(ipv4);

  // Register a message callback
  final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9020);
  migratable.setMessageCallback(peer, (record) {
    print('  [dual] received ${record.msg.length} bytes');
  });

  print('  IPv4 port before migration: ${migratable.localPort}');

  // Bind a new socket and migrate the IPv4 slot
  final newIpv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
  migratable.migrateSocketIpv4(newIpv4);

  print('  IPv4 port after migration:  ${migratable.localPort}');

  // Send a test packet to ourselves to verify the new socket works
  final data = Uint8List.fromList([1, 2, 3]);
  migratable.sendTo(data.toList(), peer);
  print('  Sent ${data.length} bytes through migrated socket');

  migratable.close();
  print('  Done.');
}

// ── Example 3: fromWrappers constructor ───────────────────────────────────

Future<void> fromWrappersExample() async {
  print('\n=== Example 3: DualShspSocketMigratable.fromWrappers ===');

  final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
  final ipv4Wrapper = ShspSocketWrapper(ipv4);

  // Pre-configure the wrapper before injecting it
  ipv4Wrapper.setListeningCallback(() => print('  [fromWrappers] listening'));

  final migratable = DualShspSocketMigratable.fromWrappers(ipv4Wrapper);

  print('  Migratable implements IDualShspSocketMigratable: '
      '${migratable is IDualShspSocketMigratable}');
  print('  ipv4SocketImpl is ShspSocketWrapper: '
      '${migratable.ipv4SocketImpl is ShspSocketWrapper}');

  migratable.close();
  print('  Done.');
}

Future<void> main() async {
  print('SHSP Socket Migration Example (v1.4.0+)');
  print('=========================================');

  try {
    await singleSocketMigration();
    await dualSocketMigration();
    await fromWrappersExample();

    print('\n=== All examples completed successfully ===');
  } catch (e, st) {
    print('Error: $e\n$st');
  }
}
