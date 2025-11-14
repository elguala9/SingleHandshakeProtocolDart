# SingleHandShakeProtocolDart

A Dart monorepo for the Single HandShake Protocol (SHSP) that runs on both backend (CLI/Server) and mobile (Flutter) platforms.

## Monorepo Structure

This project is organized as a monorepo with the following packages:

```
packages/
├── types/              # Type definitions (RemoteInfo, etc.)
├── interfaces/         # Interface contracts (IShspSocket)
├── implementations/    # Concrete implementations (ShspSocket, HandshakeProtocol)
└── tests/             # Comprehensive test suite
```

### Package Dependencies

```
types (no deps)
  ↓
interfaces (depends on types)
  ↓
implementations (depends on types, interfaces)
  ↓
tests (depends on all packages)
```

## Getting Started

### Prerequisites
- Dart SDK 3.0.0 or higher
- For mobile: Flutter SDK

### Installation

Install dependencies for all packages:

```bash
# Install dependencies for each package
cd packages/types && dart pub get
cd ../interfaces && dart pub get
cd ../implementations && dart pub get
cd ../tests && dart pub get
```

Or use the provided script (if you create one):

```bash
./install_all.sh  # or install_all.bat on Windows
```

### Running Tests

Run all tests:

```bash
cd packages/tests
dart test
```

### Using the Packages

#### In a Dart/Backend Project

Add to your `pubspec.yaml`:

```yaml
dependencies:
  shsp_types:
    path: ../SingleHandShakeProtocolDart/packages/types
  shsp_interfaces:
    path: ../SingleHandShakeProtocolDart/packages/interfaces
  shsp_implementations:
    path: ../SingleHandShakeProtocolDart/packages/implementations
```

Then import:

```dart
import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_implementations/shsp_implementations.dart';
```

#### In a Flutter/Mobile Project

Same as above - all packages are platform-agnostic and work on mobile, backend, and web.

## Package Details

### shsp_types
Contains core type definitions:
- `RemoteInfo`: Represents remote address and port

### shsp_interfaces
Contains interface contracts:
- `IShspSocket`: Interface for socket implementations

### shsp_implementations
Contains concrete implementations:
- `ShspSocket`: UDP socket with callback management
- `HandshakeProtocol`: Core protocol logic
- `CallbackMap`: Utility for managing callbacks
- `AddressUtility`: Address formatting utilities

### shsp_tests
Comprehensive test suite for all packages.

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
