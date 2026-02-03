import 'i_shsp_peer.dart';

typedef InstanceCallbacks = ({
  void Function()? onHandshake,
  void Function()? onOpen,
  void Function()? onClosing,
  void Function()? onClosed,
});

/// Interface for SHSP Instance
/// Extends IShspPeer with handshake and connection state management
abstract interface class IShspInstance implements IShspPeer {
  /// Check if handshake has been completed
  bool get handshake;

  /// Check if the instance is in closing state
  bool get closing;

  /// Check if the connection is open
  bool get open;

  /// Get the keep-alive interval in seconds
  int get keepAliveSeconds;

  /// Set the keep-alive interval in seconds
  set keepAliveSeconds(int seconds);

  /// Send a handshake message
  void sendHandshake();

  /// Send a keep-alive message
  void keepAlive();

  /// Send a closing signal
  void sendClosing();

  /// Send a closed signal
  void sendClosed();

  /// Start sending keep-alive messages periodically
  void startKeepAlive();

  /// Stop sending keep-alive messages
  void stopKeepAlive();

  void setCallbacks(InstanceCallbacks callbacks);
  InstanceCallbacks getCallbacks();
}
