import 'dart:io';

import 'package:shsp/shsp.dart';
import 'package:test/test.dart';

/// [ShspInstance] that records every outgoing datagram instead of handing it
/// to the network, so the spec conformance tests below are deterministic.
class RecordingShspInstance extends ShspInstance {
  RecordingShspInstance({
    required super.remotePeer,
    required super.socket,
    super.livenessTimeoutSeconds,
  });

  final List<List<int>> sent = [];

  @override
  void sendMessageUnchecked(List<int> message) => sent.add(List.of(message));
}

/// Spec conformance tests that observe the messages emitted by a
/// [ShspInstance].
void main() {
  late ShspSocket socket;
  late PeerInfo remotePeer;
  late RecordingShspInstance instance;
  late List<List<int>> received;

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  setUp(() async {
    socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
    remotePeer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
    instance = RecordingShspInstance(remotePeer: remotePeer, socket: socket);
    received = instance.sent;
  });

  tearDown(() {
    instance.close();
    if (!socket.isClosed) socket.close();
  });

  Future<void> openSession() async {
    instance.sendHandshake();
    instance.onMessage([0x01, 0x00], remotePeer);
    instance.onMessage([0x02], remotePeer);
    await settle();
  }

  group('Section 6 - handshake', () {
    test('every probe is acknowledged, including after OPEN (step 2)', () async {
      await openSession();
      expect(instance.open, isTrue);
      received.clear();

      instance.onMessage([0x01, 0x00], remotePeer);
      instance.onMessage([0x01, 0x00], remotePeer);
      await settle();

      expect(received.where((m) => m.length == 1 && m[0] == 0x02).length, 2);
      expect(instance.open, isTrue);
    });

    test('trailing bytes after VERSION are ignored (Section 4)', () async {
      instance.onMessage([0x01, 0x00, 0xAA, 0xBB], remotePeer);
      await settle();

      expect(instance.handshake, isTrue);
      expect(received, contains(equals([0x02])));
    });

    test('a keep-alive is sent promptly on reaching OPEN (step 7)', () async {
      await openSession();

      expect(received, contains(equals([0x05])));
    });

    test('retry exhaustion moves the session to CLOSED (step 5)', () async {
      var exhausted = false;
      ShspHandshakeRetryHandler.startRetry(
        instance: instance,
        options: const ShspHandshakeRetryOptions(
          maxAttempts: 2,
          initialDelayMs: 10,
        ),
        onMaxAttemptsExhausted: () => exhausted = true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(exhausted, isTrue);
      expect(instance.handshake, isTrue);
      expect(instance.open, isFalse);
      expect(
        () => instance.sendMessage([0x41]),
        throwsA(isA<ShspInstanceException>()),
      );
    });
  });

  group('Section 8 - termination', () {
    test('Closing received while OPEN is answered with Closed', () async {
      await openSession();
      received.clear();

      instance.onMessage([0x03], remotePeer);
      await settle();

      expect(received, contains(equals([0x04])));
      expect(instance.open, isFalse);
    });

    test('Closing received while HANDSHAKING is answered with Closed', () async {
      instance.sendHandshake();
      await settle();
      received.clear();

      instance.onMessage([0x03], remotePeer);
      await settle();

      expect(received, contains(equals([0x04])));
      expect(instance.open, isFalse);
    });

    test('Closed received is not answered', () async {
      await openSession();
      received.clear();

      instance.onMessage([0x04], remotePeer);
      await settle();

      expect(received, isEmpty);
      expect(instance.open, isFalse);
    });

    test('graceful close retransmits Closing until Closed is received',
        () async {
      await openSession();
      instance.closingRetransmitInterval = const Duration(milliseconds: 20);
      await settle();
      received.clear();

      instance.sendClosing();
      expect(instance.closing, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 90));

      expect(
        received.where((m) => m.length == 1 && m[0] == 0x03).length,
        greaterThan(1),
      );

      instance.onMessage([0x04], remotePeer);
      await settle();
      received.clear();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(instance.open, isFalse);
      expect(received, isEmpty);
    });

    test('graceful close falls back to Closed after the closing timeout',
        () async {
      await openSession();
      instance.closingTimeout = const Duration(milliseconds: 50);
      await settle();
      received.clear();

      instance.sendClosing();
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(instance.open, isFalse);
      expect(received, contains(equals([0x04])));
    });

    test('close() is abortive and sends Closed while HANDSHAKING', () async {
      instance.sendHandshake();
      await settle();
      received.clear();

      instance.close();
      await settle();

      expect(received, contains(equals([0x04])));
    });

    test('close() on a CLOSED session sends nothing', () async {
      await openSession();
      instance.close();
      await settle();
      received.clear();

      instance.close();
      await settle();

      expect(received, isEmpty);
    });
  });

  group('Section 3 - sizes', () {
    test('empty application payload is rejected', () async {
      await openSession();

      expect(
        () => instance.sendMessage([]),
        throwsA(isA<ShspValidationException>()),
      );
    });

    test('IPv6 allows datagrams up to 65,527 bytes', () {
      final peer = ShspPeer(
        remotePeer: PeerInfo(address: InternetAddress.loopbackIPv6, port: 9),
        socket: socket,
      );
      expect(
        () => peer.validateMaxSize(List.filled(65527, 0), ipv6: true),
        returnsNormally,
      );
      expect(
        () => peer.validateMaxSize(List.filled(65528, 0), ipv6: true),
        throwsA(isA<ShspValidationException>()),
      );
      expect(
        () => peer.validateMaxSize(List.filled(65508, 0)),
        throwsA(isA<ShspValidationException>()),
      );
      peer.close();
    });
  });

  group('Section 7 - liveness', () {
    late RecordingShspInstance live;
    late int closes;

    setUp(() {
      live = RecordingShspInstance(
        remotePeer: remotePeer,
        socket: socket,
        livenessTimeoutSeconds: 1,
      );
      closes = 0;
      live.onClose.register((_) => closes++);
    });

    tearDown(() => live.close());

    test('does not run while HANDSHAKING', () async {
      live.sendHandshake();
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(live.handshake, isTrue);
      expect(closes, 0);
    });

    test('closes an OPEN session and fires onClose once', () async {
      live.sendHandshake();
      live.onMessage([0x02], remotePeer);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(live.open, isFalse);
      expect(closes, 1);
      expect(live.sent, contains(equals([0x04])));
    });

    test('is not reset by unknown or malformed messages', () async {
      live.sendHandshake();
      live.onMessage([0x02], remotePeer);
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        live.onMessage([0x7F], remotePeer);
        live.onMessage([0x01], remotePeer);
      }
      expect(live.open, isFalse);
      expect(closes, 1);
    });

    test('is reset by well-formed messages', () async {
      live.sendHandshake();
      live.onMessage([0x02], remotePeer);
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        live.onMessage([0x05], remotePeer);
      }
      expect(live.open, isTrue);
      expect(closes, 0);
    });
  });

  group('Handshake handlers and session close', () {
    test('retry handler stops without exhaustion when the peer closes',
        () async {
      var exhausted = false;
      final retry = ShspHandshakeRetryHandler.startRetry(
        instance: instance,
        options: const ShspHandshakeRetryOptions(
          maxAttempts: 3,
          initialDelayMs: 20,
        ),
        onMaxAttemptsExhausted: () => exhausted = true,
      );
      instance.onMessage([0x04], remotePeer);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(retry.isActive, isFalse);
      expect(exhausted, isFalse);
    });

    test('handshake handler returns early when the session closes', () async {
      final sw = Stopwatch()..start();
      final future = ShspHandshakeHandler.handshakeInstance(
        instance,
        const ShspHandshakeHandlerOptions(timeoutMs: 5000),
      );
      instance.onMessage([0x04], remotePeer);
      await future;
      expect(sw.elapsedMilliseconds, lessThan(1000));
      expect(instance.open, isFalse);
    });
  });

  group('Configuration', () {
    test('keepAliveSeconds setter does not start a timer when not OPEN', () {
      instance.keepAliveSeconds = 5;
      expect(instance.keepAliveTimerValue, isNull);
    });

    test('keepAliveSeconds setter does not revive a timer after CLOSED',
        () async {
      await openSession();
      instance.close();
      instance.keepAliveSeconds = 5;
      expect(instance.keepAliveTimerValue, isNull);
    });

    test('profile round-trip keeps liveness and closing settings', () {
      final source = ShspInstance(
        remotePeer: remotePeer,
        socket: socket,
        livenessTimeoutSeconds: 7,
      )
        ..closingTimeout = const Duration(seconds: 9)
        ..closingRetransmitInterval = const Duration(milliseconds: 250);
      final copy = ShspInstance.withProfile(
        remotePeer: remotePeer,
        socket: socket,
        profile: source.extractProfile(),
      );
      expect(copy.livenessTimeoutSeconds, 7);
      expect(copy.closingTimeout, const Duration(seconds: 9));
      expect(copy.closingRetransmitInterval, const Duration(milliseconds: 250));
      source.close();
      copy.close();
    });
  });
}
