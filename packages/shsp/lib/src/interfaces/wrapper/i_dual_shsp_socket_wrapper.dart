

import 'package:singleton_manager/singleton_manager.dart';
import '../../../shsp.dart';

/// Interface for SHSP Socket
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
