# SHSP Examples

This directory contains practical examples of using the Single HandShake Protocol (SHSP) package.

## Examples

### 0. Initialize Point (`initialize_point.dart`) - v1.2.1+

The recommended starting point for most applications. Sets up the global socket singleton with IPv4/IPv6 support in one call.

**Demonstrates:**
- Using `initializePointShsp()` for easy setup
- Accessing the global dual socket singleton
- Setting up socket lifecycle callbacks
- Extracting socket profiles
- Proper resource cleanup with DualShspSocketSingleton

**Run:**
```bash
dart example/initialize_point.dart
```

### 1. Basic Peer (`basic_peer.dart`)

The simplest example - create a peer, send data, and receive messages.

**Demonstrates:**
- Creating a peer connection
- Registering message callbacks
- Sending data
- Proper cleanup

**Run:**
```bash
dart example/basic_peer.dart
```

### 2. Instance with Keep-Alive (`instance_with_keepalive.dart`)

Create a long-lived connection with automatic keep-alive support and lifecycle callbacks.

**Demonstrates:**
- Creating an instance with keep-alive
- Lifecycle callbacks (handshake, opening, data, closing, close)
- Long-lived connection management
- Proper cleanup with state notifications

**Run:**
```bash
dart example/instance_with_keepalive.dart
```

### 3. Socket Singleton with Compression (`singleton_with_compression.dart`)

Advanced example using global socket management and data compression.

**Demonstrates:**
- Using `ShspSocketSingleton` for global socket management
- Multiple peers sharing the same socket
- Data compression (GZip, Zstd)
- Socket switching and automatic peer reconnection

**Run:**
```bash
dart example/singleton_with_compression.dart
```

### 4. Using Interfaces (`using_interfaces.dart`)

Demonstrates dependency injection and interface-based design for better testability.

**Demonstrates:**
- Type-safe programming with interfaces
- Dependency injection patterns
- Factory interfaces for custom creation logic
- Benefits for unit testing and mocking

**Run:**
```bash
dart example/using_interfaces.dart
```

### 5. Registry Management (`registry_management.dart`) - v1.2.0+

Advanced example showcasing the new registry system for managing multiple instances.

**Demonstrates:**
- Socket registry for managing multiple sockets (IPv4/IPv6)
- Peer manager using the Registry mixin pattern
- Instance manager with lifecycle support
- Broadcast patterns for multiple destinations
- Proper resource cleanup and lifecycle management

**Run:**
```bash
dart example/registry_management.dart
```

## Common Patterns

### Creating a Peer

```dart
final peer = await AutoShspPeer.create(
  remoteInfo: RemoteInfo.fromString('192.168.1.100:8080')!,
);
```

### Creating an Instance (with keep-alive)

```dart
final instance = await AutoShspInstance.create(
  remoteInfo: RemoteInfo.fromString('192.168.1.100:8080')!,
  keepAliveSeconds: 30,
);
```

### Using Custom Socket

```dart
final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 9000);
final peer = await AutoShspPeer.create(
  remoteInfo: RemoteInfo.fromString('192.168.1.100:8080')!,
  socket: socket,
);
```

### With Compression

```dart
final peer = await AutoShspPeer.create(
  remoteInfo: RemoteInfo.fromString('192.168.1.100:8080')!,
  compressionCodec: ZstdCodec(), // or GZipCodec(), LZ4Codec()
);
```

### Receiving Messages

```dart
peer.onMessage((message) {
  print('From: ${message.remotePeer.address}:${message.remotePeer.port}');
  print('Payload: ${message.payload}');
});
```

## Testing

All examples can be tested by running:

```bash
dart pub get

# Start with the initialization point (recommended first)
dart example/initialize_point.dart

# Then try other examples
dart example/basic_peer.dart
dart example/instance_with_keepalive.dart
dart example/singleton_with_compression.dart
dart example/using_interfaces.dart
dart example/registry_management.dart
```

Note: Some examples require a remote SHSP server running on the specified address/port to fully demonstrate functionality. For isolated testing, see the test suite in `packages/tests/`.

## Troubleshooting

- **"Connection refused"**: Ensure there's a remote SHSP server listening on the specified address/port
- **"Port already in use"**: Another process is using the port; use a different port number
- **"Permission denied"**: Ports below 1024 require elevated privileges; use ports >= 1024

## License

These examples are part of the SHSP package and are licensed under LGPL-3.0.
