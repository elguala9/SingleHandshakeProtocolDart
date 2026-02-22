# SHSP Compression Codec Usage Guide

## Overview

SHSP now supports pluggable compression codecs for data messages. The default is **GZip**, but you can switch to other algorithms (LZ4, ZSTD) or implement your own.

## Architecture

- **Interface**: `ICompressionCodec` (in `packages/interfaces`)
- **Implementations**:
  - `GZipCodec` ✅ (default, fully functional)
  - `LZ4Codec` (reference implementation, ready for integration)
  - `ZstdCodec` (reference implementation, ready for integration)

## Using Different Compression Codecs

### 1. Default (GZip) ✅

```dart
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'dart:io';

final socket = await ShspSocket.bind(
  InternetAddress.loopbackIPv4,
  8000,
  // No parameter = uses GZip by default
);

print('Using: ${socket.compressionCodec.name}'); // GZip
```

### 2. Switch to LZ4

```dart
import 'package:shsp_implementations/shsp_base/compression/compression_codecs.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'dart:io';

final lz4Codec = LZ4Codec();
final socket = await ShspSocket.bind(
  InternetAddress.loopbackIPv4,
  8000,
  lz4Codec, // Use LZ4
);

print('Using: ${socket.compressionCodec.name}'); // LZ4
```

### 3. Switch to ZSTD

```dart
import 'package:shsp_implementations/shsp_base/compression/compression_codecs.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'dart:io';

final zstdCodec = ZstdCodec();
final socket = await ShspSocket.bind(
  InternetAddress.loopbackIPv4,
  8000,
  zstdCodec, // Use ZSTD
);

print('Using: ${socket.compressionCodec.name}'); // Zstandard
```

## Implementing a Custom Codec

Create your own compression codec by implementing `ICompressionCodec`:

```dart
import 'package:shsp_interfaces/shsp_interfaces.dart';

class MyCustomCodec implements ICompressionCodec {
  @override
  String get name => 'MyCustom';

  @override
  List<int> encode(List<int> data) {
    // Your compression logic here
    // Return compressed bytes
  }

  @override
  List<int> decode(List<int> data) {
    // Your decompression logic here
    // Return decompressed bytes
  }
}
```

Then use it:

```dart
final myCodec = MyCustomCodec();
final socket = await ShspSocket.bind(address, port, myCodec);
```

## Enabling Real LZ4/ZSTD Support

The current implementations (LZ4Codec, ZstdCodec) are reference implementations that return uncompressed data as fallback.

To enable real compression:

### For LZ4:

1. Add to `pubspec.yaml`:
```yaml
dependencies:
  lz4: ^1.0.0
```

2. Update `packages/implementations/lib/shsp_base/compression/lz4_codec.dart`:
```dart
import 'package:lz4/lz4.dart';

@override
List<int> encode(List<int> data) {
  return lz4Compress(data);
}

@override
List<int> decode(List<int> data) {
  return lz4Decompress(data);
}
```

### For ZSTD:

1. Add to `pubspec.yaml`:
```yaml
dependencies:
  zstd: ^0.6.0
```

2. Update `packages/implementations/lib/shsp_base/compression/zstd_codec.dart`:
```dart
import 'package:zstd/zstd.dart';

@override
List<int> encode(List<int> data) {
  return zstdEncode(data);
}

@override
List<int> decode(List<int> data) {
  return zstdDecode(data);
}
```

## Compression Behavior

### Data Messages (0x00)
- **Always compressed** with the selected codec
- Transparent to the user
- Decompressed automatically on receive

### Protocol Messages (0x01-0x04)
- **Never compressed**
- Pass through unchanged
- Minimal overhead

## Performance Comparison

| Codec | Speed | Compression | CPU Cost | Best For |
|-------|-------|-------------|----------|----------|
| GZip ✅ | ⚡⚡ | 50-95% | Moderate | General use |
| LZ4 | ⚡⚡⚡⚡⚡ | 30-40% | Minimal | Real-time, low-latency |
| ZSTD | ⚡⚡⚡⚡ | 50% | Low | Balance |

## Testing

Run compression codec tests:

```bash
dart test test/compression_codec_test.dart
```

Verify compression in comprehensive tests:

```bash
dart test test/shsp_socket_comprehensive_test.dart --grep="Compression"
```

## Examples

### Example: UDP Game Server

For a game server where latency is critical, use LZ4:

```dart
final gameServerSocket = await ShspSocket.bind(
  InternetAddress.anyIPv4,
  5000,
  LZ4Codec(), // Ultra-fast compression
);
```

### Example: IoT Data Collection

For bandwidth-constrained IoT scenarios, use GZip (default):

```dart
final iotSocket = await ShspSocket.bind(
  InternetAddress.loopbackIPv4,
  9000,
  // Default GZip - good compression ratio
);
```

### Example: Balanced Performance

For balanced needs, use ZSTD:

```dart
final balancedSocket = await ShspSocket.bind(
  InternetAddress.anyIPv4,
  8000,
  ZstdCodec(), // Good compression + speed
);
```

## Monitoring

Check which codec is in use at runtime:

```dart
print('Socket compression: ${socket.compressionCodec.name}');

// Possible outputs:
// - "GZip"
// - "LZ4"
// - "Zstandard"
// - "MyCustom"
```

## Troubleshooting

### "Codec not found" errors

Make sure you've imported the codec:

```dart
import 'package:shsp_implementations/shsp_base/compression/compression_codecs.dart';
```

### Both sides must use the same codec

The receiving socket must be configured with the same codec as the sending socket:

```dart
// Server
final serverCodec = LZ4Codec();
final serverSocket = await ShspSocket.bind(address, 5000, serverCodec);

// Client (must match!)
final clientCodec = LZ4Codec();
final clientSocket = await ShspSocket.bind(address, 0, clientCodec);
```

## Future Improvements

- [ ] Add more codec implementations (Brotli, Snappy)
- [ ] Automatic codec negotiation during handshake
- [ ] Per-message codec selection
- [ ] Compression statistics and monitoring
