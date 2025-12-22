import 'package:shsp_types/shsp_types.dart';
import 'i_shsp_socket.dart';

/// Interface for STUN Handler
/// Manages STUN requests to discover public IP/port and verify reachability
abstract interface class IStunHandler {
  /// Performs a STUN request and returns the public (IP, port) inferred by the server
  Future<StunResponse> performStunRequest();

  /// Retrieves local (IP, port) information without contacting the STUN server
  Future<LocalInfo> performLocalRequest();

  /// Verifies the reachability of the configured STUN server
  Future<bool> pingStunServer();

  /// Sets the STUN server address/port used for subsequent requests
  void setStunServer(String address, int port);

  /// Returns the underlying socket used to communicate with the STUN server
  IShspSocket getSocket();

  /// Closes the socket and releases resources held by the STUN handler
  void close();
}
