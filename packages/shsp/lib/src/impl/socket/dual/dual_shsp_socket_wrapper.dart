import 'package:meta/meta.dart';

import '../../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class DualShspSocketWrapper
    with DualShspSocketWrapperDelegationMixin
    implements IDualShspSocketWrapper {
  DualShspSocketWrapper();

  DualShspSocketWrapper.emptyForDI();

  DualShspSocketWrapper.createFromSocket(this.dualSocket);

  @isInjected
  @protected
  late IDualShspSocketAuto dualSocket;

  @override
  IDualShspSocketAuto get delegateDualSocket => dualSocket;

  set internalSocket(IDualShspSocketAuto newSocket) => dualSocket = newSocket;
}
