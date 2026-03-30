import 'dart:io';
import 'dart:typed_data';
import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Example demonstrating the initializePointRegistryAccess() function
///
/// This is the key-based alternative to initializePointDualShsp().
/// Instead of storing the socket in the singleton DI container (accessed by type),
/// it stores it in the global RegistryAccess under an explicit String key.
///
/// Benefits over initializePointDualShsp():
/// - Multiple independent socket instances can coexist (one per key)
/// - Access is explicit: RegistryAccess.getInstance<IDualShspSocketMigratable>(key)
///
/// This example shows:
/// - Basic initialization with initializePointRegistryAccess()
/// - Accessing the socket via RegistryAccess.getInstance()
/// - Setting up socket lifecycle callbacks
/// - Creating peers and sending data
/// - Running multiple named socket instances side by side
/// - Proper resource cleanup

Future<void> main() async {
  print('SHSP Initialize Point — RegistryAccess Example');
  print('===============================================\n');

  try {
    // Step 1: Initialize and register under a string key
    print('Initializing SHSP socket under key "main"...');
    await initializePointRegistryAccess('main');
    print('✓ Socket registered\n');

    // Step 2: Access the socket by key
    final dualSocket = RegistryAccess.getInstance<IDualShspSocketMigratable>('main');
    print('Socket Details:');
    print('  Key: "main"');
    print('  Local Address: ${dualSocket.localAddress}');
    print('  Local Port: ${dualSocket.localPort}');
    print('  Is Closed: ${dualSocket.isClosed}');
    print('  Compression Codec: ${dualSocket.compressionCodec.runtimeType}\n');

    // Step 3: Register socket lifecycle callbacks
    print('Setting up socket callbacks...');
    dualSocket.onListening.register((_) {
      print('→ Socket is listening');
    });

    dualSocket.onClose.register((_) {
      print('→ Socket closed');
    });

    dualSocket.onError.register((error) {
      print('→ Socket error: $error');
    });
    print('✓ Callbacks registered\n');

    // Step 4: Create a peer and register a message callback
    print('Setting up peer callback...');
    final peer1 = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9001);

    dualSocket.setMessageCallback(peer1, (record) {
      print(
        '→ Received ${record.msg.length} bytes from ${record.rinfo.address}:${record.rinfo.port}',
      );
    });
    print('✓ Peer callback registered\n');

    // Step 5: Send data to the peer
    print('Sending test data...');
    final testData = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"
    dualSocket.sendTo(testData.toList(), peer1);
    print(
      '✓ Sent ${testData.length} bytes to ${peer1.address}:${peer1.port}\n',
    );

    // Step 6: Demonstrate multiple keys — independent socket instances
    print('Initializing a secondary socket under key "secondary"...');
    await initializePointRegistryAccess('secondary');
    final secondarySocket =
        RegistryAccess.getInstance<IDualShspSocketMigratable>('secondary');
    print('  Secondary Local Port: ${secondarySocket.localPort}');
    print('  Registry contains "main": ${RegistryAccess.contains<IDualShspSocketMigratable>("main")}');
    print('  Registry contains "secondary": ${RegistryAccess.contains<IDualShspSocketMigratable>("secondary")}\n');

    // Step 7: Extract and inspect socket profile
    print('Extracting socket profile...');
    final profile = dualSocket.extractProfile();
    print('Socket Profile:');
    print('  Message Listeners: ${profile.messageListeners.length}');
    print('  Has Message Callbacks: ${profile.messageListeners.isNotEmpty}\n');

    // Step 8: Simulate some operations
    print('Running socket operations...');
    await Future.delayed(const Duration(seconds: 1));
    print('✓ Operations complete\n');

    // Step 9: Cleanup (important!)
    print('Cleaning up...');
    dualSocket.close();
    secondarySocket.close();
    RegistryAccess.unregister<IDualShspSocketMigratable>('main');
    RegistryAccess.unregister<IDualShspSocketMigratable>('secondary');
    print('✓ Sockets closed and registry entries removed');
    print('\n✓ Example completed successfully!');
  } catch (e) {
    print('✗ Error: $e');
  }
}
