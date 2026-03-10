import 'dart:io';
import 'package:callback_handler/callback_handler.dart';
import '../../types/callback_types.dart';

typedef CallbackOnMessage = CallbackHandler<MessageRecord, void>;
/// A specialized callback map for handling messages from remote endpoints
/// Supports both IPv4 and IPv6 addresses
/// Key format:
/// - IPv4: "192.168.1.100:8080"
/// - IPv6: "[2001:db8::1]:8080"
class MessageCallbackMap {
  final Map<String, CallbackOnMessage>
      _handlers = {};

  /// Add a callback for a specific remote endpoint
  /// Key format: IPv4 "192.168.1.100:8080" or IPv6 "[2001:db8::1]:8080"
  /// If a callback already exists for this key, it will be replaced
  void add(String key, MessageCallbackFunction callback) {
    final handler = CallbackOnMessage();
    handler.register((params) => callback(params));
    _handlers[key] = handler;
  }

  /// Get a callback invoker for a specific remote endpoint
  /// Returns a function that invokes the registered callback for this key
  MessageCallbackFunction? get(String key) {
    return _handlers[key]?.call;
  }

  /// Get a callback invoker for a specific remote endpoint
  /// Returns a function that invokes the registered callback for this key
  CallbackOnMessage? getHandler(String key) {
    final handler = _handlers[key];
    if (handler == null) return null;
    return handler;
  }

  /// Add a callback using InternetAddress and port
  void addByAddress(InternetAddress address, int port,
      MessageCallbackFunction callback) {
    final key = formatKey(address, port);
    add(key, callback);
  }

  /// Get a callback invoker using InternetAddress and port
  MessageCallbackFunction? getByAddress(
      InternetAddress address, int port) {
    final key = formatKey(address, port);
    return get(key);
  }



  /// Remove the callback for a key
  void remove(String key) {
    _handlers.remove(key);
  }

  /// Remove athe designed key
  void removeKey(String key) {
    _handlers.remove(key);
  }

  /// Remove all callbacks using InternetAddress and port
  void removeByAddress(InternetAddress address, int port) {
    final key = formatKey(address, port);
    removeKey(key);
  }

  /// Check if a key has registered callbacks
  bool containsKey(String key) {
    return _handlers.containsKey(key);
  }

  /// Check if an address:port combination has registered callbacks
  bool containsAddress(InternetAddress address, int port) {
    final key = formatKey(address, port);
    return containsKey(key);
  }

  /// Get all keys with registered callbacks
  Iterable<String> get keys => _handlers.keys;

  /// Get the number of registered callback keys
  int get length => _handlers.length;

  /// Clear all registered callbacks
  void clear() {
    _handlers.clear();
  }

  /// Remove the callback for a specific key
  void removeCallback(String key,
      MessageCallbackFunction callback) {
    _handlers.remove(key);
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
