import '../../types/peer_types.dart';
import '../../types/remote_info.dart';

/// Utility interface for address formatting and parsing
abstract interface class IAddressUtility {
  /// Format a RemoteInfo object into a string key (format: "address:port")
  String formatAddress(RemoteInfo rinfo);

  /// Format a PeerInfo object into a string key (format: "address:port")
  String formatAddressParts(PeerInfo peerInfo);

  /// Parse a formatted address string back to components
  /// Returns a Map with 'address' and 'port' keys, or null if invalid
  Map<String, dynamic>? parseAddress(String formatted);

  /// Create RemoteInfo from string format "address:port"
  /// Returns null if format is invalid or address/port cannot be parsed
  RemoteInfo? fromString(String formatted);

  /// Get local private IP address asynchronously
  /// Returns the first non-loopback IPv4 address found
  /// Throws ShspNetworkException if no suitable address is found
  Future<String> getLocalIp();
}
