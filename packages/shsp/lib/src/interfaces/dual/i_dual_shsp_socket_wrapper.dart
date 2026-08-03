import '../../../shsp.dart';

export 'i_dual_shsp_socket_auto.dart';
export 'i_dual_shsp_socket_migratable.dart';

abstract interface class IDualShspSocketWrapper
    implements IDualShspSocketAuto {
  set internalSocket(IDualShspSocketAuto socket);
}
