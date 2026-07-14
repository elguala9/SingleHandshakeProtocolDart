import 'dart:io';

import '../../../../shsp.dart';

class DualShspSocketAuto
    extends DualShspSocketMigratable
    implements IDualShspSocketAuto {
  DualShspSocketAuto(Sockets sockets) : super(sockets);

  DualShspSocketAuto.fromWrappers({
    IShspSocketWrapper? ipv4Wrapper,
    IShspSocketWrapper? ipv6Wrapper,
  }) : super.fromWrappers(
          ipv4Wrapper: ipv4Wrapper,
          ipv6Wrapper: ipv6Wrapper,
        );

  DualShspSocketAuto.fromMigratable(
    DualShspSocketMigratable migratable
  ) : super.fromWrappers(
          ipv4Wrapper: migratable.ipv4SocketWrapper,
          ipv6Wrapper: migratable.ipv6SocketWrapper,
        );

  static Future<DualShspSocketAuto> create() async {
    final ipv4Socket = await ShspSocket.bindIfPossible(InternetAddress.anyIPv4, 0);
    final ipv6Socket = await ShspSocket.bindIfPossible(InternetAddress.anyIPv6, 0);
    if (ipv4Socket == null && ipv6Socket == null) {
      throw Exception('Failed to bind both IPv4 and IPv6 sockets');
    }
    return DualShspSocketAuto(Sockets(ipv4SocketImpl: ipv4Socket, ipv6SocketImpl: ipv6Socket));
  }

  @override
  IShspSocket refreshSocketIpv4() {
    _rebindIpv4Async();
    final ipv4 = ipv4SocketImpl;
    if (ipv4 == null) {
      throw StateError('Cannot refresh IPv4 socket: no IPv4 socket bound');
    }
    return ipv4;
  }

  @override
  IShspSocket refreshSocketIpv6() {
    _rebindIpv6Async();
    final ipv6 = ipv6SocketImpl;
    if (ipv6 == null) {
      throw StateError('Cannot refresh IPv6 socket: no IPv6 socket bound');
    }
    return ipv6;
  }

  @override
  Sockets refreshSockets() {
    _rebindIpv4Async();
    _rebindIpv6Async();

    final ipv4 = ipv4SocketImpl;
    final ipv6 = ipv6SocketImpl;
    final sockets = Sockets(ipv4SocketImpl: ipv4);

    if (ipv6 != null) {
      final addr = ipv6.localAddress;
      if (addr != null && addr.type == InternetAddressType.IPv6) {
        sockets.ipv6SocketImpl = ipv6;
      }
    }

    return sockets;
  }

  Future<void> _rebindIpv4Async() async {
    try {
      final newSocket = await ShspSocket.bindIfPossible(InternetAddress.anyIPv4, 0);
      if (newSocket != null) {
        migrateSocketIpv4(newSocket);
      }
    } catch (_) {}
  }

  Future<void> _rebindIpv6Async() async {
    try {
      final newSocket = await ShspSocket.bindIfPossible(InternetAddress.anyIPv6, 0);
      if (newSocket != null) {
        migrateSocketIpv6(newSocket);
      }
    } catch (_) {}
  }
}
