import 'dart:async';
import 'dart:math' show pow;
import '../../../interfaces/i_shsp_instance.dart';

/// Options for configuring handshake retry behavior with exponential backoff
class ShspHandshakeRetryOptions {
  const ShspHandshakeRetryOptions({
    this.maxAttempts = 10,
    this.initialDelayMs = 500,
    this.backoffMultiplier = 1.5,
  });

  /// Maximum number of retry attempts (total ~37s with 1.5x multiplier)
  final int maxAttempts;

  /// Initial delay before first retry in milliseconds
  final int initialDelayMs;

  /// Multiplier for exponential backoff (e.g., 1.5 means each delay is 1.5x previous)
  final double backoffMultiplier;
}

/// Abstract interface for an active handshake retry session
abstract interface class ShspHandshakeRetry {
  /// Stop the retry process
  void cancel();

  /// Check if retries are still active
  bool get isActive;
}

/// Handler for SHSP handshake with exponential backoff retry logic.
///
/// Sends initial handshake immediately, then retries with exponential backoff
/// if no response is received. This addresses NAT traversal issues where:
/// - Address-restricted NAT: blocks incoming packets until we send outbound
/// - Port-restricted NAT: requires matching port and IP
///
/// Retries continue for ~37 seconds (10 attempts with 1.5x backoff), giving
/// the peer time to initialize and send its own handshake to authorize the connection.
class ShspHandshakeRetryHandler {
  /// Start handshake retry process for an instance.
  ///
  /// Returns immediately with a [ShspHandshakeRetry] object that can be used
  /// to cancel retries or check status. Retries stop automatically when:
  /// - Handshake succeeds (peer responds)
  /// - Maximum attempts are exhausted
  /// - [cancel()] is called explicitly
  static ShspHandshakeRetry startRetry({
    required IShspInstance instance,
    ShspHandshakeRetryOptions options = const ShspHandshakeRetryOptions(),
    void Function()? onMaxAttemptsExhausted,
  }) =>
      _ShspHandshakeRetryImpl(
        instance: instance,
        options: options,
        onMaxAttemptsExhausted: onMaxAttemptsExhausted,
      );
}

class _ShspHandshakeRetryImpl implements ShspHandshakeRetry {
  _ShspHandshakeRetryImpl({
    required this.instance,
    required this.options,
    this.onMaxAttemptsExhausted,
  }) {
    _onHandshakeListener = (_) => _onHandshakeReceived();
    _start();
  }

  final IShspInstance instance;
  final ShspHandshakeRetryOptions options;
  final void Function()? onMaxAttemptsExhausted;

  bool _active = true;
  int _attemptCount = 0;
  Timer? _retryTimer;
  late final void Function(void) _onHandshakeListener;

  void _start() {
    // Send initial probe immediately
    instance.sendHandshake();
    _attemptCount++;

    // Register listener for successful handshake
    instance.onHandshake.register(_onHandshakeListener);

    // Schedule first retry if max attempts not reached
    if (_attemptCount < options.maxAttempts) {
      _scheduleNextRetry();
    } else {
      _cleanup();
      onMaxAttemptsExhausted?.call();
    }
  }

  void _scheduleNextRetry() {
    if (!_active) return;

    // Calculate delay with exponential backoff
    final delayMs =
        (options.initialDelayMs * pow(options.backoffMultiplier, _attemptCount - 1))
            .toInt();

    _retryTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!_active) return;

      // Send retry probe if peer hasn't responded
      if (!instance.open) {
        instance.sendHandshake();
        _attemptCount++;

        // Schedule next retry or stop
        if (_attemptCount < options.maxAttempts) {
          _scheduleNextRetry();
        } else {
          _cleanup();
          onMaxAttemptsExhausted?.call();
        }
      }
    });
  }

  void _onHandshakeReceived() {
    if (!_active) return;
    // Handshake succeeded, stop retrying
    _cleanup();
  }

  void _cleanup() {
    if (!_active) return;
    _active = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    // Defer unregister to next microtask to avoid concurrent modification
    Future.microtask(() {
      instance.onHandshake.unregister(_onHandshakeListener);
    });
  }

  @override
  void cancel() {
    _cleanup();
  }

  @override
  bool get isActive => _active;
}
