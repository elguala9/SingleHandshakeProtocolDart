# SHSP Handshake Retry Handler

## Overview

The `ShspHandshakeRetryHandler` is a utility for reliably establishing SHSP connections with automatic exponential backoff retry logic. It addresses NAT traversal challenges where the initial handshake probe may be lost due to timing race conditions.

## Problem It Solves

When establishing a peer-to-peer connection through NAT:
- **Address-Restricted NAT**: Blocks incoming packets from the peer until the peer receives an outbound packet from us
- **Port-Restricted NAT**: Even more restrictive—requires matching both IP and port

The original single `sendHandshake()` call can fail if:
1. The peer hasn't started listening yet
2. The peer's outbound probe hasn't reached our NAT device to authorize the return traffic
3. Network timing race conditions occur

## Solution

The retry handler continuously sends handshake probes with exponential backoff, increasing the probability that:
1. The peer is ready to receive
2. The peer has already authorized the connection in both directions
3. The NAT translation is established

Default behavior: **10 attempts over ~37 seconds** (with 1.5x exponential backoff starting at 500ms)

## Usage

### Basic Usage

```dart
import 'package:shsp/shsp.dart';

final instance = ShspInstance.create(
  remotePeer: peerInfo,
  socket: socket,
);

// Start handshake with automatic retries
final retry = ShspHandshakeRetryHandler.startRetry(
  instance: instance,
);

// The handler stops automatically when:
// - The peer responds (handshake succeeds)
// - Maximum attempts are exhausted
```

### With Callbacks

```dart
final retry = ShspHandshakeRetryHandler.startRetry(
  instance: instance,
  onMaxAttemptsExhausted: () {
    print('Failed to establish handshake after max attempts');
    // Handle failure—maybe try a different connection method
  },
);
```

### Custom Configuration

```dart
final options = ShspHandshakeRetryOptions(
  maxAttempts: 20,              // More attempts for slower networks
  initialDelayMs: 1000,          // Start with 1 second
  backoffMultiplier: 2.0,        // Double delay each time
);

final retry = ShspHandshakeRetryHandler.startRetry(
  instance: instance,
  options: options,
  onMaxAttemptsExhausted: () { /* ... */ },
);
```

### Manual Cancellation

```dart
// Stop retries immediately
retry.cancel();

// Check if still active
if (retry.isActive) {
  print('Retries still in progress');
}
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `maxAttempts` | 10 | Total number of handshake attempts (0 = no retries) |
| `initialDelayMs` | 500 | Delay before first retry in milliseconds |
| `backoffMultiplier` | 1.5 | Exponential backoff multiplier (1.5x, 2.0x, etc.) |

### Timing Examples

With defaults (1.5x multiplier, 500ms initial):
- Attempt 0: 0ms (immediate)
- Attempt 1: ~500ms
- Attempt 2: ~750ms
- Attempt 3: ~1125ms
- ...
- Attempt 9: ~12.8s
- **Total time: ~37 seconds**

## Lifecycle

```
startRetry()
    ↓
[Initial handshake sent immediately]
    ↓
[Peer responds? → YES → Stop & cleanup ✓]
[NO ↓]
[Wait initialDelayMs]
    ↓
[Send retry, increment attempt count]
    ↓
[Peer responds? → YES → Stop & cleanup ✓]
[NO ↓]
[Wait initialDelayMs * backoffMultiplier^attempt]
    ↓
[Max attempts reached? → YES → Stop & call onMaxAttemptsExhausted ✗]
[NO → Loop back]
```

## Integration with ShspInstance

The handler is designed to work alongside the standard `onHandshake` callback:

```dart
instance.onHandshake.register((_) {
  print('Handshake received!');
  // Your custom handshake logic
});

// Automatic retry logic
final retry = ShspHandshakeRetryHandler.startRetry(
  instance: instance,
);

// Both the callback AND the retry handler respond to handshake events
```

## Notes

- The handler **does not** block—it returns immediately
- Retries stop automatically when `instance.open` becomes `true`
- All timers are cleaned up when retries stop (no resource leaks)
- Safe for concurrent use with other handshake code
- **Thread-safe**: Uses Dart's async/await, no manual locking needed

## Testing

```dart
// Run the test suite
dart test packages/shsp/test/shsp_handshake_retry_handler_test.dart
```

Tests verify:
- ✓ Initial handshake sent immediately
- ✓ Exponential backoff timing
- ✓ Stops on successful handshake
- ✓ Stops on cancel()
- ✓ Respects maxAttempts
- ✓ Respects custom configuration
