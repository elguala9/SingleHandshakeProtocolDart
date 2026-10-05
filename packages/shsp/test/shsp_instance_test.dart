import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('ShspInstance', () {
    group('message prefix routing', () {
      late ShspSocket socket;
      late ShspInstance instance;
      late PeerInfo remotePeer;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        remotePeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
        instance = ShspInstance.create(remotePeer: remotePeer, socket: socket);
      });

      tearDown(() {
        if (!socket.isClosed) socket.close();
      });

      test('[0x01, 0x00] message triggers onHandshake callback', () async {
        var handshakeFired = false;
        instance.onHandshake.register((_) {
          handshakeFired = true;
        });

        instance.onMessage([0x01, 0x00], remotePeer);
        await Future.microtask(() {});

        expect(handshakeFired, isTrue);
        expect(instance.handshake, isTrue);
      });

      test('[0x01] message with no VERSION byte is discarded as malformed (no callback, no state change)', () async {
        var handshakeFired = false;
        instance.onHandshake.register((_) {
          handshakeFired = true;
        });

        expect(
          () => instance.onMessage([0x01], remotePeer),
          throwsA(isA<ShspProtocolException>()),
        );

        await Future.microtask(() {});

        expect(handshakeFired, isFalse);
        expect(instance.handshake, isFalse);
      });

      test('[0x02] message sets openState = true and triggers onOpen callback', () async {
        var openFired = false;
        instance.onOpen.register((_) {
          openFired = true;
        });

        // First establish handshake
        instance.onMessage([0x01, 0x00], remotePeer);
        await Future.microtask(() {});

        // Then send [0x02] (handshake acknowledgment) to complete the handshake
        instance.onMessage([0x02], remotePeer);
        await Future.microtask(() {});

        expect(instance.open, isTrue);
        expect(openFired, isTrue);
      });

      test(
        'Data message received while HANDSHAKING is treated as implicit '
        'handshake confirmation and transitions to OPEN (Section 6 point 7)',
        () async {
          var openFiredCount = 0;
          instance.onOpen.register((_) {
            openFiredCount++;
          });

          // A sends its own handshake probe, entering HANDSHAKING.
          instance.sendHandshake();
          expect(instance.handshake, isTrue);
          expect(instance.open, isFalse);

          // The peer's ack for A's probe is lost, but a Data message from
          // the peer arrives anyway: this must implicitly confirm the
          // handshake and open the session before the message is delivered.
          instance.onMessage([0x00, 1, 2, 3], remotePeer);
          await Future.microtask(() {});

          expect(instance.open, isTrue);
          expect(openFiredCount, 1);

          // If the (delayed) explicit ack shows up later, onOpen must not
          // fire a second time.
          instance.onMessage([0x02], remotePeer);
          await Future.microtask(() {});

          expect(openFiredCount, 1);
        },
      );

      test(
        'Keep-alive message received while HANDSHAKING is treated as '
        'implicit handshake confirmation and transitions to OPEN '
        '(Section 6 point 7)',
        () async {
          var openFiredCount = 0;
          instance.onOpen.register((_) {
            openFiredCount++;
          });

          instance.sendHandshake();
          expect(instance.open, isFalse);

          instance.onMessage([0x05], remotePeer);
          await Future.microtask(() {});

          expect(instance.open, isTrue);
          expect(openFiredCount, 1);
        },
      );

      test('[0x03] message triggers onClosing callback', () async {
        var closingFired = false;
        instance.onClosing.register((_) {
          closingFired = true;
        });

        // Leave CREATED first: a Closing message received while CREATED is
        // discarded per Section 5.
        instance.onMessage([0x01, 0x00], remotePeer);
        instance.onMessage([0x03], remotePeer);
        await Future.microtask(() {});

        expect(closingFired, isTrue);
        expect(instance.closing, isTrue);
      });

      test('[0x04] message triggers onClose callback and sets openState = false', () async {
        var closeFired = false;
        instance.onClose.register((_) {
          closeFired = true;
        });

        // First establish open state
        instance.onMessage([0x01, 0x00], remotePeer);
        instance.onMessage([0x02], remotePeer);
        await Future.microtask(() {});

        instance.onMessage([0x04], remotePeer);
        await Future.microtask(() {});

        expect(closeFired, isTrue);
        expect(instance.open, isFalse);
      });

      test('[0x05] message is consumed silently (no crash, no callback)', () async {
        var anyCallbackFired = false;
        instance.onHandshake.register((_) {
          anyCallbackFired = true;
        });
        instance.messageCallback.register((_) {
          anyCallbackFired = true;
        });

        expect(() {
          instance.onMessage([0x05], remotePeer);
        }, returnsNormally);

        expect(anyCallbackFired, isFalse);
      });

      test('[0x00, data] message is forwarded to user messageCallback', () async {
        var callbackFired = false;
        instance.messageCallback.register((_) {
          callbackFired = true;
        });

        // Leave CREATED first: a Data message received while CREATED is
        // discarded per Section 5.
        instance.onMessage([0x01, 0x00], remotePeer);
        instance.onMessage([0x00, 0x41, 0x42], remotePeer);
        await Future.microtask(() {});

        expect(callbackFired, isTrue);
      });

      test(
        'unrecognized prefix received while CREATED is discarded (Section 5)',
        () {
          expect(
            () => instance.onMessage([0x99], remotePeer),
            returnsNormally,
          );
          expect(instance.handshake, isFalse);
        },
      );

      test(
        'empty message received while CREATED is discarded (Section 5)',
        () {
          expect(() => instance.onMessage([], remotePeer), returnsNormally);
          expect(instance.handshake, isFalse);
        },
      );

      test(
        'unrecognized prefix throws ShspProtocolException once past CREATED',
        () {
          // Leave CREATED first, otherwise the message would be silently
          // discarded per Section 5 instead of reaching the protocol-error path.
          instance.onMessage([0x01, 0x00], remotePeer);

          expect(
            () => instance.onMessage([0x99], remotePeer),
            throwsA(isA<ShspProtocolException>()),
          );
        },
      );

      test(
        'empty message throws ShspProtocolException with messageType "empty" once past CREATED',
        () {
          instance.onMessage([0x01, 0x00], remotePeer);

          try {
            instance.onMessage([], remotePeer);
          } on ShspProtocolException catch (e) {
            expect(e.messageType, contains('empty'));
          }
        },
      );
    });

    group('sendMessage', () {
      late ShspSocket socket;
      late ShspInstance instance;
      late PeerInfo remotePeer;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        remotePeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
        instance = ShspInstance.create(remotePeer: remotePeer, socket: socket);
      });

      tearDown(() {
        if (!socket.isClosed) socket.close();
      });

      test('sendMessage throws ShspInstanceException when connection is not open', () {
        expect(
          () => instance.sendMessage([0x41]),
          throwsA(isA<ShspInstanceException>()),
        );
      });

      test('sendMessage throws ShspInstanceException when connection is closing', () async {
        // First establish open state
        instance.onMessage([0x01, 0x00], remotePeer);
        instance.onMessage([0x02], remotePeer);
        await Future.microtask(() {});

        // Set closing state
        instance.connectionState = ShspConnectionState.closing;

        expect(
          () => instance.sendMessage([0x41]),
          throwsA(isA<ShspInstanceException>()),
        );
      });
    });

    group('extractProfile / withProfile round-trip', () {
      late ShspSocket socket;
      late ShspInstance instance;
      late PeerInfo remotePeer;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        remotePeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
        instance = ShspInstance.create(remotePeer: remotePeer, socket: socket);
      });

      tearDown(() {
        if (!socket.isClosed) socket.close();
      });

      test('extractProfile captures registered onOpen listener', () {
        instance.onOpen.register((_) {});
        final profile = instance.extractProfile();
        expect(profile.onOpenListeners, isNotEmpty);
      });

      test('extractProfile captures keepAliveSeconds', () {
        final profile = instance.extractProfile();
        expect(profile.keepAliveSeconds, equals(15)); // default value
      });

      test('ShspInstance.withProfile restores onOpen listener', () async {
        instance.onOpen.register((_) {});
        final profile = instance.extractProfile();

        final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!newSocket.isClosed) newSocket.close();
        });

        final newInstance = ShspInstance.withProfile(
          remotePeer: remotePeer,
          socket: newSocket,
          profile: profile,
        );

        final restoredProfile = newInstance.extractProfile();
        expect(restoredProfile.onOpenListeners, isNotEmpty);
      });

      test('withProfile does not restore connection state (_open remains false on new instance)', () async {
        // First open the instance
        instance.onMessage([0x01, 0x00], remotePeer);
        instance.onMessage([0x02], remotePeer);
        expect(instance.open, isTrue);

        final profile = instance.extractProfile();

        final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!newSocket.isClosed) newSocket.close();
        });

        final newInstance = ShspInstance.withProfile(
          remotePeer: remotePeer,
          socket: newSocket,
          profile: profile,
        );

        // New instance should not be open even though profile is from open instance
        expect(newInstance.open, isFalse);
      });
    });

    group('close', () {
      late ShspSocket socket;
      late ShspInstance instance;
      late PeerInfo remotePeer;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        remotePeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
        instance = ShspInstance.create(remotePeer: remotePeer, socket: socket);
      });

      tearDown(() {
        if (!socket.isClosed) socket.close();
      });

      test('close() stops keepAlive timer', () {
        instance.startKeepAlive();
        expect(instance.keepAliveTimerValue, isNotNull);

        instance.close();
        expect(instance.keepAliveTimerValue, isNull);
      });

      test('close() is idempotent', () {
        instance.close();
        expect(() {
          instance.close();
        }, returnsNormally);
      });
    });

    group('ShspInstanceKeepAliveMixin (via ShspInstance)', () {
      late ShspSocket socket;
      late ShspInstance instance;
      late PeerInfo remotePeer;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        remotePeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
        instance = ShspInstance.create(remotePeer: remotePeer, socket: socket);
      });

      tearDown(() {
        if (!socket.isClosed) socket.close();
      });

      test('startKeepAlive starts a periodic timer that calls keepAlive()', () async {
        // First establish open state so keepAlive doesn't return early
        instance.onMessage([0x01, 0x00], remotePeer);
        instance.onMessage([0x02], remotePeer);

        instance.startKeepAlive();
        expect(instance.keepAliveTimerValue, isNotNull);
        expect(instance.keepAliveTimerValue!.isActive, isTrue);
      });

      test('startKeepAlive is a no-op when timer already running', () async {
        instance.startKeepAlive();
        final timer1 = instance.keepAliveTimerValue;

        instance.startKeepAlive();
        final timer2 = instance.keepAliveTimerValue;

        // Timer should be the same or timer1 should still be active
        expect(timer1, isNotNull);
        expect(timer2, isNotNull);
      });

      test('stopKeepAlive cancels the timer and sets it to null', () async {
        instance.startKeepAlive();
        expect(instance.keepAliveTimerValue, isNotNull);

        instance.stopKeepAlive();
        expect(instance.keepAliveTimerValue, isNull);
      });

      test('keepAliveSeconds setter restarts the timer', () async {
        instance.startKeepAlive();

        instance.keepAliveSeconds = 60;

        // Timer should be different after setter (it was restarted)
        expect(instance.keepAliveTimerValue, isNotNull);
        expect(instance.keepAliveTimerValue!.isActive, isTrue);
      });
    });
  });
}
