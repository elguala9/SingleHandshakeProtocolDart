import 'package:callback_handler/callback_handler.dart';
import 'package:shsp/shsp.dart';
import 'package:test/test.dart';

/// Mock implementation of IShspInstance for testing
class MockShspInstance implements IShspInstance {
  MockShspInstance({
    this.initialOpen = false,
  }) {
    onHandshake = CallbackHandler<void, void>();
    onOpen = CallbackHandler<void, void>();
    onClosing = CallbackHandler<void, void>();
    onClose = CallbackHandler<void, void>();
    _messageCallback = CallbackHandler<PeerInfo, void>();
  }

  final bool initialOpen;
  int handshakeSendCount = 0;
  bool _handshakeState = false;
  bool _openState = false;
  late CallbackHandler<PeerInfo, void> _messageCallback;

  @override
  bool get handshake => _handshakeState;

  @override
  bool get open => _openState;

  @override
  bool get closing => false;

  @override
  int get keepAliveSeconds => 30;

  @override
  set keepAliveSeconds(int seconds) {}

  @override
  late CallbackHandler<void, void> onHandshake;

  @override
  late CallbackHandler<void, void> onOpen;

  @override
  late CallbackHandler<void, void> onClosing;

  @override
  late CallbackHandler<void, void> onClose;

  @override
  MessageCallback get messageCallback => _messageCallback;

  @override
  void sendHandshake() {
    handshakeSendCount++;
  }

  @override
  void keepAlive() {}

  @override
  void sendClosing() {}

  @override
  void sendClosed() {}

  @override
  void startKeepAlive() {}

  @override
  void stopKeepAlive() {}

  @override
  ShspInstanceProfile extractProfile() => ShspInstanceProfile(
    keepAliveSeconds: 30,
    onHandshakeListeners: [],
    onOpenListeners: [],
    onClosingListeners: [],
    onCloseListeners: [],
    onMessageListeners: [],
  );

  @override
  void close() {}

  @override
  String serializedObject() => 'MockShspInstance';

  @override
  void sendMessage(List<int> message) {}

  @override
  void onMessage(List<int> msg, PeerInfo info) {}

  @override
  void destroy() {}

  /// Simulate peer responding with handshake
  void simulateHandshakeResponse() {
    _handshakeState = true;
    _openState = true;
    onHandshake.call(null);
  }
}

void main() {
  group('ShspHandshakeRetryHandler', () {
    test('sends initial handshake immediately', () {
      final instance = MockShspInstance();
      ShspHandshakeRetryHandler.startRetry(instance: instance);

      expect(instance.handshakeSendCount, equals(1));
    });

    test('stops retrying after successful handshake', () async {
      final instance = MockShspInstance();
      final retry =
          ShspHandshakeRetryHandler.startRetry(instance: instance);

      expect(instance.handshakeSendCount, equals(1));
      expect(retry.isActive, isTrue);

      // Simulate peer responding
      instance.simulateHandshakeResponse();

      // Give callback time to execute
      await Future.delayed(Duration(milliseconds: 50));

      expect(retry.isActive, isFalse);
    });

    test('stops retrying when cancel is called', () async {
      final instance = MockShspInstance();
      final retry =
          ShspHandshakeRetryHandler.startRetry(instance: instance);

      expect(instance.handshakeSendCount, equals(1));
      expect(retry.isActive, isTrue);

      retry.cancel();

      expect(retry.isActive, isFalse);

      // Wait longer than first retry interval
      await Future.delayed(Duration(milliseconds: 600));

      // Should not have sent more handshakes after cancel
      expect(instance.handshakeSendCount, equals(1));
    });

    test('respects maxAttempts configuration', () async {
      final instance = MockShspInstance();
      final options = ShspHandshakeRetryOptions(
        maxAttempts: 3,
        initialDelayMs: 10,
        backoffMultiplier: 2.0,
      );

      var maxAttemptsCallCount = 0;
      final retry = ShspHandshakeRetryHandler.startRetry(
        instance: instance,
        options: options,
        onMaxAttemptsExhausted: () => maxAttemptsCallCount++,
      );

      // Initial + 2 retries = 3 attempts
      // Wait for all retries to complete: 10ms + 20ms + buffer
      await Future.delayed(Duration(milliseconds: 200));

      expect(instance.handshakeSendCount, equals(3));
      expect(maxAttemptsCallCount, equals(1));
      expect(retry.isActive, isFalse);
    });

    test('applies exponential backoff correctly', () async {
      final instance = MockShspInstance();
      final timestamps = <int>[];

      // Create custom options with small delays for testing
      final options = ShspHandshakeRetryOptions(
        maxAttempts: 4,
        initialDelayMs: 20,
        backoffMultiplier: 2.0,
      );

      final startTime = DateTime.now().millisecondsSinceEpoch;
      ShspHandshakeRetryHandler.startRetry(
        instance: instance,
        options: options,
      );

      // Record first attempt
      timestamps.add(0);

      // Wait for all attempts with buffer
      await Future.delayed(Duration(milliseconds: 300));

      // Expected delays:
      // Attempt 0: 0ms (immediate)
      // Attempt 1: ~20ms (initialDelayMs * 2^0)
      // Attempt 2: ~40ms (initialDelayMs * 2^1)
      // Attempt 3: ~80ms (initialDelayMs * 2^2)
      // Total: ~140ms

      expect(instance.handshakeSendCount, equals(4));
    });

    test('does not retry after connection is open', () async {
      final instance = MockShspInstance();
      final options = ShspHandshakeRetryOptions(
        maxAttempts: 5,
        initialDelayMs: 10,
        backoffMultiplier: 1.5,
      );

      final retry = ShspHandshakeRetryHandler.startRetry(
        instance: instance,
        options: options,
      );

      // Wait a bit
      await Future.delayed(Duration(milliseconds: 30));

      // Simulate successful connection
      instance._openState = true;
      instance.simulateHandshakeResponse();

      await Future.delayed(Duration(milliseconds: 100));

      // Should have sent fewer than max attempts because we stopped early
      expect(instance.handshakeSendCount, lessThan(5));
      expect(retry.isActive, isFalse);
    });
  });
}
