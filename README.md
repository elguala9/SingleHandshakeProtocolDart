# SingleHandShakeProtocolDart

A comprehensive Dart package for the Single HandShake Protocol (SHSP) that runs seamlessly on backend (CLI/Server), mobile (Flutter), and web platforms.

## Project Structure

This is a unified monorepo containing the SHSP package and its comprehensive test suite:

```
packages/
├── shsp/               # Main unified SHSP package (v1.8.0)
│   ├── lib/
│   │   ├── src/
│   │   │   ├── interfaces/     # Protocol contracts (IShspSocket, IShspPeer, etc.)
│   │   │   ├── types/          # Type definitions (RemoteInfo, SocketProfile, etc.)
│   │   │   ├── impl/           # Concrete implementations
│   │   │   └── utility/        # Helper utilities
│   │   └── shsp.dart           # Main export
│   └── example/                # Usage examples
└── tests/              # Comprehensive test suite (399+ tests)
```

## Getting Started

### Prerequisites
- Dart SDK `>=3.9.4 <4.0.0`
- For mobile: Flutter 3.13.0 or higher

### Installation

#### From pub.dev (Recommended)

Add to your `pubspec.yaml`:

```yaml
dependencies:
  shsp: ^1.8.0
```

Then run:

```bash
dart pub get
```

#### From Git (Development)

```yaml
dependencies:
  shsp:
    git:
      url: https://github.com/lgualandi/SingleHandShakeProtocolDart
      path: packages/shsp
```

### Quick Start

The easiest way to get started is with `initializePointDualShsp()`:

```dart
import 'package:shsp/shsp.dart';

void main() async {
  // Initialize singleton with IPv4/IPv6 support
  await initializePointDualShsp();

  // Use the global socket singleton
  final socket = SingletonDIAccess.get<IDualShspSocketMigratable>();
  print('Socket ready on port ${socket.localPort}');
}
```

### Running Tests

Install dependencies and run tests:

```bash
cd packages/tests
dart pub get
dart test
```

## Core Components

### Unified SHSP Package
The `shsp` package contains everything you need:

**Core Classes:**
- `ShspSocket`: UDP socket with callback management
- `ShspPeer`: High-level peer abstraction for message exchange
- `ShspInstance`: Protocol instance with automatic keep-alive support
- `DualShspSocket`: Dual IPv4/IPv6 socket support
- `ShspSocketSingleton`: Global socket management with state transfer
- `DualShspSocketSingleton`: Dual-stack singleton for IPv4/IPv6
- `RegistrySingletonShspSocket`: Registry-based socket management

**Auto-Wiring Classes (Recommended):**
- `AutoShspPeer`: Automatically binds to `ShspSocketSingleton` with seamless reconnection
- `AutoShspInstance`: Auto-wiring instance with keep-alive and reconnection support

**Compression Codecs:**
- `GZipCodec`: Best compression ratio (slower)
- `LZ4Codec`: Fast compression with reasonable ratios
- `ZstdCodec`: Balanced compression and speed (recommended)

**Utilities:**
- `AddressUtility`: IPv4/IPv6 address formatting
- `CallbackMap`: Generic callback management
- `MessageCallbackMap`: Per-peer message callback mapping
- `Registry<K, V>`: Generic instance registry pattern
- `DualShspSocketSingleton`: Manages dual-stack socket lifecycle

**Initialization:**
- `initializePointDualShsp()`: Convenient entry point for singleton setup

## High-Level API

### Initialize Singleton (Recommended Starting Point)

For most applications, start with `initializePointDualShsp()` to set up the global socket singleton:

```dart
import 'package:shsp/shsp.dart';

void main() async {
  // Initialize singleton with IPv4/IPv6 dual-stack support
  await initializePointDualShsp();

  // Get the singleton socket
  final socket = SingletonDIAccess.get<IDualShspSocketMigratable>();
  print('Socket bound to ${socket.localAddress}:${socket.localPort}');

  // Register socket lifecycle callbacks
  socket.onListening.register((_) => print('Socket listening'));
  socket.onClose.register((_) => print('Socket closed'));
  socket.onError.register((err) => print('Socket error: $err'));

  // Use with AutoShspPeer/AutoShspInstance
  final peer = await AutoShspPeer.create(
    remoteInfo: RemoteInfo('127.0.0.1', 8080),
  );

  // Clean up
  peer.close();
  DualShspSocketSingleton.destroy();
}
```

### AutoShspPeer Example (With Global Socket)

For most use cases, prefer the high-level auto-wiring classes (`AutoShspPeer` and `AutoShspInstance`) which automatically bind to `ShspSocketSingleton` and handle reconnections seamlessly:

```dart
// Create a peer that auto-wires to the global socket
final peer = await AutoShspPeer.create(
  remoteInfo: RemoteInfo('192.168.1.100', 8080),
);

// Register message callbacks - they persist across socket replacements
peer.onMessage((message) {
  print('Received: $message');
});

// Send messages normally
await peer.sendData(Uint8List.fromList([1, 2, 3]));
```

### AutoShspInstance Example

```dart
// Create an instance with auto-wiring and keep-alive support
final instance = await AutoShspInstance.create(
  remoteInfo: RemoteInfo('192.168.1.100', 8080),
  keepAliveSeconds: 30,  // Optional, configurable
);

// Callbacks persist across socket replacements
instance.onData((data) {
  print('Received data: $data');
});

// Send data
await instance.sendData(Uint8List.fromList([1, 2, 3]));
```

### Global Socket Management

Use `ShspSocketSingleton` to manage a global socket and switch between different remote targets:

```dart
// Initialize the singleton with a socket
final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
ShspSocketSingleton.instance = socket;

// Auto classes automatically use the singleton
// When you replace the socket, auto-wired peers/instances reconnect automatically
ShspSocketSingleton.instance = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
```

## Compression Codecs

SHSP supports pluggable compression for UDP data messages, enabling efficient bandwidth usage. The framework includes three production-ready codecs:

- **GZipCodec**: Best compression ratio, suitable for slow networks
- **LZ4Codec**: Fast compression with reasonable ratios, ideal for low-latency applications
- **ZstdCodec**: Balanced compression and speed, recommended for most use cases

Data messages (0x00) are automatically compressed/decompressed. Protocol messages (handshake, keep-alive) remain uncompressed for minimal overhead.

For detailed usage and benchmarking information, see [COMPRESSION_CODEC_USAGE.md](packages/implementations/COMPRESSION_CODEC_USAGE.md).

## Examples

See the `example/` directory for usage examples:
- `socket_example.dart`: ShspSocket usage
- `message_callback_map_test.dart`: IPv4/IPv6 callback map test

## IPv4 vs IPv6 Support

The SHSP socket supports both IPv4 and IPv6. You choose which protocol to use when binding the socket:

### IPv4 Examples

```dart
// IPv4 - Localhost only
final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 8080);

// IPv4 - All network interfaces
final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 8080);

// IPv4 - Specific address
final socket = await ShspSocket.bind(InternetAddress('192.168.1.100'), 8080);
```

### IPv6 Examples

```dart
// IPv6 - Localhost only
final socket = await ShspSocket.bind(InternetAddress.loopbackIPv6, 8080);

// IPv6 - All network interfaces (often supports IPv4 too via dual-stack)
final socket = await ShspSocket.bind(InternetAddress.anyIPv6, 8080);

// IPv6 - Specific address
final socket = await ShspSocket.bind(InternetAddress('2001:db8::1'), 8080);
```

### Key Format

The `MessageCallbackMap` automatically handles both IPv4 and IPv6 addresses:
- **IPv4**: `"192.168.1.100:8080"`
- **IPv6**: `"[2001:db8::1]:8080"` (brackets prevent ambiguity with port)

### Dual-Stack Support

On most systems, binding to `InternetAddress.anyIPv6` creates a dual-stack socket that accepts both IPv4 and IPv6 connections. This is often the best choice for servers that need to support both protocols.

## Development

Each package can be developed and tested independently. Changes to a package will automatically be reflected in dependent packages when using path dependencies.

## License

Private project - All rights reserved
