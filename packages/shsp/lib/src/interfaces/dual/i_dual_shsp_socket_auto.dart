import 'dart:io';

import 'package:singleton_manager/singleton_manager.dart';
import '../../../shsp.dart';

abstract interface class IDualShspSocketAuto
    implements IDualShspSocketMigratable, IValueForRegistry {
  /// Refreshes the socket for the given address family. Defaults to IPv6;
  /// pass [InternetAddressType.IPv4] to refresh the IPv4 socket.
  IShspSocket refreshSocket([
    InternetAddressType type = InternetAddressType.IPv6,
  ]);
  Sockets refreshSockets();
}
