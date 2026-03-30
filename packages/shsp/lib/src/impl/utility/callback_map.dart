import 'dart:convert';
import '../../interfaces/utility/i_callback_map.dart';

/// Generic type for callbacks
typedef Callback<T> = void Function(T args);

/// Generic callback map for managing callbacks by string keys
/// Similar to TypeScript's CallbackMap
class CallbackMap<T> implements ICallbackMap<T> {
  final Map<String, Callback<T>> _map = {};

  /// Add a callback with the given key
  @override
  void add(String key, Callback<T> callback) {
    _map[key] = callback;
  }

  /// Get a callback by key
  @override
  Callback<T>? get(String key) => _map[key];

  /// Update an existing callback (only if key exists)
  @override
  void update(String key, Callback<T> callback) {
    if (_map.containsKey(key)) {
      _map[key] = callback;
    }
  }

  /// Remove a callback by key
  /// Returns true if the key existed and was removed
  @override
  bool remove(String key) => _map.remove(key) != null;

  /// Clear all callbacks
  @override
  void clear() {
    _map.clear();
  }

  /// Check if a key exists
  @override
  bool has(String key) => _map.containsKey(key);

  /// Get all keys
  @override
  Iterable<String> get keys => _map.keys;

  /// Get all callbacks
  @override
  Iterable<Callback<T>> get values => _map.values;

  /// Get all entries
  @override
  Iterable<MapEntry<String, Callback<T>>> get entries => _map.entries;

  /// Serialize to JSON (only keys, as callbacks cannot be serialized)
  @override
  String serializedObject() {
    final keysMap = {for (final key in _map.keys) key: true};
    return jsonEncode(keysMap);
  }

  /// Get the number of callbacks
  @override
  int get length => _map.length;

  /// Check if the map is empty
  @override
  bool get isEmpty => _map.isEmpty;

  /// Check if the map is not empty
  @override
  bool get isNotEmpty => _map.isNotEmpty;
}
