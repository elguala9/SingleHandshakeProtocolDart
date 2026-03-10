import './message_callback_map.dart';
import '../../interfaces/utility/i_message_callback_map_singleton.dart';

class MessageCallbackMapSingleton extends MessageCallbackMap implements IMessageCallbackMapSingleton {
  static MessageCallbackMapSingleton? _instance;

  factory MessageCallbackMapSingleton() {
    _instance ??= MessageCallbackMapSingleton._internal();
    return _instance!;
  }

  MessageCallbackMapSingleton._internal() : super();

  /// Destroys the singleton instance (instance method for interface compliance)
  @override
  void destroy() {
    _instance = null;
  }

  /// Destroys the singleton instance (static method for convenience)
  static void destroyStatic() {
    _instance = null;
  }
}
