import 'package:singleton_manager/singleton_manager.dart';
import '../../../shsp.dart';

abstract interface class IDualShspSocketAuto
    implements IDualShspSocketMigratable, IValueForRegistry {
  IShspSocket refreshSocketIpv4();
  IShspSocket refreshSocketIpv6();
  Sockets refreshSockets();
}
