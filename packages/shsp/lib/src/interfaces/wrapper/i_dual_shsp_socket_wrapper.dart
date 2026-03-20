

import '../../../shsp.dart';

/// Interface for SHSP Socket
abstract interface class IDualShspSocketMigratable{
  void migrateSocketIpv4(IShspSocket socket);
  void migrateSocketIpv6(IShspSocket socket);
}
