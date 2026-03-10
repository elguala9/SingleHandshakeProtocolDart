import 'dart:io';
import 'package:callback_handler/callback_handler.dart';
import '../../interfaces/exceptions/shsp_exceptions.dart';
import '../../interfaces/i_compression_codec.dart';
import '../../interfaces/i_shsp_socket.dart';
import '../../types/socket_profile.dart';
import 'shsp_socket.dart';
import 'dual_shsp_socket.dart';
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
  late DualShspSocket _socket;
  late InternetAddress _address;
  late int _port;
  late ICompressionCodec _compressionCodec;
  final _socketChangedCallback = CallbackHandler<IShspSocket, void>();

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
  static Future<ShspSocketSingleton> getInstance({
    InternetAddress? address,
    int? port,
    ICompressionCodec? compressionCodec,
  }) async {
    // Return existing instance if socket is still open
    if (_instance != null && !_instance!._socket.isClosed) {
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
    _instance = ShspSocketSingleton._(dualSocket, bindAddress, bindPort, codec);

    return _instance!;
  }

  /// Reconnects the socket with a new local port while preserving all callbacks.
  ///
  /// This method:
  /// 1. Extracts the current socket's message callback profile (from both IPv4 and IPv6)
  /// 2. Closes the old sockets
  /// 3. Binds new IPv4 and IPv6 sockets to the same address
  /// 4. Restores all message callbacks from the profile to both sockets
  ///
  /// Useful when the UDP sockets need to be recreated (e.g., after network
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

    // Extract profile before closing (merges both IPv4 and IPv6 callbacks)
    final profile = _socket.extractProfile();

    // Close old sockets
    _socket.close();

    // Bind new IPv4 socket
    final newIPv4 = await ShspSocket.bind(
      _address,
      _port == 0 ? 0 : _port,
      _compressionCodec,
    );

    // Bind new IPv6 socket (optional)
    ShspSocket? newIPv6;
    try {
      final ipv6Port = newIPv4.localPort ?? (_port == 0 ? 0 : _port);
      newIPv6 = await ShspSocket.bind(
        InternetAddress.anyIPv6,
        ipv6Port,
        _compressionCodec,
      );
    } catch (e) {
      // IPv6 not available, continue with IPv4 only
      newIPv6 = null;
    }

    // Create new dual socket and apply profile to both
    final newDualSocket = DualShspSocket(newIPv4, newIPv6);
    newDualSocket.applyProfile(profile);

    _socket = newDualSocket;

    // Notify listeners that socket has changed
    _socketChangedCallback(_socket);
  }

  /// Gets the underlying DualShspSocket instance (implements IShspSocket)
  IShspSocket get socket => _socket;

  /// Gets the local address the socket is bound to
  InternetAddress? get localAddress => _socket.localAddress;

  /// Gets the local port the socket is bound to
  int? get localPort => _socket.localPort;

  /// Gets the compression codec used by the socket
  ICompressionCodec get compressionCodec => _socket.compressionCodec;

  /// Checks if the socket is currently closed
  bool get isClosed => _socket.isClosed;

  /// Gets the callback handler for socket change notifications.
  ///
  /// Register a listener to be notified whenever the socket is replaced.
  /// The callback receives the new [IShspSocket] instance (typically a [DualShspSocket]).
  ///
  /// Example:
  /// ```dart
  /// final singleton = await ShspSocketSingleton.getInstance();
  /// singleton.socketChangedCallback.listen((newSocket) {
  ///   print('Socket changed to: ${newSocket.localPort}');
  /// });
  /// ```
  CallbackHandler<IShspSocket, void> get socketChangedCallback =>
      _socketChangedCallback;

  /// Gets the current socket profile for external storage/management
  ShspSocketProfile getProfile() => _socket.extractProfile();

  /// Restores socket state from a profile (advanced usage)
  ///
  /// Creates new dual IPv4+IPv6 sockets and restores all message callbacks from the profile.
  Future<void> restoreProfile(ShspSocketProfile profile) async {
    if (_instance == null) {
      throw StateError(
        'ShspSocketSingleton not initialized. Call getInstance() first.',
      );
    }

    // Close old sockets
    _socket.close();

    // Create new IPv4 socket
    final newIPv4 = await ShspSocket.bind(
      _address,
      _port == 0 ? 0 : _port,
      _compressionCodec,
    );

    // Create new IPv6 socket (optional)
    ShspSocket? newIPv6;
    try {
      final ipv6Port = newIPv4.localPort ?? (_port == 0 ? 0 : _port);
      newIPv6 = await ShspSocket.bind(
        InternetAddress.anyIPv6,
        ipv6Port,
        _compressionCodec,
      );
    } catch (e) {
      // IPv6 not available, continue with IPv4 only
      newIPv6 = null;
    }

    // Create new dual socket and apply profile to both
    final newDualSocket = DualShspSocket(newIPv4, newIPv6);
    newDualSocket.applyProfile(profile);

    _socket = newDualSocket;

    // Notify listeners that socket has changed
    _socketChangedCallback(_socket);
  }

  /// Replaces the internal socket with a new ShspSocket instance.
  ///
  /// This method transfers all registered peer callbacks from the old socket(s)
  /// to the new socket, ensuring no callbacks are lost during the transition.
  /// The provided ShspSocket is wrapped in a DualShspSocket (with null IPv6 socket).
  ///
  /// Note: This method is synchronous and does not create an IPv6 socket.
  /// For dual-stack support, use [getInstance] instead.
  ///
  /// Parameters:
  ///   - [newSocket]: The new ShspSocket instance to use
  ///
  /// Throws:
  ///   - [StateError] if singleton has not been initialized
  ///
  /// Example:
  /// ```dart
  /// final singleton = await ShspSocketSingleton.getInstance();
  /// final newSocket = ShspSocket.fromRaw(rawSocket);
  /// singleton.setSocket(newSocket);
  /// ```
  void setSocket(ShspSocket newSocket) {
    if (_instance == null) {
      throw StateError(
        'ShspSocketSingleton not initialized. Call getInstance() first.',
      );
    }

    // Extract profile from old socket(s)
    final profile = _socket.extractProfile();

    // Close old socket(s)
    _socket.close();

    // Wrap single socket in DualShspSocket (IPv6 remains null)
    final dualSocket = DualShspSocket(newSocket, null);
    dualSocket.applyProfile(profile);

    _socket = dualSocket;

    // Update address and port if available
    _address = newSocket.localAddress ?? _address;
    _port = newSocket.localPort ?? _port;

    // Update compression codec from new socket
    _compressionCodec = newSocket.compressionCodec;

    // Notify listeners that socket has changed
    _socketChangedCallback(_socket);
  }

  /// Replaces the internal socket with a RawDatagramSocket.
  ///
  /// This method wraps the provided RawDatagramSocket in a ShspSocket via
  /// [ShspSocket.fromRaw], then transfers all registered peer callbacks from
  /// the old socket(s) to the new one. The wrapped socket is placed in a
  /// DualShspSocket (with null IPv6 socket).
  ///
  /// Parameters:
  ///   - [rawSocket]: The RawDatagramSocket to wrap and use
  ///
  /// Throws:
  ///   - [StateError] if singleton has not been initialized
  ///
  /// Example:
  /// ```dart
  /// final singleton = await ShspSocketSingleton.getInstance();
  /// final rawSocket = await RawDatagramSocket.bind(address, port);
  /// singleton.setSocketRaw(rawSocket);
  /// ```
  void setSocketRaw(RawDatagramSocket rawSocket) {
    if (_instance == null) {
      throw StateError(
        'ShspSocketSingleton not initialized. Call getInstance() first.',
      );
    }

    // Extract profile from old socket(s)
    final profile = _socket.extractProfile();

    // Close old socket(s)
    _socket.close();

    // Create new socket from raw and wrap in DualShspSocket
    final newSocket = ShspSocket.fromRaw(rawSocket, _compressionCodec);
    final dualSocket = DualShspSocket(newSocket, null);
    dualSocket.applyProfile(profile);

    // Replace socket
    _socket = dualSocket;

    // Update address and port if available
    _address = newSocket.localAddress ?? _address;
    _port = newSocket.localPort ?? _port;

    // Notify listeners that socket has changed
    _socketChangedCallback(_socket);
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
