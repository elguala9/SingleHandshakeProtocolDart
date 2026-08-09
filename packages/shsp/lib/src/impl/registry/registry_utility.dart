/// Generic registry mixin for managing keyed instances.
///
/// This provides a way to register, retrieve, and manage objects under an
/// arbitrary [Key].
mixin KeyedRegistry<Key, Value> {
  final Map<Key, Value> _entries = {};

  /// Registers [value] under [key].
  /// Throws [StateError] if [key] is already registered.
  void register(Key key, Value value) {
    if (_entries.containsKey(key)) {
      throw StateError('Key "$key" is already registered.');
    }
    _entries[key] = value;
  }

  /// Replaces the value registered under [key].
  /// Throws [StateError] if [key] is not registered.
  void replace(Key key, Value value) {
    if (!_entries.containsKey(key)) {
      throw StateError('Key "$key" is not registered.');
    }
    _entries[key] = value;
  }

  /// Retrieves the value registered under [key].
  /// Throws [StateError] if [key] is not registered.
  Value getInstance(Key key) {
    final value = _entries[key];
    if (value == null) {
      throw StateError('Key "$key" is not registered.');
    }
    return value;
  }

  /// Retrieves the value registered under [key], or `null` if absent.
  Value? getByKey(Key key) => _entries[key];

  /// Checks if [key] is registered.
  bool contains(Key key) => _entries.containsKey(key);

  /// Unregisters and returns the value for [key], if any.
  Value? unregister(Key key) => _entries.remove(key);

  /// Returns all registered keys.
  Set<Key> get keys => _entries.keys.toSet();

  /// Returns true if the registry is empty.
  bool get isEmpty => _entries.isEmpty;

  /// Returns true if the registry is not empty.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Returns the number of registered entries.
  int get registrySize => _entries.length;

  /// Clears the registry (does not call destroy on values).
  void clearRegistry() => _entries.clear();
}

/// Plain keyed registry manager.
class KeyedRegistryManager<Key, Value> with KeyedRegistry<Key, Value> {
  /// Constructor
  KeyedRegistryManager();
}

/// Singleton registry that extends [KeyedRegistryManager].
///
/// This provides a single global instance of [KeyedRegistryManager] for
/// managing objects throughout the application.
class KeyedRegistrySingleton<Key, Value> extends KeyedRegistryManager<Key, Value> {
  /// Private constructor
  KeyedRegistrySingleton._internal() : super();

  static final KeyedRegistrySingleton<dynamic, dynamic> _instance =
      KeyedRegistrySingleton._internal();

  static KeyedRegistrySingleton<dynamic, dynamic> get instance => _instance;
}
