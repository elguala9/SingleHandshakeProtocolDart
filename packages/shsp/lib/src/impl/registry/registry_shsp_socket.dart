import 'dart:io';

import '../../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

enum SocketType {
  ipv4(4),
  ipv6(6);

  const SocketType(this.value);

  final int value;
}

enum ReturnTypeInitialization {
  ipv4and6,
  ipv4only;
}

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
class RegistryShspSocket with Registry<SocketType, IShspSocket> {
  RegistryShspSocket();

  factory RegistryShspSocket.initializeDI(){
    final instance = RegistryShspSocket();
    instance.initializeDI();
    return instance;
  }

  /// Register sockets from an [IDualShspSocket].
  ///
  /// Returns [ReturnTypeInitialization.ipv4and6] if both are registered,
  /// [ReturnTypeInitialization.ipv4only] if only IPv4 is available.
  ReturnTypeInitialization initialize(IDualShspSocket dualSocket) {
    _registerSocket(SocketType.ipv4, dualSocket.ipv4Socket);
    if (dualSocket.ipv6Socket != null) {
      _registerSocket(SocketType.ipv6, dualSocket.ipv6Socket!);
      return ReturnTypeInitialization.ipv4and6;
    }
    return ReturnTypeInitialization.ipv4only;
  }



  /// Initialize using a DI-provided [IDualShspSocket].
  ReturnTypeInitialization initializeDI() =>
      initialize(SingletonDIAccess.get<IDualShspSocket>());

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
      print('Warning: IPv6 socket binding failed - IPv6 may not be available: $e');
    }

    final dualSocket = DualShspSocket.fromSockets(
      ShspSocketWrapper(ipv4Socket),
      ipv6Socket != null ? ShspSocketWrapper(ipv6Socket) : null,
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
}

/// Backward-compatibility alias.
typedef InputRegistrySingletonShspSocket = InputRegistryShspSocket;
