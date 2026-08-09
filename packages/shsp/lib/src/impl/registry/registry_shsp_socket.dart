import 'dart:io';

import '../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

enum SocketType {
  ipv4(4),
  ipv6(6);

  const SocketType(this.value);

  final int value;
}

enum ReturnTypeInitialization { ipv4and6, ipv4only }

class InputRegistryShspSocket {
  InputRegistryShspSocket({
    this.ipv4Address,
    this.ipv4Port = 0,
    this.ipv6Address,
    this.ipv6Port = 0,
  });

  InternetAddress? ipv4Address;
  int ipv4Port = 0;
  InternetAddress? ipv6Address;
  int ipv6Port = 0;
}

/// Registry for managing SHSP sockets (IPv4 and IPv6).
///
/// Can be used as a plain instance or extended for singleton use.
///
/// Usage:
/// ```dart
/// final registry = RegistryShspSocket();
/// await registry.bind(InputRegistryShspSocket(ipv4Port: 8080));
/// final ipv4 = registry.getByKey(SocketType.ipv4);
/// ```
///
/// Or resolve its IPv4/IPv6 sockets via DI — connect each [IShspSocket]
/// into [RegistryManager] under the matching `'ipv4'`/`'ipv6'` subkey (see
/// `connectDualShspSockets`) and call [dependencyInjectionFactory]:
/// ```dart
/// await connectDualShspSockets();
/// final registry = RegistryShspSocket.dependencyInjectionFactory();
/// ```
@dependencyInjectable
class RegistryShspSocket
    with KeyedRegistry<SocketType, IShspSocket>
    implements IRegistryShspSocket {
  RegistryShspSocket({
    @Subkey('ipv4') IShspSocket? ipv4Socket,
    @Subkey('ipv6') IShspSocket? ipv6Socket,
  }) {
    if (ipv4Socket != null) _registerSocket(SocketType.ipv4, ipv4Socket);
    if (ipv6Socket != null) _registerSocket(SocketType.ipv6, ipv6Socket);
  }

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory RegistryShspSocket.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final ipv4Socket = RegistryManager.instance.tryGetInstance<IShspSocket>(key: key, subkey: 'ipv4'); // GENERATED CODE - DO NOT MODIFY BY HAND
    final ipv6Socket = RegistryManager.instance.tryGetInstance<IShspSocket>(key: key, subkey: 'ipv6'); // GENERATED CODE - DO NOT MODIFY BY HAND

    return RegistryShspSocket( // GENERATED CODE - DO NOT MODIFY BY HAND
      ipv4Socket: ipv4Socket, // GENERATED CODE - DO NOT MODIFY BY HAND
      ipv6Socket: ipv6Socket, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Register sockets from an [IDualShspSocketMigratable].
  ///
  /// Returns [ReturnTypeInitialization.ipv4and6] if both are registered,
  /// [ReturnTypeInitialization.ipv4only] if only IPv4 is available.
  ReturnTypeInitialization initialize(IDualShspSocketMigratable dualSocket) {
    final ipv4 = dualSocket.getSocket(InternetAddressType.IPv4);
    if (ipv4 != null) {
      _registerSocket(SocketType.ipv4, ipv4);
    }
    final ipv6 = dualSocket.getSocket(InternetAddressType.IPv6);
    if (ipv6 != null) {
      _registerSocket(SocketType.ipv6, ipv6);
      return ReturnTypeInitialization.ipv4and6;
    }
    return ReturnTypeInitialization.ipv4only;
  }

  /// Bind new sockets from addresses/ports and register them.
  ///
  /// IPv6 binding is attempted but fails gracefully if not available.
  Future<ReturnTypeInitialization> bind(InputRegistryShspSocket input) async {
    final ipv4Socket = await ShspSocket.bind(
      input.ipv4Address ?? InternetAddress.anyIPv4,
      input.ipv4Port,
    );

    IShspSocket? ipv6Socket;
    try {
      ipv6Socket = await ShspSocket.bind(
        input.ipv6Address ?? InternetAddress.anyIPv6,
        input.ipv6Port,
      );
    } catch (e) {
      print(
        'Warning: IPv6 socket binding failed - IPv6 may not be available: $e',
      );
    }

    final IDualShspSocketMigratable dualSocket = DualShspSocketMigratable(
      ipv4Migratable: ShspSocketMigratable(ipv4Socket),
      ipv6Migratable: ipv6Socket != null ? ShspSocketMigratable(ipv6Socket) : null,
    );
    return initialize(dualSocket);
  }

  void _registerSocket(SocketType type, IShspSocket socket) {
    try {
      register(type, socket);
    } catch (_) {
      replace(type, socket);
    }
  }

  void destroy() {
    for (final type in keys) {
      getInstance(type).destroy();
    }
    clearRegistry();
  }
}

/// Backward-compatibility alias.
typedef InputRegistrySingletonShspSocket = InputRegistryShspSocket;
