import 'dart:io';

import '../../../shsp.dart';

export 'registry_shsp_socket.dart';

class InputRegistrySingletonShspSocket {
  InputRegistrySingletonShspSocket({
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

/// Singleton registry for managing SHSP sockets (IPv4 and IPv6)
///
/// Usage:
/// ```dart
/// // Bind from addresses/ports
/// await RegistrySingletonShspSocket.instance.bind(
///   InputRegistrySingletonShspSocket(ipv4Port: 8080, ipv6Port: 8081),
/// );
///
/// // Or initialize from DI
/// RegistrySingletonShspSocket.initializeDI();
///
/// // Access sockets
/// final ipv4 = RegistrySingletonShspSocket.instance.getByKey(SocketType.ipv4);
/// ```
class RegistrySingletonShspSocket extends RegistryShspSocket {
  RegistrySingletonShspSocket._internal() : super();

  RegistrySingletonShspSocket.initializeDI() {
    initializeDI();
  }

  static final RegistrySingletonShspSocket _instance = RegistrySingletonShspSocket._internal();

  static RegistrySingletonShspSocket get instance => _instance;

  /// Bind new sockets from addresses/ports and register them.
  ///
  /// IPv6 binding is attempted but fails gracefully if not available.
  Future<ReturnTypeInitialization> bind(InputRegistrySingletonShspSocket input) async {
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
}

typedef RegistrySingletonShspPeer<Key> = RegistrySingleton<Key, IShspPeer>;
