import '../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Builds a [IDualShspSocketMigratable] with IPv4 (always) and IPv6 (when available).
///
/// Shared by [initializePointDualShsp] and [initializePointRegistryAccess].
Future<IDualShspSocketMigratable> buildDualSocket() async {
  final ipv4Socket = await ShspSocket.bindDefault();
  final IShspSocketWrapper ipv4SocketWrapper = ShspSocketWrapper(ipv4Socket);
  final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
  IShspSocketWrapper? ipv6SocketWrapper;
  if (hasIPv6) {
    final ipv6Socket = await ShspSocket.bindDefault(ipv6: true);
    ipv6SocketWrapper = ShspSocketWrapper(ipv6Socket);
  }
  return DualShspSocketMigratable.fromWrappers(
    ipv4SocketWrapper,
    ipv6SocketWrapper,
  );
}

/// Initializes SHSP using the singleton DI container.
///
/// Creates dual IPv4/IPv6 sockets and registers them in [SingletonDIAccess].
/// Access the socket afterwards with:
/// ```dart
/// final socket = SingletonDIAccess.get<IDualShspSocketMigratable>();
/// ```
///
/// See also: [initializePointRegistryAccess] for key-based access.
Future<void> initializePointDualShsp() async {
  final dualSocket = await buildDualSocket();
  SingletonDIAccess.addInstance<IDualShspSocketMigratable>(dualSocket);

  final dualSingleton = DualShspSocketWrapperDI.initializeDI();
  SingletonDIAccess.addInstance(dualSingleton);

  final reg = RegistrySingletonShspSocket.instance;
  SingletonDIAccess.addInstanceAs<IRegistryShspSocket, RegistrySingletonShspSocket>(reg);
  SingletonDIAccess.addInstance(reg);
  reg.initializeDI();
}

/// Initializes SHSP using key-based [RegistryAccess].
///
/// Mirrors [initializePointDualShsp] exactly, but registers everything under
/// a [String] [key] in [RegistryAccess] instead of in [SingletonDIAccess].
///
/// Access afterwards with:
/// ```dart
/// final socket = RegistryAccess.getInstance<IDualShspSocketMigratable>(key);
/// final wrapper = RegistryAccess.getInstance<IDualShspSocketWrapper>(key);
/// final reg    = RegistryAccess.getInstance<IRegistryShspSocket>(key);
/// ```
///
/// Multiple independent instances can coexist under different keys.
///
/// See also: [initializePointDualShsp] for type-based singleton DI access.
Future<void> initializePointRegistryAccess(String key) async {
  final dualSocket = await buildDualSocket();
  RegistryAccess.register<IDualShspSocketMigratable>(key, dualSocket);

  final IDualShspSocketWrapper dualWrapper = DualShspSocketWrapperDI();
  dualWrapper.internalSocket = dualSocket;
  RegistryAccess.register<IDualShspSocketWrapper>(key, dualWrapper);

  final IRegistryShspSocket reg = RegistryShspSocket();
  reg.initialize(dualSocket);
  RegistryAccess.register<IRegistryShspSocket>(key, reg);
}
