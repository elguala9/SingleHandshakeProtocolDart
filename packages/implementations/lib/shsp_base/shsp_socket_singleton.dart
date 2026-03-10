import 'dart:io';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';
import 'shsp_socket.dart';
import 'compression/gzip_codec.dart';

/// Singleton wrapper for ShspSocket that manages a global socket instance.
///
/// This class provides:
/// - A single global ShspSocket instance accessible via [getInstance]
/// - Automatic socket recreation with state transfer via [reconnect]
/// - Profile-based state preservation for message callbacks
/// - Clean shutdown via [destroy]
///
/// Useful for applications that need a persistent UDP socket that can
/// survive reconnections while preserving registered peer callbacks.
class ShspSocketSingleton {
  static ShspSocketSingleton? _instance;
  late ShspSocket _socket;
  late InternetAddress _address;
  late int _port;
  late ICompressionCodec _compressionCodec;

  /// Private constructor
  ShspSocketSingleton._(
    this._socket,
    this._address,
    this._port,
    this._compressionCodec,
  );

  /// Gets or creates the singleton instance.
  ///
  /// If the singleton already exists and the socket is still open, returns it.
  /// Otherwise, creates a new socket and binds to the specified address and port.
  ///
  /// Parameters:
  ///   - [address]: The local address to bind to (default: anyIPv4)
  ///   - [port]: The local port to bind to (default: 0 for ephemeral)
  ///   - [compressionCodec]: Optional compression codec (default: GZipCodec)
  ///
  /// Returns: The singleton instance
  static Future<ShspSocketSingleton> getInstance({
    InternetAddress? address,
    int? port,
    ICompressionCodec? compressionCodec,
  }) async {
    // Return existing instance if socket is still open
    if (_instance != null && !_instance!._socket.isClosed) {
      return _instance!;
    }

    // Create new instance
    final bindAddress = address ?? InternetAddress.anyIPv4;
    final bindPort = port ?? 0;
    final codec = compressionCodec ?? GZipCodec();

    final socket = await ShspSocket.bind(bindAddress, bindPort, codec);
    _instance = ShspSocketSingleton._(socket, bindAddress, bindPort, codec);

    return _instance!;
  }

  /// Reconnects the socket with a new local port while preserving all callbacks.
  ///
  /// This method:
  /// 1. Extracts the current socket's message callback profile
  /// 2. Closes the old socket
  /// 3. Binds a new socket to the same address
  /// 4. Restores all message callbacks from the profile
  ///
  /// Useful when the UDP socket needs to be recreated (e.g., after network
  /// interface changes or forced disconnect scenarios).
  ///
  /// Throws:
  ///   - [StateError] if singleton has not been initialized
  ///   - [ShspValidationException] or [ShspNetworkException] from socket binding
  Future<void> reconnect() async {
    if (_instance == null) {
      throw StateError(
        'ShspSocketSingleton not initialized. Call getInstance() first.',
      );
    }

    // Extract profile before closing
    final profile = _socket.extractProfile();

    // Close old socket
    _socket.close();

    // Create new socket with profile
    _socket = await ShspSocket.withProfile(
      _address,
      _port == 0 ? 0 : _port, // Use ephemeral port if original was ephemeral
      profile,
      _compressionCodec,
    );
  }

  /// Gets the underlying ShspSocket instance
  ShspSocket get socket => _socket;

  /// Gets the local address the socket is bound to
  InternetAddress? get localAddress => _socket.localAddress;

  /// Gets the local port the socket is bound to
  int? get localPort => _socket.localPort;

  /// Gets the compression codec used by the socket
  ICompressionCodec get compressionCodec => _socket.compressionCodec;

  /// Checks if the socket is currently closed
  bool get isClosed => _socket.isClosed;

  /// Gets the current socket profile for external storage/management
  ShspSocketProfile getProfile() => _socket.extractProfile();

  /// Restores socket state from a profile (advanced usage)
  Future<void> restoreProfile(ShspSocketProfile profile) async {
    if (_instance == null) {
      throw StateError(
        'ShspSocketSingleton not initialized. Call getInstance() first.',
      );
    }

    // Close old socket
    _socket.close();

    // Create new socket with profile
    _socket = await ShspSocket.withProfile(
      _address,
      _port == 0 ? 0 : _port,
      profile,
      _compressionCodec,
    );
  }

  /// Destroys the singleton instance and closes the socket
  static void destroy() {
    if (_instance != null) {
      _instance!._socket.close();
      _instance = null;
    }
  }

  /// Gets the current singleton instance (null if not initialized)
  static ShspSocketSingleton? getCurrent() => _instance;
}
