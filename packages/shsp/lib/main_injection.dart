// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:singleton_manager/singleton_manager.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND

import 'src/impl/instance/core/auto_shsp_instance.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'src/impl/peer/auto_shsp_peer.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'src/impl/registry/registry_shsp_socket.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'src/impl/socket/core/shsp_socket.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'src/impl/socket/core/shsp_socket_migratable.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'src/impl/socket/dual/dual_shsp_socket_auto.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'src/impl/socket/dual/dual_shsp_socket_migratable.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'src/interfaces/dual/i_dual_shsp_socket_auto.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'src/interfaces/dual/i_dual_shsp_socket_migratable.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'src/interfaces/registry/i_registry_shsp_socket.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'src/interfaces/socket/i_shsp_socket.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'src/interfaces/socket/i_shsp_socket_migratable.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND

/// Connects every `@dependencyInjectable` class discovered under the scanned
/// input directory to `RegistryManager.instance`, using each generated
/// `dependencyInjectionFactory()` as the connected factory.
/// Each call is independent — registering under a different [key] never
/// overwrites a previous call, so multiple singleton graphs can be set up
/// side by side by calling this with different keys.
///
/// Every method below is a regular, overridable instance method — mix
/// [MainInjectionShspMixin] into your own class (or override on [MainInjectionShsp])
/// to hook into `beforeRegisterAllSingletonsShsp` / `afterRegisterAllSingletonsShsp`, or replace
/// `registerAllSingletonsShsp` entirely.
mixin MainInjectionShspMixin { // GENERATED CODE - DO NOT MODIFY BY HAND
  /// Called by [registerAllSingletonsShsp] right before it connects anything.
  /// Override to customize. // GENERATED CODE - DO NOT MODIFY BY HAND
  void beforeRegisterAllSingletonsShsp({String key = 'default'}) {} // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Connects every discovered singleton under [key]. // GENERATED CODE - DO NOT MODIFY BY HAND
  void registerAllSingletonsShsp({String key = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    beforeRegisterAllSingletonsShsp(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    RegistryManager.instance // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<AutoShspInstance, AutoShspInstance>(() => AutoShspInstance.dependencyInjectionFactory(key: key), key: key) // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<AutoShspPeer, AutoShspPeer>(() => AutoShspPeer.dependencyInjectionFactory(key: key), key: key) // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IRegistryShspSocket, RegistryShspSocket>(() => RegistryShspSocket.dependencyInjectionFactory(key: key), key: key) // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IShspSocket, ShspSocket>(() => ShspSocket.dependencyInjectionFactory(key: key, subkey: 'ipv4'), key: key, subkey: 'ipv4') // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IShspSocket, ShspSocket>(() => ShspSocket.dependencyInjectionFactory(key: key, subkey: 'ipv6'), key: key, subkey: 'ipv6') // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IShspSocketMigratable, ShspSocketMigratable>(() => ShspSocketMigratable.dependencyInjectionFactory(key: key, subkey: 'ipv4'), key: key, subkey: 'ipv4') // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IShspSocketMigratable, ShspSocketMigratable>(() => ShspSocketMigratable.dependencyInjectionFactory(key: key, subkey: 'ipv6'), key: key, subkey: 'ipv6') // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IDualShspSocketAuto, DualShspSocketAuto>(() => DualShspSocketAuto.dependencyInjectionFactory(key: key), key: key) // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IDualShspSocketMigratable, DualShspSocketMigratable>(() => DualShspSocketMigratable.dependencyInjectionFactory(key: key), key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    afterRegisterAllSingletonsShsp(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Called by [registerAllSingletonsShsp] right after it finishes connecting
  /// everything. Override to customize. // GENERATED CODE - DO NOT MODIFY BY HAND
  void afterRegisterAllSingletonsShsp({String key = 'default'}) {} // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Called by [registerAllSingletonsShspAsync] right before it connects anything.
  /// Override to customize. // GENERATED CODE - DO NOT MODIFY BY HAND
  Future<void> beforeRegisterAllSingletonsShspAsync({String key = 'default'}) async {} // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Async twin of [registerAllSingletonsShsp] — use this when [beforeRegisterAllSingletonsShspAsync]
  /// or [afterRegisterAllSingletonsShspAsync] need to await work (e.g. loading remote
  /// config) before or after connecting. // GENERATED CODE - DO NOT MODIFY BY HAND
  Future<void> registerAllSingletonsShspAsync({String key = 'default'}) async { // GENERATED CODE - DO NOT MODIFY BY HAND
    await beforeRegisterAllSingletonsShspAsync(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    registerAllSingletonsShsp(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    await afterRegisterAllSingletonsShspAsync(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Called by [registerAllSingletonsShspAsync] right after it finishes connecting
  /// everything. Override to customize. // GENERATED CODE - DO NOT MODIFY BY HAND
  Future<void> afterRegisterAllSingletonsShspAsync({String key = 'default'}) async {} // GENERATED CODE - DO NOT MODIFY BY HAND
} // GENERATED CODE - DO NOT MODIFY BY HAND

/// Ready-to-use [MainInjectionShspMixin] host — instantiate this directly, or
/// extend it (or mix [MainInjectionShspMixin] into your own class) to override
/// the before/register/after hooks. // GENERATED CODE - DO NOT MODIFY BY HAND
class MainInjectionShsp with MainInjectionShspMixin { // GENERATED CODE - DO NOT MODIFY BY HAND
  const MainInjectionShsp(); // GENERATED CODE - DO NOT MODIFY BY HAND
} // GENERATED CODE - DO NOT MODIFY BY HAND
