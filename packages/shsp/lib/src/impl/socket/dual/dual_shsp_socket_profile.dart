import '../../../interfaces/i_shsp_socket.dart';
import '../../../types/socket_profile.dart';

/// Mixin for managing profile extraction and application to dual sockets
mixin DualShspSocketProfileMixin {
  /// Protected getters for sockets (implemented by the class using this mixin)
  IShspSocket get ipv4SocketForProfile;
  IShspSocket? get ipv6SocketForProfile;

  /// Extract profiles from both sockets and merge them.
  ///
  /// The merged profile contains all message listeners from both IPv4 and IPv6 sockets.
  ShspSocketProfile extractProfile() {
    final ipv4Profile = ipv4SocketForProfile.extractProfile();

    final mergedListeners = Map<String, List<OnMessageListener>>.from(
      ipv4Profile.messageListeners,
    );

    // Merge IPv6 listeners into the merged profile if available
    final ipv6 = ipv6SocketForProfile;
    if (ipv6 != null) {
      final ipv6Profile = ipv6.extractProfile();
      for (final entry in ipv6Profile.messageListeners.entries) {
        final key = entry.key;
        final listeners = entry.value;

        if (mergedListeners.containsKey(key)) {
          // Merge with existing listeners
          final existing = mergedListeners[key];
          if (existing != null) {
            existing.addAll(listeners);
          }
        } else {
          mergedListeners[key] = listeners;
        }
      }
    }

    return ShspSocketProfile(messageListeners: mergedListeners);
  }

  /// Apply a profile (message callbacks) to both sockets.
  ///
  /// Callbacks are registered on both IPv4 and IPv6 sockets for redundancy.
  void applyProfile(ShspSocketProfile profile) {
    ipv4SocketForProfile.applyProfile(profile);
    ipv6SocketForProfile?.applyProfile(profile);
  }
}
