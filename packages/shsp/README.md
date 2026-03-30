# SHSP - Single HandShake Protocol

A high-performance Dart package implementing the Single HandShake Protocol (SHSP) for peer-to-peer communication over UDP. Works seamlessly on backend (Dart/Server), mobile (Flutter), and web platforms.

## Features

- **Lightweight Protocol**: Minimal overhead for peer-to-peer communication
- **Automatic Handshaking**: Streamlined connection establishment with configurable timeouts
- **Keep-Alive Support**: Maintain connections with periodic heartbeat messages
- **Pluggable Compression**: Built-in support for GZip, LZ4, and Zstd codecs
- **Auto-Wiring Classes**: `AutoShspPeer` and `AutoShspInstance` for simplified usage
- **Global Socket Management**: `ShspSocketSingleton` for seamless socket switching
- **Live Socket Migration**: `ShspSocketWrapper` and `DualShspSocketMigratable` allow swapping the underlying socket at runtime without losing peer references or callbacks
- **Cross-Platform**: Runs on Dart CLI, Flutter mobile, and web
- **IPv4/IPv6 Support**: Dual-stack ready with automatic address formatting
- **Comprehensive Testing**: 399+ passing tests ensuring reliability

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  shsp: ^1.6.1
```

Then run:

```bash
dart pub get
```

## Quick Start

### Using AutoShspPeer (Recommended)

The easiest way to get started:

```dart
import 'package:shsp/shsp.dart';
import 'dart:typed_data';

// Create a peer
final peer = await AutoShspPeer.create(
  remoteInfo: RemoteInfo('192.168.1.100', 8080),
);

// Register message callback
peer.onMessage((message) {
  print('Received: $message');
});

// Send data
await peer.sendData(Uint8List.fromList([1, 2, 3]));

// Clean up
await peer.close();
```

### Using AutoShspInstance (With Keep-Alive)

For longer-lived connections:

```dart
final instance = await AutoShspInstance.create(
  remoteInfo: RemoteInfo('192.168.1.100', 8080),
  keepAliveSeconds: 30,
);

instance.onData((data) {
  print('Received data: $data');
});

await instance.sendData(Uint8List.fromList([1, 2, 3]));
await instance.close();
```

### Global Socket Management

For applications with multiple peers/instances:

```dart
// Initialize the singleton with a socket
final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
ShspSocketSingleton.instance = socket;

// Create peers - they automatically use the singleton
final peer1 = await AutoShspPeer.create(remoteInfo: RemoteInfo('192.168.1.100', 8080));
final peer2 = await AutoShspPeer.create(remoteInfo: RemoteInfo('192.168.1.101', 8080));

// Switch socket if needed - all peers reconnect automatically
ShspSocketSingleton.instance = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
```

## Compression

SHSP supports automatic compression for data messages:

```dart
import 'package:shsp/shsp.dart';

// Available compression codecs:
// - GZipCodec: Best compression ratio (slower)
// - LZ4Codec: Fast compression (lower ratio)
// - ZstdCodec: Balanced (recommended)

final peer = await AutoShspPeer.create(
  remoteInfo: RemoteInfo('192.168.1.100', 8080),
  compressionCodec: GZipCodec(),  // Or LZ4Codec(), ZstdCodec()
);

// Compression is automatic for data messages
await peer.sendData(largeData);
```

## IPv4 and IPv6

```dart
// IPv4
final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 8080);

// IPv6 (dual-stack on most systems)
final socket = await ShspSocket.bind(InternetAddress.anyIPv6, 8080);

// Specific address
final socket = await ShspSocket.bind(InternetAddress('192.168.1.100'), 8080);
```

## Registry Management (v1.2.0+)

Manage multiple socket and peer instances efficiently:

```dart
import 'package:shsp/shsp.dart';

// Create a registry for managing multiple sockets
final socketRegistry = <SocketType, IShspSocket>{};

// Register IPv4 and IPv6 sockets
final ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 8080);
final ipv6Socket = await ShspSocket.bind(InternetAddress.anyIPv6, 8080);

socketRegistry[SocketType.ipv4] = ipv4Socket;
socketRegistry[SocketType.ipv6] = ipv6Socket;

// Access sockets by type
final activeSocket = socketRegistry[SocketType.ipv4];

// Clean up all sockets
for (final socket in socketRegistry.values) {
  socket.destroy();
}
```

## Socket Migration (v1.4.0+) and DI (v1.5.0+)

`ShspSocketWrapper` and `DualShspSocketMigratable` allow you to replace the underlying socket at runtime without invalidating any references held by peers or instances.

As of v1.5.0, `IDualShspSocketMigratable` is the primary DI type registered by `initializePointDualShsp()`:

```dart
import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

await initializePointDualShsp();
final socket = SingletonDIAccess.get<IDualShspSocketMigratable>();
// Migration methods are available without casting:
socket.migrateSocketIpv4(newIpv4Socket);
```

```dart
import 'dart:io';
import 'package:shsp/shsp.dart';

// Create a migratable dual socket
final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 8080);
final migratable = DualShspSocketMigratable(ipv4);

// Register a peer callback — this reference stays valid across migrations
final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9001);
migratable.setMessageCallback(peer, (record) {
  print('Received: ${record.msg}');
});

// Later: migrate to a new socket — callbacks are automatically re-applied
final newIpv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 8080);
migratable.migrateSocketIpv4(newIpv4);

// All callbacks and peer references remain intact
migratable.close();
```

For single-socket migration use `ShspSocketWrapper` directly:

```dart
final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 8080);
final wrapper = ShspSocketWrapper(socket);

// Register callbacks
wrapper.setListeningCallback(() => print('Listening'));

// Swap underlying socket — listening callback is re-applied automatically
final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
wrapper.migrateSocket(newSocket);
```

### Advanced: Registry Mixin Pattern

```dart
class MyPeerManager with Registry<String, IShspPeer> {
  Future<void> createPeer(String id, RemoteInfo remoteInfo) async {
    final peer = await AutoShspPeer.create(remoteInfo: remoteInfo);
    register(id, peer);
  }

  Future<void> closePeer(String id) async {
    final peer = unregister(id);
    if (peer != null) {
      await peer.close();
    }
  }

  Future<void> broadcastData(Uint8List data) async {
    for (final item in allItems) {
      await item.value.sendData(data);
    }
  }

  void cleanupAll() {
    destroyAll(); // Calls destroy() on all peers
  }
}

// Usage
final manager = MyPeerManager();
await manager.createPeer('peer1', RemoteInfo('192.168.1.100', 8080));
await manager.createPeer('peer2', RemoteInfo('192.168.1.101', 8080));

await manager.broadcastData(Uint8List.fromList([1, 2, 3]));
manager.cleanupAll();
```

## Architecture

SHSP is organized into three main components:

### Types
Core type definitions:
- `RemoteInfo`: Address and port information
- `SocketProfile`: Socket configuration and state
- `InstanceProfile`: Instance configuration and state
- Callback type definitions

### Interfaces
Protocol contracts for extensibility:
- **Core**: `IShspSocket`, `IShspPeer`, `IShspInstance`, `IShspInstanceHandler`
- **Compression**: `ICompressionCodec`
- **Handshake**: `IShspHandshake`
- **Factories** (for dependency injection): `IShspSocketFactory`, `IShspPeerFactory`, `IShspInstanceFactory`
- **Utilities**: `IAddressUtility`, `ICallbackMap<T>`, `IKeepAliveTimer`, `IMessageCallbackMap`, `IRawShspSocket`, `IDualShspSocket`, `IDualShspSocketMigratable`
- **Wrappers** (v1.4.0+): `IShspSocketWrapper`
- **Singletons**: `IMessageCallbackMapSingleton`, `IShspSocketInfoSingleton`

### Implementations
Concrete implementations:
- `ShspSocket`: UDP socket with callback management
- `ShspPeer`: Peer protocol implementation
- `ShspInstance`: Instance with keep-alive support
- `AutoShspPeer`: Auto-wiring peer (recommended for most use cases)
- `AutoShspInstance`: Auto-wiring instance
- `ShspSocketSingleton`: Global socket management
- `ShspSocketWrapper`: Proxy wrapper enabling live socket migration (v1.4.0+)
- `DualShspSocketMigratable`: Dual-stack socket with live IPv4/IPv6 migration support (v1.4.0+)
- Compression codecs: `GZipCodec`, `LZ4Codec`, `ZstdCodec`

### Registry Utilities (v1.2.0+)
Advanced instance management:
- `Registry<Key, Value>`: Generic mixin for managing keyed instances
- `Singleton`: Type-based instance registry
- `IValueForRegistry`: Interface for registry-managed objects
- `SocketType`: Enumeration for IPv4/IPv6 socket types

## Platform Support

| Platform | Support | Notes |
|----------|---------|-------|
| Dart CLI | ✅ | Full support |
| Flutter iOS | ✅ | Full support |
| Flutter Android | ✅ | Full support |
| Web | ✅ | UDP via WebRTC data channels |
| macOS | ✅ | Full support |
| Windows | ✅ | Full support |
| Linux | ✅ | Full support |

## Requirements

- Dart SDK: `>=3.9.4 <4.0.0`
- For Flutter: Flutter 3.13.0 or higher

## Examples

Comprehensive examples are available in the `example/` directory:

1. **Basic Peer** - Simple peer-to-peer communication
2. **Instance with Keep-Alive** - Long-lived connections with heartbeat
3. **Socket Singleton with Compression** - Global socket management with data compression
4. **Using Interfaces** - Dependency injection and interface-based design
5. **Registry Management** (v1.2.0+) - Advanced instance management with registry patterns
6. **Socket Migration** (v1.4.0+) - Live socket swapping with `ShspSocketWrapper` and `DualShspSocketMigratable`

[View all examples](https://github.com/lgualandi/SingleHandShakeProtocolDart/tree/main/packages/shsp/example)

## Testing

Run the test suite:

```bash
dart pub get
dart test
```

## License

This package is licensed under the GNU Lesser General Public License v3 (LGPL-3.0-only).

See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues on [GitHub](https://github.com/lgualandi/SingleHandShakeProtocolDart).

## Support

For issues, questions, or suggestions, please use the [GitHub issue tracker](https://github.com/lgualandi/SingleHandShakeProtocolDart/issues).
