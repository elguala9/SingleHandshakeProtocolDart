import 'dart:io';
import '../../../../shsp.dart';
import 'dual_shsp_socket_message.dart';
import 'dual_shsp_socket_profile.dart';

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
  DualShspSocket(IShspSocket ipv4Socket, IShspSocket? ipv6Socket) {
    ipv4SocketImpl = ipv4Socket;
    ipv6SocketImpl = ipv6Socket;
    _onClose = CallbackOn();
    _onError = CallbackOnError();
    _onListening = CallbackOn();

    // Register callbacks on IPv4 socket to forward events
    ipv4SocketImpl.setListeningCallback(() {
      _onListening.call(null);
    });
    ipv4SocketImpl.setCloseCallback(() {
      _onClose.call(null);
    });
    ipv4SocketImpl.setErrorCallback((err) {
      _onError.call(err);
    });

    // Register callbacks on IPv6 socket if available
    final ipv6 = ipv6SocketImpl;
    if (ipv6 != null) {
      ipv6.setListeningCallback(() {
        _onListening.call(null);
      });
      ipv6.setCloseCallback(() {
        _onClose.call(null);
      });
      ipv6.setErrorCallback((err) {
        _onError.call(err);
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
  ///   - [ipv4Socket]: The IPv4 ShspSocket instance (required)
  ///   - [ipv6Socket]: The IPv6 ShspSocket instance (optional)
  ///
  /// Example:
  /// ```dart
  /// final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 8000);
  /// final ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 8000);
  /// final dualSocket = DualShspSocket.fromSockets(ipv4, ipv6);
  /// ```
  DualShspSocket.fromSockets(IShspSocket ipv4Socket, [IShspSocket? ipv6Socket])
    : this(ipv4Socket, ipv6Socket);

  late IShspSocket ipv4SocketImpl;
  late IShspSocket? ipv6SocketImpl;
  late CallbackOn _onClose;
  late CallbackOnError _onError;
  late CallbackOn _onListening;

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
    final ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);

    ShspSocket? ipv6Socket;
    try {
      ipv6Socket = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
    } catch (e) {
      // IPv6 not available on this system, continue with IPv4 only
      ipv6Socket = null;
    }

    return DualShspSocket(ipv4Socket, ipv6Socket);
  }

  /// Exposes the IPv4 socket for direct access if needed
  @override
  IShspSocket get ipv4Socket => ipv4SocketImpl;

  /// Exposes the IPv6 socket for direct access if available
  @override
  IShspSocket? get ipv6Socket => ipv6SocketImpl;

  /// Get the underlying RawDatagramSocket from the IPv4 socket (for backward compatibility)
  @override
  RawDatagramSocket get socket => ipv4SocketImpl.socket;

  /// Getters for message mixin
  @override
  IShspSocket get ipv4SocketForMessages => ipv4SocketImpl;
  @override
  IShspSocket? get ipv6SocketForMessages => ipv6SocketImpl;

  /// Getters for profile mixin
  @override
  IShspSocket get ipv4SocketForProfile => ipv4SocketImpl;
  @override
  IShspSocket? get ipv6SocketForProfile => ipv6SocketImpl;

  @override
  CallbackOn get onClose => _onClose;

  @override
  CallbackOnError get onError => _onError;

  @override
  CallbackOn get onListening => _onListening;

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
    _onError.register(cb);
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
    final ipv6 = ipv6SocketImpl;

    if (isIPv6 && ipv6 != null) {
      return ipv6.sendTo(buffer, peer);
    } else {
      return ipv4SocketImpl.sendTo(buffer, peer);
    }
  }

  /// Check if either socket is closed
  @override
  bool get isClosed =>
      ipv4SocketImpl.isClosed || (ipv6SocketImpl?.isClosed ?? false);

  /// Close both sockets
  @override
  void close() {
    ipv4SocketImpl.close();
    final ipv6 = ipv6SocketImpl;
    if (ipv6 != null) {
      ipv6.close();
    }
  }

  /// Serialized state of both sockets
  @override
  String serializedObject() {
    final ipv6 = ipv6SocketImpl;
    if (ipv6 != null) {
      return 'DualShspSocket(IPv4: ${ipv4SocketImpl.serializedObject()}, IPv6: ${ipv6.serializedObject()})';
    } else {
      return 'DualShspSocket(IPv4: ${ipv4SocketImpl.serializedObject()}, IPv6: null)';
    }
  }

  /// Get the local address (returns IPv4 address, with IPv6 as fallback)
  @override
  InternetAddress? get localAddress =>
      ipv4SocketImpl.localAddress ?? ipv6SocketImpl?.localAddress;

  /// Get the local port (returns IPv4 port, with IPv6 as fallback if IPv4 not available)
  @override
  int? get localPort => ipv4SocketImpl.localPort ?? ipv6SocketImpl?.localPort;

  /// Get the compression codec (from IPv4 socket)
  @override
  ICompressionCodec get compressionCodec => ipv4SocketImpl.compressionCodec;

  @override
  void destroy() {
    close();
  }
}
