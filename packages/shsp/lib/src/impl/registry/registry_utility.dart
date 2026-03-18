import 'package:singleton_manager/singleton_manager.dart';

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
  /// Private constructor
  RegistrySingleton._internal() : super();

  static final RegistrySingleton<dynamic, IValueForRegistry> _instance = RegistrySingleton._internal();

  static RegistrySingleton<dynamic, IValueForRegistry> get instance => _instance;
}
