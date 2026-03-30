import '../../../shsp.dart';

/// Interface for simple dual socket singleton management
abstract interface class ISimpleDualSocketSingleton {
  /// Get the current dual socket instance
  IDualShspSocketMigratable? getInstance();

  /// Set a new dual socket instance
  void setInstance(IDualShspSocketMigratable socket);

  /// Check if a socket is currently set
  bool hasInstance();

  /// Clear the current socket instance
  void clear();
}
