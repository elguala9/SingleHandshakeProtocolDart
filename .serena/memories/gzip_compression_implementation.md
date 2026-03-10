# GZip Compression Implementation for SHSP Data Messages - ShspSocket Level

## Completion Date
2026-02-22

## Implementation Summary
Successfully implemented mandatory GZip compression at **ShspSocket level** (transport layer) for all data messages (0x00) while keeping protocol messages (0x01-0x04) uncompressed.

## Changes Made

### File Modified
`packages/shsp/lib/src/impl/shsp_base/shsp_socket.dart`

### 1. Added gzip Support (Already in dart:io)
- Used `gzip.encode()` and `gzip.decode()` from built-in `dart:io` package

### 2. Modified _handleReadEvent() (Lines 56-77)
- Added `_decompressIfData()` method to decompress incoming data messages
```dart
void _handleReadEvent() {
  final Datagram? datagram = socket.receive();
  if (datagram != null) {
    final rinfo = RemoteInfo(address: datagram.address, port: datagram.port);
    final data = _decompressIfData(datagram.data);  // NEW: Decompress if needed
    onMessage(data, rinfo);
  }
}

List<int> _decompressIfData(List<int> msg) {
  // Check if it's a data message (0x00)
  if (msg.isNotEmpty && msg[0] == 0x00) {
    // Decompress payload: everything after prefix
    final decompressed = gzip.decode(msg.sublist(1));
    // Return with prefix restored: [0x00] + decompressed
    return [0x00, ...decompressed];
  }
  // Not a data message, return as-is
  return msg;
}
```

### 3. Modified sendTo() (Lines 197-213)
- Added `_compressIfData()` method to compress outgoing data messages
```dart
@override
int sendTo(List<int> buffer, PeerInfo peer) {
  final data = _compressIfData(buffer);  // NEW: Compress if data
  return super.send(data, peer.address, peer.port);
}

List<int> _compressIfData(List<int> msg) {
  // Check if it's a data message (0x00)
  if (msg.isNotEmpty && msg[0] == 0x00) {
    // Compress payload: everything after prefix
    final compressed = gzip.encode(msg.sublist(1));
    // Return with prefix: [0x00] + compressed
    return [0x00, ...compressed];
  }
  // Not a data message, return as-is
  return msg;
}
```

## Protocol Messages (Uncompressed)
- **Handshake** (0x01): Not compressed ✓
- **Closing** (0x02): Not compressed ✓
- **Closed** (0x03): Not compressed ✓
- **KeepAlive** (0x04): Not compressed ✓
- **Data** (0x00): **Always compressed** ✓

## Data Flow

### Sending
```
User: sendMessage([0xAA, 0xBB, ...])
  ↓
ShspInstance: Insert prefix [0x00, 0xAA, 0xBB, ...]
  ↓
ShspSocket.sendTo(): Detect 0x00, compress payload
  [0x00] + gzip([0xAA, 0xBB, ...])
  ↓
UDP Send
```

### Receiving
```
UDP Receive: [0x00, ...compressed...]
  ↓
ShspSocket._handleReadEvent(): Detect 0x00, decompress
  [0x00] + gzip.decode([...compressed...])
  ↓
ShspInstance.onMessage(): Pass to user
  [0xAA, 0xBB, ...]
```

## Testing Results
- ✅ All 295 tests pass
- ✅ Data messages compress/decompress correctly
- ✅ Protocol messages unaffected
- ✅ Compression efficiency verified:
  - Repetitive data: 97.1% compression (1000 → 29 bytes)
  - JSON-like data: 45.9% compression (111 → 60 bytes)
- ✅ Fixed test that created messages starting with 0x00 (would be compressed)

## No External Dependencies
Uses built-in Dart `gzip` from `dart:io` package (no additional pubspec dependencies needed)

## Design Notes
- Compression happens at **transport layer** (ShspSocket), not application layer
- Transparent to ShspInstance and user code
- Only messages with prefix 0x00 (data messages) are compressed
- Protocol messages pass through unmodified
