# ShspSocketSingleton Implementation

## Summary
Implemented a global singleton wrapper for ShspSocket that manages a persistent socket instance with automatic state transfer during reconnection scenarios.

## Location
- **Main class**: `packages/implementations/lib/shsp_base/shsp_socket_singleton.dart`
- **Exported from**: `packages/implementations/lib/shsp_implementations.dart`

## Core Methods

### getInstance(address, port, codec)
- Returns the same instance on multiple calls
- Creates new socket if none exists or if existing is closed
- Parameters optional with sensible defaults (anyIPv4, port 0, GZipCodec)

### reconnect()
- Extracts current socket's message callback profile
- Closes old socket
- Creates new socket bound to same address
- Restores all message callbacks via withProfile()
- Preserves peer communication handlers transparently

### getProfile() / restoreProfile(profile)
- getProfile(): Returns ShspSocketProfile of current socket
- restoreProfile(): Restores socket state from external profile
- Enables advanced state management scenarios

### destroy() / getCurrent()
- destroy(): Closes socket and clears singleton instance
- getCurrent(): Returns singleton or null if not initialized

## Related Changes
- Added `isClosed` getter to ShspSocket for state inspection
- Leverages ShspSocketProfile (peer → message callbacks mapping)
- Full integration with compression codec support

## Test Coverage
- 12 new tests covering all functionality
- Tests include:
  - Singleton instance consistency
  - Address/port configuration
  - Callback preservation during reconnect
  - Lifecycle management (destroy, getCurrent)
  - External profile management
  - Error handling

## Usage Example
```dart
// Get global socket instance
final socketSingleton = await ShspSocketSingleton.getInstance(
  address: InternetAddress.anyIPv4,
  port: 0,
);

// Register callbacks on peers
socketSingleton.socket.setMessageCallback(peerA, (msg) => handleMsg(msg));

// Later, if socket needs to reconnect:
await socketSingleton.reconnect();  // All callbacks preserved!

// Cleanup
ShspSocketSingleton.destroy();
```

## Integration with Profiles
- Uses ShspSocketProfile to capture message callbacks
- Pattern mirrors ShspInstance profile transfer
- Enables full state preservation for UDP reconnection scenarios
