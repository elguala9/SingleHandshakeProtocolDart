import 'dart:convert';

/// Generic type for callbacks
typedef Callback<T> = void Function(T args);

/// Generic callback map for managing callbacks by string keys
/// Similar to TypeScript's CallbackMap
class CallbackMap<T> {
  final Map<String, Callback<T>> _map = {};

  /// Add a callback with the given key
  void add(String key, Callback<T> callback) {
    _map[key] = callback;
  }

  /// Get a callback by key
  Callback<T>? get(String key) {
    return _map[key];
  }

  /// Update an existing callback (only if key exists)
  void update(String key, Callback<T> callback) {
    if (_map.containsKey(key)) {
      _map[key] = callback;
    }
  }

  /// Remove a callback by key
  /// Returns true if the key existed and was removed
  bool remove(String key) {
    return _map.remove(key) != null;
  }

  /// Clear all callbacks
  void clear() {
    _map.clear();
  }

  /// Check if a key exists
  bool has(String key) {
    return _map.containsKey(key);
  }

  /// Get all keys
  Iterable<String> get keys => _map.keys;

  /// Get all callbacks
  Iterable<Callback<T>> get values => _map.values;

  /// Get all entries
  Iterable<MapEntry<String, Callback<T>>> get entries => _map.entries;

  /// Serialize to JSON (only keys, as callbacks cannot be serialized)
  String serializedObject() {
    final keysMap = {for (var key in _map.keys) key: true};
    return jsonEncode(keysMap);
  }

  /// Get the number of callbacks
  int get length => _map.length;

  /// Check if the map is empty
  bool get isEmpty => _map.isEmpty;

  /// Check if the map is not empty
  bool get isNotEmpty => _map.isNotEmpty;
}
