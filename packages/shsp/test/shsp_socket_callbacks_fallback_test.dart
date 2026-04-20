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

    // ── NAT port remapping scenario ─────────────────────────────────────────
    group('NAT port remapping fallback', () {
      test(
          'callback registered on :9002 invoked when message arrives on same IP but port :58349',
          () async {
        var callbackInvoked = false;
        late List<int> receivedMsg;
        late String receivedIp;
        late int receivedPort;

        void callback(MessageRecord record) {
          callbackInvoked = true;
          receivedMsg = record.msg;
          receivedIp = record.rinfo.address.address;
          receivedPort = record.rinfo.port;
        }

        // Bob registers callback for 172.20.0.3:9002
        final bobAddr = InternetAddress('172.20.0.3');
        harness.setMessageCallback(
          PeerInfo(address: bobAddr, port: 9002),
          callback,
        );

        // Behind NAT, MASQUERADE remaps Bob's source port to :58349
        // But invokeMessageCallback receives the remapped address
        final remappedRinfo = RemoteInfo(address: bobAddr, port: 58349);
        harness.testInvokeMessageCallback([42, 43, 44], remappedRinfo);

        await Future.microtask(() {});
        expect(callbackInvoked, isTrue);
        expect(receivedMsg, equals([42, 43, 44]));
        expect(receivedIp, equals('172.20.0.3'));
        expect(receivedPort, equals(58349)); // Message reports remapped port
      });

      test('fallback works with IPv6 addresses', () async {
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
        expect(callbackInvoked, isTrue);
      });

      test('exact match takes precedence over fallback', () async {
        var exactMatchInvoked = false;

        void exactCallback(MessageRecord record) {
          exactMatchInvoked = true;
        }

        void fallbackCallback(MessageRecord record) {
          // Not invoked
        }

        final addr = InternetAddress('192.168.1.100');
        // Register handlers for two different ports on same IP
        harness.setMessageCallback(
          PeerInfo(address: addr, port: 8080),
          exactCallback,
        );
        harness.setMessageCallback(
          PeerInfo(address: addr, port: 9090),
          fallbackCallback,
        );

        // Message arrives for exact port match
        final exactRinfo = RemoteInfo(address: addr, port: 8080);
        harness.testInvokeMessageCallback([1, 2, 3], exactRinfo);

        await Future.microtask(() {});
        expect(exactMatchInvoked, isTrue);
      });
    });

    // ── Edge cases ──────────────────────────────────────────────────────────
    group('edge cases', () {
      test('works when callback is removed and message arrives', () async {
        var callbackInvoked = false;
        void callback(record) {
          callbackInvoked = true;
        }

        final addr = InternetAddress('192.168.1.100');
        final peer = PeerInfo(address: addr, port: 8080);
        harness.setMessageCallback(peer, callback);
        harness.removeMessageCallback(peer, callback);

        final rinfo = RemoteInfo(address: addr, port: 58349);
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

        final rinfo = RemoteInfo(address: addr, port: 58349);
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
        final rinfo = RemoteInfo(address: addr, port: 58349);
        harness.testInvokeMessageCallback(largeMsg, rinfo);

        await Future.microtask(() {});
        expect(callbackInvoked, isTrue);
        expect(receivedMsg, equals(largeMsg));
      });
    });
  });
}
