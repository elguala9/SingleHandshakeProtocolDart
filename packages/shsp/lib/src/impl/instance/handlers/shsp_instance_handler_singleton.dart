import './shsp_instance_handler.dart';

class ShspInstanceHandlerSingleton extends ShspInstanceHandler {
  factory ShspInstanceHandlerSingleton() {
    _instance ??= ShspInstanceHandlerSingleton._internal();
    return _instance!;
  }

  ShspInstanceHandlerSingleton._internal() : super();

  static ShspInstanceHandlerSingleton? _instance;

  /// Destroys the singleton instance
  static void destroy() {
    _instance = null;
  }
}
