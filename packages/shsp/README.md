# SHSP - Single HandShake Protocol

A high-performance Dart package implementing the Single HandShake Protocol (SHSP) for peer-to-peer communication over UDP. Works seamlessly on backend (Dart/Server), mobile (Flutter), and web platforms.

## Features

- **Lightweight Protocol**: Minimal overhead for peer-to-peer communication
- **Automatic Handshaking**: Streamlined connection establishment with configurable timeouts
- **Keep-Alive Support**: Maintain connections with periodic heartbeat messages
- **Pluggable Compression**: Built-in support for GZip, LZ4, and Zstd codecs
- **Auto-Wiring Classes**: `AutoShspPeer` and `AutoShspInstance` for simplified usage
- **Global Socket Management**: `ShspSocketSingleton` for seamless socket switching
- **Cross-Platform**: Runs on Dart CLI, Flutter mobile, and web
- **IPv4/IPv6 Support**: Dual-stack ready with automatic address formatting
- **Comprehensive Testing**: 399+ passing tests ensuring reliability

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  shsp: ^1.0.0
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

## Architecture

SHSP is organized into three main components:

### Types
Core type definitions:
- `RemoteInfo`: Address and port information
- `SocketProfile`: Socket configuration and state
- `InstanceProfile`: Instance configuration and state
- Callback type definitions

### Interfaces
Protocol contracts:
- `IShspSocket`: Core socket interface
- `IShspPeer`: Peer abstraction
- `IShspInstance`: Instance abstraction
- `IShspInstanceHandler`: Handler for managing instances
- `ICompressionCodec`: Compression interface

### Implementations
Concrete implementations:
- `ShspSocket`: UDP socket with callback management
- `ShspPeer`: Peer protocol implementation
- `ShspInstance`: Instance with keep-alive support
- `AutoShspPeer`: Auto-wiring peer (recommended for most use cases)
- `AutoShspInstance`: Auto-wiring instance
- `ShspSocketSingleton`: Global socket management
- Compression codecs: `GZipCodec`, `LZ4Codec`, `ZstdCodec`

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

See the `example/` directory in the repository for complete examples:
- [Socket example](https://github.com/lgualandi/SingleHandShakeProtocolDart/tree/main/example)

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
