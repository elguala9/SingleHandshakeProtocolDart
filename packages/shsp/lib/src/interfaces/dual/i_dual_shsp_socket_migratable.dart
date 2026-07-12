import 'package:singleton_manager/singleton_manager.dart';
import '../../../shsp.dart';

abstract interface class IDualShspSocketMigratable
    implements DualShspSocket, IValueForRegistry {
  void migrateSocketIpv4(IShspSocket socket);
  void migrateSocketIpv6(IShspSocket socket);
}
