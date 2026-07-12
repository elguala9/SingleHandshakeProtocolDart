

import 'package:singleton_manager/singleton_manager.dart';
import '../../../shsp.dart';


/// Interface for autonomus sockets, it should avoid the developer to handle sockets directly
/// implements DualShspSocket so that i am sure that is the same
abstract interface class IDualShspSocketAuto
    implements IDualShspSocketMigratable, IValueForRegistry {
  /// create a new socket for ipv4
  IShspSocket refreshSocketIpv4();
  /// create a new socket for ipv6
  IShspSocket refreshSocketIpv6();
  /// create a new socket for ipv6 and ipv4
  Sockets refreshSockets();
}

/// // implements DualShspSocket so that i am sure that is the same
abstract interface class IDualShspSocketMigratable
    implements DualShspSocket, IValueForRegistry {
  void migrateSocketIpv4(IShspSocket socket);
  void migrateSocketIpv6(IShspSocket socket);
}


/// Interface for the DualShspSocketWrapper/DualShspSocketWrapperDI proxy.
abstract interface class IDualShspSocketWrapper
    implements IDualShspSocket, IValueForRegistry {
  set internalSocket(IDualShspSocketMigratable socket);
}
