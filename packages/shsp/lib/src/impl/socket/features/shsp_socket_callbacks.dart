import 'package:meta/meta.dart';
import '../../../types/callback_types.dart';
import '../../../types/peer_types.dart';
import '../../../types/remote_info.dart';
import '../../../interfaces/i_shsp_instance.dart'
    show CallbackOn, CallbackOnError;
import '../../utility/message_callback_map.dart';

/// Mixin for managing socket callbacks (message, close, error, listening)
mixin ShspSocketCallbacksMixin {
  /// Protected getters for callbacks (implemented by the class using this mixin)
  MessageCallbackMap get messageCallbacksImpl;
  CallbackOn get onCloseImpl;
  CallbackOnError get onErrorImpl;
  CallbackOn get onListeningImpl;

  /// Register a callback for messages from a specific peer
  void setMessageCallback(PeerInfo peer, MessageCallbackFunction cb) {
    final key = MessageCallbackMap.formatKey(peer.address, peer.port);
    messageCallbacksImpl.add(key, cb);
  }

  /// Remove a message callback for a specific peer
  bool removeMessageCallback(PeerInfo peer, MessageCallbackFunction cb) {
    final key = MessageCallbackMap.formatKey(peer.address, peer.port);
    if (messageCallbacksImpl.containsKey(key)) {
      messageCallbacksImpl.removeCallback(key, cb);
      return true;
    }
    return false;
  }

  /// Register a callback for socket close events
  void setCloseCallback(void Function() cb) {
    onCloseImpl.register((_) => cb());
  }

  /// Register a callback for socket error events
  void setErrorCallback(void Function(dynamic err) cb) {
    onErrorImpl.register(cb);
  }

  /// Register a callback for socket listening events
  void setListeningCallback(void Function() cb) {
    onListeningImpl.register((_) => cb());
  }

  /// Get the close event callback handler
  CallbackOn get onClose => onCloseImpl;

  /// Get the error event callback handler
  CallbackOnError get onError => onErrorImpl;

  /// Get the listening event callback handler
  CallbackOn get onListening => onListeningImpl;

  /// Invoke the close callback
  @protected
  void invokeOnClose() {
    onCloseImpl.call(null);
  }

  /// Invoke the error callback
  @protected
  void invokeOnError(dynamic err) {
    onErrorImpl.call(err);
  }

  /// Invoke the listening callback
  @protected
  void invokeOnListening() {
    onListeningImpl.call(null);
  }

  /// Invoke the message callback for a specific peer
  /// Uses getByAddress which falls back to IP-only match if exact port doesn't match
  @protected
  void invokeMessageCallback(List<int> msg, RemoteInfo rinfo) {
    final cb = messageCallbacksImpl.getByAddress(rinfo.address, rinfo.port);
    cb?.call((msg: msg, rinfo: rinfo));
  }

  /// Clear all registered callbacks
  @protected
  void clearCallbacks() {
    messageCallbacksImpl.clear();
  }
}
