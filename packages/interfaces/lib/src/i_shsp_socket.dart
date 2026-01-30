import 'dart:io';

import 'package:shsp_types/shsp_types.dart';

/// Interface for SHSP Socket
abstract interface class IShspSocket {
  /// Returns the socket state as a serialized string (type, endpoints, registered callbacks)
  String serializedObject();

  /// Registers the callback invoked when the socket begins listening
  void setListeningCallback(void Function() cb);

  /// Registers the callback executed when the socket closes
  void setCloseCallback(void Function() cb);

  /// Registers the callback invoked when the socket encounters an error
  void setErrorCallback(void Function(dynamic err) cb);

  /// Registers the callback executed when the socket completes a connection
  void setConnectCallback(void Function() cb);

  /// Associates a callback with incoming messages from a specific remote endpoint
  void setMessageCallback(
      String key, void Function(List<int> msg, RemoteInfo rinfo) cb);

  /// Internal callback triggered when the socket starts listening
  void onListening();

  /// Internal callback triggered when the socket closes
  void onClose();

  /// Internal callback triggered for socket errors
  void onError(dynamic err);

  /// Internal callback triggered when the socket establishes a connection
  void onConnect();

  /// Internal callback triggered upon receiving a UDP message to enable custom handling
  void onMessage(List<int> msg, RemoteInfo rinfo);

  /// Send data to a remote address (as string) and port
  /// Returns the number of bytes written
  int sendTo(List<int> buffer, InternetAddress address, int port);

  /// Close the socket
  void close();
}
