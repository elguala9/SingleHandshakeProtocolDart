import 'dart:io';
import 'dart:typed_data';
import 'package:shsp/shsp.dart';

/// Example demonstrating the Registry Management system (v1.2.0+)
///
/// This example shows how to:
/// - Manage multiple socket instances using registry patterns
/// - Use the Registry mixin for custom instance management
/// - Implement peer managers with registry support
/// - Handle lifecycle and cleanup properly

// Example 1: Simple Socket Registry
Future<void> simpleSocketRegistry() async {
  print('\n=== Example 1: Socket Registry ===');

  // Create a registry for managing multiple sockets
  final socketRegistry = <SocketType, IShspSocket>{};

  try {
    // Bind IPv4 socket
    final ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 8080);
    socketRegistry[SocketType.ipv4] = ipv4Socket;
    print('IPv4 socket registered: ${ipv4Socket.localAddress}:${ipv4Socket.localPort}');

    // Bind IPv6 socket
    final ipv6Socket = await ShspSocket.bind(InternetAddress.anyIPv6, 8081);
    socketRegistry[SocketType.ipv6] = ipv6Socket;
    print('IPv6 socket registered: ${ipv6Socket.localAddress}:${ipv6Socket.localPort}');

    // Access sockets by type
    final activeIpv4 = socketRegistry[SocketType.ipv4];
    print('Active IPv4 socket: ${activeIpv4?.localPort}');

    // Check if socket type exists
    if (socketRegistry.containsKey(SocketType.ipv4)) {
      print('IPv4 socket exists in registry');
    }
  } finally {
    // Clean up all sockets
    for (final socket in socketRegistry.values) {
      socket.destroy();
    }
    print('All sockets destroyed');
  }
}

// Example 2: Peer Manager with Registry Mixin
class PeerManager with Registry<String, IShspPeer> {
  /// Create and register a new peer
  Future<void> createPeer(String id, PeerInfo remoteInfo) async {
    if (contains(id)) {
      print('Peer $id already exists');
      return;
    }

    final peer = await AutoShspPeer.create(remotePeer: remoteInfo);
    register(id, peer);
    print('Peer $id registered: ${remoteInfo.address.address}:${remoteInfo.port}');
  }

  /// Close and unregister a specific peer
  Future<void> closePeer(String id) async {
    final peer = unregister(id);
    if (peer != null) {
      await peer.close();
      print('Peer $id closed and unregistered');
    }
  }

  /// Send data to a specific peer
  Future<void> sendToPeer(String id, Uint8List data) async {
    final peer = getByKey(id);
    if (peer != null) {
      await peer.sendData(data);
      print('Sent ${data.length} bytes to peer $id');
    }
  }

  /// Broadcast data to all registered peers
  Future<void> broadcastData(Uint8List data) async {
    print('Broadcasting ${data.length} bytes to ${registrySize} peers');
    for (final peer in allValues) {
      await peer.sendData(data);
    }
  }

  /// Get the number of registered peers
  int getPeerCount() => registrySize;

  /// Clean up all peers
  Future<void> cleanupAll() async {
    final peersCopy = allValues;
    for (final peer in peersCopy) {
      await peer.close();
    }
    clearRegistry();
    print('All peers cleaned up');
  }

  /// Register callbacks for a peer
  void setupPeerCallbacks(String id) {
    final peer = getByKey(id);
    if (peer != null) {
      peer.onMessage((message) {
        print('Peer $id received message from ${message.remotePeer.address}:${message.remotePeer.port}');
      });

      peer.onClose(() {
        print('Peer $id closed');
      });
    }
  }
}

// Example 3: Instance Manager with Registry
class InstanceManager with Registry<String, IShspInstance> {
  /// Create and register an instance
  Future<void> createInstance(
    String id,
    PeerInfo remoteInfo, {
    int keepAliveSeconds = 30,
  }) async {
    if (contains(id)) {
      print('Instance $id already exists');
      return;
    }

    final instance = await AutoShspInstance.create(
      remotePeer: remoteInfo,
      keepAliveSeconds: keepAliveSeconds,
    );
    register(id, instance);
    print('Instance $id registered with keep-alive: ${keepAliveSeconds}s');
  }

  /// Close and unregister an instance
  Future<void> closeInstance(String id) async {
    final instance = unregister(id);
    if (instance != null) {
      await instance.close();
      print('Instance $id closed and unregistered');
    }
  }

  /// Get instance count
  int getInstanceCount() => registrySize;

  /// Clean up all instances
  Future<void> cleanupAll() async {
    final instancesCopy = allValues;
    for (final instance in instancesCopy) {
      await instance.close();
    }
    clearRegistry();
    print('All instances cleaned up');
  }
}

// Example 4: Run all demonstrations
Future<void> main() async {
  print('SHSP Registry Management Examples (v1.2.0+)');
  print('============================================');

  try {
    // Example 1: Simple socket registry
    await simpleSocketRegistry();

    // Example 2: Peer Manager with Registry Mixin
    print('\n=== Example 2: Peer Manager ===');
    final peerManager = PeerManager();

    final peer1Info = PeerInfo(
      address: InternetAddress('127.0.0.1'),
      port: 9001,
    );

    final peer2Info = PeerInfo(
      address: InternetAddress('127.0.0.1'),
      port: 9002,
    );

    // Create peers
    await peerManager.createPeer('server-a', peer1Info);
    await peerManager.createPeer('server-b', peer2Info);

    // Setup callbacks
    peerManager.setupPeerCallbacks('server-a');
    peerManager.setupPeerCallbacks('server-b');

    // Send data
    final data = Uint8List.fromList([1, 2, 3, 4, 5]);
    await peerManager.sendToPeer('server-a', data);

    // Broadcast data
    await peerManager.broadcastData(data);

    print('Active peers: ${peerManager.getPeerCount()}');

    // Cleanup
    await peerManager.closePeer('server-a');
    await peerManager.cleanupAll();

    // Example 3: Instance Manager
    print('\n=== Example 3: Instance Manager ===');
    final instanceManager = InstanceManager();

    final instanceInfo = PeerInfo(
      address: InternetAddress('127.0.0.1'),
      port: 9003,
    );

    // Create instance with keep-alive
    await instanceManager.createInstance(
      'main-connection',
      instanceInfo,
      keepAliveSeconds: 30,
    );

    print('Active instances: ${instanceManager.getInstanceCount()}');

    // Cleanup
    await instanceManager.closeInstance('main-connection');

    print('\n=== Examples Complete ===');
    print('All resources cleaned up successfully');
  } catch (e) {
    print('Error: $e');
  }
}
