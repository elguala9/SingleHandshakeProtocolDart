import 'dart:io';
import 'package:callback_handler/callback_handler.dart';
import 'package:shsp/src/impl/socket/features/shsp_socket_callbacks.dart';
import 'package:shsp/src/impl/utility/message_callback_map.dart';
import 'package:shsp/src/types/callback_types.dart';
import 'package:shsp/src/types/peer_types.dart';
import 'package:shsp/src/types/remote_info.dart';
import 'package:test/test.dart';

/// Test harness implementing ShspSocketCallbacksMixin to expose its methods
class _ShspSocketCallbacksTestHarness with ShspSocketCallbacksMixin {
  _ShspSocketCallbacksTestHarness() {
    messageCallbacksImpl = MessageCallbackMap();
    onCloseImpl = CallbackHandler();
    onErrorImpl = CallbackHandler();
    onListeningImpl = CallbackHandler();
  }

  @override
  late MessageCallbackMap messageCallbacksImpl;

  @override
  late CallbackHandler<MessageRecord, void> onCloseImpl;

  @override
  late CallbackHandler<dynamic, void> onErrorImpl;

  @override
  late CallbackHandler<MessageRecord, void> onListeningImpl;

  /// Expose the protected method for testing
  void testInvokeMessageCallback(List<int> msg, RemoteInfo rinfo) =>
      invokeMessageCallback(msg, rinfo);
}

void main() {
  group('ShspSocketCallbacksMixin.invokeMessageCallback', () {
    late _ShspSocketCallbacksTestHarness harness;

    setUp(() {
      harness = _ShspSocketCallbacksTestHarness();
    });

    // ── Basic callback invocation ───────────────────────────────────────────
    group('basic invocation', () {
      test('invokes callback for exact IP:port match', () async {
        var callbackInvoked = false;
        void callback(record) {
          callbackInvoked = true;
          expect(record.msg, equals([1, 2, 3]));
          expect(record.rinfo.address.address, equals('192.168.1.100'));
          expect(record.rinfo.port, equals(8080));
        }

        final addr = InternetAddress('192.168.1.100');
        harness.setMessageCallback(
          PeerInfo(address: addr, port: 8080),
          callback,
        );

        final rinfo = RemoteInfo(address: addr, port: 8080);
        harness.testInvokeMessageCallback([1, 2, 3], rinfo);

        await Future.microtask(() {});
        expect(callbackInvoked, isTrue);
      });

      test('does not invoke callback for unregistered IP:port', () async {
        var callbackInvoked = false;
        void callback(record) {
          callbackInvoked = true;
        }

        final addr1 = InternetAddress('192.168.1.100');
        final addr2 = InternetAddress('192.168.1.101');
        harness.setMessageCallback(
          PeerInfo(address: addr1, port: 8080),
          callback,
        );

        final rinfo = RemoteInfo(address: addr2, port: 8080);
        harness.testInvokeMessageCallback([1, 2, 3], rinfo);

        await Future.microtask(() {});
        expect(callbackInvoked, isFalse);
      });
    });

    // ── NAT port remapping ── exact port match required ──────────────────────
    group('exact port matching required', () {
      test(
          'callback registered on :9002 not invoked when message arrives on same IP but different port :58349',
          () async {
        var callbackInvoked = false;

        void callback(MessageRecord record) {
          callbackInvoked = true;
        }

        final bobAddr = InternetAddress('172.20.0.3');
        harness.setMessageCallback(
          PeerInfo(address: bobAddr, port: 9002),
          callback,
        );

        final remappedRinfo = RemoteInfo(address: bobAddr, port: 58349);
        harness.testInvokeMessageCallback([42, 43, 44], remappedRinfo);

        await Future.microtask(() {});
        expect(callbackInvoked, isFalse);
      });

      test('different port with IPv6 does not invoke callback', () async {
        var callbackInvoked = false;
        void callback(record) {
          callbackInvoked = true;
        }

        final addr = InternetAddress('2001:db8::1');
        harness.setMessageCallback(
          PeerInfo(address: addr, port: 8080),
          callback,
        );

        final remappedRinfo = RemoteInfo(address: addr, port: 58349);
        harness.testInvokeMessageCallback([1, 2, 3], remappedRinfo);

        await Future.microtask(() {});
        expect(callbackInvoked, isFalse);
      });

      test('exact match invokes callback', () async {
        var exactMatchInvoked = false;

        void exactCallback(MessageRecord record) {
          exactMatchInvoked = true;
        }

        final addr = InternetAddress('192.168.1.100');
        harness.setMessageCallback(
          PeerInfo(address: addr, port: 8080),
          exactCallback,
        );
        harness.setMessageCallback(
          PeerInfo(address: addr, port: 9090),
          (record) {},
        );

        final exactRinfo = RemoteInfo(address: addr, port: 8080);
        harness.testInvokeMessageCallback([1, 2, 3], exactRinfo);

        await Future.microtask(() {});
        expect(exactMatchInvoked, isTrue);
      });
    });

    // ── Edge cases ──────────────────────────────────────────────────────────
    group('edge cases', () {
      test('does not invoke callback when removed', () async {
        var callbackInvoked = false;
        void callback(record) {
          callbackInvoked = true;
        }

        final addr = InternetAddress('192.168.1.100');
        final peer = PeerInfo(address: addr, port: 8080);
        harness.setMessageCallback(peer, callback);
        harness.removeMessageCallback(peer, callback);

        final rinfo = RemoteInfo(address: addr, port: 8080);
        harness.testInvokeMessageCallback([1, 2, 3], rinfo);

        await Future.microtask(() {});
        expect(callbackInvoked, isFalse);
      });

      test('handles empty message correctly', () async {
        var callbackInvoked = false;
        late List<int> receivedMsg;

        void callback(MessageRecord record) {
          callbackInvoked = true;
          receivedMsg = record.msg;
        }

        final addr = InternetAddress('192.168.1.100');
        harness.setMessageCallback(
          PeerInfo(address: addr, port: 8080),
          callback,
        );

        final rinfo = RemoteInfo(address: addr, port: 8080);
        harness.testInvokeMessageCallback([], rinfo);

        await Future.microtask(() {});
        expect(callbackInvoked, isTrue);
        expect(receivedMsg, isEmpty);
      });

      test('handles large message correctly', () async {
        var callbackInvoked = false;
        late List<int> receivedMsg;

        void callback(MessageRecord record) {
          callbackInvoked = true;
          receivedMsg = record.msg;
        }

        final addr = InternetAddress('192.168.1.100');
        harness.setMessageCallback(
          PeerInfo(address: addr, port: 8080),
          callback,
        );

        final largeMsg = List.generate(10000, (i) => i % 256);
        final rinfo = RemoteInfo(address: addr, port: 8080);
        harness.testInvokeMessageCallback(largeMsg, rinfo);

        await Future.microtask(() {});
        expect(callbackInvoked, isTrue);
        expect(receivedMsg, equals(largeMsg));
      });
    });
  });
}
