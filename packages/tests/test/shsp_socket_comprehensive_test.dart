import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';
import 'package:shsp/src/impl/shsp_base/shsp_socket.dart';
import 'package:shsp/shsp.dart';
import 'helpers/testable_shsp_socket.dart';

/// Comprehensive test suite for ShspSocket
/// Tests binding, callbacks, message handling, error cases, and resource cleanup
void main() {
  group('ShspSocket Comprehensive Tests', () {
    group('Binding and Initialization', () {
      late InternetAddress address;

      setUp(() {
        address = InternetAddress.loopbackIPv4;
      });

      test('should bind to loopback IPv4 with ephemeral port', () async {
        final socket = await ShspSocket.bind(address, 0);
        expect(socket.localAddress, equals(address));
        expect(socket.localPort, isNotNull);
        expect(socket.localPort, greaterThan(0));
        socket.close();
      });

      test('should bind to specific port', () async {
        // Use a high port that's likely available
        const testPort = 54321;
        final socket = await ShspSocket.bind(address, testPort);
        expect(socket.localPort, equals(testPort));
        socket.close();
      });

      test('should throw ShspValidationException for negative port', () async {
        expect(
          () => ShspSocket.bind(address, -1),
          throwsA(isA<ShspValidationException>()),
        );
      });

      test('should throw ShspValidationException for port > 65535', () async {
        expect(
          () => ShspSocket.bind(address, 65536),
          throwsA(isA<ShspValidationException>()),
        );
      });

      test('should throw ShspValidationException for port > 100000', () async {
        expect(
          () => ShspSocket.bind(address, 100000),
          throwsA(isA<ShspValidationException>()),
        );
      });

      test('should have correct serialized object format', () async {
        final socket = await ShspSocket.bind(address, 0);
        final serialized = socket.serializedObject();
        expect(serialized, contains('ShspSocket'));
        expect(serialized, contains('localAddress'));
        expect(serialized, contains('localPort'));
        socket.close();
      });

      test('should bind to anyIPv4', () async {
        final anyAddress = InternetAddress.anyIPv4;
        final socket = await ShspSocket.bind(anyAddress, 0);
        expect(socket.localAddress, equals(anyAddress));
        expect(socket.localPort, isNotNull);
        socket.close();
      });

      test('socket property should return underlying RawDatagramSocket',
          () async {
        final socket = await ShspSocket.bind(address, 0);
        expect(socket.socket, isA<RawDatagramSocket>());
        socket.close();
      });
    });

    group('Message Callbacks', () {
      late ShspSocket socket;
      late InternetAddress address;
      late int port;

      setUp(() async {
        address = InternetAddress.loopbackIPv4;
        socket = await ShspSocket.bind(address, 0);
        port = socket.localPort!;
      });

      tearDown(() {
        socket.close();
      });

      test('should set and invoke message callback', () async {
        final testMsg = [1, 2, 3];
        final rinfo = RemoteInfo(address: address, port: port);
        bool called = false;
        List<int>? receivedMsg;
        RemoteInfo? receivedRinfo;

        socket.setMessageCallback(
          PeerInfo(address: address, port: port),
          (record) {
            called = true;
            receivedMsg = record.msg;
            receivedRinfo = record.rinfo;
          },
        );

        socket.testOnMessage(testMsg, rinfo);

        expect(called, isTrue);
        expect(receivedMsg, equals(testMsg));
        expect(receivedRinfo?.address, equals(address));
        expect(receivedRinfo?.port, equals(port));
      });

      test('should replace callback when setting same key multiple times',
          () async {
        final testMsg = [4, 5, 6];
        final rinfo = RemoteInfo(address: address, port: port);
        int callCount = 0;

        socket.setMessageCallback(PeerInfo(address: address, port: port), (record) {
          callCount++;
        });
        socket.setMessageCallback(PeerInfo(address: address, port: port), (record) {
          callCount++;
        });
        socket.setMessageCallback(PeerInfo(address: address, port: port), (record) {
          callCount++;
        });

        socket.testOnMessage(testMsg, rinfo);

        // Last callback should be the only one invoked
        expect(callCount, equals(1));
      });

      test('should handle callbacks with different sender addresses', () async {
        final addr1 = InternetAddress.loopbackIPv4;
        final addr2 = InternetAddress.loopbackIPv4;
        final port1 = 1234;
        final port2 = 5678;

        bool called1 = false;
        bool called2 = false;

        socket.setMessageCallback(PeerInfo(address: addr1, port: port1), (record) {
          called1 = true;
        });
        socket.setMessageCallback(PeerInfo(address: addr2, port: port2), (record) {
          called2 = true;
        });

        socket.testOnMessage([1], RemoteInfo(address: addr1, port: port1));
        expect(called1, isTrue);
        expect(called2, isFalse);

        called1 = false;
        socket.testOnMessage([2], RemoteInfo(address: addr2, port: port2));
        expect(called1, isFalse);
        expect(called2, isTrue);
      });

      test('should handle empty message', () async {
        final testMsg = <int>[];
        final rinfo = RemoteInfo(address: address, port: port);
        bool called = false;

        socket.setMessageCallback(PeerInfo(address: address, port: port), (record) {
          called = true;
          expect(record.msg.isEmpty, isTrue);
        });

        socket.testOnMessage(testMsg, rinfo);
        expect(called, isTrue);
      });

      test('should handle large message', () async {
        final testMsg = List<int>.generate(65507, (i) => i % 256);
        final rinfo = RemoteInfo(address: address, port: port);
        bool called = false;

        socket.setMessageCallback(PeerInfo(address: address, port: port), (record) {
          called = true;
          expect(record.msg.length, equals(65507));
        });

        socket.testOnMessage(testMsg, rinfo);
        expect(called, isTrue);
      });

      test('removeMessageCallback should remove callback', () async {
        final testMsg = [7, 8, 9];
        final rinfo = RemoteInfo(address: address, port: port);
        final key = PeerInfo(address: address, port: port);
        bool called = false;

        void callback(MessageRecord record) {
          called = true;
        }

        socket.setMessageCallback(key, callback);
        bool removed = socket.removeMessageCallback(key, callback);

        expect(removed, isTrue);

        socket.testOnMessage(testMsg, rinfo);
        expect(called, isFalse);
      });

      test('removeMessageCallback should return false for non-existent callback',
          () async {
        final key = PeerInfo(address: address, port: port);

        bool removed = socket.removeMessageCallback(key, (record) {
          // Dummy callback
        });

        expect(removed, isFalse);
      });

      test('removeMessageCallback should return false for non-existent key',
          () async {
        bool removed = socket.removeMessageCallback(
            PeerInfo(address: InternetAddress('192.0.2.255'), port: 99999),
            (record) {
          // Dummy callback
        });

        expect(removed, isFalse);
      });

      test('should not call removed callback', () async {
        final testMsg = [10, 11];
        final rinfo = RemoteInfo(address: address, port: port);
        final key = PeerInfo(address: address, port: port);
        int callCount = 0;

        void callback(MessageRecord record) {
          callCount++;
        }

        socket.setMessageCallback(key, callback);
        socket.setMessageCallback(key, callback);

        socket.removeMessageCallback(key, callback);
        socket.testOnMessage(testMsg, rinfo);

        // Callback should be removed, so no call should happen
        expect(callCount, equals(0));
      });
    });

    group('Close Callback', () {
      late ShspSocket socket;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      });

      tearDown(() {
        socket.close();
      });

      test('should set and invoke close callback', () async {
        bool closed = false;
        socket.setCloseCallback(() {
          closed = true;
        });

        socket.onClose.call(null);
        expect(closed, isTrue);
      });

      test('should support multiple close callbacks', () async {
        final callCounts = <int>[];
        socket.setCloseCallback(() {
          callCounts.add(1);
        });
        socket.setCloseCallback(() {
          callCounts.add(2);
        });
        socket.setCloseCallback(() {
          callCounts.add(3);
        });

        socket.onClose.call(null);
        expect(callCounts, equals([1, 2, 3]));
      });

      test('close callback should be directly callable via getter',
          () async {
        bool called = false;
        final onCloseCallback = socket.onClose;
        onCloseCallback.register((_) {
          called = true;
        });

        onCloseCallback.call(null);
        expect(called, isTrue);
      });
    });

    group('Error Callback', () {
      late ShspSocket socket;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      });

      tearDown(() {
        socket.close();
      });

      test('should set and invoke error callback', () async {
        bool errored = false;
        dynamic receivedError;
        final testError = Exception('Test error');

        socket.setErrorCallback((err) {
          errored = true;
          receivedError = err;
        });

        socket.onError.call(testError);
        expect(errored, isTrue);
        expect(receivedError, equals(testError));
      });

      test('should support multiple error callbacks', () async {
        final errors = <dynamic>[];
        // ignore: prefer_const_constructors
        final testError = SocketException('Network error');

        socket.setErrorCallback((err) {
          errors.add(err);
        });
        socket.setErrorCallback((err) {
          errors.add(err);
        });

        socket.onError.call(testError);
        expect(errors.length, equals(2));
        expect(errors[0], equals(testError));
        expect(errors[1], equals(testError));
      });

      test('should handle null error', () async {
        bool called = false;
        socket.setErrorCallback((err) {
          called = true;
        });

        socket.onError.call(null);
        expect(called, isTrue);
      });

      test('error callback should be directly callable via getter',
          () async {
        bool called = false;
        final onErrorCallback = socket.onError;
        onErrorCallback.register((err) {
          called = true;
        });

        onErrorCallback.call(Exception('Test'));
        expect(called, isTrue);
      });
    });

    group('Listening Callback', () {
      late ShspSocket socket;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      });

      tearDown(() {
        socket.close();
      });

      test('should set and invoke listening callback', () async {
        bool listening = false;
        socket.setListeningCallback(() {
          listening = true;
        });

        socket.onListening.call(null);
        expect(listening, isTrue);
      });

      test('should support multiple listening callbacks', () async {
        final callCounts = <int>[];
        socket.setListeningCallback(() {
          callCounts.add(1);
        });
        socket.setListeningCallback(() {
          callCounts.add(2);
        });

        socket.onListening.call(null);
        expect(callCounts, equals([1, 2]));
      });

      test('listening callback should be directly callable via getter',
          () async {
        bool called = false;
        final onListeningCallback = socket.onListening;
        onListeningCallback.register((_) {
          called = true;
        });

        onListeningCallback.call(null);
        expect(called, isTrue);
      });
    });

    group('SendTo Method', () {
      late ShspSocket socket1;
      late ShspSocket socket2;
      late InternetAddress address;

      setUp(() async {
        address = InternetAddress.loopbackIPv4;
        socket1 = await ShspSocket.bind(address, 0);
        socket2 = await ShspSocket.bind(address, 0);
      });

      tearDown(() {
        socket1.close();
        socket2.close();
      });

      test('should send and receive message between sockets', () async {
        final testMsg = [10, 20, 30];
        final completer = Completer<void>();
        final socket2Port = socket2.localPort!;

        socket2.setMessageCallback(
          PeerInfo(address: address, port: socket1.localPort!),
          (record) {
            expect(record.msg, equals(testMsg));
            completer.complete();
          },
        );

        socket1.sendTo(testMsg, PeerInfo(address: address, port: socket2Port));

        await completer.future
            .timeout(const Duration(seconds: 2), onTimeout: () {
          fail('Message not received within timeout');
        });
      });

      test('sendTo should return bytes sent', () async {
        final testMsg = [1, 2, 3];
        final bytesSent = socket1.sendTo(testMsg, PeerInfo(address: address, port: socket2.localPort!));
        expect(bytesSent, equals(3));
      });

      test('should send empty message', () async {
        final testMsg = <int>[];
        final bytesSent = socket1.sendTo(testMsg, PeerInfo(address: address, port: socket2.localPort!));
        expect(bytesSent, equals(0));
      });

      test('should send large message', () async {
        // Generate message starting from 1 to avoid 0x00 prefix which triggers compression
        final testMsg = List<int>.generate(1000, (i) => (i + 1) % 256);
        final completer = Completer<void>();
        final socket2Port = socket2.localPort!;

        socket2.setMessageCallback(
          PeerInfo(address: address, port: socket1.localPort!),
          (record) {
            expect(record.msg.length, equals(1000));
            completer.complete();
          },
        );

        final bytesSent = socket1.sendTo(testMsg, PeerInfo(address: address, port: socket2Port));
        expect(bytesSent, equals(1000));

        await completer.future
            .timeout(const Duration(seconds: 2), onTimeout: () {
          fail('Large message not received');
        });
      });

      test('should send message with all byte values (0-255)', () async {
        final testMsg = List<int>.generate(256, (i) => i);
        final completer = Completer<void>();
        final socket2Port = socket2.localPort!;

        socket2.setMessageCallback(
          PeerInfo(address: address, port: socket1.localPort!),
          (record) {
            expect(record.msg, equals(testMsg));
            completer.complete();
          },
        );

        socket1.sendTo(testMsg, PeerInfo(address: address, port: socket2Port));

        await completer.future
            .timeout(const Duration(seconds: 2), onTimeout: () {
          fail('Message with all byte values not received');
        });
      });

      test('should send multiple messages in sequence', () async {
        final msg1 = [1, 2];
        final msg2 = [3, 4];
        final msg3 = [5, 6];
        final completer = Completer<void>();
        final receivedMessages = <List<int>>[];
        final socket2Port = socket2.localPort!;
        final socket1Port = socket1.localPort!;

        socket2.setMessageCallback(
          PeerInfo(address: address, port: socket1Port),
          (record) {
            receivedMessages.add(record.msg);
            if (receivedMessages.length == 3) {
              completer.complete();
            }
          },
        );

        socket1.sendTo(msg1, PeerInfo(address: address, port: socket2Port));
        await Future.delayed(const Duration(milliseconds: 50));
        socket1.sendTo(msg2, PeerInfo(address: address, port: socket2Port));
        await Future.delayed(const Duration(milliseconds: 50));
        socket1.sendTo(msg3, PeerInfo(address: address, port: socket2Port));

        await completer.future
            .timeout(const Duration(seconds: 2), onTimeout: () {
          fail('Not all messages received');
        });

        expect(receivedMessages, equals([msg1, msg2, msg3]));
      });
    });

    group('Close and Idempotency', () {
      late ShspSocket socket;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      });

      test('close should be idempotent - callable multiple times', () async {
        expect(() {
          socket.close();
          socket.close();
          socket.close();
        }, returnsNormally);
      });

      test('close should be callable even if already closed', () async {
        socket.close();
        expect(socket.close, isA<Function>());
        socket.close();
      });

      test('multiple close calls should not throw', () async {
        expect(socket.close, isA<Function>());
        for (int i = 0; i < 10; i++) {
          socket.close();
        }
      });
    });

    group('Resource Management', () {
      test('should create and close multiple sockets sequentially', () async {
        for (int i = 0; i < 5; i++) {
          final socket =
              await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
          expect(socket.localPort, isNotNull);
          expect(socket.localPort, greaterThan(0));
          socket.close();
        }
      });

      test('should create and close many sockets', () async {
        final sockets = <ShspSocket>[];
        for (int i = 0; i < 20; i++) {
          final socket =
              await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
          sockets.add(socket);
        }

        for (final socket in sockets) {
          expect(socket.localPort, isNotNull);
        }

        for (final socket in sockets) {
          socket.close();
        }
      });

      test('should handle callback cleanup on close', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final address = InternetAddress.loopbackIPv4;
        int callCount = 0;

        socket.setMessageCallback(PeerInfo(address: address, port: 1234), (record) {
          callCount++;
        });

        socket.close();

        // After close, message callbacks should be cleared
        socket.testOnMessage([1, 2, 3], RemoteInfo(address: address, port: 1234));
        expect(callCount, equals(0));
      });
    });

    group('Edge Cases and Error Conditions', () {
      test('should handle binding to high port number', () async {
        const highPort = 60000;
        final socket =
            await ShspSocket.bind(InternetAddress.loopbackIPv4, highPort);
        expect(socket.localPort, equals(highPort));
        socket.close();
      });

      test('port 0 should use ephemeral port assignment', () async {
        final socket =
            await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        expect(socket.localPort, isNotNull);
        expect(socket.localPort! > 0, isTrue);
        expect(socket.localPort! < 65536, isTrue);
        socket.close();
      });

      test('localAddress should return bound address', () async {
        final address = InternetAddress.loopbackIPv4;
        final socket = await ShspSocket.bind(address, 0);
        expect(socket.localAddress, equals(address));
        socket.close();
      });

      test('should properly identify socket via serializedObject', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final serialized = socket.serializedObject();

        expect(serialized.contains('ShspSocket'), isTrue);
        expect(serialized.contains('127.0.0.1'), isTrue);
        expect(serialized.contains(socket.localPort.toString()), isTrue);

        socket.close();
      });

      test('should not interfere with socket property access after creation',
          () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final underlyingSocket = socket.socket;

        expect(underlyingSocket, isNotNull);
        expect(underlyingSocket.isBroadcast, isA<bool>());

        socket.close();
      });

      test('should handle calling setCloseCallback after initialization',
          () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        bool called = false;

        socket.setCloseCallback(() {
          called = true;
        });

        socket.onClose.call(null);
        expect(called, isTrue);

        socket.close();
      });

      test('should handle calling setErrorCallback after initialization',
          () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        bool called = false;

        socket.setErrorCallback((err) {
          called = true;
        });

        socket.onError.call(Exception('Test'));
        expect(called, isTrue);

        socket.close();
      });
    });

    group('Concurrent Operations', () {
      test('should handle concurrent callbacks from different sockets',
          () async {
        final socket1 = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final socket2 = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);

        bool callback1Called = false;
        bool callback2Called = false;

        socket1.setMessageCallback(PeerInfo(address: InternetAddress('127.0.0.1'), port: 5000), (record) {
          callback1Called = true;
        });

        socket2.setMessageCallback(PeerInfo(address: InternetAddress('127.0.0.1'), port: 6000), (record) {
          callback2Called = true;
        });

        socket1.testOnMessage([1], RemoteInfo(address: InternetAddress.loopbackIPv4, port: 5000));
        socket2.testOnMessage([2], RemoteInfo(address: InternetAddress.loopbackIPv4, port: 6000));

        expect(callback1Called, isTrue);
        expect(callback2Called, isTrue);

        socket1.close();
        socket2.close();
      });

      test('should handle rapid message sending', () async {
        final socket1 = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final socket2 = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final completer = Completer<void>();
        int messageCount = 0;

        socket2.setMessageCallback(
          PeerInfo(address: InternetAddress.loopbackIPv4, port: socket1.localPort!),
          (record) {
            messageCount++;
            if (messageCount == 5) {
              completer.complete();
            }
          },
        );

        for (int i = 0; i < 5; i++) {
          socket1.sendTo(
              [i], PeerInfo(address: InternetAddress.loopbackIPv4, port: socket2.localPort!));
          await Future.delayed(const Duration(milliseconds: 10));
        }

        await completer.future
            .timeout(const Duration(seconds: 5), onTimeout: () {
          fail(
              'Not all rapid messages received (got $messageCount/5)');
        });

        expect(messageCount, equals(5));

        socket1.close();
        socket2.close();
      });
    });

    group('State Preservation', () {
      test('localPort should remain constant after binding', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final port1 = socket.localPort;
        final port2 = socket.localPort;
        final port3 = socket.localPort;

        expect(port1, equals(port2));
        expect(port2, equals(port3));

        socket.close();
      });

      test('localAddress should remain constant after binding', () async {
        final address = InternetAddress.loopbackIPv4;
        final socket = await ShspSocket.bind(address, 0);
        final addr1 = socket.localAddress;
        final addr2 = socket.localAddress;

        expect(addr1, equals(addr2));
        expect(addr2, equals(address));

        socket.close();
      });
    });

    group('GZip Compression Tests', () {
      late ShspSocket socket1;
      late ShspSocket socket2;
      late InternetAddress address;

      setUp(() async {
        address = InternetAddress.loopbackIPv4;
        socket1 = await ShspSocket.bind(address, 0);
        socket2 = await ShspSocket.bind(address, 0);
      });

      tearDown(() {
        socket1.close();
        socket2.close();
      });

      test('data messages (0x00) are compressed and decompressed correctly', () async {
        // Create a large repetitive message to ensure good compression
        final originalMessage = List<int>.generate(500, (i) => 0x41); // 500 'A's
        final dataMessage = [0x00, ...originalMessage]; // Add data prefix
        final completer = Completer<void>();

        socket2.setMessageCallback(
          PeerInfo(address: address, port: socket1.localPort!),
          (record) {
            // Should receive the original uncompressed message with prefix
            expect(record.msg.length, equals(501)); // 1 (prefix) + 500
            expect(record.msg[0], equals(0x00)); // Data prefix
            expect(record.msg.sublist(1), equals(originalMessage));
            completer.complete();
          },
        );

        final bytesSent = socket1.sendTo(
          dataMessage,
          PeerInfo(address: address, port: socket2.localPort!),
        );

        // Bytes sent should be much less than 501 due to compression
        expect(bytesSent, lessThan(501));
        print('Compression: 501 bytes → $bytesSent bytes (${((1 - bytesSent / 501) * 100).toStringAsFixed(1)}% reduction)');

        await completer.future.timeout(const Duration(seconds: 2), onTimeout: () {
          fail('Data message not received');
        });
      });

      test('protocol messages (0x01-0x04) are NOT compressed', () async {
        final protocolMessages = [
          [0x01], // Handshake
          [0x02], // Closing
          [0x03], // Closed
          [0x04], // KeepAlive
        ];
        int receivedCount = 0;
        final completer = Completer<void>();

        socket2.setMessageCallback(
          PeerInfo(address: address, port: socket1.localPort!),
          (record) {
            // Protocol messages should pass through unchanged
            expect(record.msg.length, equals(1));
            expect([0x01, 0x02, 0x03, 0x04], contains(record.msg[0]));
            receivedCount++;
            if (receivedCount == 4) {
              completer.complete();
            }
          },
        );

        // Send all protocol messages
        for (final msg in protocolMessages) {
          socket1.sendTo(msg, PeerInfo(address: address, port: socket2.localPort!));
          await Future.delayed(const Duration(milliseconds: 50)); // Small delay between sends
        }

        await completer.future.timeout(const Duration(seconds: 2), onTimeout: () {
          fail('Protocol messages not received (received: $receivedCount/4)');
        });
      });
    });
  });
}
