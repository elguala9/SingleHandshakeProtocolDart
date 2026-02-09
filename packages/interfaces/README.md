# SHSP Interfaces

[![pub package](https://img.shields.io/pub/v/shsp_interfaces.svg)](https://pub.dev/packages/shsp_interfaces)
[![License](https://img.shields.io/badge/license-LGPL--3.0-blue.svg)](https://github.com/lgualandi/SingleHandShakeProtocolDart/blob/main/LICENSE)

Abstract interfaces and contracts for Single HandShake Protocol (SHSP) implementations - defines the core API for peer-to-peer networking.

## Features

- 🏗️ **Abstract interfaces** defining the core SHSP API
- 🔒 **Type-safe contracts** for all protocol components  
- 📚 **Comprehensive documentation** for implementers
- 🎯 **Dependency injection** friendly design
- ⚡ **Async/await** support throughout

## Installation

Add this to your package's `pubspec.yaml`:

```yaml
dependencies:
  shsp_interfaces: ^1.1.0
  shsp_types: ^1.1.0  # Required dependency
```

## Usage

```dart
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

// Implement a custom socket
class MyCustomSocket implements IShspSocket {
  @override
  Future<void> bind(InternetAddress address, int port) async {
    // Your implementation here
  }
  
  @override
  Future<void> send(List<int> data, RemoteInfo remoteInfo) async {
    // Your implementation here
  }
  
  // ... implement other required methods
}
```

## Interfaces Included

- **`IShspSocket`**: Socket implementation contract
- **`IShspPeer`**: Peer management interface
- **`IShspInstance`**: Protocol instance interface  
- **`IShsp`**: Core protocol interface
- **`IShspHandshake`**: Handshake mechanism interface
- **`IShspHandshakeHandler`**: Handshake processing interface

## Architecture

This package provides the foundational contracts that any SHSP implementation must follow. It's designed to:

- Enable multiple implementations of the protocol
- Provide clear separation of concerns
- Support dependency injection and testing
- Maintain consistency across implementations

## Related Packages

- [`shsp_types`](https://pub.dev/packages/shsp_types) - Type definitions (required dependency)
- [`shsp_implementations`](https://pub.dev/packages/shsp_implementations) - Complete implementation

## Documentation

For complete documentation, visit [pub.dev/packages/shsp_interfaces](https://pub.dev/packages/shsp_interfaces).

## License

This project is licensed under the LGPL-3.0 License.
