import 'dart:async';
import '../../interfaces/utility/i_keep_alive_timer.dart';

/// Custom timer for managing keep-alive messages with intelligent activity tracking
class KeepAliveTimer implements IKeepAliveTimer {
  KeepAliveTimer._empty();

  factory KeepAliveTimer.from(Timer timer) {
    final instance = KeepAliveTimer._empty();
    instance._internalTimer = timer;
    instance._isRunning = timer.isActive;
    return instance;
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
      instance._internalTimer =
          Zone.current.createPeriodicTimer(duration, wrappedCallback);
    } else {
      final boundCallback =
          Zone.current.bindUnaryCallbackGuarded<Timer>(wrappedCallback);
      instance._internalTimer =
          Zone.current.createPeriodicTimer(duration, boundCallback);
    }

    instance._isRunning = true;
    return instance;
  }

  late Timer _internalTimer;
  bool _isRunning = false;
  int _tickCount = 0;

  @override
  void cancel() {
    stop();
  }

  @override
  void stop() {
    _internalTimer.cancel();
    _isRunning = false;
  }

  @override
  bool get isActive => _isRunning;

  @override
  int get tick => _tickCount;

  /// Reset the tick countdown, restarts the keep-alive timer
  /// The next keep-alive message will be sent after the full interval
  @override
  void resetTick() {}
}
