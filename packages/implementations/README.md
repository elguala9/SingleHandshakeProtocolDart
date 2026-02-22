# SHSP Implementations

[![pub package](https://img.shields.io/pub/v/shsp_implementations.svg)](https://pub.dev/packages/shsp_implementations)
[![License](https://img.shields.io/badge/license-LGPL--3.0-blue.svg)](https://github.com/lgualandi/SingleHandShakeProtocolDart/blob/main/LICENSE)

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
  shsp_implementations: ^1.2.0
```

This will automatically include the required dependencies:
- `shsp_types` ^1.0.7
- `shsp_interfaces` ^1.2.0

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

## Creating SHSP Objects

This package provides factory methods for creating each main SHSP component:

### 1. Creating a ShspSocket

The socket is the foundation for all network communication. Use the `bind()` factory to create and bind a socket:

```dart
import 'dart:io';
import 'package:shsp_implementations/shsp_implementations.dart';

void main() async {
  // Create and bind a new socket to listen on all IPv4 interfaces, port 8000
  final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 8000);
  print('Socket listening on port 8000');
  
  // Set up callbacks for socket events
  socket.setCloseCallback(() => print('Socket closed'));
  socket.setErrorCallback((err) => print('Socket error: $err'));
  
  // Clean up when done
  socket.close();
}
```

### 2. Creating a ShspPeer

A peer represents a remote connection. Use the `create()` factory to create a peer:

```dart
import 'dart:io';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'package:shsp_types/shsp_types.dart';

void main() async {
  final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 8000);
  
  // Define the remote peer's information
  final remotePeer = PeerInfo(
    address: InternetAddress('192.168.1.100'),
    port: 9000,
  );
  
  // Create a peer for communication with that remote address
  final peer = ShspPeer.create(
    remotePeer: remotePeer,
    socket: socket,
  );
  
  // Send a message to the peer
  peer.sendMessage([1, 2, 3, 4]);
  
  peer.close();
  socket.close();
}
```

### 3. Creating a ShspInstance

ShspInstance extends ShspPeer with protocol-aware message handling (handshakes, keep-alive, etc.):

```dart
import 'dart:io';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'package:shsp_types/shsp_types.dart';

void main() async {
  final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 8000);
  
  final remotePeer = PeerInfo(
    address: InternetAddress('192.168.1.100'),
    port: 9000,
  );
  
  // Create a protocol instance with 20-second keep-alive
  final instance = ShspInstance.create(
    remotePeer: remotePeer,
    socket: socket,
    keepAliveSeconds: 20,
  );
  
  // Set up message callback
  instance.setMessageCallback((msg) {
    print('Received message: $msg');
  });
  
  // Start sending keep-alive messages
  instance.startKeepAlive();
  
  // Send handshake
  instance.sendHandshake();
  
  instance.stopKeepAlive();
  instance.close();
  socket.close();
}
```

### 4. Converting a Peer to an Instance

You can upgrade an existing ShspPeer to a ShspInstance using `fromPeer()`:

```dart
import 'dart:io';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'package:shsp_types/shsp_types.dart';

void main() async {
  final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 8000);
  
  final remotePeer = PeerInfo(
    address: InternetAddress('192.168.1.100'),
    port: 9000,
  );
  
  // Start with a basic peer
  final peer = ShspPeer.create(
    remotePeer: remotePeer,
    socket: socket,
  );
  
  // Later, upgrade to protocol instance with keep-alive
  final instance = ShspInstance.fromPeer(
    peer,
    keepAliveSeconds: 25,
  );
  
  instance.startKeepAlive();
  instance.close();
  socket.close();
}
```

### 5. Creating a Low-Level Shsp Object

For direct socket management, use the `Shsp.create()` factory:

```dart
import 'dart:io';
import 'package:shsp_implementations/shsp_implementations.dart';

void main() async {
  // Create a raw UDP socket first
  final rawSocket = await RawDatagramSocket.bind(
    InternetAddress.anyIPv4,
    8000,
  );
  
  // Wrap it in a Shsp object with remote peer info and optional signal
  final shsp = Shsp.create(
    socket: rawSocket,
    remoteIp: '192.168.1.100',
    remotePort: 9000,
    signal: 'CLIENT_HELLO',
  );
  
  print('SHSP signal: ${shsp.getSignal()}');
  
  shsp.close();
}
```

### Complete Example: Creating All Objects Together

```dart
import 'dart:io';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'package:shsp_types/shsp_types.dart';

void main() async {
  // Step 1: Create a socket
  final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 8000);
  print('✓ Socket created on port 8000');
  
  // Step 2: Create a peer
  final remotePeer = PeerInfo(
    address: InternetAddress('192.168.1.100'),
    port: 9000,
  );
  final peer = ShspPeer.create(
    remotePeer: remotePeer,
    socket: socket,
  );
  print('✓ Peer created for 192.168.1.100:9000');
  
  // Step 3: Upgrade to protocol instance
  final instance = ShspInstance.fromPeer(peer, keepAliveSeconds: 20);
  print('✓ Instance created with 20s keep-alive');
  
  // Step 4: Set up and start
  instance.setMessageCallback((msg) {
    print('Message received: $msg');
  });
  
  instance.startKeepAlive();
  print('✓ Keep-alive started');
  
  // Step 5: Clean up
  instance.stopKeepAlive();
  instance.close();
  socket.close();
  print('✓ All objects closed');
}
```

## Working with Singletons

The package provides singleton implementations for managing global SHSP resources. Singletons ensure you have only one instance of critical components throughout your application.

### 1. ShspSocketInfoSingleton

Manages socket configuration (address and port) globally. Loads configuration from `shsp_socket_config.json` file or uses defaults (127.0.0.1:6969).

```dart
import 'package:shsp_implementations/shsp_implementations.dart';

void main() {
  // Get singleton instance (loads from shsp_socket_config.json if exists)
  final info = ShspSocketInfoSingleton();
  print('Address: ${info.address}, Port: ${info.port}');

  // Subsequent calls return the same instance
  final sameInfo = ShspSocketInfoSingleton();
  assert(identical(info, sameInfo));

  // Clean up when needed
  ShspSocketInfoSingleton.destroy();
}
```

**Configuration File (`shsp_socket_config.json`):**

The singleton automatically looks for a file named `shsp_socket_config.json` in the current directory. If the file exists, it loads the configuration from there. If not, it uses default values.

```json
{
  "address": "192.168.1.100",
  "port": 8080
}
```

**Default values (if file not found or fields missing):**
- Address: `127.0.0.1`
- Port: `6969`

### 2. ShspSocketSingleton

Global socket instance with thread-safe initialization. Prevents multiple socket bindings.

```dart
import 'package:shsp_implementations/shsp_implementations.dart';

void main() async {
  // Create singleton socket (thread-safe)
  final socket = await ShspSocketSingleton.bind();

  // Subsequent calls return the same instance
  final socket2 = await ShspSocketSingleton.bind();
  assert(identical(socket, socket2));

  // Access existing instance without async
  final existing = ShspSocketSingleton.instance;

  // Set up message handling
  socket.onMessage = (data, remoteInfo) {
    print('Received: $data from $remoteInfo');
  };

  // Clean up
  ShspSocketSingleton.destroy();
}
```

### 3. MessageCallbackMapSingleton

Global callback registry for message handling across your application.

```dart
import 'package:shsp_implementations/shsp_implementations.dart';

void main() {
  // Get singleton instance
  final callbacks = MessageCallbackMapSingleton();

  // Register callbacks for different message types
  callbacks.addCallback((data, remoteInfo) {
    print('Handler 1: $data');
  });

  callbacks.addCallback((data, remoteInfo) {
    print('Handler 2: $data');
  });

  // All parts of your app use the same callback map
  final sameCallbacks = MessageCallbackMapSingleton();
  assert(identical(callbacks, sameCallbacks));

  // Clean up
  MessageCallbackMapSingleton.destroy();
}
```

### 4. ShspInstanceHandlerSingleton

Global handler for managing SHSP protocol instances.

```dart
import 'package:shsp_implementations/shsp_implementations.dart';

void main() {
  // Get singleton handler
  final handler = ShspInstanceHandlerSingleton();

  // Use it to manage instances across your application
  // (manages peer connections and protocol instances)

  // Subsequent calls return the same instance
  final sameHandler = ShspInstanceHandlerSingleton();
  assert(identical(handler, sameHandler));

  // Clean up
  ShspInstanceHandlerSingleton.destroy();
}
```

### Complete Singleton Usage Example

```dart
import 'package:shsp_implementations/shsp_implementations.dart';

void main() async {
  // NOTE: All singleton constructors have NO parameters
  // Configuration is loaded from shsp_socket_config.json if it exists

  // Step 1: Get socket info singleton (no parameters)
  final info = ShspSocketInfoSingleton();
  print('✓ Socket info: ${info.address}:${info.port}');

  // Step 2: Set up global callbacks (no parameters)
  final callbacks = MessageCallbackMapSingleton();
  callbacks.addCallback((data, remoteInfo) {
    print('Global handler received: $data');
  });
  print('✓ Global callbacks registered');

  // Step 3: Create singleton socket (no parameters)
  final socket = await ShspSocketSingleton.bind();
  print('✓ Singleton socket created');

  // Step 4: Get instance handler (no parameters)
  final handler = ShspInstanceHandlerSingleton();
  print('✓ Instance handler ready');

  // Now all parts of your application share these instances
  // Calling the constructors again returns the same instances

  // Clean up all singletons when done
  ShspSocketSingleton.destroy();
  ShspSocketInfoSingleton.destroy();
  MessageCallbackMapSingleton.destroy();
  ShspInstanceHandlerSingleton.destroy();
  print('✓ All singletons cleaned up');
}
```

### When to Use Singletons

Use singletons when you need:
- **Global socket configuration** across multiple modules
- **Single socket binding** to prevent port conflicts
- **Shared callback registry** for centralized message handling
- **Unified instance management** across your application

### Important Notes

- **Empty constructors**: All singleton constructors have no parameters - this ensures proper singleton behavior
  - `ShspSocketInfoSingleton()` - no parameters, loads from `shsp_socket_config.json` or uses defaults
  - `MessageCallbackMapSingleton()` - no parameters
  - `ShspInstanceHandlerSingleton()` - no parameters
  - `ShspSocketSingleton.bind()` - no parameters, automatically uses the other singletons

- **Configuration**: To customize socket address/port, create a `shsp_socket_config.json` file before calling any singleton

- **Thread-safe**: All singletons are thread-safe, especially `ShspSocketSingleton.bind()` which uses a Completer to prevent race conditions

- **Testing**: Call `.destroy()` on each singleton to reset state during testing or reconfiguration

- **Use case**: Singletons are ideal for applications with a single SHSP connection. For multiple connections or dynamic configurations, use the non-singleton classes instead

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

This project is licensed under the LGPL-3.0 License.
