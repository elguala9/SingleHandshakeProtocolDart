/// Generic callback type for map entries
typedef CallbackEntry<T> = void Function(T args);

/// Generic callback map interface for managing callbacks by string keys
abstract interface class ICallbackMap<T> {
  /// Add a callback with the given key
  void add(String key, CallbackEntry<T> callback);

  /// Get a callback by key
  CallbackEntry<T>? get(String key);

  /// Update an existing callback (only if key exists)
  void update(String key, CallbackEntry<T> callback);

  /// Remove a callback by key
  /// Returns true if the key existed and was removed
  bool remove(String key);

  /// Clear all callbacks
  void clear();

  /// Check if a key exists
  bool has(String key);

  /// Get all keys
  Iterable<String> get keys;

  /// Get all callbacks
  Iterable<CallbackEntry<T>> get values;

  /// Get all entries
  Iterable<MapEntry<String, CallbackEntry<T>>> get entries;

  /// Serialize to JSON (only keys, as callbacks cannot be serialized)
  String serializedObject();

  /// Get the number of callbacks
  int get length;

  /// Check if the map is empty
  bool get isEmpty;

  /// Check if the map is not empty
  bool get isNotEmpty;
}
