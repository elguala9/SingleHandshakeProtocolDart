
import 'dart:io';

import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

enum SocketType {
  ipv4(4),
  ipv6(6);

  final int value;

  const SocketType(this.value);
}

enum ReturnTypeInitialization {
  ipv4and6,
  ipv4only;
}

class InputRegistrySingletonShspSocket {
  InternetAddress? ipv4Address;
  int ipv4Port = 0;
  InternetAddress? ipv6Address;
  int ipv6Port = 0;
  
  InputRegistrySingletonShspSocket({
    this.ipv4Address,
    this.ipv4Port = 0,
    this.ipv6Address,
    this.ipv6Port = 0,
  });
}

/// Singleton registry for managing SHSP sockets (IPv4 and IPv6)
///
/// Provides automatic socket initialization with IPv6 fallback support.
/// Usage:
/// ```dart
/// // Initialize with automatic IPv6 fallback
/// final ipv6Available = await RegistrySingletonShspSocket.instance.initialize(
///   ipv4Port: 8080,
///   ipv6Port: 8081,
/// );
///
/// // Access sockets
/// final ipv4 = RegistrySingletonShspSocket.instance.getByKey(SocketType.ipv4);
/// ```
class RegistrySingletonShspSocket with Registry<SocketType, IShspSocket> implements ISingleton<InputRegistrySingletonShspSocket, ReturnTypeInitialization> {
  static final RegistrySingletonShspSocket _instance = RegistrySingletonShspSocket._internal();

  static RegistrySingletonShspSocket get instance => _instance;

  /// Private constructor
  RegistrySingletonShspSocket._internal();

  RegistrySingletonShspSocket();

  RegistrySingletonShspSocket.initializeDI(){
    initializeDI();
  }

  /// Initialize the socket registry with IPv4 and IPv6 sockets
  ///
  /// IPv6 binding is attempted but fails gracefully if not available.
  /// Returns true if both IPv4 and IPv6 are bound, false if only IPv4.
  @override
  Future<ReturnTypeInitialization> initialize(InputRegistrySingletonShspSocket input) async {
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
      ipv6Socket = null;
    }


    initializeWithSockets(ipv4Socket, ipv6Socket);

    if (ipv6Socket != null) {
      return ReturnTypeInitialization.ipv4only;
    }
    return ReturnTypeInitialization.ipv4and6;
    
  }

  /// Initialize the socket registry with IPv4 and IPv6 sockets
  ///
  /// IPv6 binding is attempted but fails gracefully if not available.
  /// Returns true if both IPv4 and IPv6 are bound, false if only IPv4.
  @override
  Future<ReturnTypeInitialization> initializeDI() async {
    return initializeWithDualSocket(SingletonDIAccess.get<IDualShspSocket>());
  }

  /// Initialize the socket registry with existing socket instances
  ReturnTypeInitialization initializeWithSockets(
    IShspSocket ipv4Socket,
    IShspSocket? ipv6Socket,
  ) {
    try {
      register(SocketType.ipv4, ipv4Socket);
    } catch (e) {
      // If already registered, replace it
      replace(SocketType.ipv4, ipv4Socket);
    }
    if (ipv6Socket != null) {
      try {
        register(SocketType.ipv6, ipv6Socket);
      } catch (e) {
        // If already registered, replace it
        replace(SocketType.ipv6, ipv6Socket);
      }
      return ReturnTypeInitialization.ipv4and6;
    }
    return ReturnTypeInitialization.ipv4and6;
  }

  /// Initialize the socket registry with existing socket instances
  ReturnTypeInitialization initializeWithDualSocket(
    IDualShspSocket dualShspSocket,
  ) {
    return initializeWithSockets(dualShspSocket.ipv4Socket, dualShspSocket.ipv6Socket);
  }
}

typedef RegistrySingletonShspPeer<Key> = RegistrySingleton<Key, IShspPeer>;

