import 'package:singleton_manager/singleton_manager.dart';
import '../../../shsp.dart';

/// Interface for a registry that manages SHSP sockets by [SocketType].
abstract interface class IRegistryShspSocket implements IValueForRegistry {
  ReturnTypeInitialization initialize(IDualShspSocketMigratable dualSocket);
  ReturnTypeInitialization initializeDI();
  Future<ReturnTypeInitialization> bind(InputRegistryShspSocket input);
}
