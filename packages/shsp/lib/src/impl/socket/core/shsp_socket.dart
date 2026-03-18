import 'dart:async';
import 'dart:io';
import 'package:meta/meta.dart';
import 'package:singleton_manager/singleton_manager.dart';
import '../../../types/peer_types.dart';
import '../../../types/remote_info.dart';
import '../../../types/socket_profile.dart';
import '../../../interfaces/exceptions/shsp_exceptions.dart';
import '../../../interfaces/i_compression_codec.dart';
import '../../../interfaces/i_shsp_instance.dart' show CallbackOn, CallbackOnError;
import '../../../interfaces/i_shsp_socket.dart';
import '../../utility/message_callback_map.dart';
import '../../utility/raw_shsp_socket.dart';
import '../features/shsp_socket_callbacks.dart';
import '../features/shsp_socket_compression.dart';
import '../features/shsp_socket_profile.dart';

/// SHSP Socket implementation wrapping RawDatagramSocket
class ShspSocket extends RawShspSocket
    with ShspSocketCallbacksMixin, ShspSocketCompressionMixin, ShspSocketProfileMixin
    implements IShspSocket, IValueForRegistry {
  /// Internal constructor for factory creation
  ShspSocket.internal(
    super.socket,
    MessageCallbackMap messageCallbacks, [
    ICompressionCodec? compressionCodec,
  ]) {
    _messageCallbacksImpl = messageCallbacks;
    initCompressionCodec(compressionCodec);
    _onClose = CallbackOn();
    _onError = CallbackOnError();
    _onListening = CallbackOn();
    _setupEventListeners();
  }

  /// Creates a new ShspSocket from an existing RawDatagramSocket.
  ///
  /// This constructor wraps an already-bound RawDatagramSocket without
  /// performing another bind operation. Useful when you have an existing socket
  /// from external sources and want to use it with the SHSP protocol.
  ///
  /// Parameters:
  ///   - [rawSocket]: The existing RawDatagramSocket to wrap
  ///   - [compressionCodec]: Optional compression codec (default: GZipCodec)
  ///
  /// Example:
  /// ```dart
  /// final rawSocket = await RawDatagramSocket.bind(address, port);
  /// final socket = ShspSocket.fromRaw(rawSocket);
  /// ```
  ShspSocket.fromRaw(
    RawDatagramSocket rawSocket, [
    ICompressionCodec? compressionCodec,
  ]) : super(rawSocket) {
    _messageCallbacksImpl = MessageCallbackMap();
    initCompressionCodec(compressionCodec);
    _onClose = CallbackOn();
    _onError = CallbackOnError();
    _onListening = CallbackOn();
    _localAddress = rawSocket.address;
    _localPort = rawSocket.port;
    _setupEventListeners();
    invokeOnListening();
  }

  late MessageCallbackMap _messageCallbacksImpl;
  late CallbackOn _onClose;
  late CallbackOnError _onError;
  late CallbackOn _onListening;
  StreamSubscription<RawSocketEvent>? _socketSubscription;

  InternetAddress? _localAddress;
  int? _localPort;
  bool _closed = false;

  /// Setup event listeners for the raw socket
  void _setupEventListeners() {
    _socketSubscription = socket.listen(
      (event) {
        switch (event) {
          case RawSocketEvent.read:
            _handleReadEvent();
            break;
          case RawSocketEvent.closed:
            invokeOnClose();
            break;
          case RawSocketEvent.readClosed:
            // Read end of socket closed
            break;
          case RawSocketEvent.write:
            // Write events are handled synchronously, no callback needed
            break;
        }
      },
      onError: (error) {
        invokeOnError(error);
      },
    );
  }

  /// Handle incoming data from the socket
  void _handleReadEvent() {
    final Datagram? datagram = socket.receive();
    if (datagram != null) {
      final rinfo = RemoteInfo(address: datagram.address, port: datagram.port);
      final data = decompressIfData(datagram.data);
      onMessage(data, rinfo);
    }
  }

  /// Create and bind a new SHSP socket with default settings for IPv4 or IPv6.
  ///
  /// This factory method:
  /// - Automatically selects the appropriate default address based on protocol version
  /// - Binds the socket to port 0 for automatic port assignment
  /// - Initializes the message callback map
  /// - Sets up all event listeners (read, close, error, etc.)
  ///
  /// Parameters:
  ///   - [ipv6]: If true, binds to InternetAddress.anyIPv6; if false, binds to InternetAddress.anyIPv4
  ///   - [port]: The local port number to listen on (0-65535, default: 0 for auto-assign)
  ///   - [compressionCodec]: Optional compression codec (default: GZipCodec)
  ///
  /// Returns: A Future that resolves to a new ShspSocket instance
  ///
  /// Throws:
  ///   - [ShspValidationException] if port is invalid
  ///   - [ShspNetworkException] if binding fails
  ///
  /// Example:
  /// ```dart
  /// final socketIPv4 = await ShspSocket.bindDefault(ipv6: false);
  /// final socketIPv6 = await ShspSocket.bindDefault(ipv6: true);
  /// ```
  static Future<ShspSocket> bindDefault({
    bool ipv6 = false,
    int port = 0,
    ICompressionCodec? compressionCodec,
  }) async {
    final address = ipv6 ? InternetAddress.anyIPv6 : InternetAddress.anyIPv4;
    return bind(address, port, compressionCodec);
  }

  /// Create and bind a new SHSP socket to a specific address and port
  ///
  /// This factory method:
  /// - Validates the port number (must be between 0 and 65535)
  /// - Binds the socket to the specified local address and port
  /// - Initializes the message callback map
  /// - Sets up all event listeners (read, close, error, etc.)
  ///
  /// Parameters:
  ///   - [address]: The local InternetAddress to bind to (e.g., InternetAddress.anyIPv4)
  ///   - [port]: The local port number to listen on (0-65535)
  ///
  /// Returns: A Future that resolves to a new ShspSocket instance
  ///
  /// Throws:
  ///   - [ShspValidationException] if port is invalid
  ///   - [ShspNetworkException] if binding fails
  ///
  /// Example:
  /// ```dart
  /// final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 8000);
  /// ```
  static Future<ShspSocket> bind(
    InternetAddress address,
    int port, [
    ICompressionCodec? compressionCodec,
  ]) async {
    // Validate port range
    if (port < 0 || port > 65535) {
      throw ShspValidationException(
        'Port must be between 0 and 65535',
        field: 'port',
        value: port,
      );
    }

    final rawSocket = await RawDatagramSocket.bind(address, port);
    final callbacks = MessageCallbackMap();
    final shspSocket = ShspSocket.internal(rawSocket, callbacks, compressionCodec);

    shspSocket._localAddress = address;
    shspSocket._localPort = rawSocket.port;  // Read actual port from OS, not parameter

    shspSocket.invokeOnListening();

    return shspSocket;
  }

  /// Creates a new ShspSocket from an existing profile.
  ///
  /// This restores all message callbacks registered on the old socket
  /// without needing to re-register them manually. Useful for reconnecting
  /// over a new socket while maintaining peer message handlers.
  static Future<ShspSocket> withProfile(
    InternetAddress address,
    int port,
    ShspSocketProfile profile, [
    ICompressionCodec? compressionCodec,
  ]) async {
    // Create a new socket
    final newSocket = await bind(address, port, compressionCodec);

    // Restore all message callbacks from profile
    for (final entry in profile.messageListeners.entries) {
      final key = entry.key;
      final handlers = entry.value;

      for (final listener in handlers) {
        // Re-register the listener in the new socket
        newSocket._messageCallbacksImpl.add(key, listener);
      }
    }

    return newSocket;
  }

  @override
  String serializedObject() =>
      'ShspSocket{localAddress: $_localAddress, localPort: $_localPort}';

  @protected
  void onMessage(List<int> msg, RemoteInfo rinfo) {
    invokeMessageCallback(msg, rinfo);
  }

  @override
  int sendTo(List<int> buffer, PeerInfo peer) {
    final data = compressIfData(buffer);
    return super.send(data, peer.address, peer.port);
  }

  @override
  void close() {
    // Make close() idempotent - can be called multiple times safely
    if (_closed) return;
    _closed = true;

    // Cancel the stream subscription if active
    _socketSubscription?.cancel();

    // Clear all message callbacks to prevent memory leaks
    clearCallbacks();

    // Close the underlying socket
    socket.close();
  }

  @override
  void destroy() {
    close();
  }

  // ...existing code...

  /// Get local address (null if not bound)
  @override
  InternetAddress? get localAddress => _localAddress;

  /// Get local port (null if not bound)
  @override
  int? get localPort => _localPort;

  /// Get the underlying RawDatagramSocket
  @override
  RawDatagramSocket get socket => super.socket;

  /// Check if the socket is closed
  @override
  bool get isClosed => _closed;

  /// Getter for profile mixin to access message callbacks
  MessageCallbackMap get messageCallbacksForProfile => _messageCallbacksImpl;

  /// Getters for callback mixin
  @override
  MessageCallbackMap get messageCallbacksImpl => _messageCallbacksImpl;
  @override
  CallbackOn get onCloseImpl => _onClose;
  @override
  CallbackOnError get onErrorImpl => _onError;
  @override
  CallbackOn get onListeningImpl => _onListening;
}
