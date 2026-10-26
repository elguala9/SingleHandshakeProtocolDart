import 'dart:async';
import 'dart:io';
import 'package:shsp/shsp.dart';
import 'package:test/test.dart';

/// Rejects (returns 0) every send until [accepting] is set, like a socket
/// that cannot take a datagram yet.
class _GatedSender with ShspSocketSendQueueMixin {
  bool accepting = false;
  bool closed = false;
  bool writeEvents = false;
  final List<List<int>> sent = [];

  @override
  int rawSend(List<int> buffer, InternetAddress address, int port) {
    if (!accepting) return 0;
    sent.add(buffer);
    return buffer.length;
  }

  @override
  set writeEventsEnabled(bool value) => writeEvents = value;

  @override
  bool get isSendClosed => closed;

  @override
  Duration get retryDelay => const Duration(milliseconds: 1);

  @override
  Duration get maxRetryDelay => const Duration(milliseconds: 4);

  @override
  int get maxRetryAttempts => 5;

  int send(List<int> buffer) =>
      sendOrQueue(buffer, InternetAddress.loopbackIPv4, 9);

  void drain() => drainSendQueue();

  void dispose() => clearSendQueue();
}

void main() {
  group('ShspSocketSendQueueMixin', () {
    late _GatedSender sender;

    setUp(() => sender = _GatedSender());
    tearDown(() => sender.dispose());

    test('queues a rejected datagram and reports it as sent', () {
      expect(sender.send([1, 2, 3]), equals(3));
      expect(sender.queuedDatagramCount, equals(1));
      expect(sender.writeEvents, isTrue);
    });

    test('drains in order once the socket accepts again', () {
      for (var i = 0; i < 4; i++) {
        sender.send([i]);
      }
      sender.accepting = true;
      sender.drain();

      expect(sender.sent, equals([[0], [1], [2], [3]]));
      expect(sender.queuedDatagramCount, equals(0));
      expect(sender.writeEvents, isFalse);
    });

    test('does not overtake queued datagrams with a new send', () {
      sender.send([1]);
      sender.accepting = true;
      sender.send([2]);
      expect(sender.sent, isEmpty);

      sender.drain();
      expect(sender.sent, equals([[1], [2]]));
    });

    test('keeps the rest queued while the socket still rejects', () {
      sender.send([1]);
      sender.send([2]);
      sender.drain();

      expect(sender.queuedDatagramCount, equals(2));
      expect(sender.writeEvents, isTrue);
    });

    test('throws ShspNetworkException when the queue is full', () {
      for (var i = 0; i < ShspSocketSendQueueMixin.maxQueuedDatagrams; i++) {
        sender.send([i]);
      }
      expect(() => sender.send([0]), throwsA(isA<ShspNetworkException>()));
    });

    test('gives up and drops the queue after repeated fruitless retries',
        () async {
      sender.send([1]);
      sender.send([2]);
      expect(sender.queuedDatagramCount, equals(2));

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(sender.queuedDatagramCount, equals(0));
      expect(sender.writeEvents, isFalse);
      expect(sender.sent, isEmpty);
    });

    test('delivers late once the socket accepts before giving up', () async {
      sender.send([7]);
      sender.accepting = true;

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sender.sent, equals([[7]]));
      expect(sender.queuedDatagramCount, equals(0));
    });

    test('returns 0 and queues nothing when the socket is closed', () {
      sender.closed = true;
      expect(sender.send([1]), equals(0));
      expect(sender.queuedDatagramCount, equals(0));
    });

    test('drops pending datagrams when the socket closes before draining',
        () {
      sender.send([1]);
      sender.closed = true;
      sender.drain();
      expect(sender.queuedDatagramCount, equals(0));
      expect(sender.sent, isEmpty);
    });
  });

  group('ShspSocket whose raw socket was closed directly', () {
    test('stops retrying instead of looping forever', () async {
      final raw = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final socket = ShspSocket.fromRaw(raw);
      addTearDown(socket.close);
      raw.close();
      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9);

      socket.sendTo([1], peer);
      expect(socket.queuedDatagramCount, equals(1));

      await Future<void>.delayed(const Duration(seconds: 2));

      expect(socket.queuedDatagramCount, equals(0));
    });
  });

  group('ShspSocket back-to-back sends', () {
    late ShspSocket tx;
    late RawDatagramSocket rx;

    setUp(() async {
      tx = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      rx = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    });

    tearDown(() {
      tx.close();
      rx.close();
    });

    test('delivers every datagram, in order, without throwing', () async {
      const count = 50;
      final received = <int>[];
      final done = Completer<void>();
      rx.listen((event) {
        if (event != RawSocketEvent.read) return;
        for (var d = rx.receive(); d != null; d = rx.receive()) {
          received.add(d.data.first);
        }
        if (received.length == count && !done.isCompleted) done.complete();
      });

      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: rx.port);
      for (var i = 0; i < count; i++) {
        expect(tx.sendTo([i], peer), greaterThan(0));
      }

      await done.future.timeout(const Duration(seconds: 5));
      expect(received, equals(List<int>.generate(count, (i) => i)));
    });
  });
}
