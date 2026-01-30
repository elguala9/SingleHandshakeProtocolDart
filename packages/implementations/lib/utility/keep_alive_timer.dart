import 'dart:async';

/// Custom timer for managing keep-alive messages with intelligent activity tracking
class KeepAliveTimer implements Timer {
  late Timer _internalTimer;
  bool _isRunning = false;
  DateTime? _lastActivity;
  int _tickCount = 0;

  KeepAliveTimer._empty();

  factory KeepAliveTimer.from(Timer timer) {
    final instance = KeepAliveTimer._empty();
    instance._internalTimer = timer;
    instance._isRunning = timer.isActive;
    return instance;
  }

  @override
  void cancel() {
    stop();
  }

  void stop() {
    _internalTimer.cancel();
    _isRunning = false;
  }

  factory KeepAliveTimer.periodic(
    Duration duration,
    void Function(Timer timer) callback,
  ) {
    final instance = KeepAliveTimer._empty();

    // Wrap the callback to increment tick count
    void wrappedCallback(Timer timer) {
      instance._tickCount++;
      callback(timer);
    }

    if (Zone.current == Zone.root) {
      instance._internalTimer = Zone.current.createPeriodicTimer(duration, wrappedCallback);
    } else {
      var boundCallback = Zone.current.bindUnaryCallbackGuarded<Timer>(wrappedCallback);
      instance._internalTimer = Zone.current.createPeriodicTimer(duration, boundCallback);
    }

    instance._isRunning = true;
    return instance;
  }

  @override
  bool get isActive => _isRunning;

  @override
  int get tick {
    // Return the actual number of times the timer callback has been invoked
    return _tickCount;
  }

  /// Reset the tick countdown, restarts the keep-alive timer
  /// The next keep-alive message will be sent after the full interval
  void resetTick() {
    _lastActivity = DateTime.now();
  }
}
