import '../../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

class ShspSocketWrapper
    with ShspSocketWrapperDelegationMixin
    implements IValueForRegistry, IShspSocketWrapper {
  ShspSocketWrapper(IShspSocket socket) : _socket = socket {
    if (socket is ShspSocketWrapper) {
      throw ArgumentError(
        'ShspSocketWrapper cannot wrap another ShspSocketWrapper — nesting is not allowed.',
      );
    }
  }

  IShspSocket _socket;

  @override
  IShspSocket get delegateSocket => _socket;

  set internalSocket(ShspSocket newSocket) => _socket = newSocket;

  void Function()? _listeningCallback;
  void Function()? _closeCallback;
  void Function(dynamic)? _errorCallback;

  @override
  void migrateSocket(IShspSocket newSocket) {
    final oldSocket = _socket;
    final profile = oldSocket.extractProfile();
    _socket = newSocket;
    _socket.applyProfile(profile);
    final lc = _listeningCallback;
    if (lc != null) _socket.setListeningCallback(lc);
    final cc = _closeCallback;
    if (cc != null) _socket.setCloseCallback(cc);
    final ec = _errorCallback;
    if (ec != null) _socket.setErrorCallback(ec);
    if (!oldSocket.isClosed) {
      oldSocket.close();
    }
  }

  @override
  void setCloseCallback(void Function() cb) {
    _closeCallback = cb;
    delegateSocket.setCloseCallback(cb);
  }

  @override
  void setErrorCallback(void Function(dynamic err) cb) {
    _errorCallback = cb;
    delegateSocket.setErrorCallback(cb);
  }

  @override
  void setListeningCallback(void Function() cb) {
    _listeningCallback = cb;
    delegateSocket.setListeningCallback(cb);
  }
}
