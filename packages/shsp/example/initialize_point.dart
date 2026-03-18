import 'dart:io';
import 'dart:typed_data';
import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Example demonstrating the initializePointShsp() function
///
/// This is the recommended entry point for setting up SHSP in your application.
/// It automatically:
/// - Creates and initializes dual IPv4/IPv6 sockets
/// - Sets up the singleton DI container
/// - Manages socket lifecycle with proper cleanup
///
/// This example shows:
/// - Basic initialization with initializePointShsp()
/// - Accessing the global socket singleton
/// - Setting up socket lifecycle callbacks
/// - Creating peers/instances from the initialized socket
/// - Proper resource cleanup

Future<void> main() async {
  print('SHSP Initialize Point Example');
  print('==============================\n');

  try {
    // Step 1: Initialize the singleton
    // This creates both IPv4 and IPv6 sockets and registers them in DI
    print('Initializing SHSP singleton...');
    await initializePointShsp();
    print('✓ Singleton initialized\n');

    // Step 2: Get the dual socket from DI
    final dualSocket = SingletonDIAccess.get<IDualShspSocket>();
    print('Socket Details:');
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

    // Step 4: Get the registry singleton
    final registry = SingletonDIAccess.get<RegistrySingletonShspSocket>();
    print('Registry Details:');
    print('  Type: ${registry.runtimeType}');
    print('  IPv4 Socket: ${registry.getInstance(SocketType.ipv4).runtimeType}');
    if (await AddressUtility.canCreateIPv6Socket()) {
      print('  IPv6 Socket: ${registry.getInstance(SocketType.ipv6).runtimeType}');
    } else {
      print('  IPv6 Socket: Not available on this system');
    }
    print('');

    // Step 5: Create a peer using the initialized socket
    print('Creating peers using the initialized socket...');
    final peer1 = PeerInfo(
      address: InternetAddress.loopbackIPv4,
      port: 9001,
    );

    // Register a message callback for this peer
    dualSocket.setMessageCallback(peer1, (record) {
      print('→ Received ${record.msg.length} bytes from ${record.rinfo.address}:${record.rinfo.port}');
    });

    print('✓ Peer callback registered\n');

    // Step 6: Send data to a peer
    print('Sending test data...');
    final testData = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"
    dualSocket.sendTo(testData.toList(), peer1);
    print('✓ Sent ${testData.length} bytes to ${peer1.address}:${peer1.port}\n');

    // Step 7: Extract and inspect socket profile
    print('Extracting socket profile...');
    final profile = dualSocket.extractProfile();
    print('Socket Profile:');
    print('  Message Listeners: ${profile.messageListeners.length}');
    print('  Has Message Callbacks: ${profile.messageListeners.isNotEmpty}');
    print('');

    // Step 8: Simulate some operations
    print('Running socket operations...');
    await Future.delayed(const Duration(seconds: 1));
    print('✓ Operations complete\n');

    // Step 9: Cleanup (important!)
    print('Cleaning up...');
    dualSocket.close();
    DualShspSocketSingleton.destroy();
    print('✓ Socket closed and singleton destroyed');
    print('\n✓ Example completed successfully!');
  } catch (e) {
    print('✗ Error: $e');
  }
}
