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

/// Registry for managing SHSP sockets (IPv4 and IPv6)
///
/// Provides socket initialization with IPv6 fallback support.
class RegistryShspSocket with Registry<SocketType, IShspSocket> {
  RegistryShspSocket();

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

  void _registerSocket(SocketType type, IShspSocket socket) {
    try {
      register(type, socket);
    } catch (_) {
      replace(type, socket);
    }
  }
}
