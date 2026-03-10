import 'dart:convert';
import 'dart:io';
import '../../interfaces/utility/i_shsp_socket_info_singleton.dart';

class ShspSocketInfoSingleton implements IShspSocketInfoSingleton {
  static ShspSocketInfoSingleton? _instance;

  @override
  final String address;
  @override
  final int port;

  /// Private constructor with address and port
  ShspSocketInfoSingleton._(this.address, this.port);

  /// Factory constructor that returns or creates the singleton instance
  ///
  /// Parameters:
  ///   - [configPath]: Optional path to config JSON file
  ///   - [defaultAddress]: Default address if no config file (default: '127.0.0.1')
  ///   - [defaultPort]: Default port if no config file (default: 6969)
  ///
  /// If a config file path is provided and exists, loads from file.
  /// Otherwise, uses default values.
  factory ShspSocketInfoSingleton() {
    if (_instance != null) return _instance!;

    // Try to load from config file
    const String configPath = 'shsp_socket_config.json';
    const String defaultAddress = '127.0.0.1';
    const int defaultPort = 6969;

    final config = _loadConfig(configPath);

    // Use config values if available, otherwise use defaults
    final address = config?['address'] as String? ?? defaultAddress;
    final port = config?['port'] as int? ?? defaultPort;

    _instance = ShspSocketInfoSingleton._(address, port);
    return _instance!;
  }

  /// Loads config from file, returns null if file doesn't exist or parsing fails
  static Map<String, dynamic>? _loadConfig(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      print('Config file not found at: $path (using defaults)');
      return null;
    }
    try {
      final content = file.readAsStringSync();
      return jsonDecode(content) as Map<String, dynamic>;
    } on FileSystemException catch (e) {
      // File system error (permissions, etc.)
      print('Error reading config file at $path: ${e.message}');
      return null;
    } on FormatException catch (e) {
      // JSON parsing error
      print('Error parsing JSON config file at $path: ${e.message}');
      return null;
    } catch (e) {
      // Other unexpected errors
      print('Unexpected error loading config from $path: $e');
      return null;
    }
  }

  /// Destroys the singleton instance (instance method for interface compliance)
  @override
  void destroy() {
    _instance = null;
  }

  /// Destroys the singleton instance (static method for convenience)
  static void destroyStatic() {
    _instance = null;
  }
}