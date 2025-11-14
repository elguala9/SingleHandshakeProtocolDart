
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_interfaces/src/connection/i_shsp_signal.dart';

/// Hanlde punching hole for LAN traversal
abstract interface class IShspHandshakeHandler {
  Future<IShspPeer> startHandshake(IHandshakeInitiatorSignalHandler remotePeer);
  void setCallbackHandshake(void Function(IShspPeer peer) callback);
}
