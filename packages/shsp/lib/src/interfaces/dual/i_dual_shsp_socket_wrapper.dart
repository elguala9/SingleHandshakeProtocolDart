import 'package:singleton_manager/singleton_manager.dart';
import '../../../shsp.dart';

export 'i_dual_shsp_socket_auto.dart';
export 'i_dual_shsp_socket_migratable.dart';

abstract interface class IDualShspSocketWrapper
    implements IDualShspSocketAuto, IValueForRegistry {
  set internalSocket(IDualShspSocketAuto socket);
}
