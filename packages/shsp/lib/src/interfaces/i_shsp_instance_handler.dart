import './index.dart';
import '../types/callback_types.dart';
import '../types/instance_profile.dart';
import '../types/internet_address_converter.dart';
import '../types/peer_types.dart';
import '../types/remote_info.dart';
import '../types/socket_profile.dart';

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
