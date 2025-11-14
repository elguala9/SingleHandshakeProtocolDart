import 'i_shsp_peer.dart';

/// Interface for SHSP Instance
/// Extends IShspPeer with handshake and connection state management
abstract interface class IShspInstance implements IShspPeer {
  /// Check if handshake has been completed
  bool get handshake;

  /// Check if the instance is in closing state
  bool get closing;

  /// Check if the connection is open
  bool get open;
}
