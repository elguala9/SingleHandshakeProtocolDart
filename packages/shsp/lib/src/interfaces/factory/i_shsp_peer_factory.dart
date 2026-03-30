import 'dart:io';
import '../i_shsp_socket.dart';
import '../i_shsp_peer.dart';
import '../../types/peer_types.dart';

/// Factory interface for creating ShspPeer instances
abstract interface class IShspPeerFactory {
  /// Create a ShspPeer with all required dependencies
  IShspPeer create({required PeerInfo remotePeer, required IShspSocket socket});

  /// Create a ShspPeer from PeerInfo and raw socket
  /// Builds required dependencies internally
  IShspPeer createFromRemoteInfo({
    required PeerInfo remotePeer,
    required RawDatagramSocket rawSocket,
  });
}
