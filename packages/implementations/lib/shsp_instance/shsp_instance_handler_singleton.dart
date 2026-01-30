import 'package:shsp_implementations/shsp_instance/shsp_instance_handler.dart';

class ShspInstanceHandlerSingleton extends ShspInstanceHandler {
  static ShspInstanceHandlerSingleton? _instance;

  factory ShspInstanceHandlerSingleton() {
    _instance ??= ShspInstanceHandlerSingleton._internal();
    return _instance!;
  }

  ShspInstanceHandlerSingleton._internal() : super();

  /// Destroys the singleton instance
  static void destroy() {
    _instance = null;
  }
}
