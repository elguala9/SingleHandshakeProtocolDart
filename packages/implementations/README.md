# SHSP Implementations

[![pub package](https://img.shields.io/pub/v/shsp_implementations.svg)](https://pub.dev/packages/shsp_implementations)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/lgualandi/SingleHandShakeProtocolDart/blob/main/LICENSE)

Complete implementation of Single HandShake Protocol (SHSP) - provides UDP sockets, handshake logic, and utilities for peer-to-peer networking.

## Features

- 🚀 **Complete SHSP implementation** ready to use
- 📡 **UDP-based networking** with peer-to-peer support
- 🤝 **Multiple handshake mechanisms** (IP, ownership, time-based)
- 🔄 **Callback-driven architecture** for asynchronous communication  
- 🌐 **IPv4 and IPv6 support** with STUN integration
- 🔒 **Cryptographic utilities** for secure communications
- 🛠️ **Comprehensive utilities** for address formatting and data handling
- ⚡ **High performance** UDP socket operations

## Installation

Add this to your package's `pubspec.yaml`:

```yaml
dependencies:
  shsp_implementations: ^1.0.0
```

This will automatically include the required dependencies:
- `shsp_types`
- `shsp_interfaces`

## Quick Start

```dart
import 'package:shsp_implementations/shsp_implementations.dart';

void main() async {
  // Create a new SHSP socket
  final socket = ShspSocket();
  
  // Bind to a local address
  await socket.bind(InternetAddress.anyIPv4, 0);
  
  // Set up message handling
  socket.onMessage = (data, remoteInfo) {
    print('Received: ${String.fromCharCodes(data)} from $remoteInfo');
  };
  
  // Send a message to a peer
  final peer = RemoteInfo(InternetAddress.loopbackIPv4, 8080);
  await socket.send('Hello SHSP!'.codeUnits, peer);
}
```

## Core Components

### Socket Implementation
- **`ShspSocket`**: Complete UDP socket with callback management
- **`RawShspSocket`**: Low-level socket operations

### Protocol Management  
- **`Shsp`**: Core protocol implementation
- **`ShspInstance`**: Protocol instance management
- **`ShspPeer`**: Peer connection management

### Handshake Mechanisms
- **`HandshakeIp`**: IP-based handshakes
- **`HandshakeOwnership`**: Ownership verification
- **`HandshakeTime`**: Time-based handshakes

### Utilities
- **`CallbackMap`**: Multiple callback management
- **`MessageCallbackMap`**: Message-specific callbacks  
- **`AddressUtility`**: Address formatting
- **`ConcatUtility`**: Data concatenation

## Advanced Usage

```dart
import 'package:shsp_implementations/shsp_implementations.dart';

void advancedExample() async {
  final shsp = Shsp();
  
  // Configure with custom handshake
  final handshake = HandshakeIp();
  await shsp.configure(handshake: handshake);
  
  // Set up peer discovery
  shsp.onPeerDiscovered = (peer) {
    print('New peer discovered: $peer');
  };
  
  // Start the protocol
  await shsp.start();
  
  // Use callback map for organized message handling
  final callbackMap = MessageCallbackMap<String>();
  callbackMap.addCallback('greeting', (data, peer) {
    print('Greeting received from $peer: $data');
  });
}
```

## Related Packages

- [`shsp_types`](https://pub.dev/packages/shsp_types) - Type definitions
- [`shsp_interfaces`](https://pub.dev/packages/shsp_interfaces) - Abstract interfaces

## Performance

The implementation is optimized for:
- Low-latency UDP communication
- Efficient memory usage
- Minimal allocations in hot paths
- Asynchronous operations throughout

## Documentation

For complete API documentation, visit [pub.dev/packages/shsp_implementations](https://pub.dev/packages/shsp_implementations).

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our [GitHub repository](https://github.com/lgualandi/SingleHandShakeProtocolDart).

## License

This project is licensed under the MIT License.
