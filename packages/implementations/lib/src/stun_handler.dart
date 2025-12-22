import 'dart:io';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

/// Default STUN configuration
class DefaultStunConfig {
  static const String address = 'stun.l.google.com';
  static const int port = 19302;
  static const int localPort = 49152;
}

/// Implementation of IStunHandler interface
/// Manages STUN requests to discover public IP/port
class StunHandler implements IStunHandler {
  String _stunAddress;
  int _stunPort;
  final IShspSocket _socket;

  StunHandler({
    String? address,
    int? port,
    int? localPort,
    required IShspSocket socket,
  })  : _stunAddress = address ?? DefaultStunConfig.address,
        _stunPort = port ?? DefaultStunConfig.port,
        _socket = socket;

  /// Factory constructor that creates a socket automatically
  static Future<StunHandler> create({
    String? address,
    int? port,
    int? localPort,
  }) async {
    // TODO: Create appropriate socket implementation
    throw UnimplementedError('StunHandler.create requires socket implementation');
  }

  @override
  Future<StunResponse> performStunRequest() async {
    // TODO: Implement STUN request using a STUN library or custom implementation
    // This will require either:
    // 1. A Dart STUN library (e.g., dart_stun package if available)
    // 2. Custom STUN protocol implementation
    
    final server = '$_stunAddress:$_stunPort';
    
    // Placeholder implementation - replace with actual STUN request
    throw UnimplementedError(
      'STUN request implementation required. Server: $server\n'
      'Consider using a STUN library like dart_stun or implementing STUN RFC 5389'
    );
    
    // Expected return format (once implemented):
    // return StunResponse(
    //   publicIp: xorAddr.address,
    //   publicPort: xorAddr.port,
    //   transactionId: transactionId,
    //   raw: rawResponse,
    //   attrs: attributes,
    // );
  }

  @override
  Future<LocalInfo> performLocalRequest() async {
    // Get local network interface information
    final interfaces = await NetworkInterface.list();
    
    // Find first non-loopback IPv4 address
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          // Get socket local port
          // Note: This assumes the socket has been bound
          // Actual port retrieval depends on socket implementation
          
          return LocalInfo(
            localIp: addr.address,
            localPort: 0, // TODO: Get actual port from socket
          );
        }
      }
    }
    
    throw Exception('[StunHandler] Unable to determine local IP address');
  }

  @override
  Future<bool> pingStunServer() async {
    try {
      await performStunRequest();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void setStunServer(String address, int port) {
    _stunAddress = (address.trim().isNotEmpty) ? address : 'stun.l.google.com';
    _stunPort = (port > 0 && port < 65536) ? port : 19302;
  }

  @override
  IShspSocket getSocket() {
    return _socket;
  }

  @override
  void close() {
    _socket.close();
  }
}
