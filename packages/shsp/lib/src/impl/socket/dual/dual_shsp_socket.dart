import 'dart:io';
import '../../../../shsp.dart';

/// Routing adapter that manages both IPv4 and IPv6 sockets as a single unified interface.
///
/// This class implements [IDualShspSocket] and internally holds two [ShspSocket] instances:
/// - `_ipv4Socket`: IPv4 socket, always required
/// - `_ipv6Socket`: IPv6 socket, optional (may be null on systems without IPv6)
///
/// All outgoing messages are routed to the appropriate socket based on the peer's
/// address family. Message callbacks are registered on both sockets so that either
/// can receive and deliver messages to the appropriate handler.
class DualShspSocket
    with DualShspSocketMessageMixin, DualShspSocketProfileMixin
    implements IDualShspSocket {
  DualShspSocket(Sockets sockets) {
    ipv4SocketImpl = sockets.ipv4SocketImpl;
    ipv6SocketImpl = sockets.ipv6SocketImpl;
    _onClose = CallbackOnWithSocket();
    _onError = CallbackOnErrorWithSocket();
    _onListening = CallbackOnWithSocket();

    final ipv4 = ipv4SocketImpl;
    if (ipv4 != null) {
      ipv4.setListeningCallback(() {
        _onListening.call(ipv4);
      });
      ipv4.setCloseCallback(() {
        _onClose.call(ipv4);
      });
      ipv4.setErrorCallback((err) {
        _onError.call((error: err, socket: ipv4));
      });
    }

    final ipv6 = ipv6SocketImpl;
    if (ipv6 != null) {
      ipv6.setListeningCallback(() {
        _onListening.call(ipv6);
      });
      ipv6.setCloseCallback(() {
        _onClose.call(ipv6);
      });
      ipv6.setErrorCallback((err) {
        _onError.call((error: err, socket: ipv6));
      });
    }
  }

  /// Named constructor to create a DualShspSocket from two existing socket instances.
  ///
  /// Wraps the provided IPv4 and IPv6 sockets without creating new ones.
  /// Useful when you already have configured sockets and want to manage them
  /// as a single unified dual-stack interface.
  ///
  /// Parameters:
  ///   - [ipv4Socket]: The IPv4 ShspSocket instance (optional)
  ///   - [ipv6Socket]: The IPv6 ShspSocket instance (optional)
  ///
  /// Example:
  /// ```dart
  /// final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 8000);
  /// final ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 8000);
  /// final dualSocket = DualShspSocket.fromSockets(ipv4, ipv6);
  /// ```
  DualShspSocket.fromSockets(Sockets sockets)
    : this(sockets);

  late IShspSocket? ipv4SocketImpl;
  late IShspSocket? ipv6SocketImpl;
  late CallbackOnWithSocket _onClose;
  late CallbackOnErrorWithSocket _onError;
  late CallbackOnWithSocket _onListening;

  /// Factory method to create a DualShspSocket without parameters.
  ///
  /// Automatically creates both IPv4 and IPv6 sockets with default settings:
  /// - IPv4 socket bound to InternetAddress.anyIPv4 on a dynamic port (0)
  /// - IPv6 socket bound to InternetAddress.anyIPv6 on a dynamic port (0), if available
  ///
  /// Returns: A Future that resolves to a new DualShspSocket instance
  ///
  /// Example:
  /// ```dart
  /// final dualSocket = await DualShspSocket.create();
  /// ```
  static Future<DualShspSocket> create() async {
    ShspSocket? ipv6Socket;
    try {
      ipv6Socket = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
    } catch (e) {
      ipv6Socket = null;
    }

    ShspSocket? ipv4Socket;
    try {
      ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (e) {
      ipv4Socket = null;
    }
    // no socket, no party
    if(ipv4Socket == null && ipv6Socket == null)
      throw ArgumentError('Error during the socket binding');
    return DualShspSocket(Sockets(ipv4SocketImpl: ipv4Socket, ipv6SocketImpl: ipv6Socket));
  }

  /// Exposes the IPv4 socket for direct access if needed
  @override
  IShspSocket? get ipv4Socket => ipv4SocketImpl;

  /// Exposes the IPv6 socket for direct access if available
  @override
  IShspSocket? get ipv6Socket => ipv6SocketImpl;

  /// Get the underlying RawDatagramSocket from the IPv4 socket (for backward compatibility)
  RawDatagramSocket get socket {
    final ipv6 = ipv6SocketImpl;
    if (ipv6 != null)
      return ipv6.socket;
    final ipv4 = ipv4SocketImpl;
    if (ipv4 != null)
      return ipv4.socket;
    throw StateError('No Socket Found');
  }

  /// Getters for message mixin
  @override
  IShspSocket? get ipv4SocketForMessages => ipv4SocketImpl;
  @override
  IShspSocket? get ipv6SocketForMessages => ipv6SocketImpl;

  /// Getters for profile mixin
  @override
  IShspSocket? get ipv4SocketForProfile => ipv4SocketImpl;
  @override
  IShspSocket? get ipv6SocketForProfile => ipv6SocketImpl;

  @override
  CallbackOnWithSocket get onClose => _onClose;

  @override
  CallbackOnErrorWithSocket get onError => _onError;

  @override
  CallbackOnWithSocket get onListening => _onListening;

  @override
  void setListeningCallback(void Function() cb) {
    _onListening.register((_) => cb());
  }

  @override
  void setCloseCallback(void Function() cb) {
    _onClose.register((_) => cb());
  }

  @override
  void setErrorCallback(void Function(dynamic err) cb) {
    _onError.register((record) => cb(record.error));
  }

  /// Send data to a peer, routing to the appropriate socket based on address family.
  ///
  /// If the peer has an IPv6 address and IPv6 socket is available, routes to IPv6.
  /// Otherwise routes to IPv4.
  ///
  /// Returns the number of bytes written.
  @override
  int sendTo(List<int> buffer, PeerInfo peer) {
    final isIPv6 = peer.address.type == InternetAddressType.IPv6;
    final isIPv4 = peer.address.type == InternetAddressType.IPv4;
    final ipv6 = ipv6SocketImpl;
    final ipv4 = ipv4SocketImpl;

    if (isIPv6 && ipv6 != null) {
      return ipv6.sendTo(buffer, peer);
    } 
    if (isIPv4 && ipv4 != null) {
      return ipv4.sendTo(buffer, peer);
    }
    if(isIPv6 && ipv6 == null && ipv4 != null)
      throw StateError('IPv6 adress but only ipv4 socket found');
    if(isIPv4 && ipv4 == null && ipv6 != null)
      throw StateError('IPv4 adress but only ipv6 socket found');
    throw StateError('Socket not found for sending data');
  }

  /// Check if both sockets are closed (or unavailable)
  @override
  bool get isClosed =>
      (ipv4SocketImpl?.isClosed ?? true) && (ipv6SocketImpl?.isClosed ?? true);

  /// Close both sockets
  @override
  void close() {
    ipv4SocketImpl?.close();
    ipv6SocketImpl?.close();
  }

  /// Serialized state of both sockets
  @override
  String serializedObject() {
    final ipv4 = ipv4SocketImpl;
    final ipv6 = ipv6SocketImpl;
    final ipv4Str = ipv4?.serializedObject() ?? 'null';
    final ipv6Str = ipv6?.serializedObject() ?? 'null';
    return 'DualShspSocket(IPv4: $ipv4Str, IPv6: $ipv6Str)';
  }

  /// Get the local address (returns IPv6 address, with IPv4 as fallback)
  @override
  InternetAddress? get localAddress =>
      ipv6SocketImpl?.localAddress ?? ipv4SocketImpl?.localAddress;

  /// Get the local port (returns IPv6 port, with IPv4 as fallback if IPv6 not available)
  @override
  int? get localPort =>
      ipv6SocketImpl?.localPort ?? ipv4SocketImpl?.localPort;

  /// Get the compression codec (from IPv6 socket, with IPv4 as fallback)
  @override
  ICompressionCodec get compressionCodec {
    final ipv6 = ipv6SocketImpl;
    if (ipv6 != null) return ipv6.compressionCodec;
    final ipv4 = ipv4SocketImpl;
    if (ipv4 != null) return ipv4.compressionCodec;
    throw StateError('No socket available to get compression codec');
  }

  @override
  void destroy() {
    close();
  }
}
