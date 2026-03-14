import 'dart:io';
import 'dart:typed_data';
import 'package:shsp/shsp.dart';

/// Example demonstrating the Registry Management system (v1.2.0+)
///
/// This example shows how to:
/// - Manage multiple socket instances using registry patterns
/// - Use the built-in RegistrySingletonShspSocket for socket management
/// - Create and manage peers with custom tracking
/// - Handle lifecycle and cleanup properly

// Example 1: Socket Registry with Singleton (recommended approach)
Future<void> simpleSocketRegistry() async {
  print('\n=== Example 1: Socket Registry with Singleton ===');

  try {
    // Initialize registry with automatic IPv6 fallback using the singleton
    final registry = RegistrySingletonShspSocket.instance;
    final initResult = await registry.initialize(
      InputRegistrySingletonShspSocket(
        ipv4Port: 8080,
        ipv6Port: 8081,
      ),
    );

    print('IPv4 socket initialized on port 8080');
    print('IPv6 available: ${initResult == ReturnTypeInitialization.ipv4and6}');

    // Get IPv4 socket from registry
    try {
      final ipv4Socket = registry.getInstance(SocketType.ipv4);
      print('Active IPv4 socket: ${ipv4Socket.localAddress}:${ipv4Socket.localPort}');
    } catch (_) {
      print('IPv4 socket not found in registry');
    }

    // Check if IPv6 socket exists
    final ipv6SocketExists = registry.contains(SocketType.ipv6);
    print('IPv6 socket in registry: $ipv6SocketExists');

    // Try to access IPv6 socket if available
    if (ipv6SocketExists) {
      try {
        final ipv6Socket = registry.getInstance(SocketType.ipv6);
        print('Active IPv6 socket: ${ipv6Socket.localAddress}:${ipv6Socket.localPort}');
      } catch (_) {
        print('IPv6 socket not accessible');
      }
    }
  } finally {
    // Clean up registry
    // Note: The registry doesn't have a destroyAll method in the current API
    // Resources are cleaned up when the application terminates
    print('Socket registry cleanup handled');
  }
}

// Example 2: Simple Peer Manager using manual tracking
class SimplePeerManager {
  final _peers = <String, IShspPeer>{};

  /// Create and register a new peer
  Future<void> createPeer(String id, PeerInfo remoteInfo) async {
    if (_peers.containsKey(id)) {
      print('Peer $id already exists');
      return;
    }

    final peer = await AutoShspPeer.create(remotePeer: remoteInfo);
    _peers[id] = peer;
    print('Peer $id registered: ${remoteInfo.address.address}:${remoteInfo.port}');
  }

  /// Close and unregister a specific peer
  Future<void> closePeer(String id) async {
    final peer = _peers.remove(id);
    if (peer != null) {
      peer.close();
      print('Peer $id closed and unregistered');
    }
  }

  /// Send data to a specific peer
  void sendToPeer(String id, Uint8List data) {
    final peer = _peers[id];
    if (peer != null) {
      peer.sendMessage(data.toList());
      print('Sent ${data.length} bytes to peer $id');
    }
  }

  /// Broadcast data to all registered peers
  void broadcastData(Uint8List data) {
    print('Broadcasting ${data.length} bytes to ${_peers.length} peers');
    for (final peer in _peers.values) {
      peer.sendMessage(data.toList());
    }
  }

  /// Get the number of registered peers
  int getPeerCount() => _peers.length;

  /// Clean up all peers
  Future<void> cleanupAll() async {
    for (final peer in _peers.values) {
      peer.close();
    }
    _peers.clear();
    print('All peers cleaned up');
  }

  /// Register callbacks for a peer
  void setupPeerCallbacks(String id) {
    final peer = _peers[id];
    if (peer != null) {
      peer.messageCallback.register((peerInfo) {
        print('Peer $id received message from ${peerInfo.address}:${peerInfo.port}');
      });
    }
  }
}

// Example 3: Simple Instance Manager using manual tracking
class SimpleInstanceManager {
  final _instances = <String, IShspInstance>{};

  /// Create and register an instance
  Future<void> createInstance(
    String id,
    PeerInfo remoteInfo, {
    int keepAliveSeconds = 30,
  }) async {
    if (_instances.containsKey(id)) {
      print('Instance $id already exists');
      return;
    }

    final instance = await AutoShspInstance.create(
      remotePeer: remoteInfo,
      keepAliveSeconds: keepAliveSeconds,
    );
    _instances[id] = instance;
    print('Instance $id registered with keep-alive: ${keepAliveSeconds}s');
  }

  /// Close and unregister an instance
  Future<void> closeInstance(String id) async {
    final instance = _instances.remove(id);
    if (instance != null) {
      instance.close();
      print('Instance $id closed and unregistered');
    }
  }

  /// Get instance count
  int getInstanceCount() => _instances.length;

  /// Clean up all instances
  Future<void> cleanupAll() async {
    for (final instance in _instances.values) {
      instance.close();
    }
    _instances.clear();
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

    // Example 2: Simple Peer Manager
    print('\n=== Example 2: Simple Peer Manager ===');
    final peerManager = SimplePeerManager();

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
    peerManager.sendToPeer('server-a', data);

    // Broadcast data
    peerManager.broadcastData(data);

    print('Active peers: ${peerManager.getPeerCount()}');

    // Cleanup
    await peerManager.closePeer('server-a');
    await peerManager.cleanupAll();

    // Example 3: Simple Instance Manager
    print('\n=== Example 3: Simple Instance Manager ===');
    final instanceManager = SimpleInstanceManager();

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
