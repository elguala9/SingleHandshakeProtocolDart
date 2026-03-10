# ShspSocket Profile Transfer Implementation

## Summary
Implemented the ability to extract message callback registrations from a ShspSocket and apply them to a new socket instance for reconnection scenarios (e.g., UDP reconnection with new local port).

## Changes Made

### 1. New Type: `ShspSocketProfile`
- Created `packages/types/lib/src/socket_profile.dart`
- Immutable class capturing message listener registrations by peer
- Uses typedef `OnMessageListener = CallbackWithReturn<MessageRecord, void>`
- Maps peer keys (formatted as "address:port") to their message listeners

### 2. ShspSocket Methods
- **`extractProfile(): ShspSocketProfile`** - Extracts all registered message callbacks
  - Located in `packages/implementations/lib/shsp_base/shsp_socket.dart`
  - Accesses listeners via `handler.map.getByIndex(i)` 
  - Returns Map<String, List<OnMessageListener>>

- **`ShspSocket.withProfile(...)`** - Static factory constructor
  - Creates new socket via `bind()`
  - Re-registers all message callbacks from profile
  - Supports custom compression codec

### 3. Export Support
- Added ShspSocketProfile export to `packages/types/lib/shsp_types.dart`

### 4. Test Coverage
- Created test suite in `packages/tests/test/shsp_socket_profile_test.dart`
- 6 test cases covering:
  - Profile extraction with single/multiple peers
  - Profile restoration to new socket
  - Empty profile handling
  - Profile reuse across multiple sockets
  - Compression codec support

## Verification
- All 318 tests pass (312 existing + 6 new)
- No breaking changes - all modifications additive
- Message callbacks preserved across socket transitions
- Compatible with custom compression codecs

## Usage Example
```dart
// Extract profile from original socket
final profile = socketA.extractProfile();
socketA.close();

// Create new socket with all callbacks restored
final socketB = await ShspSocket.withProfile(
  InternetAddress.anyIPv4,
  0,  // new port
  profile,
);

// All peer message callbacks already registered!
```

## Technical Details
- MessageCallbackMap stores callbacks as `Map<String, CallbackOnMessage>`
- Key format: "192.168.1.1:8080" (IPv4) or "[2001:db8::1]:8080" (IPv6)
- MessageRecord type: `({List<int> msg, RemoteInfo rinfo})`
- Callback listeners extracted via CallbackHandler.map field (same as ShspInstance)
