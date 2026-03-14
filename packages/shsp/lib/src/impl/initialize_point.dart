import 'package:shsp/shsp.dart';
import 'package:shsp/src/impl/socket/shsp_socket_wrapper.dart';
import 'package:singleton_manager/singleton_manager.dart';

Future<void> initializePointShsp() async{
  final ipv4Socket = await ShspSocket.bindDefault();
  final ipv4SocketWrapper = ShspSocketWrapper(ipv4Socket);
  final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
  ShspSocketWrapper? ipv6SocketWrapper;
  if(hasIPv6){
    final ipv6Socket = await ShspSocket.bindDefault(ipv6: true);
    ipv6SocketWrapper = ShspSocketWrapper(ipv6Socket);
  }
  final dualSocket = DualShspSocket.fromSockets(ipv4SocketWrapper, ipv6SocketWrapper);
  await SingletonDIAccess.addInstanceAs<IDualShspSocket, DualShspSocket>(dualSocket);

  final reg = RegistrySingletonShspSocket.initializeDI();
  await SingletonDIAccess.addInstance<RegistrySingletonShspSocket>(reg);
}