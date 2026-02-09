import 'package:shsp_types/shsp_types.dart';
import 'i_shsp_instance.dart';

/// Interface for SHSP Socket
abstract interface class IShspSocket {
  /// Returns the socket state as a serialized string (type, endpoints, registered callbacks)
  String serializedObject();

  /// Get the callback invoked when the socket begins listening
  CallbackOn get onListening;

  /// Get the callback executed when the socket closes
  CallbackOn get onClose;

  /// Get the callback invoked when the socket encounters an error
  CallbackOnError get onError;


  /// Registers the callback invoked when the socket begins listening
  @Deprecated('use the get to retrive the onListening and register directly there')
  void setListeningCallback(void Function() cb);

  /// Registers the callback executed when the socket closes
  @Deprecated('use the get to retrive the onClose and register directly there')
  void setCloseCallback(void Function() cb);

  /// Registers the callback invoked when the socket encounters an error
  @Deprecated('use the get to retrive the onError and register directly there')
  void setErrorCallback(void Function(dynamic err) cb);


  /// Associates a callback with incoming messages from a specific remote endpoint
  void setMessageCallback(PeerInfo peer, MessageCallbackFunction cb);

  /// Removes a message callback associated with a specific remote endpoint
  /// Returns true if a callback was removed, false if no callback was found
  bool removeMessageCallback(PeerInfo peer, MessageCallbackFunction cb);

  /// Send data to a remote address (as string) and port
  /// Returns the number of bytes written
  int sendTo(List<int> buffer, PeerInfo peer);

  /// Close the socket
  void close();
}
