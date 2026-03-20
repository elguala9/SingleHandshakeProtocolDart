import '../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';


Future<void> initializePointDualShsp() async {
  final ipv4Socket = await ShspSocket.bindDefault();
  final ipv4SocketWrapper = ShspSocketWrapper(ipv4Socket);
  final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
  ShspSocketWrapper? ipv6SocketWrapper;
  if (hasIPv6) {
    final ipv6Socket = await ShspSocket.bindDefault(ipv6: true);
    ipv6SocketWrapper = ShspSocketWrapper(ipv6Socket);
  }
  final dualSocket = DualShspSocketMigratable.fromWrappers(
    ipv4SocketWrapper,
    ipv6SocketWrapper,
  );
  SingletonDIAccess.addInstanceAs<IDualShspSocketMigratable, DualShspSocketMigratable>(dualSocket);

  final dualSingleton = DualShspSocketWrapperDI.initializeDI();
  SingletonDIAccess.addInstance(dualSingleton);

  final reg = RegistrySingletonShspSocket.instance;
  reg.initializeDI();
  SingletonDIAccess.addInstanceAs<RegistryShspSocket, RegistrySingletonShspSocket>(reg);
  SingletonDIAccess.addInstance(reg);
}
