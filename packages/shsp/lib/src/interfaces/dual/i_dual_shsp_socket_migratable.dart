import 'dart:io';

import 'package:singleton_manager/singleton_manager.dart';
import '../../../shsp.dart';

abstract interface class IDualShspSocketMigratable
    implements DualShspSocket, IValueForRegistry {
  /// Migrates the socket for the given address family. Defaults to IPv6;
  /// pass [InternetAddressType.IPv4] to migrate the IPv4 socket.
  void migrateSocket(
    IShspSocket socket, [
    InternetAddressType type = InternetAddressType.IPv6,
  ]);

  /// The socket wrapper for the given address family. Defaults to IPv6;
  /// pass [InternetAddressType.IPv4] for the IPv4 wrapper.
  IShspSocketWrapper getSocketWrapper([
    InternetAddressType type = InternetAddressType.IPv6,
  ]);
}
