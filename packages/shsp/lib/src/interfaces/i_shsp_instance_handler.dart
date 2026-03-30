import './index.dart';
import '../types/peer_types.dart';

typedef InstanceCallback = void Function(IShspInstance instance);
typedef Opts = ({InstanceCallback? instanceCallback});

abstract interface class IShspInstanceHandler {
  Future<IShspInstance> initiateShsp(
    PeerInfo remotePeer,
    IShspInstance instance,
    Opts opts,
  );
  Future<IShspInstance?> getShsp(PeerInfo remotePeer);
  Future<IShspInstance> getShspSafe(PeerInfo remotePeer);
  void close(PeerInfo remotePeer);
  void closeAll();
}
