import '../../../interfaces/i_shsp_socket.dart';
import '../../../types/callback_types.dart';
import '../../../types/peer_types.dart';

/// Mixin for managing message callback routing to IPv4/IPv6 sockets
mixin DualShspSocketMessageMixin {
  /// Protected getters for sockets (implemented by the class using this mixin)
  IShspSocket get ipv4SocketForMessages;
  IShspSocket? get ipv6SocketForMessages;

  /// Register a message callback on both sockets.
  ///
  /// This ensures that incoming messages from either IPv4 or IPv6 are
  /// correctly delivered to the callback for the specified peer.
  void setMessageCallback(PeerInfo peer, MessageCallbackFunction cb) {
    ipv4SocketForMessages.setMessageCallback(peer, cb);
    ipv6SocketForMessages?.setMessageCallback(peer, cb);
  }

  /// Remove a message callback from both sockets.
  ///
  /// Returns true if the callback was found and removed from at least one socket.
  bool removeMessageCallback(PeerInfo peer, MessageCallbackFunction cb) {
    final ipv4Removed = ipv4SocketForMessages.removeMessageCallback(peer, cb);
    final ipv6Removed = ipv6SocketForMessages?.removeMessageCallback(peer, cb) ?? false;
    return ipv4Removed || ipv6Removed;
  }
}
