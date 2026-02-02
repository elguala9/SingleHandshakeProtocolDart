import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

typedef InstanceCallback = void Function(IShspInstance instance);
typedef Opts = ({InstanceCallback? instanceCallback});

abstract interface class IShspInstanceHandler {
  Future<IShspInstance> initiateShsp(
      PeerInfo remotePeer, IShspInstance instance, Opts opts);
  Future<IShspInstance?> getShsp(PeerInfo remotePeer);
  Future<IShspInstance> getShspSafe(PeerInfo remotePeer);
  void close(PeerInfo remotePeer);
  void closeAll();
}
