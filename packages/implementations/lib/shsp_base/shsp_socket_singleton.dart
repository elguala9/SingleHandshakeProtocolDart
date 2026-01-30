import 'dart:io';

import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:shsp_implementations/utility/message_callback_map_singleton.dart';
import 'package:shsp_implementations/utility/shsp_socket_info_singleton.dart';

/// SHSP Socket implementation wrapping RawDatagramSocket
class ShspSocketSingleton extends ShspSocket {
  static ShspSocketSingleton? _instance;

  ShspSocketSingleton._internal(super.socket, super._messageCallbacks)
      : super.internal();

  /// Async factory to create or return the singleton instance
  static Future<ShspSocketSingleton> bind(
      {ShspSocketInfoSingleton? info,
      MessageCallbackMapSingleton? callbacks}) async {
    if (_instance != null) return _instance!;
    info ??= ShspSocketInfoSingleton();
    callbacks ??= MessageCallbackMapSingleton();
    final rawSocket = await RawDatagramSocket.bind(info.address, info.port);
    _instance = ShspSocketSingleton._internal(rawSocket, callbacks);
    return _instance!;
  }

  /// Returns the instance if already created, otherwise null
  static ShspSocketSingleton? get instance => _instance;

  /// Destroys the singleton and closes the socket
  static void destroy() {
    _instance?.close();
    _instance = null;
  }
}
