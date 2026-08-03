import 'dart:io';

import '../../../shsp.dart';

abstract interface class IDualShspSocketAuto
    implements IDualShspSocketMigratable {
  /// Refreshes the socket for the given address family. Defaults to IPv6;
  /// pass [InternetAddressType.IPv4] to refresh the IPv4 socket.
  IShspSocket refreshSocket([
    InternetAddressType type = InternetAddressType.IPv6,
  ]);
  Sockets refreshSockets();
}
