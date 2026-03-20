

import '../../../shsp.dart';

/// Interface for SHSP Socket
/// // implements DualShspSocket so that i am sure that is the same 
abstract interface class IDualShspSocketMigratable implements DualShspSocket {
  void migrateSocketIpv4(IShspSocket socket);
  void migrateSocketIpv6(IShspSocket socket);
}
