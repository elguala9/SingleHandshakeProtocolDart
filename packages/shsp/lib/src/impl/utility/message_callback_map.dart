import 'dart:io';
import 'package:callback_handler/callback_handler.dart';
import '../../types/callback_types.dart';
import '../../interfaces/utility/i_message_callback_map.dart';

typedef CallbackOnMessage = CallbackHandler<MessageRecord, void>;

/// A specialized callback map for handling messages from remote endpoints
/// Supports both IPv4 and IPv6 addresses
/// Key format:
/// - IPv4: "192.168.1.100:8080"
/// - IPv6: "[2001:db8::1]:8080"
class MessageCallbackMap implements IMessageCallbackMap {
  final Map<String, CallbackOnMessage> _handlers = {};

  /// Add a callback for a specific remote endpoint
  /// Key format: IPv4 "192.168.1.100:8080" or IPv6 "[2001:db8::1]:8080"
  /// If a callback already exists for this key, it will be replaced
  @override
  void add(String key, MessageCallbackFunction callback) {
    final handler = CallbackOnMessage();
    handler.register((params) => callback(params));
    _handlers[key] = handler;
  }

  /// Get a callback invoker for a specific remote endpoint
  /// Returns a function that invokes the registered callback for this key
  @override
  MessageCallbackFunction? get(String key) => _handlers[key]?.call;

  /// Get a callback invoker for a specific remote endpoint
  /// Returns a function that invokes the registered callback for this key
  CallbackOnMessage? getHandler(String key) => _handlers[key];

  /// Add a callback using InternetAddress and port
  @override
  void addByAddress(
    InternetAddress address,
    int port,
    MessageCallbackFunction callback,
  ) {
    final key = formatKey(address, port);
    add(key, callback);
  }

  /// Get a callback invoker using InternetAddress and port
  /// Falls back to IP-only match if exact IP:port is not found
  /// (handles NAT scenarios where port gets remapped but IP stays same)
  @override
  MessageCallbackFunction? getByAddress(InternetAddress address, int port) {
    final key = formatKey(address, port);
    final cb = get(key);
    if (cb != null) return cb;
    return _getByAddressFallback(address);
  }

  /// Fallback: find first callback registered for this IP (any port)
  /// Returns null if no handler exists for this IP address
  MessageCallbackFunction? _getByAddressFallback(InternetAddress address) {
    final targetIp = address.address;
    for (final key in _handlers.keys) {
      final parsed = parseKey(key);
      if (parsed != null && parsed.address == targetIp) {
        final callback = get(key);
        if (callback != null) return callback;
      }
    }
    return null;
  }

  /// Remove the callback for a key
  @override
  void remove(String key) {
    _handlers.remove(key);
  }

  /// Remove the designed key
  void removeKey(String key) => remove(key);

  /// Remove all callbacks using InternetAddress and port
  @override
  void removeByAddress(InternetAddress address, int port) {
    final key = formatKey(address, port);
    removeKey(key);
  }

  /// Check if a key has registered callbacks
  @override
  bool containsKey(String key) => _handlers.containsKey(key);

  /// Check if an address:port combination has registered callbacks
  @override
  bool containsAddress(InternetAddress address, int port) {
    final key = formatKey(address, port);
    return containsKey(key);
  }

  /// Get all keys with registered callbacks
  @override
  Iterable<String> get keys => _handlers.keys;

  /// Get the number of registered callback keys
  @override
  int get length => _handlers.length;

  /// Clear all registered callbacks
  @override
  void clear() {
    _handlers.clear();
  }

  /// Remove all callbacks for a specific key.
  /// Note: the [_] parameter is intentionally unused — the entire handler
  /// for the key is removed regardless of which callback is passed.
  void removeCallback(String key, MessageCallbackFunction _) {
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
