import 'dart:io';

import 'package:singleton_manager/singleton_manager.dart';

import '../../../shsp.dart';

/// Migrates the ipv4 and/or ipv6 slots of the [IDualShspSocketMigratable]
/// registered under [key] in one call, instead of calling [migrateShspSocket]
/// once per family by hand.
///
/// Pass whichever of [ipv4Socket]/[ipv6Socket] needs migrating — the other
/// can be left `null` to leave that family untouched. Each socket must
/// actually be bound to the family it's passed as (an IPv6 [ipv4Socket]
/// throws [ArgumentError]), since [migrateShspSocket] otherwise infers the
/// subkey from the socket itself and a mismatch would silently migrate the
/// wrong slot.
///
/// As with [migrateShspSocket], the dual migratable's own router is never
/// replaced; only the plain `IShspSocket`/`RawDatagramSocket` registry
/// entries move.
({IShspSocket? ipv4, IShspSocket? ipv6}) migrateDualShspSockets({
  IShspSocket? ipv4Socket,
  IShspSocket? ipv6Socket,
  String key = 'default',
}) {
  if (ipv4Socket == null && ipv6Socket == null) {
    throw ArgumentError(
      'migrateDualShspSockets: pass at least one of '
      'ipv4Socket/ipv6Socket.',
    );
  }

  // Fetching the dual migratable confirms one is actually registered under
  // [key] before anything is migrated.
  RegistryManager.instance.getInstance<IDualShspSocketMigratable>(key: key);

  if (ipv4Socket != null &&
      ipv4Socket.localAddress?.type != InternetAddressType.IPv4) {
    throw ArgumentError.value(
      ipv4Socket,
      'ipv4Socket',
      'must be bound to an IPv4 address, got '
          '${ipv4Socket.localAddress?.type}.',
    );
  }
  if (ipv6Socket != null &&
      ipv6Socket.localAddress?.type != InternetAddressType.IPv6) {
    throw ArgumentError.value(
      ipv6Socket,
      'ipv6Socket',
      'must be bound to an IPv6 address, got '
          '${ipv6Socket.localAddress?.type}.',
    );
  }

  return (
    ipv4: ipv4Socket == null ? null : migrateShspSocket(ipv4Socket, key: key),
    ipv6: ipv6Socket == null ? null : migrateShspSocket(ipv6Socket, key: key),
  );
}
