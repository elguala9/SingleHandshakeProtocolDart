

import '../../../shsp.dart';

/// Interface for SHSP Socket
abstract interface class IShspSocketWrapper implements IShspSocket{
  void migrateSocket(IShspSocket socket);
}
