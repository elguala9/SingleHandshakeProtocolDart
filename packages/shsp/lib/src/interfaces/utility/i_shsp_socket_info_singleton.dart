/// Singleton interface for socket configuration information
abstract interface class IShspSocketInfoSingleton {
  /// The configured socket address
  String get address;

  /// The configured socket port
  int get port;

  /// Destroys the singleton instance
  void destroy();
}
