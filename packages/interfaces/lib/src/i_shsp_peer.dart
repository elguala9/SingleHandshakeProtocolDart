import 'package:shsp_types/shsp_types.dart';

/// Interface for SHSP Peer
abstract interface class IShspPeer {
  /// Close the peer connection
  void close();

  /// Get a serialized representation of the peer
  // ...existing code...

  /// Send a message to this peer
  void sendMessage(List<int> message);

  /// Register a callback for receiving messages from this peer
  void setMessageCallback(MessageCallback cb);

  /// Internal callback triggered when a message arrives for this peer
  void onMessage(List<int> msg, PeerInfo info);
}
