import 'dart:developer';

import 'package:meta/meta.dart';
import '../../utility/keep_alive_timer.dart';

/// Mixin for managing keep-alive functionality
mixin ShspInstanceKeepAliveMixin {
  /// Protected getter for keep-alive seconds
  int get keepAliveSecondsValue;
  @protected
  set keepAliveSecondsValue(int value);

  /// Protected getter/setter for keep-alive timer
  KeepAliveTimer? get keepAliveTimerValue;
  @protected
  set keepAliveTimerValue(KeepAliveTimer? value);

  /// Get keep-alive interval in seconds
  int get keepAliveSeconds => keepAliveSecondsValue;

  /// Set keep-alive interval in seconds (restarts the timer)
  set keepAliveSeconds(int seconds) {
    keepAliveSecondsValue = seconds;
    stopKeepAlive();
    startKeepAlive();
  }

  /// Send a keep-alive message (if connection is open and not closing)
  void keepAlive();

  /// Starts periodic keep-alive sending.
  void startKeepAlive() {
    if (keepAliveTimerValue != null && keepAliveTimerValue!.isActive) {
      return; // Already running
    }
    keepAliveTimerValue = KeepAliveTimer.periodic(
      Duration(seconds: keepAliveSecondsValue),
      (_) {
        try {
          keepAlive();
        } catch (e, stackTrace) {
          // Log error but don't crash the timer
          // In production, use a proper logger
          log(
            'Error in keep-alive callback: $e\n$stackTrace',
            name: 'ShspInstance',
          );
          // Optionally close the connection on repeated errors
        }
      },
    );
  }

  /// Stops periodic keep-alive sending.
  void stopKeepAlive() {
    if (keepAliveTimerValue != null) {
      try {
        keepAliveTimerValue!.cancel();
      } catch (e) {
        // Log error but continue cleanup
        log('Error canceling keep-alive timer: $e', name: 'ShspInstance');
      } finally {
        keepAliveTimerValue = null;
      }
    }
  }

  /// Resets the keep-alive timer (postpones the next sending).
  @protected
  void resetKeepAlive() {
    keepAliveTimerValue?.resetTick();
  }
}
