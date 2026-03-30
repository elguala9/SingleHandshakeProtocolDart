import '../../../types/socket_profile.dart';
import '../../utility/message_callback_map.dart';

/// Mixin for managing socket profiles (extracting and applying callbacks)
mixin ShspSocketProfileMixin {
  /// Protected getter for message callbacks (implemented by the class using this mixin)
  MessageCallbackMap get messageCallbacksForProfile;

  /// Extracts all registered message callbacks for remote peers.
  ///
  /// Returns a [ShspSocketProfile] containing all message listener registrations.
  /// This can be applied to a new socket via [withProfile].
  ShspSocketProfile extractProfile() {
    final Map<String, List<OnMessageListener>> listeners = {};
    final callbacks = messageCallbacksForProfile;

    // Extract all message callbacks from the callback map
    for (final key in callbacks.keys) {
      final handler = callbacks.getHandler(key);
      if (handler != null) {
        final handlerListeners = <OnMessageListener>[];
        for (var i = 0; i < handler.map.length; i++) {
          handlerListeners.add(handler.map.getByIndex(i));
        }
        if (handlerListeners.isNotEmpty) {
          listeners[key] = handlerListeners;
        }
      }
    }

    return ShspSocketProfile(messageListeners: listeners);
  }

  /// Applies a profile (message callbacks) to this existing socket.
  ///
  /// This instance method restores all message callbacks from a [ShspSocketProfile]
  /// to this socket. Useful when transferring state from an old socket to a new one.
  /// The callbacks are added to any existing callbacks in this socket (merge, not replace).
  ///
  /// Parameters:
  ///   - [profile]: The ShspSocketProfile containing message listeners to apply
  ///
  /// Example:
  /// ```dart
  /// final profile = oldSocket.extractProfile();
  /// final newSocket = ShspSocket.fromRaw(rawSocket);
  /// newSocket.applyProfile(profile);
  /// ```
  void applyProfile(ShspSocketProfile profile) {
    final callbacks = messageCallbacksForProfile;
    for (final entry in profile.messageListeners.entries) {
      final key = entry.key;
      for (final listener in entry.value) {
        callbacks.add(key, listener);
      }
    }
  }
}
