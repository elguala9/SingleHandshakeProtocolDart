import 'dart:io';
import '../../types/callback_types.dart';

/// Specialized callback map interface for handling messages from remote endpoints
/// Supports both IPv4 and IPv6 addresses
abstract interface class IMessageCallbackMap {
  /// Add a callback for a specific remote endpoint
  /// Key format: IPv4 "192.168.1.100:8080" or IPv6 "[2001:db8::1]:8080"
  void add(String key, MessageCallbackFunction callback);

  /// Get a callback invoker for a specific remote endpoint
  MessageCallbackFunction? get(String key);

  /// Add a callback using InternetAddress and port
  void addByAddress(
    InternetAddress address,
    int port,
    MessageCallbackFunction callback,
  );

  /// Get a callback invoker using InternetAddress and port
  /// Falls back to IP-only match if exact IP:port is not found
  /// (handles NAT scenarios where port gets remapped but IP stays same)
  MessageCallbackFunction? getByAddress(InternetAddress address, int port);

  /// Remove the callback for a key
  void remove(String key);

  /// Remove all callbacks using InternetAddress and port
  void removeByAddress(InternetAddress address, int port);

  /// Check if a key has registered callbacks
  bool containsKey(String key);

  /// Check if an address:port combination has registered callbacks
  bool containsAddress(InternetAddress address, int port);

  /// Get all keys with registered callbacks
  Iterable<String> get keys;

  /// Get the number of registered callback keys
  int get length;

  /// Clear all registered callbacks
  void clear();

  /// Format an InternetAddress and port into a key string
  /// Format: IPv4 "192.168.1.100:8080" or IPv6 "[2001:db8::1]:8080"
  static String formatKey(InternetAddress address, int port) {
    if (address.type == InternetAddressType.IPv6) {
      return '[${address.address}]:$port';
    }
    return '${address.address}:$port';
  }
}
