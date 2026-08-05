import 'dart:io';

import 'package:singleton_manager/singleton_manager.dart';

import '../../../shsp.dart';

/// Subkey SHSP sockets are registered/resolved under for a given [type].
String shspSocketSubkeyFor(InternetAddressType type) =>
    type == InternetAddressType.IPv4 ? 'ipv4' : 'ipv6';

/// Migrates the [IDualShspSocketMigratable] registered under [key] onto
/// [socket], resolving which subkey ('ipv4'/'ipv6') to target straight from
/// the socket's own address family.
///
/// The [IDualShspSocketMigratable] already registered for [key] is never
/// replaced — that's the whole point of the migratable variant: it stays put
/// as the live router, and this call just swaps the socket it delegates to
/// for that family. Only the `RawDatagramSocket`/`IShspSocket` registry
/// entries for the resolved subkey are overwritten (via
/// [RegistryManager.setInstance]), since those are the ones meant to be
/// swapped out.
IShspSocket migrateShspSocket(
  IShspSocket socket, {
  String key = 'default',
}) {
  final address = socket.localAddress;
  if (address == null) {
    throw ArgumentError.value(
      socket,
      'socket',
      'must be bound to a local address before it can be migrated.',
    );
  }
  final type = address.type;
  final subkey = shspSocketSubkeyFor(type);

  final current = RegistryManager.instance
      .getInstance<IDualShspSocketMigratable>(key: key);
  current.migrateSocket(socket, type);

  RegistryManager.instance.setInstance<RawDatagramSocket>(
    socket.socket,
    key: key,
    subkey: subkey,
  );
  RegistryManager.instance.setInstance<IShspSocket>(
    socket,
    key: key,
    subkey: subkey,
  );

  return socket;
}
