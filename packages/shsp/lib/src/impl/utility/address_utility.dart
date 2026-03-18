import 'dart:io';
import '../../types/peer_types.dart';
import '../../types/remote_info.dart';
import '../../interfaces/exceptions/shsp_exceptions.dart';

/// Utility functions for address formatting
/// See IAddressUtility for the interface contract
class AddressUtility {
  /// Format a RemoteInfo object into a string key
  /// Format: "address:port"
  static String formatAddress(RemoteInfo rinfo) =>
      '${rinfo.address.address}:${rinfo.port}';

  /// Format a PeerInfo object into a string key
  /// Format: "address:port"
  static String formatAddressParts(PeerInfo peerInfo) =>
      '${peerInfo.address.address}:${peerInfo.port}';

  /// Parse a formatted address string back to components
  /// Returns a Map with 'address' and 'port' keys
  static Map<String, dynamic>? parseAddress(String formatted) {
    final parts = formatted.split(':');
    if (parts.length != 2) return null;

    final port = int.tryParse(parts[1]);
    if (port == null) return null;

    return {
      'address': parts[0],
      'port': port,
    };
  }

  /// Create RemoteInfo from string format "address:port"
  /// Returns null if the format is invalid or the address/port cannot be parsed
  static RemoteInfo? fromString(String formatted) {
    final parsed = parseAddress(formatted);
    if (parsed == null) return null;

    final port = parsed['port'] as int;

    // Validate port range
    if (port < 0 || port > 65535) {
      return null;
    }

    try {
      final address = InternetAddress(parsed['address'] as String);
      return RemoteInfo(address: address, port: port);
    } on SocketException {
      // Invalid IP address format
      return null;
    } catch (e) {
      // Other errors
      return null;
    }
  }

  /// Get local private IP address
  /// Returns the first non-loopback IPv4 address found
  /// Throws [ShspNetworkException] if no suitable address is found
  static Future<String> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              _isPrivateIp(addr.address)) {
            return addr.address;
          }
        }
      }

      throw ShspNetworkException(
        'Unable to determine local private IP address - no suitable network interface found',
      );
    } on SocketException catch (e) {
      throw ShspNetworkException(
        'Failed to list network interfaces',
        cause: e,
      );
    }
  }

  /// Check if an IP address is in private range
  /// Private ranges: 10.x.x.x, 192.168.x.x, 172.16-31.x.x
  static bool _isPrivateIp(String ip) =>
      ip.startsWith('10.') ||
      ip.startsWith('192.168.') ||
      RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(ip);

  /// Check if IPv6 sockets can be created on this system
  /// Returns true if IPv6 is available and functional, false otherwise
  /// This performs a lightweight check by attempting to bind to an IPv6 socket
  static Future<bool> canCreateIPv6Socket() async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv6, 0);
      socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }
}
