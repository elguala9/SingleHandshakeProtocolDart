import '../../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Resolves [socket] via DI — connect an `IShspSocket` into
/// [RegistryManager] under the `'ipv4'`/`'ipv6'` subkey (see
/// `connectDualShspSockets`) and call [dependencyInjectionFactory]:
/// ```dart
/// await connectDualShspSockets();
/// final wrapper = ShspSocketMigratable.dependencyInjectionFactory(subkey: 'ipv4');
/// ```
@dependencyInjectable
class ShspSocketMigratable
    with ShspSocketMigratableDelegationMixin
    implements IShspSocketMigratable {
  ShspSocketMigratable(@Subkey.inherited() IShspSocket socket) : _socket = socket {
    if (socket is ShspSocketMigratable) {
      throw ArgumentError(
        'ShspSocketMigratable cannot wrap another ShspSocketMigratable — nesting is not allowed.',
      );
    }
  }

  factory ShspSocketMigratable.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final socket = RegistryManager.instance.getInstance<IShspSocket>(key: key, subkey: subkey); // GENERATED CODE - DO NOT MODIFY BY HAND

    return ShspSocketMigratable( // GENERATED CODE - DO NOT MODIFY BY HAND
      socket, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

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
