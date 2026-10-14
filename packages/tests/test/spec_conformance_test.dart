import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

/// Conformance tests against SHSP-protocol.md. A raw UDP "wire peer" crafts
/// and observes exact datagrams so every state transition and message of the
/// specification can be exercised deterministically.
const _tick = Duration(milliseconds: 80);

class _Wire {
  _Wire(this.raw, this.target) {
    raw.listen((event) {
      if (event == RawSocketEvent.read) {
        final d = raw.receive();
        if (d != null) received.add(d.data.toList());
      }
    });
  }

  final RawDatagramSocket raw;
  final int target;
  final List<List<int>> received = [];

  PeerInfo get info =>
      PeerInfo(address: InternetAddress.loopbackIPv4, port: raw.port);

  Future<void> send(List<int> bytes) async {
    raw.send(bytes, InternetAddress.loopbackIPv4, target);
    await Future.delayed(_tick);
  }

  int count(int prefix) =>
      received.where((m) => m.isNotEmpty && m[0] == prefix).length;
}

void main() {
  late ShspSocket socket;
  late _Wire wire;
  late ShspInstance instance;
  late int opens, closings, closes, handshakes, messages;
  late List<dynamic> errors;

  Future<void> build({
    int keepAliveSeconds = 15,
    int? liveness,
  }) async {
    socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
    wire = _Wire(
      await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0),
      socket.localPort!,
    );
    instance = ShspInstance(
      remotePeer: wire.info,
      socket: socket,
      keepAliveSeconds: keepAliveSeconds,
      livenessTimeoutSeconds: liveness,
    );
    opens = closings = closes = handshakes = messages = 0;
    errors = [];
    instance.onOpen.register((_) => opens++);
    instance.onClosing.register((_) => closings++);
    instance.onClose.register((_) => closes++);
    instance.onHandshake.register((_) => handshakes++);
    instance.messageCallback.register((_) => messages++);
    socket.onError.register(errors.add);
  }

  Future<void> teardown() async {
    instance.close();
    socket.close();
    wire.raw.close();
  }

  Future<void> toOpen() async {
    instance.sendHandshake();
    await wire.send([0x02]);
    wire.received.clear();
    expect(instance.open, isTrue);
  }

  group('Wire format (Section 4) and handshake (Section 6)', () {
    setUp(() => build());
    tearDown(teardown);

    test('probe is exactly [0x01, 0x00] and moves CREATED -> HANDSHAKING',
        () async {
      expect(instance.handshake, isFalse);
      instance.sendHandshake();
      await Future.delayed(_tick);
      expect(wire.received.single, [0x01, 0x00]);
      expect(instance.handshake, isTrue);
      expect(instance.open, isFalse);
    });

    test('shspVersion is pinned to 0x00', () {
      expect(shspVersion, 0x00);
    });

    test('received probe is acknowledged with [0x02] and fires onHandshake',
        () async {
      await wire.send([0x01, 0x00]);
      expect(wire.received.single, [0x02]);
      expect(handshakes, 1);
      expect(instance.open, isFalse);
      expect(instance.handshake, isTrue);
    });

    test('ack of a received probe carries no body and no version echo',
        () async {
      await wire.send([0x01, 0x07]);
      expect(wire.received.single, [0x02]);
    });

    test('a different declared VERSION neither blocks nor errors', () async {
      await wire.send([0x01, 0xFF]);
      expect(wire.count(0x02), 1);
      expect(errors, isEmpty);
      await wire.send([0x02]);
      expect(instance.open, isTrue);
    });

    test('probe without VERSION byte is malformed: discarded, no ack',
        () async {
      await wire.send([0x01]);
      expect(wire.received, isEmpty);
      expect(handshakes, 0);
      expect(instance.handshake, isFalse);
    });

    test('bytes after VERSION are ignored (Section 4)', () async {
      await wire.send([0x01, 0x00, 0xAA, 0xBB]);
      expect(wire.received.single, [0x02]);
      expect(handshakes, 1);
    });

    test('duplicate probes are all acked, onHandshake fires once', () async {
      await wire.send([0x01, 0x00]);
      await wire.send([0x01, 0x00]);
      expect(wire.count(0x02), 2);
      expect(handshakes, 1);
    });

    test('malformed probe never becomes an implicit version 0x00', () async {
      await wire.send([0x01]);
      await wire.send([0x02]);
      // CREATED discards the ack: still not open.
      expect(instance.open, isFalse);
    });

    test('duplicate probes are tolerated', () async {
      await wire.send([0x01, 0x00]);
      await wire.send([0x01, 0x00]);
      await wire.send([0x01, 0x00]);
      expect(errors, isEmpty);
      expect(instance.open, isFalse);
      expect(wire.count(0x02), greaterThanOrEqualTo(1));
    });

    test('ack moves HANDSHAKING -> OPEN and onOpen fires exactly once',
        () async {
      instance.sendHandshake();
      await wire.send([0x02]);
      expect(instance.open, isTrue);
      expect(opens, 1);
      await wire.send([0x02]);
      await wire.send([0x02]);
      expect(opens, 1);
      expect(instance.open, isTrue);
    });

    test('probe received while OPEN does not downgrade the session',
        () async {
      await toOpen();
      await wire.send([0x01, 0x00]);
      expect(instance.open, isTrue);
      expect(closings, 0);
    });

    test('ack received on a probe-first (receiver) side opens it', () async {
      await wire.send([0x01, 0x00]);
      await wire.send([0x02]);
      expect(instance.open, isTrue);
      expect(opens, 1);
    });

    test('order independent: ack then probe', () async {
      instance.sendHandshake();
      await wire.send([0x02]);
      await wire.send([0x01, 0x00]);
      expect(instance.open, isTrue);
      expect(opens, 1);
    });
  });

  group('CREATED state (Section 5)', () {
    setUp(() => build());
    tearDown(teardown);

    for (final prefix in [0x00, 0x02, 0x03, 0x04, 0x05, 0x09]) {
      test('prefix 0x0$prefix is discarded', () async {
        await wire.send([prefix, 1, 2]);
        expect(instance.handshake, isFalse);
        expect(instance.open, isFalse);
        expect(opens + closings + closes + messages, 0);
        expect(wire.received, isEmpty);
      });
    }
  });

  group('Implicit confirmation and HANDSHAKING (Section 6.7, 6.8)', () {
    setUp(() async {
      await build();
      instance.sendHandshake();
      await Future.delayed(_tick);
      wire.received.clear();
    });
    tearDown(teardown);

    test('Data in HANDSHAKING opens the session and is delivered', () async {
      await wire.send([0x00, 1, 2, 3]);
      expect(instance.open, isTrue);
      expect(opens, 1);
      expect(messages, 1);
    });

    test('Keep-alive in HANDSHAKING opens the session, not delivered',
        () async {
      await wire.send([0x05]);
      expect(instance.open, isTrue);
      expect(opens, 1);
      expect(messages, 0);
    });

    test('Closing in HANDSHAKING does NOT open; replies Closed, CLOSED',
        () async {
      wire.received.clear();
      await wire.send([0x03]);
      expect(instance.open, isFalse);
      expect(opens, 0);
      expect(wire.received, [
        [0x04],
      ]);
      expect(closes, 1);
      // CLOSED is terminal: a late ack does not open the session.
      await wire.send([0x02]);
      expect(instance.open, isFalse);
    });

    test('Closed in HANDSHAKING does NOT open and ends the session',
        () async {
      await wire.send([0x04]);
      expect(instance.open, isFalse);
      expect(opens, 0);
      expect(closes, 1);
    });

    test('unknown prefix in HANDSHAKING is discarded, state kept',
        () async {
      await wire.send([0x7F]);
      expect(errors, isEmpty);
      expect(instance.open, isFalse);
      expect(instance.handshake, isTrue);
    });
  });

  group('OPEN state', () {
    setUp(() async {
      await build();
      await toOpen();
    });
    tearDown(teardown);

    test('Data is delivered; Keep-alive is not', () async {
      await wire.send([0x00, 9]);
      await wire.send([0x05]);
      expect(messages, 1);
    });

    test('unknown prefix is discarded and does not close', () async {
      await wire.send([0x42]);
      expect(errors, isEmpty);
      expect(instance.open, isTrue);
    });

    test('probe received while OPEN is still acknowledged', () async {
      await wire.send([0x01, 0x00]);
      expect(wire.received.single, [0x02]);
      expect(instance.open, isTrue);
    });

    test('sendMessage emits [0x00, ...payload] byte-for-byte (opaque)',
        () async {
      final payload = [0x1f, 0x8b, 0x08, 0, 255, 1]; // looks like gzip
      instance.sendMessage(payload);
      await Future.delayed(_tick);
      expect(wire.received.single, [0x00, ...payload]);
    });

    test('sendMessage does not mutate the caller list', () async {
      final payload = [1, 2, 3];
      instance.sendMessage(payload);
      expect(payload, [1, 2, 3]);
    });

    test('oversized message is rejected and nothing is sent', () async {
      expect(
        () => instance.sendMessage(List.filled(65507, 1)),
        throwsA(isA<ShspValidationException>()),
      );
      await Future.delayed(_tick);
      expect(wire.received, isEmpty);
    });

    test('maximum size message (65507 bytes on the wire) is accepted', () {
      expect(
        () => instance.sendMessage(List.filled(65506, 1)),
        returnsNormally,
      );
    });

    test('Closing received: notifies, replies Closed, CLOSED', () async {
      await wire.send([0x03]);
      expect(closings, 1);
      expect(closes, 1);
      expect(wire.received, [
        [0x04],
      ]);
      expect(instance.open, isFalse);
      expect(instance.closing, isFalse);
    });

    test('local CLOSING still delivers incoming Data', () async {
      instance.sendClosing();
      await wire.send([0x00, 1]);
      expect(instance.closing, isTrue);
      expect(messages, 1);
    });

    test('CLOSING rejects Data and Keep-alive sends', () async {
      instance.sendClosing();
      await Future.delayed(_tick);
      wire.received.clear();
      expect(() => instance.sendMessage([1]), throwsA(isA<ShspInstanceException>()));
      instance.keepAlive();
      await Future.delayed(_tick);
      expect(wire.count(0x00), 0);
      expect(wire.count(0x05), 0);
    });

    test('duplicate Closing fires onClosing once', () async {
      await wire.send([0x03]);
      await wire.send([0x03]);
      expect(closings, 1);
    });

    test('local Closing then peer Closed -> CLOSED, onClose once', () async {
      instance.sendClosing();
      await wire.send([0x04]);
      expect(closes, 1);
      expect(instance.open, isFalse);
      expect(instance.closing, isFalse);
      // Retransmission stops after CLOSED.
      wire.received.clear();
      await Future.delayed(const Duration(milliseconds: 700));
      expect(wire.received, isEmpty);
    });

    test(
        'simultaneous close: Closing while CLOSING replies Closed, '
        'no onClosing on the initiator', () async {
      instance.sendClosing();
      await Future.delayed(_tick);
      wire.received.clear();
      await wire.send([0x03]);
      expect(closings, 0);
      expect(closes, 1);
      expect(wire.received, [
        [0x04],
      ]);
    });

    test('closing timeout sends best-effort Closed and moves to CLOSED',
        () async {
      instance.closingTimeout = const Duration(milliseconds: 150);
      instance.sendClosing();
      await Future.delayed(const Duration(milliseconds: 300));
      expect(instance.open, isFalse);
      expect(closes, 1);
      expect(wire.count(0x04), 1);
    });

    test('local close() fires onClose exactly once', () async {
      instance.close();
      instance.close();
      expect(closes, 1);
    });

    test('Closed directly from OPEN -> CLOSED, onClose once', () async {
      await wire.send([0x04]);
      expect(closes, 1);
      expect(instance.open, isFalse);
      await wire.send([0x04]);
      expect(closes, 1);
    });

    test('local sendClosing -> CLOSING, further sends rejected', () async {
      instance.sendClosing();
      await Future.delayed(_tick);
      expect(wire.received.single, [0x03]);
      expect(instance.closing, isTrue);
      expect(() => instance.sendMessage([1]), throwsA(isA<ShspInstanceException>()));
    });
  });

  group('CLOSED is terminal (Section 5, 8, 10)', () {
    setUp(() async {
      await build(keepAliveSeconds: 1);
      await toOpen();
      await wire.send([0x04]);
      wire.received.clear();
    });
    tearDown(teardown);

    test('incoming Data is discarded', () async {
      await wire.send([0x00, 1]);
      expect(messages, 0);
    });

    test('stray ack does not reopen and onOpen does not fire again',
        () async {
      await wire.send([0x02]);
      expect(instance.open, isFalse);
      expect(opens, 1);
    });

    test('stray Closing does not revive CLOSING', () async {
      await wire.send([0x03]);
      expect(instance.closing, isFalse);
      expect(closings, 0);
    });

    test('new probe is neither acked nor accepted', () async {
      await wire.send([0x01, 0x00]);
      expect(wire.received, isEmpty);
      expect(handshakes, 0);
      expect(instance.open, isFalse);
    });

    test('sendHandshake on a closed session sends nothing', () async {
      instance.sendHandshake();
      await Future.delayed(_tick);
      expect(wire.received, isEmpty);
      expect(instance.open, isFalse);
    });

    test('sendMessage reports "closed"', () {
      expect(
        () => instance.sendMessage([1]),
        throwsA(predicate((e) => e.toString().contains('closed'))),
      );
    });

    test('keep-alive timer is released', () async {
      await Future.delayed(const Duration(milliseconds: 1300));
      expect(wire.received, isEmpty);
    });

    test('close() is idempotent: no error, nothing retransmitted', () async {
      instance.close();
      instance.close();
      await Future.delayed(_tick);
      expect(wire.received, isEmpty);
    });
  });

  group('Local close (Section 8)', () {
    setUp(() => build());
    tearDown(teardown);

    test('close() on OPEN sends [0x04] once and ends in CLOSED', () async {
      await toOpen();
      instance.close();
      instance.close();
      await Future.delayed(_tick);
      expect(wire.received, [
        [0x04],
      ]);
      expect(instance.open, isFalse);
    });

    test('after close the socket callback is released', () async {
      await toOpen();
      instance.close();
      await wire.send([0x00, 1]);
      expect(messages, 0);
    });

    test('close() in HANDSHAKING sends Closed (abortive) and is terminal',
        () async {
      instance.sendHandshake();
      await Future.delayed(_tick);
      wire.received.clear();
      instance.close();
      await Future.delayed(_tick);
      expect(wire.received, [
        [0x04],
      ]);
      await wire.send([0x02]);
      expect(instance.open, isFalse);
    });

    test('close() when the socket is already closed does not throw',
        () async {
      await toOpen();
      socket.close();
      expect(() => instance.close(), returnsNormally);
    });

    test('sending while not open is rejected', () {
      expect(
        () => instance.sendMessage([1]),
        throwsA(isA<ShspInstanceException>()),
      );
    });
  });

  group('Keep-alive (Section 7)', () {
    tearDown(teardown);

    test('starts automatically on OPEN and sends [0x05]', () async {
      await build(keepAliveSeconds: 1);
      await toOpen();
      await Future.delayed(const Duration(milliseconds: 1400));
      expect(wire.count(0x05), greaterThanOrEqualTo(1));
    });

    test('is also started by implicit confirmation', () async {
      await build(keepAliveSeconds: 1);
      instance.sendHandshake();
      await wire.send([0x00, 1]);
      wire.received.clear();
      await Future.delayed(const Duration(milliseconds: 1400));
      expect(wire.count(0x05), greaterThanOrEqualTo(1));
    });

    test('is not sent before the session is open', () async {
      await build(keepAliveSeconds: 1);
      instance.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 1400));
      expect(wire.count(0x05), 0);
    });

    test('is suppressed while other outbound traffic is recent', () async {
      await build(keepAliveSeconds: 1);
      await toOpen();
      for (var i = 0; i < 4; i++) {
        instance.sendMessage([i]);
        await Future.delayed(const Duration(milliseconds: 400));
      }
      expect(wire.count(0x05), 0);
    });

    test('not sent after Closing is announced', () async {
      await build(keepAliveSeconds: 1);
      await toOpen();
      await wire.send([0x03]);
      wire.received.clear();
      await Future.delayed(const Duration(milliseconds: 1400));
      expect(wire.count(0x05), 0);
    });

    test('failure in keep-alive is non-fatal', () async {
      await build(keepAliveSeconds: 1);
      await toOpen();
      wire.raw.close(); // peer unreachable; sends may fail
      await Future.delayed(const Duration(milliseconds: 2200));
      expect(instance.open, isTrue);
    });
  });

  group('Liveness timeout (Section 7)', () {
    tearDown(teardown);

    test('expiry closes locally and announces [0x04]', () async {
      await build(liveness: 1);
      await toOpen();
      await Future.delayed(const Duration(milliseconds: 1400));
      expect(instance.open, isFalse);
      expect(wire.count(0x04), 1);
    });

    test('is reset by every message type', () async {
      await build(liveness: 1);
      await toOpen();
      final stream = <List<int>>[
        [0x00, 1],
        [0x05],
        [0x01, 0x00],
        [0x02],
      ];
      for (var round = 0; round < 2; round++) {
        for (final m in stream) {
          await wire.send(m);
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
      expect(instance.open, isTrue);
    });

    test('disabled (null) never closes', () async {
      await build(liveness: null);
      await toOpen();
      await Future.delayed(const Duration(milliseconds: 1500));
      expect(instance.open, isTrue);
    });

    test('timer is released on close (no later effect)', () async {
      await build(liveness: 1);
      await toOpen();
      instance.close();
      await Future.delayed(_tick);
      wire.received.clear();
      await Future.delayed(const Duration(milliseconds: 1500));
      expect(wire.received, isEmpty);
    });
  });

  group('Handshake retransmission (Section 6.4, 6.5)', () {
    setUp(() => build());
    tearDown(teardown);

    const fast = ShspHandshakeRetryOptions(
      maxAttempts: 4,
      initialDelayMs: 60,
      backoffMultiplier: 1.0,
    );

    test('retransmits probes until the attempt budget is exhausted',
        () async {
      var exhausted = 0;
      final retry = ShspHandshakeRetryHandler.startRetry(
        instance: instance,
        options: fast,
        onMaxAttemptsExhausted: () => exhausted++,
      );
      await Future.delayed(const Duration(milliseconds: 600));
      expect(wire.count(0x01), 4);
      expect(exhausted, 1);
      expect(retry.isActive, isFalse);
      expect(instance.open, isFalse); // no exception, just state
    });

    test('exhaustion is reported only after the last interval', () async {
      var exhausted = 0;
      ShspHandshakeRetryHandler.startRetry(
        instance: instance,
        options: const ShspHandshakeRetryOptions(
          maxAttempts: 2,
          initialDelayMs: 300,
          backoffMultiplier: 1.0,
        ),
        onMaxAttemptsExhausted: () => exhausted++,
      );
      await Future.delayed(const Duration(milliseconds: 450));
      expect(wire.count(0x01), 2);
      expect(exhausted, 0);
      await Future.delayed(const Duration(milliseconds: 400));
      expect(exhausted, 1);
    });

    test('backoff makes successive delays grow', () async {
      final times = <int>[];
      final sw = Stopwatch()..start();
      ShspHandshakeRetryHandler.startRetry(
        instance: instance,
        options: const ShspHandshakeRetryOptions(
          maxAttempts: 4,
          initialDelayMs: 100,
          backoffMultiplier: 2.0,
        ),
      );
      var seen = 0;
      while (seen < 4 && sw.elapsedMilliseconds < 3000) {
        await Future.delayed(const Duration(milliseconds: 10));
        while (seen < wire.count(0x01)) {
          times.add(sw.elapsedMilliseconds);
          seen++;
        }
      }
      expect(times.length, 4);
      expect(times[3] - times[2], greaterThan(times[1] - times[0]));
    });

    test('stops once OPEN, no exhaustion callback', () async {
      var exhausted = 0;
      final retry = ShspHandshakeRetryHandler.startRetry(
        instance: instance,
        options: fast,
        onMaxAttemptsExhausted: () => exhausted++,
      );
      await wire.send([0x02]);
      final sent = wire.count(0x01);
      await Future.delayed(const Duration(milliseconds: 500));
      expect(wire.count(0x01), sent);
      expect(exhausted, 0);
      expect(retry.isActive, isFalse);
    });

    test('keeps retransmitting after the peer probe is merely observed',
        () async {
      ShspHandshakeRetryHandler.startRetry(instance: instance, options: fast);
      await wire.send([0x01, 0x00]); // peer probe, but we are not OPEN yet
      final before = wire.count(0x01);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(wire.count(0x01), greaterThan(before));
    });

    test('cancel() stops retransmission', () async {
      final retry = ShspHandshakeRetryHandler.startRetry(
        instance: instance,
        options: fast,
      );
      retry.cancel();
      await Future.delayed(_tick);
      final sent = wire.count(0x01);
      await Future.delayed(const Duration(milliseconds: 400));
      expect(wire.count(0x01), sent);
    });

    test('fixed-interval handler: timeout is not an error', () async {
      final result = await ShspHandshakeHandler.handshakeInstance(
        instance,
        const ShspHandshakeHandlerOptions(
          timeoutMs: 300,
          intervalOfSendingHandshakeMs: 100,
        ),
      );
      expect(result.open, isFalse);
      expect(wire.count(0x01), greaterThanOrEqualTo(2));
    });

    test('fixed-interval handler: returns open when ack arrives', () async {
      final future = ShspHandshakeHandler.handshakeInstance(
        instance,
        const ShspHandshakeHandlerOptions(
          timeoutMs: 2000,
          intervalOfSendingHandshakeMs: 100,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 150));
      wire.raw.send([0x02], InternetAddress.loopbackIPv4, socket.localPort!);
      final result = await future;
      expect(result.open, isTrue);
    });
  });

  group('Transport (Section 3) and errors (Section 10)', () {
    test('bind with invalid port is a validation error', () async {
      await expectLater(
        ShspSocket.bind(InternetAddress.loopbackIPv4, 70000),
        throwsA(isA<ShspValidationException>()),
      );
      await expectLater(
        ShspSocket.bind(InternetAddress.loopbackIPv4, -1),
        throwsA(isA<ShspValidationException>()),
      );
    });

    test('empty message is rejected at peer level', () async {
      await build();
      final peer = ShspPeer(remotePeer: wire.info, socket: socket);
      expect(() => peer.sendMessage([]), throwsA(isA<ShspValidationException>()));
      expect(
        () => peer.sendMessage(List.filled(65508, 0)),
        throwsA(isA<ShspValidationException>()),
      );
      peer.close();
      await teardown();
    });

    test('socket does not transform payloads (no compression)', () async {
      await build();
      final bytes = List<int>.generate(200, (i) => i % 7);
      socket.sendTo(bytes, wire.info);
      await Future.delayed(_tick);
      expect(wire.received.single, bytes);
      await teardown();
    });

    test('IPv6 session round-trip works when IPv6 is available', () async {
      RawDatagramSocket? v6;
      try {
        v6 = await RawDatagramSocket.bind(InternetAddress.loopbackIPv6, 0);
      } catch (_) {
        return; // IPv6 unavailable on this host
      }
      final s = await ShspSocket.bind(InternetAddress.loopbackIPv6, 0);
      final inst = ShspInstance(
        remotePeer: PeerInfo(
          address: InternetAddress.loopbackIPv6,
          port: v6.port,
        ),
        socket: s,
        livenessTimeoutSeconds: null,
      );
      final got = Completer<List<int>>();
      v6.listen((e) {
        final d = v6!.receive();
        if (d != null && !got.isCompleted) got.complete(d.data);
      });
      inst.sendHandshake();
      expect(await got.future.timeout(const Duration(seconds: 2)), [0x01, 0x00]);
      inst.close();
      s.close();
      v6.close();
    });
  });
}
