import 'dart:io';
import 'package:meta/meta.dart';
import '../../../interfaces/i_compression_codec.dart';
import '../../../interfaces/i_shsp_socket.dart';
import 'base_shsp_socket_singleton.dart';
import '../compression/gzip_codec.dart';
import 'shsp_socket.dart';

/// Singleton wrapper for a single ShspSocket (IPv4 only).
///
/// This class provides:
/// - A single global ShspSocket instance accessible via [getInstance]
/// - Automatic socket recreation with state transfer via [reconnect]
/// - Profile-based state preservation for message callbacks
/// - Clean shutdown via [destroy]
///
/// Unlike [DualShspSocketSingleton], this manages only IPv4 sockets.
/// Useful for applications that need a simple, single-stack UDP socket.
class ShspSocketSingleton extends BaseShspSocketSingleton<ShspSocket> {
  /// Private constructor
  ShspSocketSingleton._(
    ShspSocket socket,
    InternetAddress address,
    int port,
    ICompressionCodec compressionCodec,
  ) : super(socket, address, port, compressionCodec) {
    _currentSocket = socket;
  }

  static ShspSocketSingleton? _instance;
  late ShspSocket _currentSocket;

  /// Gets or creates the singleton instance.
  ///
  /// If the singleton already exists and the socket is still open, returns it.
  /// Otherwise, creates an IPv4-only socket and binds to the specified address and port.
  ///
  /// Parameters:
  ///   - [address]: The local address to bind to (default: anyIPv4)
  ///   - [port]: The local port to bind to (default: 0 for ephemeral)
  ///   - [compressionCodec]: Optional compression codec (default: GZipCodec)
  ///
  /// Returns: The singleton instance with single IPv4 socket
  static Future<ShspSocketSingleton> getInstance({
    InternetAddress? address,
    int? port,
    ICompressionCodec? compressionCodec,
  }) async {
    // Return existing instance if socket is still open
    if (_instance != null && !_instance!.isClosed) {
      return _instance!;
    }

    // Create new instance with single IPv4 socket
    final bindAddress = address ?? InternetAddress.anyIPv4;
    final bindPort = port ?? 0;
    final codec = compressionCodec ?? GZipCodec();

    // Bind IPv4 socket
    final ipv4Socket = await ShspSocket.bind(bindAddress, bindPort, codec);

    _instance = ShspSocketSingleton._(ipv4Socket, bindAddress, bindPort, codec);

    return _instance!;
  }

  @override
  IShspSocket get socket => _currentSocket;

  @override
  @protected
  Future<ShspSocket> buildSocket(
    InternetAddress address,
    int port,
    ICompressionCodec codec,
  ) =>
      ShspSocket.bind(address, port, codec);

  @override
  @protected
  ShspSocket wrapRawSocket(ShspSocket shspSocket, ICompressionCodec codec) =>
      // No wrapping needed - return the socket directly
      shspSocket;

  @override
  @protected
  void replaceSocket(ShspSocket newSocket) {
    _currentSocket = newSocket;
  }

  @override
  @protected
  void requireInitialized() {
    if (_instance == null) {
      throw StateError(
        'ShspSocketSingleton not initialized. Call getInstance() first.',
      );
    }
  }

  /// Destroys the singleton instance and closes the socket
  static void destroy() {
    if (_instance != null) {
      _instance!._currentSocket.close();
      _instance = null;
    }
  }

  /// Gets the current singleton instance (null if not initialized)
  static ShspSocketSingleton? getCurrent() => _instance;
}
