import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

class MockDualMigratable implements IDualShspSocketMigratable {
  bool closed = false;

  @override
  void close() {
    closed = true;
  }

  @override
  bool get isClosed => closed;

  @override
  IShspSocket get ipv4Socket => throw UnimplementedError();

  @override
  IShspSocket? get ipv6Socket => null;

  @override
  void migrateSocketIpv4(IShspSocket socket) {}

  @override
  void migrateSocketIpv6(IShspSocket socket) {}

  @override
  void applyProfile(ShspSocketProfile profile) {}

  @override
  ShspSocketProfile extractProfile() => const ShspSocketProfile(messageListeners: {});

  @override
  int? get localPort => null;

  @override
  InternetAddress? get localAddress => null;

  @override
  ICompressionCodec get compressionCodec => throw UnimplementedError();

  @override
  bool removeMessageCallback(PeerInfo key, MessageCallbackFunction callback) => false;

  @override
  void setMessageCallback(PeerInfo key, MessageCallbackFunction callback) {}

  @override
  int sendTo(List<int> buffer, PeerInfo peer) => 0;

  @override
  Future<void> destroy() async {}

  @override
  void setListeningCallback(void Function() cb) {}

  @override
  void setCloseCallback(void Function() cb) {}

  @override
  void setErrorCallback(void Function(dynamic err) cb) {}

  @override
  CallbackOn get onClose => throw UnimplementedError();

  @override
  CallbackOnError get onError => throw UnimplementedError();

  @override
  CallbackOn get onListening => throw UnimplementedError();

  @override
  String serializedObject() => '';

  @override
  IShspSocket get ipv4SocketForMessages => throw UnimplementedError();

  @override
  IShspSocket? get ipv6SocketForMessages => null;

  @override
  IShspSocket get ipv4SocketForProfile => throw UnimplementedError();

  @override
  IShspSocket? get ipv6SocketForProfile => null;

  @override
  late IShspSocket ipv4SocketImpl;

  @override
  late IShspSocket? ipv6SocketImpl;

  @override
  IShspSocket get socket => throw UnimplementedError();
}

void main() {
  group('DualShspSocket', () {
    group('DualShspSocket.create', () {
      late DualShspSocket dual;

      tearDown(() {
        if (!dual.isClosed) dual.close();
      });

      test('create() returns a DualShspSocket instance', () async {
        dual = await DualShspSocket.create();
        expect(dual, isA<DualShspSocket>());
      });

      test('ipv4Socket is non-null and implements IShspSocket', () async {
        dual = await DualShspSocket.create();
        expect(dual.ipv4Socket, isNotNull);
        expect(dual.ipv4Socket, isA<IShspSocket>());
      });

      test('localPort returns ipv4 socket port (> 0)', () async {
        dual = await DualShspSocket.create();
        expect(dual.localPort, isNotNull);
        expect(dual.localPort, greaterThan(0));
      });

      test('isClosed is false after create', () async {
        dual = await DualShspSocket.create();
        expect(dual.isClosed, isFalse);
      });
    });

    group('fromSockets constructor', () {
      late DualShspSocket dual;

      tearDown(() {
        if (!dual.isClosed) dual.close();
      });

      test('fromSockets wraps provided ipv4Socket', () async {
        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        dual = DualShspSocket.fromSockets(ipv4);
        expect(dual.ipv4Socket, equals(ipv4));
      });

      test('ipv6Socket is null when not provided', () async {
        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        dual = DualShspSocket.fromSockets(ipv4);
        expect(dual.ipv6Socket, isNull);
      });

      test('fromSockets with both sockets sets ipv6Socket non-null', () async {
        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        // Try to bind IPv6, but be graceful if not available
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 != null) {
          dual = DualShspSocket.fromSockets(ipv4, ipv6);
          expect(dual.ipv6Socket, isNotNull);
        }
      });
    });

    group('close / isClosed', () {
      test('close() sets isClosed to true', () async {
        final dual = await DualShspSocket.create();
        dual.close();
        expect(dual.isClosed, isTrue);
      });

      test('isClosed reflects ipv4 socket state', () async {
        final dual = await DualShspSocket.create();
        expect(dual.isClosed, isFalse);
        dual.close();
        expect(dual.isClosed, isTrue);
      });

      test('close() is idempotent', () async {
        final dual = await DualShspSocket.create();
        dual.close();
        expect(dual.close, returnsNormally);
      });
    });
  });

  group('SimpleDualSocketSingleton', () {
    late SimpleDualSocketSingleton singleton;

    setUp(() {
      singleton = SimpleDualSocketSingleton();
    });

    tearDown(() {
      singleton.clear();
    });

    group('initial state', () {
      test('hasInstance() is false when no instance set', () {
        expect(singleton.hasInstance(), isFalse);
      });

      test('getInstance() returns null when no instance set', () {
        expect(singleton.getInstance(), isNull);
      });
    });

    group('setInstance', () {
      test('hasInstance() becomes true after setInstance', () {
        final mock = MockDualMigratable();
        singleton.setInstance(mock);
        expect(singleton.hasInstance(), isTrue);
      });

      test('getInstance() returns the set instance', () {
        final mock = MockDualMigratable();
        singleton.setInstance(mock);
        expect(singleton.getInstance(), equals(mock));
      });

      test('setInstance with a second socket closes the first and replaces it', () {
        final mock1 = MockDualMigratable();
        singleton.setInstance(mock1);
        expect(mock1.closed, isFalse);

        final mock2 = MockDualMigratable();
        singleton.setInstance(mock2);

        expect(mock1.closed, isTrue);
        expect(singleton.getInstance(), equals(mock2));
      });
    });

    group('clear', () {
      test('hasInstance() becomes false after clear', () {
        final mock = MockDualMigratable();
        singleton.setInstance(mock);
        singleton.clear();
        expect(singleton.hasInstance(), isFalse);
      });

      test('getInstance() returns null after clear', () {
        final mock = MockDualMigratable();
        singleton.setInstance(mock);
        singleton.clear();
        expect(singleton.getInstance(), isNull);
      });

      test('clear() is safe when no instance was set (no-op)', () {
        expect(() {
          singleton.clear();
        }, returnsNormally);
      });
    });

    group('factory singleton', () {
      test('two calls to SimpleDualSocketSingleton() return the same instance', () {
        final singleton1 = SimpleDualSocketSingleton();
        final singleton2 = SimpleDualSocketSingleton();
        expect(identical(singleton1, singleton2), isTrue);
      });
    });
  });
}
