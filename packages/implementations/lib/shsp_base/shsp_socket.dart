import 'dart:async';
import 'dart:io';
// ...existing code...
import 'package:meta/meta.dart';
import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import '../utility/message_callback_map.dart';
import '../utility/raw_shsp_socket.dart';

/// SHSP Socket implementation wrapping RawDatagramSocket
class ShspSocket extends RawShspSocket implements IShspSocket {
  final MessageCallbackMap _messageCallbacks;
  StreamSubscription<RawSocketEvent>? _socketSubscription;

  late CallbackOn _onClose;
  late CallbackOnError _onError;
  late CallbackOn _onListening;

  InternetAddress? _localAddress;
  int? _localPort;
  bool _closed = false;

  /// Internal constructor for factory creation
  ShspSocket.internal(super.socket, this._messageCallbacks) {
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
      onMessage(datagram.data, rinfo);
    }
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
  static Future<ShspSocket> bind(InternetAddress address, int port) async {
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
    final socket = ShspSocket.internal(rawSocket, callbacks);

    socket._localAddress = address;
    socket._localPort = rawSocket.port;  // Read actual port from OS, not parameter

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
    return super.send(buffer, peer.address, peer.port);
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

  /// Get the underlying RawDatagramSocket
  @override
  RawDatagramSocket get socket => super.socket;
}
