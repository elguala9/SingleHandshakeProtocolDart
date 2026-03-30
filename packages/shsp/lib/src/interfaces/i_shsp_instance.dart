import 'i_shsp_peer.dart';
import 'package:callback_handler/callback_handler.dart';
import '../types/instance_profile.dart';

typedef CallbackOn = CallbackHandler<void, void>;
typedef CallbackOnError = CallbackHandler<dynamic, void>;

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

  CallbackOn get onHandshake;
  CallbackOn get onOpen;
  CallbackOn get onClosing;
  CallbackOn get onClose;

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

  /// Extract all registered listeners and configuration as a profile.
  ///
  /// Returns a snapshot of the current callback listeners and configuration
  /// that can be applied to a new instance via [ShspInstance.withProfile].
  /// This is useful when reconnecting over a new socket while preserving
  /// all callback registrations.
  ShspInstanceProfile extractProfile();
}
