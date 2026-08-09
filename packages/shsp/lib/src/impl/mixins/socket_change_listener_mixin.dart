import 'package:meta/meta.dart';
import '../../interfaces/socket/i_shsp_socket.dart';
import '../../types/callback_types.dart';
import '../../types/peer_types.dart';
import '../socket/core/shsp_socket_singleton.dart';

mixin SocketChangeListenerMixin {
  ShspSocketSingleton? _singleton;
  void Function(IShspSocket)? _socketChangedListener;

  PeerInfo get remotePeer;
  MessageCallbackFunction get socketCallbackFunction;

  @protected
  void initSocketChangeListener(ShspSocketSingleton singleton) {
    if (_socketChangedListener != null) return;
    _singleton = singleton;
    _socketChangedListener = (newSocket) {
      newSocket.setMessageCallback(remotePeer, socketCallbackFunction);
    };
    singleton.socketChangedCallback.register(_socketChangedListener!);
  }

  @protected
  void deregisterSocketChangeListener() {
    if (_socketChangedListener != null) {
      _singleton!.socketChangedCallback.unregister(_socketChangedListener!);
      _socketChangedListener = null;
      _singleton = null;
    }
  }
}
