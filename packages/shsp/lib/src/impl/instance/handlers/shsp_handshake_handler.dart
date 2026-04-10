import 'dart:async';
import '../../../interfaces/i_shsp_instance.dart';

class ShspHandshakeHandlerOptions {
  const ShspHandshakeHandlerOptions({
    this.timeoutMs = 5000,
    this.intervalOfSendingHandshakeMs = 500,
  });

  final int timeoutMs;
  final int intervalOfSendingHandshakeMs;
}

/// Automatic handshake and connection open/close handling
class ShspHandshakeHandler {
  /// Perform handshake procedure and return when connection is open.
  ///
  /// Uses an event-driven approach: registers on [IShspInstance.onOpen] and
  /// races that against a timeout, sending handshake packets periodically
  /// in between. This avoids polling races where the open event fires in the
  /// same event-loop turn as the delay timer.
  static Future<IShspInstance> handshakeInstance(
    IShspInstance instance,
    ShspHandshakeHandlerOptions options, [
    void Function(IShspInstance instance)? onOpen,
  ]) async {
    if (instance.open) {
      onOpen?.call(instance);
      return instance;
    }

    final completer = Completer<void>();

    void openListener(_) {
      if (!completer.isCompleted) completer.complete();
    }

    instance.onOpen.register(openListener);
    instance.sendHandshake();

    final periodicTimer = Timer.periodic(
      Duration(milliseconds: options.intervalOfSendingHandshakeMs),
      (_) { if (!instance.open) instance.sendHandshake(); },
    );

    await Future.any([
      completer.future,
      Future.delayed(Duration(milliseconds: options.timeoutMs)),
    ]);

    periodicTimer.cancel();
    instance.onOpen.unregister(openListener);

    if (instance.open) onOpen?.call(instance);

    return instance;
  }
}
