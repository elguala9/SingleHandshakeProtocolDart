import 'dart:io';

/// Interface for SHSP (Single Hand Shake Protocol)
/// Main interface providing access to signaling tokens and underlying socket
abstract interface class IShsp {
  /// Returns the current signaling token (e.g., invitation/handshake string) for this SHSP peer
  String getSignal();

  /// Updates the signaling token associated with the peer, used for handshake or coordination
  void setSignal(String signal);

  /// Returns the underlying UDP socket associated with this SHSP instance
  RawDatagramSocket getSocket();

  /// Serializes the current state of the instance as a stringified JSON document
  String serializedObject();
}
