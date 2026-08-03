import 'dart:io';
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
  void migrateSocket(
    IShspSocket socket, [
    InternetAddressType type = InternetAddressType.IPv6,
  ]) {
    switch (type) {
      case InternetAddressType.IPv4:
        _migrateSocketIpv4(socket);
      case InternetAddressType.IPv6:
        _migrateSocketIpv6(socket);
    }
  }

  void _migrateSocketIpv4(IShspSocket socket) {
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

  void _migrateSocketIpv6(IShspSocket socket) {
    final existing = ipv6SocketImpl;
    if (existing == null) {
      ipv6SocketImpl = ShspSocketWrapper(socket);
    } else {
      if (existing is! ShspSocketWrapper) ipv6SocketImpl = ShspSocketWrapper(existing);
      (ipv6SocketImpl as ShspSocketWrapper).migrateSocket(socket);
    }
  }

  @override
  IShspSocketWrapper getSocketWrapper([
    InternetAddressType type = InternetAddressType.IPv6,
  ]) {
    final impl = type == InternetAddressType.IPv4 ? ipv4SocketImpl : ipv6SocketImpl;
    if (impl is! IShspSocketWrapper) {
      final label = type == InternetAddressType.IPv4 ? 'IPv4' : 'IPv6';
      throw StateError('$label socket is not available or not wrapped');
    }
    return impl;
  }

  void migrateSocketIpv4(IShspSocket socket) => _migrateSocketIpv4(socket);

  void migrateSocketIpv6(IShspSocket socket) => _migrateSocketIpv6(socket);

  IShspSocketWrapper get ipv4SocketWrapper => getSocketWrapper(InternetAddressType.IPv4);

  IShspSocketWrapper get ipv6SocketWrapper => getSocketWrapper(InternetAddressType.IPv6);
}
