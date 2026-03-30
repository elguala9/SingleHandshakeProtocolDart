import 'dart:io';
import '../i_shsp_socket.dart';
import '../../impl/utility/message_callback_map.dart';

/// Factory interface for creating ShspSocket instances
abstract interface class IShspSocketFactory {
  /// Create a ShspSocket with explicit socket and message callbacks
  IShspSocket create(
    RawDatagramSocket socket,
    MessageCallbackMap messageCallbacks,
  );

  /// Create a ShspSocket from just a RawDatagramSocket
  /// Creates default MessageCallbackMap internally
  IShspSocket createFromSocket(RawDatagramSocket socket);
}
