import 'dart:io';

import '../../types/callback_types.dart';
import '../../types/socket_profile.dart';
import '../i_compression_codec.dart';
import 'i_shsp_socket_base.dart';

/// Interface for SHSP Socket
abstract interface class IShspSocket
    implements IShspSocketBase, RawDatagramSocket {
  /// Returns the socket state as a serialized string (type, endpoints, registered callbacks)
  String serializedObject();

  /// Get the callback invoked when the socket begins listening
  CallbackOn get onListening;

  /// Get the callback executed when the socket closes
  CallbackOn get onClose;

  /// Get the callback invoked when the socket encounters an error
  CallbackOnError get onError;

  /// Registers the callback invoked when the socket begins listening
  @Deprecated(
    'use the get to retrive the onListening and register directly there',
  )
  void setListeningCallback(void Function() cb);

  /// Registers the callback executed when the socket closes
  @Deprecated('use the get to retrive the onClose and register directly there')
  void setCloseCallback(void Function() cb);

  /// Registers the callback invoked when the socket encounters an error
  @Deprecated('use the get to retrive the onError and register directly there')
  void setErrorCallback(void Function(dynamic err) cb);


  

  /// Get the local address the socket is bound to
  InternetAddress? get localAddress;

  /// Get the local port the socket is bound to
  int? get localPort;

  /// Get the underlying RawDatagramSocket (for IPv4-only sockets or adapter implementation)
  RawDatagramSocket get socket;

  /// Get the compression codec used by the socket
  ICompressionCodec get compressionCodec;

  /// Check if the socket is closed
  bool get isClosed;

  /// Extract the current socket's message callback profile
  ShspSocketProfile extractProfile();

  /// Apply a profile (message callbacks) to the socket
  void applyProfile(ShspSocketProfile profile);

  /// Close the socket
  void close();

  /// Destroy the socket and release all resources
  void destroy();
}
