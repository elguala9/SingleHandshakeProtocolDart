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
Future<IShspSocket> migrateShspSocket(
  RawDatagramSocket socket, {
  String key = 'default',
}) async {
  final address = socket.address;

  final type = address.type;
  final subkey = shspSocketSubkeyFor(type);


  RegistryManager.instance.setInstance<RawDatagramSocket>(
    socket,
    key: key,
    subkey: subkey,
  );

  final oldIshspSocket = RegistryManager.instance.getInstance<IShspSocket>();
  
  final wrapper = RegistryManager.instance.getInstance<IShspSocketWrapper>();

  final newIShspSocket = ShspSocket.withRawAndProfile(socket, oldIshspSocket.extractProfile());

  wrapper.migrateSocket(newIShspSocket);

  RegistryManager.instance.setInstance<IShspSocket>(
    newIShspSocket,
    key: key,
    subkey: subkey,
  );

  return newIShspSocket;
}

Future<IShspSocket> migrateShspSocketIpv4({
  String key = 'default',
}) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  return migrateShspSocket(socket, key: key);
}

Future<IShspSocket> migrateShspSocketIpv6({
  String key = 'default',
}) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv6, 0);
  return migrateShspSocket(socket, key: key);
}