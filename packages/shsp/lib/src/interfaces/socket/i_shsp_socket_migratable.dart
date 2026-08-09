

import '../../../shsp.dart';

/// Interface for SHSP Socket
abstract interface class IShspSocketMigratable implements IShspSocket{
  void migrateSocket(IShspSocket socket);
}
