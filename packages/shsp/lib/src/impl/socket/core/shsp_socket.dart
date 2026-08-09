import 'dart:async';
import 'dart:io';
import 'package:meta/meta.dart';
import '../../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// SHSP Socket implementation wrapping RawDatagramSocket.
///
/// Resolves [rawSocket] via DI when tagged `@Subkey.inherited()` — connect a
/// `RawDatagramSocket` into [RegistryManager] under the `'ipv4'`/`'ipv6'`
/// subkey (see `connectDualShspSockets`) and call
/// [dependencyInjectionFactory]:
/// ```dart
/// await connectDualShspSockets();
/// final socket = ShspSocket.dependencyInjectionFactory(subkey: 'ipv4');
/// ```
@dependencyInjectable
class ShspSocket extends RawShspSocket
    with
        IdempotentCloseMixin,
        ShspSocketCallbacksMixin,
        ShspSocketCompressionMixin,
        ShspSocketProfileMixin
    implements IShspSocket {
  /// Resolves [rawSocket] via DI — see the class docs above.
  ShspSocket(
    @Subkey.inherited() RawDatagramSocket rawSocket, [
    ICompressionCodec? compressionCodec,
  ]) : this.fromRaw(rawSocket, compressionCodec);

  factory ShspSocket.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final rawSocket = RegistryManager.instance.getInstance<RawDatagramSocket>(key: key, subkey: subkey); // GENERATED CODE - DO NOT MODIFY BY HAND
    final compressionCodec = RegistryManager.instance.tryGetInstance<ICompressionCodec>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND

    return ShspSocket( // GENERATED CODE - DO NOT MODIFY BY HAND
      rawSocket, // GENERATED CODE - DO NOT MODIFY BY HAND
      compressionCodec, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

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

  /// Creates a new ShspSocket wrapping an existing RawDatagramSocket,
  /// restoring all message callbacks from an existing profile.
  ///
  /// This restores all message callbacks registered on the old socket
  /// without needing to re-register them manually. Useful for reusing
  /// an already-bound RawDatagramSocket while maintaining peer message
  /// handlers from a previous ShspSocket.
  factory ShspSocket.withRawAndProfile(
    RawDatagramSocket rawSocket,
    ShspSocketProfile profile, [
    ICompressionCodec? compressionCodec,
  ]) {
    final newSocket = ShspSocket.fromRaw(rawSocket, compressionCodec);
    newSocket._restoreProfile(profile);
    return newSocket;
  }

  /// Re-registers every message listener recorded in [profile] onto this socket.
  void _restoreProfile(ShspSocketProfile profile) {
    for (final entry in profile.messageListeners.entries) {
      final key = entry.key;
      final handlers = entry.value;

      for (final listener in handlers) {
        _messageCallbacksImpl.add(key, listener);
      }
    }
  }

  late MessageCallbackMap _messageCallbacksImpl;
  late CallbackOn _onClose;
  late CallbackOnError _onError;
  late CallbackOn _onListening;
  StreamSubscription<RawSocketEvent>? _socketSubscription;

  InternetAddress? _localAddress;
  int? _localPort;

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
    bool ipv6 = true,
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
    final shspSocket = ShspSocket.internal(
      rawSocket,
      callbacks,
      compressionCodec,
    );

    shspSocket._localAddress = address;
    shspSocket._localPort =
        rawSocket.port; // Read actual port from OS, not parameter

    shspSocket.invokeOnListening();

    return shspSocket;
  }

  static Future<ShspSocket?> bindIfPossible(
    InternetAddress address,
    int port, [
    ICompressionCodec? compressionCodec,
  ]) async {
    try{
      return ShspSocket.bind(address, port, compressionCodec);
    }
    catch(error){
      return null;
    }
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
    newSocket._restoreProfile(profile);
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
  void closeImpl() {
    _socketSubscription?.cancel();
    clearCallbacks();
    socket.close();
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
  bool get isClosed => super.isClosed;

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
