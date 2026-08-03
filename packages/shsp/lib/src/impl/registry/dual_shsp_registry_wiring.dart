import 'dart:io';

import 'package:singleton_manager/singleton_manager.dart';

import '../../../shsp.dart';

/// Binds a real IPv4 `RawDatagramSocket` and, best-effort, a real IPv6 one,
/// and registers each under the matching `'ipv4'`/`'ipv6'` subkey.
///
/// `ShspSocket` resolves its raw socket parameter via `@Subkey.inherited()`
/// — auto-connected under both `'ipv4'`/`'ipv6'` by the generated
/// `registerAllSingletonsShsp()` because `DualShspSocketWrapper`/
/// `RegistryShspSocket` demand `IShspSocket` under those same subkeys via
/// `@Subkey('ipv4')`/`@Subkey('ipv6')`. But binding a socket is async and
/// `RawDatagramSocket` itself isn't `@dependencyInjectable`, so nothing ever
/// supplies it without this call.
///
/// Call this once per [key] before resolving `IDualShspSocketWrapper`/
/// `IRegistryShspSocket` under that same [key] — order relative to
/// `registerAllSingletonsShsp()` doesn't matter, since `RawDatagramSocket`
/// and `IShspSocket`/the wrapper/registry types are different registry
/// slots.
Future<void> connectDualShspSockets({String key = 'default'}) async {
  final ipv4Socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  RawDatagramSocket? ipv6Socket;
  try {
    ipv6Socket = await RawDatagramSocket.bind(InternetAddress.anyIPv6, 0);
  } catch (e) {
    print(
      'Warning: IPv6 socket binding failed - IPv6 may not be available: $e',
    );
  }

  final registry = RegistryManager.instance;
  registry.connectInstance<RawDatagramSocket, RawDatagramSocket>(
    () => ipv4Socket,
    key: key,
    subkey: 'ipv4',
  );
  if (ipv6Socket != null) {
    registry.connectInstance<RawDatagramSocket, RawDatagramSocket>(
      () => ipv6Socket!,
      key: key,
      subkey: 'ipv6',
    );
  }
}

/// Connects `ShspSocketWrapper` under the `'ipv4'`/`'ipv6'` subkeys.
///
/// `ShspSocketWrapper` has no fixed subkey of its own and nothing else in
/// the graph demands `IShspSocketWrapper` under `'ipv4'`/`'ipv6'` (unlike
/// `IShspSocket`, which `DualShspSocketWrapper`/`RegistryShspSocket` do
/// demand), so the generator can't infer this automatically — it connects
/// `ShspSocketWrapper` once, under the default subkey, same as the `Single`
/// pattern in the `singleton_manager` README.
void connectShspSocketWrapperSubkeys({String key = 'default'}) {
  RegistryManager.instance
    ..connectInstance<IShspSocketWrapper, ShspSocketWrapper>(
      () => ShspSocketWrapper.dependencyInjectionFactory(
        key: key,
        subkey: 'ipv4',
      ),
      key: key,
      subkey: 'ipv4',
    )
    ..connectInstance<IShspSocketWrapper, ShspSocketWrapper>(
      () => ShspSocketWrapper.dependencyInjectionFactory(
        key: key,
        subkey: 'ipv6',
      ),
      key: key,
      subkey: 'ipv6',
    );
}

/// Connects `AutoShspPeer` under the `'ipv4'`/`'ipv6'` subkeys.
///
/// Same situation as [connectShspSocketWrapperSubkeys]: `AutoShspPeer`
/// implements nothing, so it registers under its own class name, and
/// nothing else demands `AutoShspPeer` under a subkey — the generator can't
/// infer this automatically.
///
/// Its `socket` param resolves via `@Subkey.inherited()`; its `remotePeer`
/// (and, for [connectAutoShspInstanceSubkeys], `keepAliveSeconds`) are
/// required, non-`@Subkey`-tagged params with no connected default — resolve
/// them under [key] yourself (`connectInstance<PeerInfo, PeerInfo>(...)`,
/// `connectInstance<int, int>(...)`) before calling `getInstance`, or expect
/// `RegistryNotFoundError`.
void connectAutoShspPeerSubkeys({String key = 'default'}) {
  RegistryManager.instance
    ..connectInstance<AutoShspPeer, AutoShspPeer>(
      () => AutoShspPeer.dependencyInjectionFactory(key: key, subkey: 'ipv4'),
      key: key,
      subkey: 'ipv4',
    )
    ..connectInstance<AutoShspPeer, AutoShspPeer>(
      () => AutoShspPeer.dependencyInjectionFactory(key: key, subkey: 'ipv6'),
      key: key,
      subkey: 'ipv6',
    );
}

/// Connects `AutoShspInstance` under the `'ipv4'`/`'ipv6'` subkeys — see
/// [connectAutoShspPeerSubkeys].
void connectAutoShspInstanceSubkeys({String key = 'default'}) {
  RegistryManager.instance
    ..connectInstance<AutoShspInstance, AutoShspInstance>(
      () =>
          AutoShspInstance.dependencyInjectionFactory(key: key, subkey: 'ipv4'),
      key: key,
      subkey: 'ipv4',
    )
    ..connectInstance<AutoShspInstance, AutoShspInstance>(
      () =>
          AutoShspInstance.dependencyInjectionFactory(key: key, subkey: 'ipv6'),
      key: key,
      subkey: 'ipv6',
    );
}

/// [MainInjectionShspMixin] host that wires [connectDualShspSockets] into
/// `beforeRegisterAllSingletonsShspAsync` and [connectShspSocketWrapperSubkeys]/
/// [connectAutoShspPeerSubkeys]/[connectAutoShspInstanceSubkeys] into
/// `beforeRegisterAllSingletonsShsp`, so a single call to
/// `registerAllSingletonsShspAsync` binds the ipv4/ipv6 sockets and connects
/// every `@dependencyInjectable` singleton — including every per-subkey
/// variant — instead of wiring each by hand.
class DualShspInjector with MainInjectionShspMixin {
  const DualShspInjector();

  @override
  void beforeRegisterAllSingletonsShsp({String key = 'default'}) {
    connectShspSocketWrapperSubkeys(key: key);
    connectAutoShspPeerSubkeys(key: key);
    connectAutoShspInstanceSubkeys(key: key);
  }

  @override
  Future<void> beforeRegisterAllSingletonsShspAsync({
    String key = 'default',
  }) => connectDualShspSockets(key: key);
}
