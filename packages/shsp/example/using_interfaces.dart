/// Using SHSP Interfaces for Type-Safe Programming
///
/// This example demonstrates:
/// - Using factory interfaces for dependency injection
/// - Type-safe programming with interfaces
/// - Creating services with interface dependencies

import 'dart:io';
import 'dart:typed_data';
import 'package:shsp/shsp.dart';

/// Example service that depends on SHSP abstractions
class MessageService {
  final IShspSocket socket;
  final IMessageCallbackMap callbacks;

  MessageService({
    required this.socket,
    required this.callbacks,
  });

  /// Register a callback for a remote peer
  void registerPeerCallback(
    InternetAddress address,
    int port,
    MessageCallbackFunction callback,
  ) {
    callbacks.addByAddress(address, port, callback);
    print('Registered callback for ${address.address}:$port');
  }

  /// Send data to a remote peer
  int sendToPeer(
    InternetAddress address,
    int port,
    List<int> data,
  ) {
    final peerInfo = PeerInfo(address: address, port: port);
    return socket.sendTo(Uint8List.fromList(data), peerInfo);
  }

  /// Get number of registered callbacks
  int getCallbackCount() {
    return callbacks.length;
  }
}

void main() async {
  print('=== Using SHSP Interfaces Example ===\n');

  // Create socket and callbacks using factory methods
  final rawSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final socket = ShspSocketFactory.createFromSocket(rawSocket);
  final callbacks = MessageCallbackMapFactory.create();

  print('Created socket on port ${socket.localPort}');
  print('Created callback map\n');

  // Create message service with dependency injection
  final messageService = MessageService(socket: socket, callbacks: callbacks);

  print('Created MessageService with interface-based dependencies\n');

  // Register callbacks for remote peers
  final remoteAddress1 = InternetAddress('127.0.0.1');
  final remoteAddress2 = InternetAddress('192.168.1.100');

  messageService.registerPeerCallback(remoteAddress1, 9000, (message) {
    print('Received from ${remoteAddress1.address}:9000');
  });

  messageService.registerPeerCallback(remoteAddress2, 9001, (message) {
    print('Received from ${remoteAddress2.address}:9001');
  });

  print('Registered ${messageService.getCallbackCount()} callbacks\n');

  // Send some data
  print('Sending data to registered peers...');
  final bytesSent1 = messageService.sendToPeer(
    remoteAddress1,
    9000,
    [1, 2, 3, 4, 5],
  );
  print('✓ Sent $bytesSent1 bytes to peer1');

  final bytesSent2 = messageService.sendToPeer(
    remoteAddress2,
    9001,
    [10, 20, 30],
  );
  print('✓ Sent $bytesSent2 bytes to peer2\n');

  // Benefits of using interfaces:
  print('Benefits of Interface-Based Design:');
  print('  ✓ Easy to mock for unit testing');
  print('  ✓ Decoupled service dependencies');
  print('  ✓ Type-safe dependency injection');
  print('  ✓ Easy to swap implementations');

  // Clean up
  socket.close();
  print('\n✓ Example completed');
}
