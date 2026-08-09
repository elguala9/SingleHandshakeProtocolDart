import 'dart:io';

import 'package:shsp/shsp.dart';
import 'package:test/test.dart';

/// Concrete host for the generic [KeyedRegistry] mixin.
class _StringRegistry with KeyedRegistry<String, int> {}

Future<IShspSocket> _bindIpv4() =>
    ShspSocket.bind(InternetAddress.anyIPv4, 0);

Future<IShspSocket?> _bindIpv6OrNull() async {
  try {
    return await ShspSocket.bind(InternetAddress.anyIPv6, 0);
  } catch (_) {
    return null; // host without IPv6
  }
}

void main() {
  group('KeyedRegistry', () {
    late _StringRegistry registry;

    setUp(() => registry = _StringRegistry());

    test('starts empty', () {
      expect(registry.isEmpty, isTrue);
      expect(registry.isNotEmpty, isFalse);
      expect(registry.registrySize, 0);
      expect(registry.keys, isEmpty);
    });

    test('register stores a value under the key', () {
      registry.register('a', 1);

      expect(registry.getInstance('a'), 1);
      expect(registry.getByKey('a'), 1);
      expect(registry.contains('a'), isTrue);
      expect(registry.isNotEmpty, isTrue);
      expect(registry.registrySize, 1);
      expect(registry.keys, {'a'});
    });

    test('register on an already registered key throws', () {
      registry.register('a', 1);

      expect(() => registry.register('a', 2), throwsA(isA<StateError>()));
      expect(registry.getInstance('a'), 1);
    });

    test('replace overwrites an existing key', () {
      registry.register('a', 1);
      registry.replace('a', 2);

      expect(registry.getInstance('a'), 2);
      expect(registry.registrySize, 1);
    });

    test('replace on a missing key throws', () {
      expect(() => registry.replace('a', 1), throwsA(isA<StateError>()));
    });

    test('getInstance on a missing key throws, getByKey returns null', () {
      expect(() => registry.getInstance('missing'), throwsA(isA<StateError>()));
      expect(registry.getByKey('missing'), isNull);
      expect(registry.contains('missing'), isFalse);
    });

    test('unregister removes and returns the value', () {
      registry.register('a', 1);

      expect(registry.unregister('a'), 1);
      expect(registry.contains('a'), isFalse);
      expect(registry.unregister('a'), isNull);
    });

    test('clearRegistry drops every entry', () {
      registry
        ..register('a', 1)
        ..register('b', 2);

      registry.clearRegistry();

      expect(registry.isEmpty, isTrue);
      expect(registry.keys, isEmpty);
    });
  });

  group('KeyedRegistryManager / KeyedRegistrySingleton', () {
    test('manager instances hold independent state', () {
      final first = KeyedRegistryManager<String, int>()..register('a', 1);
      final second = KeyedRegistryManager<String, int>();

      expect(first.contains('a'), isTrue);
      expect(second.contains('a'), isFalse);
    });

    test('singleton returns the same instance and shares state', () {
      final instance = KeyedRegistrySingleton.instance;
      addTearDown(instance.clearRegistry);

      expect(KeyedRegistrySingleton.instance, same(instance));

      instance.register('shared', 42);
      expect(KeyedRegistrySingleton.instance.getInstance('shared'), 42);
    });

    test('the shared singleton is untyped, so any value type fits', () {
      // `RegistrySingletonShspPeer<Key>` aliases this class, but its static
      // `instance` is always the one `KeyedRegistrySingleton<dynamic, dynamic>`
      // — it is never specialised to `IShspPeer`.
      final instance = KeyedRegistrySingleton.instance;
      addTearDown(instance.clearRegistry);

      instance
        ..register('int', 1)
        ..register('string', 'two');

      expect(instance.getInstance('int'), 1);
      expect(instance.getInstance('string'), 'two');
    });
  });

  group('RegistryShspSocket constructor', () {
    test('registers the sockets passed in', () async {
      final ipv4 = await _bindIpv4();
      final ipv6 = await _bindIpv6OrNull();
      final registry = RegistryShspSocket(ipv4Socket: ipv4, ipv6Socket: ipv6);
      addTearDown(registry.destroy);

      expect(registry.getByKey(SocketType.ipv4), same(ipv4));
      expect(registry.getByKey(SocketType.ipv6), same(ipv6));
    });

    test('leaves the ipv6 slot empty when no ipv6 socket is passed', () async {
      final ipv4 = await _bindIpv4();
      final registry = RegistryShspSocket(ipv4Socket: ipv4);
      addTearDown(registry.destroy);

      expect(registry.getByKey(SocketType.ipv6), isNull);
      expect(registry.registrySize, 1);
    });

    test('registers nothing when no socket is passed', () {
      final registry = RegistryShspSocket();

      expect(registry.isEmpty, isTrue);
    });
  });

  group('RegistryShspSocket.initialize', () {
    test('returns ipv4and6 when the dual socket has both families', () async {
      final ipv4 = await _bindIpv4();
      final ipv6 = await _bindIpv6OrNull();
      if (ipv6 == null) return; // host without IPv6

      final dual = DualShspSocketMigratable.fromSockets(
        Sockets(ipv4SocketImpl: ipv4, ipv6SocketImpl: ipv6),
      );
      addTearDown(dual.close);
      final registry = RegistryShspSocket();

      expect(registry.initialize(dual), ReturnTypeInitialization.ipv4and6);
      expect(registry.registrySize, 2);
      expect(
        registry.getInstance(SocketType.ipv4).localPort,
        ipv4.localPort,
      );
    });

    test('returns ipv4only when the dual socket has no ipv6', () async {
      final ipv4 = await _bindIpv4();
      final dual = DualShspSocketMigratable.fromSockets(
        Sockets(ipv4SocketImpl: ipv4),
      );
      addTearDown(dual.close);
      final registry = RegistryShspSocket();

      expect(registry.initialize(dual), ReturnTypeInitialization.ipv4only);
      expect(registry.getByKey(SocketType.ipv6), isNull);
    });

    test('re-initializing replaces the previously registered sockets', () async {
      final first = await _bindIpv4();
      final firstDual = DualShspSocketMigratable.fromSockets(
        Sockets(ipv4SocketImpl: first),
      );
      addTearDown(firstDual.close);
      final registry = RegistryShspSocket()..initialize(firstDual);

      final second = await _bindIpv4();
      final secondDual = DualShspSocketMigratable.fromSockets(
        Sockets(ipv4SocketImpl: second),
      );
      addTearDown(secondDual.close);

      // register() would throw on the already-taken key — initialize falls
      // back to replace() instead.
      expect(registry.initialize(secondDual), ReturnTypeInitialization.ipv4only);
      expect(registry.registrySize, 1);
      expect(
        registry.getInstance(SocketType.ipv4).localPort,
        second.localPort,
      );
    });
  });

  group('RegistryShspSocket.bind', () {
    test('binds and registers an ipv4 socket on an ephemeral port', () async {
      final registry = RegistryShspSocket();
      addTearDown(registry.destroy);

      final result = await registry.bind(InputRegistryShspSocket());

      expect(
        result,
        anyOf(
          ReturnTypeInitialization.ipv4and6,
          ReturnTypeInitialization.ipv4only,
        ),
      );
      final ipv4 = registry.getInstance(SocketType.ipv4);
      expect(ipv4.localPort, isNotNull);
      expect(ipv4.localPort, isNot(0));
      expect(ipv4.isClosed, isFalse);
    });

    test('honours the requested addresses and ports', () async {
      final registry = RegistryShspSocket();
      addTearDown(registry.destroy);

      // Ports are picked by the OS via 0 to keep the test independent of
      // whatever else is bound on this machine; the addresses are ours.
      await registry.bind(
        InputRegistryShspSocket(
          ipv4Address: InternetAddress.loopbackIPv4,
          ipv4Port: 0,
        ),
      );

      expect(registry.getInstance(SocketType.ipv4).localPort, isNot(0));
    });

    test('InputRegistryShspSocket defaults to ephemeral ports', () {
      final input = InputRegistryShspSocket();

      expect(input.ipv4Address, isNull);
      expect(input.ipv6Address, isNull);
      expect(input.ipv4Port, 0);
      expect(input.ipv6Port, 0);
    });

    test('InputRegistrySingletonShspSocket is an alias of the input type', () {
      expect(InputRegistrySingletonShspSocket(), isA<InputRegistryShspSocket>());
    });
  });

  group('RegistryShspSocket.destroy', () {
    test('closes every registered socket and empties the registry', () async {
      final ipv4 = await _bindIpv4();
      final registry = RegistryShspSocket(ipv4Socket: ipv4);

      registry.destroy();

      expect(ipv4.isClosed, isTrue);
      expect(registry.isEmpty, isTrue);
    });
  });

  group('RegistrySingletonShspSocket', () {
    test('always returns the same instance and is a RegistryShspSocket', () {
      final instance = RegistrySingletonShspSocket.instance;
      addTearDown(instance.clearRegistry);

      expect(RegistrySingletonShspSocket.instance, same(instance));
      expect(instance, isA<RegistryShspSocket>());
    });

    test('registered sockets are visible through the shared instance', () async {
      final registry = RegistrySingletonShspSocket.instance;
      addTearDown(registry.destroy);

      await registry.bind(InputRegistryShspSocket());

      expect(
        RegistrySingletonShspSocket.instance.getByKey(SocketType.ipv4),
        isNotNull,
      );
    });
  });
}
