import 'package:meta/meta.dart';

import '../../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Resolves its IPv4/IPv6 sockets via DI when given — connect each
/// [IShspSocket] into [RegistryManager] under the matching `'ipv4'`/`'ipv6'`
/// subkey (see `connectDualShspSockets`) and call
/// [dependencyInjectionFactory]:
/// ```dart
/// await connectDualShspSockets();
/// final wrapper = DualShspSocketWrapper.dependencyInjectionFactory();
/// ```
@dependencyInjectable
class DualShspSocketWrapper
    with DualShspSocketWrapperDelegationMixin
    implements IDualShspSocketWrapper {
  DualShspSocketWrapper({
    @Subkey('ipv4') IShspSocket? ipv4Socket,
    @Subkey('ipv6') IShspSocket? ipv6Socket,
  }) {
    if (ipv4Socket != null || ipv6Socket != null) {
      dualSocket = DualShspSocketAuto(
        Sockets(ipv4SocketImpl: ipv4Socket, ipv6SocketImpl: ipv6Socket),
      );
    }
  }

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory DualShspSocketWrapper.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final ipv4Socket = RegistryManager.instance.getInstanceNullable<IShspSocket>(key: key, subkey: 'ipv4'); // GENERATED CODE - DO NOT MODIFY BY HAND
    final ipv6Socket = RegistryManager.instance.getInstanceNullable<IShspSocket>(key: key, subkey: 'ipv6'); // GENERATED CODE - DO NOT MODIFY BY HAND

    return DualShspSocketWrapper( // GENERATED CODE - DO NOT MODIFY BY HAND
      ipv4Socket: ipv4Socket, // GENERATED CODE - DO NOT MODIFY BY HAND
      ipv6Socket: ipv6Socket, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  DualShspSocketWrapper.emptyForDI();

  DualShspSocketWrapper.createFromSocket(this.dualSocket);

  @protected
  late IDualShspSocketAuto dualSocket;

  @override
  IDualShspSocketAuto get delegateDualSocket => dualSocket;

  set internalSocket(IDualShspSocketAuto newSocket) => dualSocket = newSocket;
}
