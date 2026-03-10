import '../../interfaces/i_shsp_instance.dart';

class ShspHandshakeHandlerOptions {
  final int timeoutMs;
  final int intervalOfSendingHandshakeMs;

  const ShspHandshakeHandlerOptions(
      {this.timeoutMs = 5000, this.intervalOfSendingHandshakeMs = 500});
}

/// Automatic handshake and connection open/close handling
class ShspHandshakeHandler {
  /// Perform handshake procedure and return when connection is open
  static Future<IShspInstance> handshakeInstance(
      IShspInstance instance, ShspHandshakeHandlerOptions options,
      [void Function(IShspInstance instance)? onOpen]) async {
    final int maxMs = options.timeoutMs;
    int elapsed = 0;
    final int interval = options.intervalOfSendingHandshakeMs;

    while (elapsed < maxMs) {
      instance.sendHandshake();
      await Future.delayed(Duration(milliseconds: interval));
      elapsed += interval;
      if (instance.open) {
        if (onOpen != null) onOpen(instance);
        break; // connection open so i quit
      }
    }
    return instance;
  }
}
