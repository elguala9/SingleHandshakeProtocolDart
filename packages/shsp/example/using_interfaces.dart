/// Using SHSP Interfaces for Dependency Injection and Testing
///
/// This example demonstrates:
/// - Using factory interfaces for dependency injection
/// - Type-safe programming with interfaces
/// - Benefits for testing and mocking

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
  Future<int> sendToPeer(
    InternetAddress address,
    int port,
    List<int> data,
  ) async {
    return socket.sendTo(Uint8List.fromList(data), address, port);
  }
}

/// Example factory service
class PeerFactory implements IShspPeerFactory {
  final IShspSocket socket;

  PeerFactory(this.socket);

  @override
  IShspPeer create({
    required PeerInfo remotePeer,
    required IShspSocket socket,
  }) {
    // Custom creation logic here
    return ShspPeer(remotePeer: remotePeer, socket: socket);
  }

  @override
  IShspPeer createFromRemoteInfo({
    required PeerInfo remotePeer,
    required RawDatagramSocket rawSocket,
  }) {
    // Custom creation with raw socket
    final messageCallbacks = MessageCallbackMapFactory.create();
    final shspSocket = ShspSocketFactory.create(rawSocket, messageCallbacks);
    return ShspPeer(remotePeer: remotePeer, socket: shspSocket);
  }
}

void main() async {
  print('=== Using SHSP Interfaces Example ===\n');

  // Create socket and callbacks using interfaces
  final rawSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final socket = ShspSocketFactory.createFromSocket(rawSocket);
  final callbacks = MessageCallbackMapFactory.create();

  // Create message service with dependency injection
  final messageService = MessageService(socket: socket, callbacks: callbacks);

  // Create custom peer factory
  final peerFactory = PeerFactory(socket);

  print('Created services with interface-based dependencies');

  // Register a callback for a remote peer
  final remoteAddress = InternetAddress('127.0.0.1');
  messageService.registerPeerCallback(remoteAddress, 9000, (message) {
    print('Received data: ${message.payload}');
  });

  // Use the factory to create a peer
  print('\nCreating peer via custom factory...');
  // Note: In a real scenario, you would have error handling

  // Send some data
  print('\nSending data...');
  final bytesSent = await messageService.sendToPeer(
    remoteAddress,
    9000,
    [1, 2, 3, 4, 5],
  );
  print('Sent $bytesSent bytes');

  // Benefits of using interfaces:
  // 1. Easy to mock for testing
  // 2. Easy to create alternative implementations
  // 3. Type-safe dependency injection
  // 4. Decoupled service dependencies

  print('\n✓ Interface usage example completed');
  print('Benefits:');
  print('  - Easy to test with mock implementations');
  print('  - Decoupled components');
  print('  - Type-safe API');

  // Clean up
  await socket.close();
}
