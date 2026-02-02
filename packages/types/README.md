# SHSP Types

[![pub package](https://img.shields.io/pub/v/shsp_types.svg)](https://pub.dev/packages/shsp_types)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/lgualandi/SingleHandShakeProtocolDart/blob/main/LICENSE)

Type definitions and serializable models for Single HandShake Protocol (SHSP) - a custom networking protocol for peer-to-peer communication.

## Features

- 🔧 **Type-safe models** for network communication
- 📦 **JSON serialization** support for all types
- 🌐 **IPv4 and IPv6** address support
- ✅ **Built-in validation** and error handling
- 🚀 **Zero dependencies** (except for JSON annotations)

## Installation

Add this to your package's `pubspec.yaml`:

```yaml
dependencies:
  shsp_types: ^1.0.5
```

## Usage

```dart
import 'package:shsp_types/shsp_types.dart';

// Create remote info for peer communication
final rinfo = RemoteInfo(InternetAddress.loopbackIPv4, 8080);
print(rinfo); // 127.0.0.1:8080

// Serialize to JSON
final json = rinfo.toJson();
final restored = RemoteInfo.fromJson(json);
```

## Types Included

- **`RemoteInfo`**: Class representing remote address and port information
- **`PeerTypes`**: Peer identification and metadata
- **`StunTypes`**: STUN protocol integration types
- **`InternetAddressConverter`**: JSON serialization for IP addresses

## Documentation

For complete documentation, visit [pub.dev/packages/shsp_types](https://pub.dev/packages/shsp_types).

## License

This project is licensed under the MIT License.
