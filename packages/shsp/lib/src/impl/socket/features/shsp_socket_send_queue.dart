import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' show min;
import 'package:meta/meta.dart';
import '../../../interfaces/exceptions/shsp_exceptions.dart';

class _PendingDatagram {
  _PendingDatagram(this.buffer, this.address, this.port);

  final List<int> buffer;
  final InternetAddress address;
  final int port;
}

/// Mixin that absorbs transient `RawDatagramSocket.send` rejections.
///
/// `RawDatagramSocket.send` returns 0 when it cannot take a datagram right
/// now. On Windows the socket accepts only one send at a time, so a second
/// send issued in the same tick (for example two peers sharing this socket,
/// or a handshake reply right after our own handshake) is rejected with 0
/// even though no buffer is full. A rejected
/// datagram was not sent, so it is queued and flushed in order on the next
/// write event instead of failing the caller. A retry timer with exponential
/// backoff backs the write event up, since the platform does not always raise
/// one. A socket that keeps rejecting (e.g. its raw socket was closed behind
/// this object's back) is given up on after [maxRetryAttempts] fruitless
/// retries: the pending datagrams are dropped, as UDP allows, and the timer
/// stops.
mixin ShspSocketSendQueueMixin {
  /// Maximum number of datagrams waiting for the socket to become writable.
  static const int maxQueuedDatagrams = 256;

  /// Delay before the first fallback flush when no write event drained the
  /// queue; doubled after every fruitless retry up to [maxRetryDelay].
  @protected
  Duration get retryDelay => const Duration(milliseconds: 2);

  /// Upper bound of the backed-off retry delay.
  @protected
  Duration get maxRetryDelay => const Duration(milliseconds: 100);

  /// Consecutive fruitless retries after which the queue is dropped.
  @protected
  int get maxRetryAttempts => 15;

  final Queue<_PendingDatagram> _sendQueue = Queue<_PendingDatagram>();
  Timer? _retryTimer;
  int _retryFailures = 0;

  /// Sends one datagram on the underlying socket; 0 means it was rejected.
  @protected
  int rawSend(List<int> buffer, InternetAddress address, int port);

  /// Enables or disables write events on the underlying socket.
  @protected
  set writeEventsEnabled(bool value);

  /// Whether the underlying socket is closed (a closed socket never drains).
  @protected
  bool get isSendClosed;

  /// Number of datagrams currently waiting to be sent.
  @visibleForTesting
  int get queuedDatagramCount => _sendQueue.length;

  /// Sends [buffer], queueing it when the socket rejects it. Returns the
  /// buffer length when sent or queued, 0 when the socket is closed.
  @protected
  int sendOrQueue(List<int> buffer, InternetAddress address, int port) {
    if (_sendQueue.isEmpty) {
      final sent = rawSend(buffer, address, port);
      if (sent > 0 || isSendClosed) return sent;
    }
    if (_sendQueue.length >= maxQueuedDatagrams) {
      throw ShspNetworkException(
        'Failed to send message - send queue full '
        '($maxQueuedDatagrams datagrams pending)',
        address: address.address,
        port: port,
      );
    }
    _sendQueue.add(_PendingDatagram(List<int>.of(buffer), address, port));
    writeEventsEnabled = true;
    _scheduleRetry();
    return buffer.length;
  }

  /// Flushes queued datagrams in order; call on every write event.
  @protected
  void drainSendQueue() {
    while (_sendQueue.isNotEmpty) {
      if (isSendClosed) {
        _sendQueue.clear();
        return;
      }
      final next = _sendQueue.first;
      if (rawSend(next.buffer, next.address, next.port) == 0) {
        _scheduleRetry();
        return;
      }
      _sendQueue.removeFirst();
    }
    _retryTimer?.cancel();
    _retryFailures = 0;
    writeEventsEnabled = false;
  }

  void _scheduleRetry() {
    if (_retryTimer?.isActive ?? false) return;
    final backedOff =
        retryDelay.inMicroseconds << min(_retryFailures, 16);
    _retryTimer = Timer(
      Duration(microseconds: min(backedOff, maxRetryDelay.inMicroseconds)),
      _onRetryTimer,
    );
  }

  /// Fallback flush: counts a retry that sent nothing and gives up once
  /// [maxRetryAttempts] of them happened in a row.
  void _onRetryTimer() {
    final before = _sendQueue.length;
    drainSendQueue();
    if (_sendQueue.isEmpty) return;
    if (_sendQueue.length < before) {
      _retryFailures = 0;
      return;
    }
    if (++_retryFailures >= maxRetryAttempts) {
      clearSendQueue();
      writeEventsEnabled = false;
    }
  }

  /// Drops every pending datagram (the socket is going away).
  @protected
  void clearSendQueue() {
    _retryTimer?.cancel();
    _retryFailures = 0;
    _sendQueue.clear();
  }
}
