import 'dart:io';
import 'package:callback_handler/callback_handler.dart';
import 'package:meta/meta.dart';
import '../../interfaces/i_compression_codec.dart';
import '../../interfaces/i_shsp_socket.dart';
import '../../types/socket_profile.dart';
import 'shsp_socket.dart';

/// Abstract base class for SHSP socket singletons.
///
/// This generic class provides common functionality for managing a singleton socket instance,
/// including reconnection, profile management, and callback notification.
///
/// Type parameter [T] specifies the concrete socket type (e.g., ShspSocket or DualShspSocket).
abstract class BaseShspSocketSingleton<T extends IShspSocket> {
  final T _socket;
  final InternetAddress _address;
  final int _port;
  final ICompressionCodec _compressionCodec;
  final _socketChangedCallback = CallbackHandler<IShspSocket, void>();

  /// Protected constructor for subclasses
  @protected
  BaseShspSocketSingleton(
    this._socket,
    this._address,
    this._port,
    this._compressionCodec,
  );

  /// Protected getter for the current socket (Dart library-scoped privacy)
  @protected
  T get currentSocket => _socket;

  /// Protected setter for the current socket
  @protected
  set currentSocket(T value) {
    // Override _socket field through a new instance or mutation
    // Since fields are final, we need a different approach
    throw UnimplementedError(
      'Socket replacement requires creating a new singleton instance',
    );
  }

  /// Gets the underlying socket instance (implements IShspSocket)
  IShspSocket get socket => _socket;

  /// Gets the local address the socket is bound to
  InternetAddress? get localAddress => socket.localAddress;

  /// Gets the local port the socket is bound to
  int? get localPort => socket.localPort;

  /// Gets the compression codec used by the socket
  ICompressionCodec get compressionCodec => socket.compressionCodec;

  /// Checks if the socket is currently closed
  bool get isClosed => socket.isClosed;

  /// Gets the callback handler for socket change notifications.
  ///
  /// Register a listener to be notified whenever the socket is replaced.
  /// The callback receives the new [IShspSocket] instance.
  CallbackHandler<IShspSocket, void> get socketChangedCallback =>
      _socketChangedCallback;

  /// Gets the current socket profile for external storage/management
  ShspSocketProfile getProfile() => socket.extractProfile();

  /// Reconnects the socket with a new local port while preserving all callbacks.
  ///
  /// This method:
  /// 1. Extracts the current socket's message callback profile
  /// 2. Closes the old socket
  /// 3. Builds a new socket via [buildSocket]
  /// 4. Restores all message callbacks from the profile
  ///
  /// Throws:
  ///   - [StateError] if singleton has not been initialized
  Future<void> reconnect() async {
    _requireInitialized();

    // Extract profile before closing
    final profile = socket.extractProfile();

    // Close old socket
    socket.close();

    // Build new socket
    final newSocket = await buildSocket(_address, _port, _compressionCodec);

    // Apply profile to new socket
    newSocket.applyProfile(profile);

    // Replace in subclass
    replaceSocket(newSocket);

    // Notify listeners that socket has changed
    _socketChangedCallback(newSocket);
  }

  /// Restores socket state from a profile (advanced usage)
  ///
  /// Creates new socket and restores all message callbacks from the profile.
  ///
  /// Throws:
  ///   - [StateError] if singleton has not been initialized
  Future<void> restoreProfile(ShspSocketProfile profile) async {
    _requireInitialized();

    // Close old socket
    socket.close();

    // Build new socket
    final newSocket = await buildSocket(_address, _port, _compressionCodec);

    // Apply profile to new socket
    newSocket.applyProfile(profile);

    // Replace in subclass
    replaceSocket(newSocket);

    // Notify listeners that socket has changed
    _socketChangedCallback(newSocket);
  }

  /// Replaces the internal socket with a new ShspSocket instance.
  ///
  /// This method transfers all registered peer callbacks from the old socket
  /// to the new socket via [wrapRawSocket].
  ///
  /// Throws:
  ///   - [StateError] if singleton has not been initialized
  void setSocket(ShspSocket newSocket) {
    _requireInitialized();

    // Extract profile from old socket
    final profile = socket.extractProfile();

    // Close old socket
    socket.close();

    // Wrap and apply profile
    final wrappedSocket = wrapRawSocket(newSocket, newSocket.compressionCodec);
    wrappedSocket.applyProfile(profile);

    // Replace in subclass
    replaceSocket(wrappedSocket);

    // Notify listeners that socket has changed
    _socketChangedCallback(wrappedSocket);
  }

  /// Replaces the internal socket with a RawDatagramSocket.
  ///
  /// This method wraps the provided RawDatagramSocket in a ShspSocket via
  /// [ShspSocket.fromRaw], then transfers all registered peer callbacks.
  ///
  /// Throws:
  ///   - [StateError] if singleton has not been initialized
  void setSocketRaw(RawDatagramSocket rawSocket) {
    _requireInitialized();

    // Extract profile from old socket
    final profile = socket.extractProfile();

    // Close old socket
    socket.close();

    // Create new socket from raw
    final newSocket = ShspSocket.fromRaw(rawSocket, _compressionCodec);

    // Wrap and apply profile
    final wrappedSocket = wrapRawSocket(newSocket, _compressionCodec);
    wrappedSocket.applyProfile(profile);

    // Replace in subclass
    replaceSocket(wrappedSocket);

    // Notify listeners that socket has changed
    _socketChangedCallback(wrappedSocket);
  }

  /// Abstract method to replace the internal socket.
  /// Subclasses must implement this to update their singleton instance.
  @protected
  void replaceSocket(T newSocket);

  /// Abstract method to build a new socket of type T.
  ///
  /// Implementations should create a socket bound to the specified address and port.
  @protected
  Future<T> buildSocket(
    InternetAddress address,
    int port,
    ICompressionCodec codec,
  );

  /// Abstract method to wrap a ShspSocket into the concrete socket type T.
  ///
  /// This is used by [setSocket] and [setSocketRaw] to wrap single ShspSocket instances.
  @protected
  T wrapRawSocket(ShspSocket shspSocket, ICompressionCodec codec);

  /// Verifies that the singleton has been initialized
  @protected
  void requireInitialized() {
    throw StateError(
      '${runtimeType.toString()} not initialized. Call getInstance() first.',
    );
  }

  /// Internal helper to check initialization
  void _requireInitialized() => requireInitialized();
}
