import 'dart:io';
import 'package:shsp_types/shsp_types.dart';

/// Utility functions for address formatting
class AddressUtility {
  /// Format a RemoteInfo object into a string key
  /// Format: "address:port"
  static String formatAddress(RemoteInfo rinfo) {
    return '${rinfo.address.address}:${rinfo.port}';
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
}
