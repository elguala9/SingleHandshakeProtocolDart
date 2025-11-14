import 'dart:io';
import 'package:shsp_types/shsp_types.dart';

/// A specialized callback map for handling messages from remote endpoints
/// Supports both IPv4 and IPv6 addresses
/// Key format:
/// - IPv4: "192.168.1.100:8080"
/// - IPv6: "[2001:db8::1]:8080"
class MessageCallbackMap {
  final Map<String, void Function(List<int> msg, RemoteInfo rinfo)> _callbacks = {};

  /// Add a callback for a specific remote endpoint
  /// Key format: IPv4 "192.168.1.100:8080" or IPv6 "[2001:db8::1]:8080"
  void add(String key, void Function(List<int> msg, RemoteInfo rinfo) callback) {
    _callbacks[key] = callback;
  }

  /// Get a callback for a specific remote endpoint
  void Function(List<int> msg, RemoteInfo rinfo)? get(String key) {
    return _callbacks[key];
  }

  /// Add a callback using InternetAddress and port
  void addByAddress(InternetAddress address, int port, void Function(List<int> msg, RemoteInfo rinfo) callback) {
    final key = formatKey(address, port);
    _callbacks[key] = callback;
  }

  /// Get a callback using InternetAddress and port
  void Function(List<int> msg, RemoteInfo rinfo)? getByAddress(InternetAddress address, int port) {
    final key = formatKey(address, port);
    return _callbacks[key];
  }

  /// Remove a callback by key
  void remove(String key) {
    _callbacks.remove(key);
  }

  /// Remove a callback using InternetAddress and port
  void removeByAddress(InternetAddress address, int port) {
    final key = formatKey(address, port);
    _callbacks.remove(key);
  }

  /// Check if a key exists
  bool containsKey(String key) {
    return _callbacks.containsKey(key);
  }

  /// Check if an address:port combination exists
  bool containsAddress(InternetAddress address, int port) {
    final key = formatKey(address, port);
    return _callbacks.containsKey(key);
  }

  /// Get all keys
  Iterable<String> get keys => _callbacks.keys;

  /// Get the number of callbacks
  int get length => _callbacks.length;

  /// Clear all callbacks
  void clear() {
    _callbacks.clear();
  }

  /// Format an InternetAddress and port into a key string
  /// Format: 
  /// - IPv4: "192.168.1.100:8080"
  /// - IPv6: "[2001:db8::1]:8080"
  static String formatKey(InternetAddress address, int port) {
    if (address.type == InternetAddressType.IPv6) {
      return '[${address.address}]:$port';
    }
    return '${address.address}:$port';
  }

  /// Parse a key string into address and port
  /// Supports both IPv4 and IPv6 formats:
  /// - IPv4: "192.168.1.100:8080"
  /// - IPv6: "[2001:db8::1]:8080"
  /// Returns null if the format is invalid
  static ({String address, int port})? parseKey(String key) {
    // Check for IPv6 format with brackets
    if (key.startsWith('[')) {
      final closeBracket = key.indexOf(']');
      if (closeBracket == -1) return null;
      
      final ipv6Address = key.substring(1, closeBracket);
      final portPart = key.substring(closeBracket + 1);
      
      if (!portPart.startsWith(':')) return null;
      
      final port = int.tryParse(portPart.substring(1));
      if (port == null) return null;
      
      return (address: ipv6Address, port: port);
    }
    
    // IPv4 format
    final lastColon = key.lastIndexOf(':');
    if (lastColon == -1) return null;
    
    final address = key.substring(0, lastColon);
    final port = int.tryParse(key.substring(lastColon + 1));
    if (port == null) return null;
    
    return (address: address, port: port);
  }
}
