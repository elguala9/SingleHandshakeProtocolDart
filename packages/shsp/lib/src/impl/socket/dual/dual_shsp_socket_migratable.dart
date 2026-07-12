import '../../../../shsp.dart';

class DualShspSocketMigratable
    extends DualShspSocket
    implements IDualShspSocketMigratable {
  DualShspSocketMigratable(Sockets sockets)
    : super(Sockets(
        ipv4SocketImpl: _wrap(sockets.ipv4SocketImpl),
        ipv6SocketImpl: _wrap(sockets.ipv6SocketImpl),
      ));

  DualShspSocketMigratable.fromWrappers({
    IShspSocketWrapper? ipv4Wrapper,
    IShspSocketWrapper? ipv6Wrapper,
  }) : super(Sockets(
        ipv4SocketImpl: ipv4Wrapper,
        ipv6SocketImpl: ipv6Wrapper,
      ));

  static IShspSocket? _wrap(IShspSocket? socket) {
    if (socket == null) return null;
    if (socket is ShspSocketWrapper) return socket;
    return ShspSocketWrapper(socket);
  }

  @override
  void migrateSocketIpv4(IShspSocket socket) {
    final ipv4 = ipv4SocketImpl;
    if (ipv4 == null) {
      ipv4SocketImpl = ShspSocketWrapper(socket);
      return;
    }
    if (ipv4 is! ShspSocketWrapper) {
      ipv4SocketImpl = ShspSocketWrapper(ipv4);
    }
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
