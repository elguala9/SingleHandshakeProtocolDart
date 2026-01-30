import 'dart:async';
import 'dart:io';

import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:shsp_implementations/utility/message_callback_map_singleton.dart';
import 'package:shsp_implementations/utility/shsp_socket_info_singleton.dart';

/// SHSP Socket implementation wrapping RawDatagramSocket
class ShspSocketSingleton extends ShspSocket {
  static ShspSocketSingleton? _instance;
  static Completer<ShspSocketSingleton>? _initializationCompleter;

  ShspSocketSingleton._internal(super.socket, super._messageCallbacks)
      : super.internal();

  /// Async factory to create or return the singleton instance
  /// Thread-safe: uses Completer to prevent race conditions
  static Future<ShspSocketSingleton> bind() async {
    // If already initialized, return existing instance
    if (_instance != null) return _instance!;

    // If initialization is in progress, wait for it to complete
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    // Start initialization
    _initializationCompleter = Completer<ShspSocketSingleton>();


    ShspSocketInfoSingleton info = ShspSocketInfoSingleton();
    MessageCallbackMapSingleton callbacks = MessageCallbackMapSingleton();
    final rawSocket = await RawDatagramSocket.bind(info.address, info.port);
    _instance = ShspSocketSingleton._internal(rawSocket, callbacks);
    _initializationCompleter!.complete(_instance!);
    return _instance!;


 
  }

  /// Returns the instance if already created, otherwise null
  static ShspSocketSingleton? get instance => _instance;

  /// Destroys the singleton and closes the socket
  static void destroy() {
    _instance?.close();
    _instance = null;
    _initializationCompleter = null;
  }
}
