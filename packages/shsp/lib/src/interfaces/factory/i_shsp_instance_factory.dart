import 'dart:io';
import '../i_shsp_socket.dart';
import '../i_shsp_instance.dart';
import '../../types/peer_types.dart';
import '../../types/instance_profile.dart';

/// Factory interface for creating ShspInstance instances
abstract interface class IShspInstanceFactory {
  /// Create a ShspInstance with all required dependencies
  IShspInstance create({
    required PeerInfo remotePeer,
    required IShspSocket socket,
    int keepAliveSeconds = 30,
  });

  /// Create a ShspInstance from PeerInfo and raw socket
  /// Builds required dependencies internally
  IShspInstance createFromSocket({
    required PeerInfo remotePeer,
    required RawDatagramSocket rawSocket,
    int keepAliveSeconds = 30,
  });

  /// Create a ShspInstance from an existing profile
  /// Useful for reconnecting while preserving callbacks
  IShspInstance createWithProfile({
    required PeerInfo remotePeer,
    required IShspSocket socket,
    required ShspInstanceProfile profile,
  });
}
