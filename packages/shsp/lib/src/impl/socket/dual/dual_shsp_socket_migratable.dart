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
class DualShspSocketMigratable
    extends DualShspSocket
    implements IDualShspSocketMigratable {
  /// Creates a [DualShspSocketMigratable] wrapping raw sockets in [ShspSocketWrapper] internally.
  DualShspSocketMigratable(IShspSocket ipv4Socket, [IShspSocket? ipv6Socket])
    : super(
        ShspSocketWrapper(ipv4Socket),
        ipv6Socket != null ? ShspSocketWrapper(ipv6Socket) : null,
      );

  /// Creates a [DualShspSocketMigratable] from already-wrapped sockets.
  DualShspSocketMigratable.fromWrappers(
    IShspSocketWrapper ipv4Wrapper, [
    IShspSocketWrapper? ipv6Wrapper,
  ]) : super(ipv4Wrapper, ipv6Wrapper);

  @override
  void migrateSocketIpv4(IShspSocket socket) {
    if (ipv4SocketImpl is! ShspSocketWrapper) ipv4SocketImpl = ShspSocketWrapper(ipv4SocketImpl);
    (ipv4SocketImpl as ShspSocketWrapper).migrateSocket(socket);
  }

  @override
  void migrateSocketIpv6(IShspSocket socket) {
    final existing = ipv6SocketImpl;
    if (existing == null) {
      ipv6SocketImpl = ShspSocketWrapper(socket);
    } else {
      if (existing is! ShspSocketWrapper) ipv6SocketImpl = ShspSocketWrapper(existing);
      (ipv6SocketImpl as ShspSocketWrapper).migrateSocket(socket);
    }
  }
}
