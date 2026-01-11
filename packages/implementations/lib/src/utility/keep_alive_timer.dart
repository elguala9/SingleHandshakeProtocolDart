import 'dart:async';

/// Custom timer for managing keep-alive messages with intelligent activity tracking
class KeepAliveTimer implements Timer {
  late Timer _internalTimer;
  bool _isRunning = false;
  DateTime? _lastActivity;

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
    if (_internalTimer != null) {
      _internalTimer.cancel();
    }
    _isRunning = false;
  }

  factory KeepAliveTimer.periodic(
    Duration duration,
    void Function(Timer timer) callback,
  ) {
    if (Zone.current == Zone.root) {
      return KeepAliveTimer.from(
        Zone.current.createPeriodicTimer(duration, callback),
      );
    }
    var boundCallback = Zone.current.bindUnaryCallbackGuarded<Timer>(callback);
    return KeepAliveTimer.from(
      Zone.current.createPeriodicTimer(duration, boundCallback),
    );
  }

  @override
  bool get isActive => _isRunning;

  @override
  int get tick {
    if (_lastActivity == null) return 0;
    return DateTime.now().difference(_lastActivity!).inMilliseconds ~/ 1000;
  }

  /// Reset the tick countdown, restarts the keep-alive timer
  /// The next keep-alive message will be sent after the full interval
  void resetTick() {
    _lastActivity = DateTime.now();
  }
  
}