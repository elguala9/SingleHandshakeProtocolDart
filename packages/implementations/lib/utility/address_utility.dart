import 'dart:io';
import 'package:shsp_types/shsp_types.dart';

/// Utility functions for address formatting
class AddressUtility {
  /// Format a RemoteInfo object into a string key
  /// Format: "address:port"
  static String formatAddress(RemoteInfo rinfo) {
    return '${rinfo.address.address}:${rinfo.port}';
  }

  /// Format a PeerInfo object into a string key
  /// Format: "address:port"
  static String formatAddressParts(PeerInfo peerInfo) {
    return '${peerInfo.address.address}:${peerInfo.port}';
  }

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
  static RemoteInfo? fromString(String formatted) {
    final parsed = parseAddress(formatted);
    if (parsed == null) return null;

    try {
      final address = InternetAddress(parsed['address'] as String);
      return RemoteInfo(address: address, port: parsed['port'] as int);
    } catch (e) {
      return null;
    }
  }

  /// Get local private IP address
  /// Returns the first non-loopback IPv4 address found
  static Future<String> getLocalIp() async {
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

    throw Exception('Unable to determine local IP address');
  }

  /// Check if an IP address is in private range
  /// Private ranges: 10.x.x.x, 192.168.x.x, 172.16-31.x.x
  static bool _isPrivateIp(String ip) {
    return ip.startsWith('10.') ||
        ip.startsWith('192.168.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(ip);
  }
}
