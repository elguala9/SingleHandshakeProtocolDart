import 'dart:io';

import '../../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

@dependencyInjectable
class DualShspSocketAuto
    extends DualShspSocketMigratable
    implements IDualShspSocketAuto {
  DualShspSocketAuto({
    @Subkey('ipv4') IShspSocketMigratable? ipv4Migratable,
    @Subkey('ipv6') IShspSocketMigratable? ipv6Migratable,
  }) : super(
          ipv4Migratable: ipv4Migratable,
          ipv6Migratable: ipv6Migratable,
        );

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory DualShspSocketAuto.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final ipv4Migratable = RegistryManager.instance.getInstanceNullable<IShspSocketMigratable>(key: key, subkey: 'ipv4'); // GENERATED CODE - DO NOT MODIFY BY HAND
    final ipv6Migratable = RegistryManager.instance.getInstanceNullable<IShspSocketMigratable>(key: key, subkey: 'ipv6'); // GENERATED CODE - DO NOT MODIFY BY HAND

    return DualShspSocketAuto( // GENERATED CODE - DO NOT MODIFY BY HAND
      ipv4Migratable: ipv4Migratable, // GENERATED CODE - DO NOT MODIFY BY HAND
      ipv6Migratable: ipv6Migratable, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  DualShspSocketAuto.fromSockets(Sockets sockets) : super.fromSockets(sockets);

  DualShspSocketAuto.fromMigratable(
    DualShspSocketMigratable migratable
  ) : super(
          ipv4Migratable: migratable.ipv4SocketMigratable,
          ipv6Migratable: migratable.ipv6SocketMigratable,
        );

  static Future<DualShspSocketAuto> create() async {
    final ipv4Socket = await ShspSocket.bindIfPossible(InternetAddress.anyIPv4, 0);
    final ipv6Socket = await ShspSocket.bindIfPossible(InternetAddress.anyIPv6, 0);
    if (ipv4Socket == null && ipv6Socket == null) {
      throw Exception('Failed to bind both IPv4 and IPv6 sockets');
    }
    return DualShspSocketAuto.fromSockets(Sockets(ipv4SocketImpl: ipv4Socket, ipv6SocketImpl: ipv6Socket));
  }

  @override
  IShspSocket refreshSocket([
    InternetAddressType type = InternetAddressType.IPv6,
  ]) {
    if (type == InternetAddressType.IPv4) {
      _rebindIpv4Async();
      final ipv4 = ipv4SocketImpl;
      if (ipv4 == null) {
        throw StateError('Cannot refresh IPv4 socket: no IPv4 socket bound');
      }
      return ipv4;
    }
    _rebindIpv6Async();
    final ipv6 = ipv6SocketImpl;
    if (ipv6 == null) {
      throw StateError('Cannot refresh IPv6 socket: no IPv6 socket bound');
    }
    return ipv6;
  }

  IShspSocket refreshSocketIpv4() => refreshSocket(InternetAddressType.IPv4);

  IShspSocket refreshSocketIpv6() => refreshSocket(InternetAddressType.IPv6);

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
