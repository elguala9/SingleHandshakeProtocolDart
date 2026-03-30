import 'package:singleton_manager/singleton_manager.dart';

import '../types/peer_types.dart';

/// Interface for SHSP Peer
abstract interface class IShspPeer implements IValueForRegistry {
  /// Close the peer connection
  void close();

  /// Get a serialized representation of the peer
  String serializedObject();

  /// Send a message to this peer
  void sendMessage(List<int> message);

  MessageCallback get messageCallback;

  /// Internal callback triggered when a message arrives for this peer
  void onMessage(List<int> msg, PeerInfo info);
}
