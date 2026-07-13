import '../../shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Builds a [DualShspSocketAuto] with IPv4 (when available) and IPv6 (when available).
///
/// Its sockets can be rebound at runtime via [DualShspSocketAuto.refreshSocketIpv4],
/// [DualShspSocketAuto.refreshSocketIpv6] or [DualShspSocketAuto.refreshSockets],
/// useful to recover from network interface changes (Wi-Fi reconnects, VPN
/// toggles, etc.).
///
/// Shared by [initializePointDualShsp] and [initializePointRegistryAccess].
Future<IDualShspSocketAuto> buildDualSocket() => DualShspSocketAuto.create();

/// Initializes SHSP using the singleton DI container.
///
/// Creates dual IPv4/IPv6 sockets and registers them in [SingletonDIAccess].
/// Access the socket afterwards with:
/// ```dart
/// final socket = SingletonDIAccess.get<IDualShspSocketAuto>();
/// socket.refreshSockets();
/// ```
///
/// See also: [initializePointRegistryAccess] for key-based access.
Future<void> initializePointDualShsp() async {
  final dualSocket = await buildDualSocket();
  SingletonDIAccess.addInstance<IDualShspSocketMigratable>(dualSocket);
  SingletonDIAccess.addInstance<IDualShspSocketAuto>(dualSocket);

  final dualSingleton = DualShspSocketWrapperDI.initializeDI();
  SingletonDIAccess.addInstance(dualSingleton);

  final reg = RegistrySingletonShspSocket.instance;
  SingletonDIAccess.addInstanceAs<IRegistryShspSocket, RegistrySingletonShspSocket>(reg);
  SingletonDIAccess.addInstanceAs<RegistryShspSocket, RegistrySingletonShspSocket>(reg);
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
/// final socket = RegistryAccess.getInstance<IDualShspSocketAuto>(key);
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
  RegistryAccess.register<IDualShspSocketAuto>(key, dualSocket);

  final IDualShspSocketWrapper dualWrapper = DualShspSocketWrapperDI();
  dualWrapper.internalSocket = dualSocket;
  RegistryAccess.register<IDualShspSocketWrapper>(key, dualWrapper);

  final IRegistryShspSocket reg = RegistryShspSocket();
  reg.initialize(dualSocket);
  RegistryAccess.register<IRegistryShspSocket>(key, reg);
}
