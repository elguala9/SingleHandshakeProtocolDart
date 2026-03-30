import 'dart:async';

/// Timer interface for managing keep-alive messages with activity tracking
abstract interface class IKeepAliveTimer implements Timer {
  /// Stop the timer
  void stop();

  /// Reset the tick countdown, restarts the keep-alive timer
  /// The next keep-alive message will be sent after the full interval
  void resetTick();
}
