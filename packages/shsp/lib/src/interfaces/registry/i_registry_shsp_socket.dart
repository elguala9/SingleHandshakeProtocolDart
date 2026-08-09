import '../../../shsp.dart';

/// Interface for a registry that manages SHSP sockets by [SocketType].
abstract interface class IRegistryShspSocket {
  ReturnTypeInitialization initialize(IDualShspSocketMigratable dualSocket);
  Future<ReturnTypeInitialization> bind(InputRegistryShspSocket input);
}
