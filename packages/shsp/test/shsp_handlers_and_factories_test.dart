import 'dart:io';
import 'package:test/test.dart';
import 'package:callback_handler/callback_handler.dart';
import 'package:shsp/shsp.dart';

class MockShspInstance implements IShspInstance {
  MockShspInstance({
    this.initialOpen = false,
  }) {
    onHandshake = CallbackHandler<void, void>();
    onOpen = CallbackHandler<void, void>();
    onClosing = CallbackHandler<void, void>();
    onClose = CallbackHandler<void, void>();
    _messageCallback = CallbackHandler<PeerInfo, void>();
    if (initialOpen) {
      _openState = true;
    }
  }

  final bool initialOpen;
  int handshakeSendCount = 0;
  final bool _handshakeState = false;
  bool _openState = false;
  late CallbackHandler<PeerInfo, void> _messageCallback;

  @override
  bool get handshake => _handshakeState;

  @override
  bool get open => _openState;

  @override
  bool get closing => false;

  @override
  int get keepAliveSeconds => 30;

  @override
  set keepAliveSeconds(int seconds) {}

  @override
  late CallbackHandler<void, void> onHandshake;

  @override
  late CallbackHandler<void, void> onOpen;

  @override
  late CallbackHandler<void, void> onClosing;

  @override
  late CallbackHandler<void, void> onClose;

  @override
  MessageCallback get messageCallback => _messageCallback;

  @override
  void sendHandshake() {
    handshakeSendCount++;
  }

  @override
  void keepAlive() {}

  @override
  void sendClosing() {}

  @override
  void sendClosed() {}

  @override
  void startKeepAlive() {}

  @override
  void stopKeepAlive() {}

  @override
  ShspInstanceProfile extractProfile() => const ShspInstanceProfile(
    keepAliveSeconds: 30,
    onHandshakeListeners: [],
    onOpenListeners: [],
    onClosingListeners: [],
    onCloseListeners: [],
    onMessageListeners: [],
  );

  @override
  void close() {}

  @override
  String serializedObject() => 'MockShspInstance';

  @override
  void sendMessage(List<int> message) {}

  @override
  void onMessage(List<int> msg, PeerInfo info) {}

  @override
  void destroy() {}

  void setOpen() {
    _openState = true;
    onOpen.call(null);
  }
}

void main() {
  group('ShspHandshakeHandler', () {
    group('already open', () {
      test('returns immediately without sending handshake when instance.open is true', () async {
        final instance = MockShspInstance(initialOpen: true);
        expect(instance.handshakeSendCount, equals(0));

        await ShspHandshakeHandler.handshakeInstance(instance);

        expect(instance.handshakeSendCount, equals(0));
      });

      test('invokes onOpen callback if provided when already open', () async {
        var onOpenCallbackFired = false;
        final instance = MockShspInstance(initialOpen: true);
        instance.onOpen.register((_) {
          onOpenCallbackFired = true;
        });

        await ShspHandshakeHandler.handshakeInstance(instance);

        expect(onOpenCallbackFired, isTrue);
      });
    });

    group('resolves on open', () {
      test('sends initial handshake immediately', () async {
        final instance = MockShspInstance();
        ShspHandshakeHandler.handshakeInstance(instance);
        await Future.microtask(() {});

        expect(instance.handshakeSendCount, greaterThan(0));
      });

      test('resolves the returned future when onOpen fires', () async {
        final instance = MockShspInstance();
        final future = ShspHandshakeHandler.handshakeInstance(instance);

        Future.delayed(const Duration(milliseconds: 30)).then((_) {
          instance.setOpen();
        });

        await expectLater(future, completes);
      });

      test('returned instance is the same instance passed in', () async {
        final instance = MockShspInstance();
        final result = await ShspHandshakeHandler.handshakeInstance(
          instance..setOpen(),
          const ShspHandshakeHandlerOptions(),
        );

        expect(identical(result, instance), isTrue);
      });
    });

    group('timeout', () {
      test('future completes after timeoutMs even if onOpen never fires', () async {
        final instance = MockShspInstance();
        const options = ShspHandshakeHandlerOptions(timeoutMs: 100);

        final future = ShspHandshakeHandler.handshakeInstance(instance, options);
        await expectLater(future, completes);
      });

      test('instance.open is still false after timeout if never opened', () async {
        final instance = MockShspInstance();
        const options = ShspHandshakeHandlerOptions(timeoutMs: 100);

        await ShspHandshakeHandler.handshakeInstance(instance, options);

        expect(instance.open, isFalse);
      });
    });

    group('periodic retry', () {
      test('sends handshake multiple times during retry interval before timeout', () async {
        final instance = MockShspInstance();
        const options = ShspHandshakeHandlerOptions(
          timeoutMs: 200,
          intervalOfSendingHandshakeMs: 50,
        );

        ShspHandshakeHandler.handshakeInstance(instance, options);
        await Future.delayed(const Duration(milliseconds: 180));

        expect(instance.handshakeSendCount, greaterThanOrEqualTo(2));
      });
    });
  });

  group('ShspInstanceHandler', () {
    late ShspInstanceHandler handler;

    setUp(() {
      handler = ShspInstanceHandler();
    });

    group('initiateShsp', () {
      test('stores instance in map accessible via getShsp after initiation', () async {
        final instance = MockShspInstance(initialOpen: true);
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);

        await handler.initiateShsp(peer, instance, (instanceCallback: null));

        final retrieved = await handler.getShsp(peer);
        expect(retrieved, equals(instance));
      });

      test('calls instanceCallback when provided', () async {
        var callbackFired = false;
        final instance = MockShspInstance(initialOpen: true);
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);

        await handler.initiateShsp(
          peer,
          instance,
          (instanceCallback: (_) {
            callbackFired = true;
          }),
        );

        expect(callbackFired, isTrue);
      });
    });

    group('getShsp', () {
      test('returns null for unknown peer', () async {
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
        final result = await handler.getShsp(peer);
        expect(result, isNull);
      });

      test('returns stored instance for known peer', () async {
        final instance = MockShspInstance(initialOpen: true);
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);

        await handler.initiateShsp(peer, instance, (instanceCallback: null));

        final retrieved = await handler.getShsp(peer);
        expect(retrieved, equals(instance));
      });
    });

    group('getShspSafe', () {
      test('throws ShspInstanceException for unknown peer', () async {
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
        expect(
          () => handler.getShspSafe(peer),
          throwsA(isA<ShspInstanceException>()),
        );
      });

      test('returns instance for known peer', () async {
        final instance = MockShspInstance(initialOpen: true);
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);

        await handler.initiateShsp(peer, instance, (instanceCallback: null));

        final retrieved = await handler.getShspSafe(peer);
        expect(retrieved, equals(instance));
      });
    });

    group('close', () {
      test('removes the peer from the map', () async {
        final instance = MockShspInstance(initialOpen: true);
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);

        await handler.initiateShsp(peer, instance, (instanceCallback: null));
        handler.close(peer);

        final retrieved = await handler.getShsp(peer);
        expect(retrieved, isNull);
      });

      test('returns null from getShsp after close', () async {
        final instance = MockShspInstance(initialOpen: true);
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);

        await handler.initiateShsp(peer, instance, (instanceCallback: null));
        handler.close(peer);

        expect(await handler.getShsp(peer), isNull);
      });

      test('close on unknown peer is a no-op', () async {
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
        expect(() {
          handler.close(peer);
        }, returnsNormally);
      });
    });

    group('closeAll', () {
      test('clears all stored instances', () async {
        final instance1 = MockShspInstance(initialOpen: true);
        final instance2 = MockShspInstance(initialOpen: true);
        final peer1 = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
        final peer2 = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8081);

        await handler.initiateShsp(peer1, instance1, ());
        await handler.initiateShsp(peer2, instance2, ());

        handler.closeAll();

        expect(await handler.getShsp(peer1), isNull);
        expect(await handler.getShsp(peer2), isNull);
      });

      test('getShsp returns null for all peers after closeAll', () async {
        final instance = MockShspInstance(initialOpen: true);
        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);

        await handler.initiateShsp(peer, instance, (instanceCallback: null));
        handler.closeAll();

        expect(await handler.getShsp(peer), isNull);
      });

      test('closeAll on empty handler is a no-op', () async {
        expect(() {
          handler.closeAll();
        }, returnsNormally);
      });
    });
  });

  group('ShspSocketFactory', () {
    test('create returns a ShspSocket wrapping provided socket', () async {
      final rawSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(rawSocket.close);

      final messageCallbacks = MessageCallbackMapFactory.create();
      final socket = ShspSocketFactory.create(rawSocket, messageCallbacks);
      addTearDown(() {
        if (!socket.isClosed) socket.close();
      });

      expect(socket, isA<ShspSocket>());
    });

    test('createFromSocket creates ShspSocket with empty callback map', () async {
      final rawSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(rawSocket.close);

      final socket = ShspSocketFactory.createFromSocket(rawSocket);
      addTearDown(() {
        if (!socket.isClosed) socket.close();
      });

      expect(socket, isA<ShspSocket>());
    });
  });

  group('ShspPeerFactory', () {
    test('create returns a ShspPeer with correct remotePeer', () async {
      final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() {
        if (!socket.isClosed) socket.close();
      });

      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
      final shspPeer = ShspPeerFactory.create(remotePeer: peer, socket: socket);

      expect(shspPeer.remotePeer, equals(peer));
    });

    test('createFromRemoteInfo returns a ShspPeer with internal socket', () async {
      final remotePeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
      final rawSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(rawSocket.close);

      final shspPeer = ShspPeerFactory.createFromRemoteInfo(
        remotePeer: remotePeer,
        rawSocket: rawSocket,
      );
      addTearDown(() {
        if (!shspPeer.socket.isClosed) shspPeer.socket.close();
      });

      expect(shspPeer, isA<ShspPeer>());
    });
  });

  group('ShspInstanceFactory', () {
    test('create returns a ShspInstance with correct remotePeer and keepAliveSeconds', () async {
      final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() {
        if (!socket.isClosed) socket.close();
      });

      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
      final instance = ShspInstanceFactory.create(
        remotePeer: peer,
        socket: socket,
        keepAliveSeconds: 60,
      );

      expect(instance.remotePeer, equals(peer));
      expect(instance.keepAliveSeconds, equals(60));
    });

    test('createFromSocket returns a ShspInstance wrapping a new ShspSocket', () async {
      final remotePeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
      final rawSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(rawSocket.close);

      final instance = ShspInstanceFactory.createFromSocket(
        remotePeer: remotePeer,
        rawSocket: rawSocket,
      );
      addTearDown(() {
        if (!instance.socket.isClosed) instance.socket.close();
      });

      expect(instance, isA<ShspInstance>());
      expect(instance.socket, isA<IShspSocket>());
    });

    test('createWithProfile restores profile listeners to new instance', () async {
      final socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() {
        if (!socket.isClosed) socket.close();
      });

      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
      final original = ShspInstance.create(remotePeer: peer, socket: socket);
      original.onOpen.register((_) {});

      final profile = original.extractProfile();

      final socket2 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(() {
        if (!socket2.isClosed) socket2.close();
      });

      final restored = ShspInstanceFactory.createWithProfile(
        remotePeer: peer,
        socket: socket2,
        profile: profile,
      );

      expect(restored.extractProfile().onOpenListeners, isNotEmpty);
    });
  });
}
