import 'i_message_callback_map.dart';

/// Singleton interface for the message callback map
/// Extends IMessageCallbackMap and provides singleton lifecycle methods
abstract interface class IMessageCallbackMapSingleton implements IMessageCallbackMap {
  /// Destroys the singleton instance
  void destroy();
}
