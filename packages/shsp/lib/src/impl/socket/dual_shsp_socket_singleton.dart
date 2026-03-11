import 'dart:io';
import 'package:meta/meta.dart';
import '../../interfaces/i_compression_codec.dart';
import '../../interfaces/i_shsp_socket.dart';
import 'base_shsp_socket_singleton.dart';
import 'compression/gzip_codec.dart';
import 'dual_shsp_socket.dart';
import 'shsp_socket.dart';

/// Singleton wrapper for dual-stack IPv4+IPv6 sockets.
///
/// This class provides:
/// - A single global DualShspSocket instance accessible via [getInstance]
/// - Automatic dual-socket recreation with state transfer via [reconnect]
/// - Profile-based state preservation for message callbacks
/// - Clean shutdown via [destroy]
/// - Graceful IPv6 fallback if unavailable on the system
///
/// This is the dual-stack version that supports both IPv4 and IPv6 simultaneously.
/// Useful for applications that need to handle both address families.
class DualShspSocketSingleton extends BaseShspSocketSingleton<DualShspSocket> {
  static DualShspSocketSingleton? _instance;
  late DualShspSocket _currentSocket;

  /// Private constructor
  DualShspSocketSingleton._(
    DualShspSocket socket,
    InternetAddress address,
    int port,
    ICompressionCodec compressionCodec,
  ) : super(socket, address, port, compressionCodec) {
    _currentSocket = socket;
  }

  /// Gets or creates the singleton instance.
  ///
  /// If the singleton already exists and the socket is still open, returns it.
  /// Otherwise, creates dual IPv4+IPv6 sockets and binds to the specified address and port.
  ///
  /// Parameters:
  ///   - [address]: The local address to bind to (default: anyIPv4)
  ///   - [port]: The local port to bind to (default: 0 for ephemeral)
  ///   - [compressionCodec]: Optional compression codec (default: GZipCodec)
  ///
  /// Returns: The singleton instance with dual-stack socket support
  ///
  /// Note: IPv6 socket binding is optional. If the system doesn't support IPv6,
  /// the singleton will still work with IPv4 only.
  static Future<DualShspSocketSingleton> getInstance({
    InternetAddress? address,
    int? port,
    ICompressionCodec? compressionCodec,
  }) async {
    // Return existing instance if socket is still open
    if (_instance != null && !_instance!.isClosed) {
      return _instance!;
    }

    // Create new instance with dual sockets
    final bindAddress = address ?? InternetAddress.anyIPv4;
    final bindPort = port ?? 0;
    final codec = compressionCodec ?? GZipCodec();

    // Bind IPv4 socket (always required)
    final ipv4Socket = await ShspSocket.bind(bindAddress, bindPort, codec);

    // Bind IPv6 socket (optional, graceful fallback if unavailable)
    ShspSocket? ipv6Socket;
    try {
      // Use the same port as IPv4 if available
      final ipv6Port = ipv4Socket.localPort ?? bindPort;
      ipv6Socket = await ShspSocket.bind(
        InternetAddress.anyIPv6,
        ipv6Port,
        codec,
      );
    } catch (e) {
      // IPv6 not available on this system, continue with IPv4 only
      // This is not an error condition - just gracefully degrade
      ipv6Socket = null;
    }

    // Create dual socket wrapper
    final dualSocket = DualShspSocket(ipv4Socket, ipv6Socket);
    _instance = DualShspSocketSingleton._(dualSocket, bindAddress, bindPort, codec);

    return _instance!;
  }

  @override
  IShspSocket get socket => _currentSocket;

  @override
  @protected
  Future<DualShspSocket> buildSocket(
    InternetAddress address,
    int port,
    ICompressionCodec codec,
  ) async {
    // Bind IPv4 socket (always required)
    final ipv4Socket = await ShspSocket.bind(address, port, codec);

    // Bind IPv6 socket (optional, graceful fallback if unavailable)
    ShspSocket? ipv6Socket;
    try {
      final ipv6Port = ipv4Socket.localPort ?? port;
      ipv6Socket = await ShspSocket.bind(
        InternetAddress.anyIPv6,
        ipv6Port,
        codec,
      );
    } catch (e) {
      // IPv6 not available, continue with IPv4 only
      ipv6Socket = null;
    }

    return DualShspSocket(ipv4Socket, ipv6Socket);
  }

  @override
  @protected
  DualShspSocket wrapRawSocket(ShspSocket shspSocket, ICompressionCodec codec) {
    // Wrap single socket in DualShspSocket (IPv6 remains null)
    return DualShspSocket(shspSocket, null);
  }

  @override
  @protected
  void replaceSocket(DualShspSocket newSocket) {
    _currentSocket = newSocket;
  }

  @override
  @protected
  void requireInitialized() {
    if (_instance == null) {
      throw StateError(
        'DualShspSocketSingleton not initialized. Call getInstance() first.',
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
  static DualShspSocketSingleton? getCurrent() => _instance;
}
