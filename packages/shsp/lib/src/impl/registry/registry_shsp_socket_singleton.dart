import '../../../shsp.dart';

export 'registry_shsp_socket.dart';

/// Singleton registry for managing SHSP sockets (IPv4 and IPv6).
///
/// For non-singleton usage, use [RegistryShspSocket] directly.
///
/// Usage:
/// ```dart
/// // Bind from addresses/ports
/// await RegistrySingletonShspSocket.instance.bind(
///   InputRegistryShspSocket(ipv4Port: 8080, ipv6Port: 8081),
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
}

typedef RegistrySingletonShspPeer<Key> = RegistrySingleton<Key, IShspPeer>;
