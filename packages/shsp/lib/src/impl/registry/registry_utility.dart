import '../../interfaces/mixin/registry_mixin.dart';

/// Generic registry manager for managing objects that implement IValueForRegistry
///
/// This class provides a way to register, retrieve, and manage
/// objects that implement IValueForRegistry.
class RegistryManager<Key, Value extends IValueForRegistry> with Registry<Key, Value> {
  /// Constructor
  RegistryManager();
}


/// Singleton registry that extends RegistryManager
///
/// This provides a single global instance of RegistryManager for managing
/// objects that implement IValueForRegistry throughout the application.
class RegistrySingleton<Key, Value extends IValueForRegistry> extends RegistryManager<Key, Value> {
  static final RegistrySingleton _instance = RegistrySingleton._internal();

  static RegistrySingleton get instance => _instance;
  /// Private constructor
  RegistrySingleton._internal() : super();

}

