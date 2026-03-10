import 'dart:async';
import 'dart:io';
// ...existing code...
import 'package:meta/meta.dart';
import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import '../utility/message_callback_map.dart';
import '../utility/raw_shsp_socket.dart';
import 'compression/gzip_codec.dart';

/// SHSP Socket implementation wrapping RawDatagramSocket
class ShspSocket extends RawShspSocket implements IShspSocket {
  final MessageCallbackMap _messageCallbacks;
  final ICompressionCodec _compressionCodec;
  StreamSubscription<RawSocketEvent>? _socketSubscription;

  late CallbackOn _onClose;
  late CallbackOnError _onError;
  late CallbackOn _onListening;

  InternetAddress? _localAddress;
  int? _localPort;
  bool _closed = false;

  /// Internal constructor for factory creation
  ShspSocket.internal(
    super.socket,
    this._messageCallbacks, [
    ICompressionCodec? compressionCodec,
  ]) : _compressionCodec = compressionCodec ?? GZipCodec() {
    _onClose = CallbackOn();
    _onError = CallbackOnError();
    _onListening = CallbackOn();
    _setupEventListeners();
  }

  /// Setup event listeners for the raw socket
  void _setupEventListeners() {
    _socketSubscription = socket.listen(
      (event) {
        switch (event) {
          case RawSocketEvent.read:
            _handleReadEvent();
            break;
          case RawSocketEvent.closed:
            _invokeOnClose();
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
        _invokeOnError(error);
      },
    );
  }

  /// Handle incoming data from the socket
  void _handleReadEvent() {
    final Datagram? datagram = socket.receive();
    if (datagram != null) {
      final rinfo = RemoteInfo(address: datagram.address, port: datagram.port);
      final data = _decompressIfData(datagram.data);
      onMessage(data, rinfo);
    }
  }

  /// Decompress data messages (0x00) while keeping protocol messages as-is
  List<int> _decompressIfData(List<int> msg) {
    // Check if it's a data message (0x00)
    if (msg.isNotEmpty && msg[0] == 0x00) {
      // Decompress the payload (everything after the prefix)
      final decompressed = _compressionCodec.decode(msg.sublist(1));
      // Return with prefix restored: [0x00] + decompressed
      return [0x00, ...decompressed];
    }
    // Not a data message, return as-is
    return msg;
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

    RawDatagramSocket? rawSocket = await RawDatagramSocket.bind(address, port);
    final callbacks = MessageCallbackMap();
    final socket = ShspSocket.internal(rawSocket, callbacks, compressionCodec);

    socket._localAddress = address;
    socket._localPort = rawSocket.port;  // Read actual port from OS, not parameter

    socket._invokeOnListening();

    return socket;
  }

  /// Creates a new ShspSocket from an existing RawDatagramSocket.
  ///
  /// This factory method wraps an already-bound RawDatagramSocket without
  /// performing another bind operation. Useful when you have an existing socket
  /// from external sources and want to use it with the SHSP protocol.
  ///
  /// Parameters:
  ///   - [rawSocket]: The existing RawDatagramSocket to wrap
  ///   - [compressionCodec]: Optional compression codec (default: GZipCodec)
  ///
  /// Returns: A new ShspSocket instance wrapping the provided socket
  ///
  /// Example:
  /// ```dart
  /// final rawSocket = await RawDatagramSocket.bind(address, port);
  /// final socket = ShspSocket.fromRaw(rawSocket);
  /// ```
  static ShspSocket fromRaw(
    RawDatagramSocket rawSocket, [
    ICompressionCodec? compressionCodec,
  ]) {
    final callbacks = MessageCallbackMap();
    final socket = ShspSocket.internal(rawSocket, callbacks, compressionCodec);
    socket._localAddress = rawSocket.address;
    socket._localPort = rawSocket.port;
    socket._invokeOnListening();
    return socket;
  }

  @override
  void setMessageCallback(PeerInfo peer, MessageCallbackFunction cb) {
    final key =
            MessageCallbackMap.formatKey(peer.address, peer.port);
    _messageCallbacks.add(key, cb);
  }

  @override
  bool removeMessageCallback(PeerInfo peer, MessageCallbackFunction cb) {
    final key =
            MessageCallbackMap.formatKey(peer.address, peer.port);
    if (_messageCallbacks.containsKey(key)) {
      _messageCallbacks.removeCallback(key, cb);
      return true;
    }
    return false;
  }

  @override
  void setCloseCallback(void Function() cb) {
    _onClose.register((_) => cb());
  }

  @override
  void setErrorCallback(void Function(dynamic err) cb) {
    _onError.register(cb);
  }

  @override
  void setListeningCallback(void Function() cb) {
    _onListening.register((_) => cb());
  }


  @override
  CallbackOn get onClose => _onClose;

  @override
  CallbackOnError get onError => _onError;

  @override
  CallbackOn get onListening => _onListening;


  @protected
  void _invokeOnClose() {
    _onClose.call(null);
  }

  @protected
  void _invokeOnError(dynamic err) {
    _onError.call(err);
  }

  @protected
  void _invokeOnListening() {
    _onListening.call(null);
  }



  @override
  String serializedObject() {
    return 'ShspSocket{localAddress: $_localAddress, localPort: $_localPort}';
  }

  @protected
  void onMessage(List<int> msg, RemoteInfo rinfo) {
    final key = MessageCallbackMap.formatKey(rinfo.address, rinfo.port);
    final cb = _messageCallbacks.get(key);
    cb?.call((msg: msg, rinfo: rinfo));
  }

  @override
  int sendTo(List<int> buffer, PeerInfo peer) {
    final data = _compressIfData(buffer);
    return super.send(data, peer.address, peer.port);
  }

  /// Compress data messages (0x00) while keeping protocol messages as-is
  List<int> _compressIfData(List<int> msg) {
    // Check if it's a data message (0x00)
    if (msg.isNotEmpty && msg[0] == 0x00) {
      // Compress the payload (everything after the prefix)
      final compressed = _compressionCodec.encode(msg.sublist(1));
      // Return with prefix: [0x00] + compressed
      return [0x00, ...compressed];
    }
    // Not a data message, return as-is
    return msg;
  }

  @override
  void close() {
    // Make close() idempotent - can be called multiple times safely
    if (_closed) return;
    _closed = true;

    // Cancel the stream subscription if active
    _socketSubscription?.cancel();

    // Clear all message callbacks to prevent memory leaks
    _messageCallbacks.clear();

    // Close the underlying socket
    socket.close();
  }

  // ...existing code...

  /// Get local address (null if not bound)
  InternetAddress? get localAddress => _localAddress;

  /// Get local port (null if not bound)
  int? get localPort => _localPort;

  /// Get the compression codec used for data messages
  ICompressionCodec get compressionCodec => _compressionCodec;

  /// Get the underlying RawDatagramSocket
  @override
  RawDatagramSocket get socket => super.socket;

  /// Check if the socket is closed
  bool get isClosed => _closed;

  /// Extracts all registered message callbacks for remote peers.
  ///
  /// Returns a [ShspSocketProfile] containing all message listener registrations.
  /// This can be applied to a new socket via [withProfile].
  ShspSocketProfile extractProfile() {
    final Map<String, List<OnMessageListener>> listeners = {};

    // Extract all message callbacks from the callback map
    for (final key in _messageCallbacks.keys) {
      final handler = _messageCallbacks.getHandler(key);
      if (handler != null) {
        final handlerListeners = <OnMessageListener>[];
        for (var i = 0; i < handler.map.length; i++) {
          handlerListeners.add(handler.map.getByIndex(i) as OnMessageListener);
        }
        if (handlerListeners.isNotEmpty) {
          listeners[key] = handlerListeners;
        }
      }
    }

    return ShspSocketProfile(messageListeners: listeners);
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
        newSocket._messageCallbacks.add(
          key,
          (record) => listener(record),
        );
      }
    }

    return newSocket;
  }

  /// Applies a profile (message callbacks) to this existing socket.
  ///
  /// This instance method restores all message callbacks from a [ShspSocketProfile]
  /// to this socket. Useful when transferring state from an old socket to a new one.
  /// The callbacks are added to any existing callbacks in this socket (merge, not replace).
  ///
  /// Parameters:
  ///   - [profile]: The ShspSocketProfile containing message listeners to apply
  ///
  /// Example:
  /// ```dart
  /// final profile = oldSocket.extractProfile();
  /// final newSocket = ShspSocket.fromRaw(rawSocket);
  /// newSocket.applyProfile(profile);
  /// ```
  void applyProfile(ShspSocketProfile profile) {
    for (final entry in profile.messageListeners.entries) {
      final key = entry.key;
      for (final listener in entry.value) {
        _messageCallbacks.add(key, (record) => listener(record));
      }
    }
  }
}
