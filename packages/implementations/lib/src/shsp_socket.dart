import 'dart:io';
// ...existing code...
import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'utility/message_callback_map.dart';
import 'utility/raw_shsp_socket.dart';

/// SHSP Socket implementation wrapping RawDatagramSocket 
class ShspSocket extends RawShspSocket implements IShspSocket {
  final MessageCallbackMap _messageCallbacks;
  
  void Function()? _closeCallback;
  void Function(dynamic err)? _errorCallback;
  void Function()? _listeningCallback;
  void Function()? _connectCallback;

  InternetAddress? _localAddress;
  int? _localPort;

  /// Internal constructor for factory creation
  ShspSocket.internal(super.socket, this._messageCallbacks) {
    _setupEventListeners();
  }

  /// Setup event listeners for the raw socket
  void _setupEventListeners() {
    socket.listen(
      (event) {
        switch (event) {
          case RawSocketEvent.read:
            _handleReadEvent();
            break;
          case RawSocketEvent.closed:
            onClose();
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
        onError(error);
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
  /// - Binds the socket to the specified local address and port
  /// - Initializes the message callback map
  /// - Sets up all event listeners (read, close, error, etc.)
  /// 
  /// Parameters:
  ///   - [address]: The local InternetAddress to bind to (e.g., InternetAddress.anyIPv4)
  ///   - [port]: The local port number to listen on
  /// 
  /// Returns: A Future that resolves to a new ShspSocket instance
  /// 
  /// Example:
  /// ```dart
  /// final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 8000);
  /// ```
  static Future<ShspSocket> bind(InternetAddress address, int port) async {
    final rawSocket = await RawDatagramSocket.bind(address, port);
    final callbacks = MessageCallbackMap();
    final socket = ShspSocket.internal(rawSocket, callbacks);
    
    socket._localAddress = address;
    socket._localPort = port;
    
    return socket;
  }



  @override
  void setMessageCallback(String key, void Function(List<int> msg, RemoteInfo rinfo) cb) {
    _messageCallbacks.add(key, cb);
  }

  @override
  void setCloseCallback(void Function() cb) {
    _closeCallback = cb;
  }

  @override
  void setErrorCallback(void Function(dynamic err) cb) {
    _errorCallback = cb;
  }

  @override
  void setListeningCallback(void Function() cb) {
    _listeningCallback = cb;
  }

  @override
  void setConnectCallback(void Function() cb) {
    _connectCallback = cb;
  }

  @override
  void onClose() {
    _closeCallback?.call();
  }

  @override
  void onError(dynamic err) {
    _errorCallback?.call(err);
  }

  @override
  void onListening() {
    _listeningCallback?.call();
  }

  @override
  void onConnect() {
    _connectCallback?.call();
  }

  @override
  String serializedObject() {
    return 'ShspSocket{localAddress: $_localAddress, localPort: $_localPort}';
  }

  @override
  void onMessage(List<int> msg, RemoteInfo rinfo) {
    final key = MessageCallbackMap.formatKey(rinfo.address, rinfo.port);
    final cb = _messageCallbacks.get(key);
    cb?.call(msg, rinfo);
  }

  @override
  int sendTo(List<int> buffer, InternetAddress address, int port) {
    return super.send(buffer, address, port);
  }

  @override
  void close() {
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
