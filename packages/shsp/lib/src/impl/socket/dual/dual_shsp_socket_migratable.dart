import 'dart:io';
import '../../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

@dependencyInjectable
class DualShspSocketMigratable
    extends DualShspSocket
    implements IDualShspSocketMigratable {

  DualShspSocketMigratable({
    @Subkey('ipv4') IShspSocketMigratable? ipv4Migratable,
    @Subkey('ipv6') IShspSocketMigratable? ipv6Migratable,
  }) : super(Sockets(
        ipv4SocketImpl: ipv4Migratable,
        ipv6SocketImpl: ipv6Migratable,
      ));

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory DualShspSocketMigratable.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final ipv4Migratable = RegistryManager.instance.getInstanceNullable<IShspSocketMigratable>(key: key, subkey: 'ipv4'); // GENERATED CODE - DO NOT MODIFY BY HAND
    final ipv6Migratable = RegistryManager.instance.getInstanceNullable<IShspSocketMigratable>(key: key, subkey: 'ipv6'); // GENERATED CODE - DO NOT MODIFY BY HAND

    return DualShspSocketMigratable( // GENERATED CODE - DO NOT MODIFY BY HAND
      ipv4Migratable: ipv4Migratable, // GENERATED CODE - DO NOT MODIFY BY HAND
      ipv6Migratable: ipv6Migratable, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  DualShspSocketMigratable.fromSockets(Sockets sockets)
    : super(Sockets(
        ipv4SocketImpl: _wrap(sockets.ipv4SocketImpl),
        ipv6SocketImpl: _wrap(sockets.ipv6SocketImpl),
      ));

  static IShspSocket? _wrap(IShspSocket? socket) {
    if (socket == null) return null;
    if (socket is ShspSocketMigratable) return socket;
    return ShspSocketMigratable(socket);
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
      ipv4SocketImpl = ShspSocketMigratable(socket);
      return;
    }
    if (ipv4 is! ShspSocketMigratable) {
      ipv4SocketImpl = ShspSocketMigratable(ipv4);
    }
    (ipv4SocketImpl as ShspSocketMigratable).migrateSocket(socket);
  }

  void _migrateSocketIpv6(IShspSocket socket) {
    final existing = ipv6SocketImpl;
    if (existing == null) {
      ipv6SocketImpl = ShspSocketMigratable(socket);
    } else {
      if (existing is! ShspSocketMigratable) ipv6SocketImpl = ShspSocketMigratable(existing);
      (ipv6SocketImpl as ShspSocketMigratable).migrateSocket(socket);
    }
  }

  @override
  IShspSocketMigratable getSocketMigratable([
    InternetAddressType type = InternetAddressType.IPv6,
  ]) {
    final impl = type == InternetAddressType.IPv4 ? ipv4SocketImpl : ipv6SocketImpl;
    if (impl is! IShspSocketMigratable) {
      final label = type == InternetAddressType.IPv4 ? 'IPv4' : 'IPv6';
      throw StateError('$label socket is not available or not wrapped');
    }
    return impl;
  }

  void migrateSocketIpv4(IShspSocket socket) => _migrateSocketIpv4(socket);

  void migrateSocketIpv6(IShspSocket socket) => _migrateSocketIpv6(socket);

  IShspSocketMigratable get ipv4SocketMigratable => getSocketMigratable(InternetAddressType.IPv4);

  IShspSocketMigratable get ipv6SocketMigratable => getSocketMigratable(InternetAddressType.IPv6);
}
