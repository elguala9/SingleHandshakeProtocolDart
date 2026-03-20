import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

void main() {
  group('initializePointDualShsp', () {
    setUpAll(() async {
      SingletonManager.instance.destroyAll();
      await initializePointDualShsp();
    });

    tearDownAll(() {
      SingletonManager.instance.destroyAll();
    });

    // ── DI: IDualShspSocketMigratable ────────────────────────────────────────

    test('registers IDualShspSocketMigratable in DI', () {
      expect(() => SingletonDIAccess.get<IDualShspSocketMigratable>(), returnsNormally);
    });

    test('IDualShspSocketMigratable is a DualShspSocket', () {
      expect(SingletonDIAccess.get<IDualShspSocketMigratable>(), isA<DualShspSocket>());
    });

    // ── IPv4 socket ──────────────────────────────────────────────────────────

    test('ipv4Socket is not closed', () {
      final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
      expect(dual.ipv4Socket.isClosed, isFalse);
    });

    test('ipv4Socket has an assigned local port', () {
      final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
      expect(dual.ipv4Socket.localPort, isNotNull);
      expect(dual.ipv4Socket.localPort, greaterThan(0));
    });

    // ── DI: DualShspSocketWrapperDI ──────────────────────────────────────────

    test('registers DualShspSocketWrapperDI in DI', () {
      expect(
        () => SingletonDIAccess.get<DualShspSocketWrapperDI>(),
        returnsNormally,
      );
    });

    test(
      'DualShspSocketWrapperDI delegates to the registered IDualShspSocketMigratable',
      () {
        final wrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
        final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
        expect(wrapper.ipv4Socket, same(dual.ipv4Socket));
      },
    );

    // ── DI: RegistryShspSocket ───────────────────────────────────────────────

    test('registers RegistryShspSocket in DI', () {
      expect(
        () => SingletonDIAccess.get<RegistryShspSocket>(),
        returnsNormally,
      );
    });

    test('RegistryShspSocket contains SocketType.ipv4', () {
      final reg = SingletonDIAccess.get<RegistryShspSocket>();
      expect(reg.contains(SocketType.ipv4), isTrue);
    });

    test(
      'RegistryShspSocket ipv4 socket matches IDualShspSocketMigratable.ipv4Socket',
      () {
        final reg = SingletonDIAccess.get<RegistryShspSocket>();
        final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
        expect(reg.getInstance(SocketType.ipv4), same(dual.ipv4Socket));
      },
    );

    // ── IPv6 coerenza ────────────────────────────────────────────────────────

    test('IPv6 registration is consistent with system IPv6 support', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
      final reg = SingletonDIAccess.get<RegistryShspSocket>();

      if (hasIPv6) {
        expect(
          dual.ipv6Socket,
          isNotNull,
          reason: 'IPv6 available: dualSocket.ipv6Socket should be set',
        );
        expect(
          reg.contains(SocketType.ipv6),
          isTrue,
          reason: 'IPv6 available: registry should contain SocketType.ipv6',
        );
        expect(
          reg.getInstance(SocketType.ipv6),
          same(dual.ipv6Socket),
          reason: 'registry ipv6 socket should match dualSocket.ipv6Socket',
        );
      } else {
        expect(
          dual.ipv6Socket,
          isNull,
          reason: 'IPv6 unavailable: dualSocket.ipv6Socket should be null',
        );
        expect(
          reg.contains(SocketType.ipv6),
          isFalse,
          reason:
              'IPv6 unavailable: registry should not contain SocketType.ipv6',
        );
      }
    });
  });
}
