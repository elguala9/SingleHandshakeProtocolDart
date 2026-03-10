# Socket Replacement Methods Implementation

## Summary
Implemented two new methods for ShspSocket and ShspSocketSingleton to allow replacing internal sockets without losing registered callbacks.

## Files Modified

### 1. `packages/shsp/lib/src/impl/shsp_base/shsp_socket.dart`

**Added Methods:**

1. **`ShspSocket.fromRaw()` (static, sync)**
   - Wraps an existing RawDatagramSocket in a ShspSocket
   - Location: After `bind()` method
   - Initializes MessageCallbackMap and sets local address/port
   - Invokes onListening callback
   - Parameters: `RawDatagramSocket rawSocket, [ICompressionCodec? compressionCodec]`

2. **`ShspSocket.applyProfile()` (instance, sync)**
   - Applies a ShspSocketProfile (callbacks) to an existing socket
   - Location: After `withProfile()` method
   - Iterates through profile.messageListeners and adds each callback
   - Callbacks are merged (not replaced)
   - Parameters: `ShspSocketProfile profile`

### 2. `packages/shsp/lib/src/impl/shsp_base/shsp_socket_singleton.dart`

**Added Methods:**

1. **`ShspSocketSingleton.setSocket()` (instance, sync)**
   - Replaces `_socket` with a ShspSocket while preserving callbacks
   - Extracts profile from old socket
   - Closes old socket
   - Applies profile to new socket
   - Updates address, port, and compression codec
   - Throws StateError if singleton not initialized

2. **`ShspSocketSingleton.setSocketRaw()` (instance, sync)**
   - Replaces `_socket` by wrapping a RawDatagramSocket
   - Extracts profile from old socket
   - Closes old socket
   - Wraps RawDatagramSocket via `ShspSocket.fromRaw()`
   - Applies profile to new socket
   - Updates address and port
   - Keeps singleton's compression codec
   - Throws StateError if singleton not initialized

## Tests Added

Added 7 new tests in `packages/tests/test/shsp_socket_singleton_test.dart`:

1. `setSocket replaces socket and preserves callbacks` - Verifies socket replacement and callback preservation
2. `setSocketRaw wraps RawDatagramSocket and preserves callbacks` - Tests raw socket wrapping
3. `setSocket throws StateError if not initialized` - Error handling test
4. `setSocketRaw throws StateError if not initialized` - Error handling test
5. `ShspSocket.fromRaw creates socket from existing RawDatagramSocket` - Tests fromRaw creation
6. `ShspSocket.applyProfile applies profile to existing socket` - Tests profile application
7. Additional state transfer verification tests

## Test Results
- All 349 tests pass
- New tests specifically verify callback preservation during socket replacement
- No regressions in existing tests

## Design Notes
- Both methods are **synchronous** (no async I/O needed)
- Callbacks are **merged** into new socket, not replaced
- **StateError** thrown if singleton not initialized
- **Address/port updates** handle null values properly (fallback to old values)
- **Compression codec** is updated from new socket in `setSocket()`, preserved in `setSocketRaw()`
