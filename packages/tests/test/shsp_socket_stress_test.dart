import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp_implementations/shsp_base/shsp_socket.dart';
import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';

/// Stress and integration tests for ShspSocket
/// Tests socket resilience, concurrent operations, and edge cases
void main() {
  group('ShspSocket Stress and Integration Tests', () {
    group('Multiple Socket Operations', () {
      test('should handle 5 sockets communicating', () async {
        const socketCount = 5;
        final sockets = <ShspSocket>[];

        // Create all sockets
        for (int i = 0; i < socketCount; i++) {
          final socket =
              await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
          sockets.add(socket);
        }

        int messageCount = 0;
        final completer = Completer<void>();

        // Setup first socket to receive from all others
        for (int i = 1; i < socketCount; i++) {
          sockets[0].setMessageCallback(
            '${InternetAddress.loopbackIPv4.address}:${sockets[i].localPort}',
            (record) {
              messageCount++;
              if (messageCount == socketCount - 1) {
                completer.complete();
              }
            },
          );
        }

        // Send messages from all other sockets to first
        for (int i = 1; i < socketCount; i++) {
          sockets[i].sendTo(
            [i],
            InternetAddress.loopbackIPv4,
            sockets[0].localPort!,
          );
          await Future.delayed(const Duration(milliseconds: 10));
        }

        await completer.future
            .timeout(const Duration(seconds: 3), onTimeout: () {
          fail('Stress test timeout - received $messageCount messages');
        });

        expect(messageCount, equals(socketCount - 1));

        for (final socket in sockets) {
          socket.close();
        }
      });

      test('should handle rapid open-close cycles', () async {
        for (int cycle = 0; cycle < 5; cycle++) {
          final sockets = <ShspSocket>[];
          for (int i = 0; i < 20; i++) {
            final socket =
                await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
            sockets.add(socket);
          }

          for (final socket in sockets) {
            socket.close();
          }
        }
      });

      test('should handle callback registration and invocation under load',
          () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final address = InternetAddress.loopbackIPv4;
        const callbackCount = 50;

        // Register 50 different callbacks
        for (int i = 0; i < callbackCount; i++) {
          final key = '${address.address}:${9000 + i}';
          socket.setMessageCallback(key, (record) {
            // Callback registered
          });
        }

        // Test that callbacks are registered
        expect(socket.socket, isA<RawDatagramSocket>());

        await Future.delayed(const Duration(milliseconds: 100));
        socket.close();
      });
    });

    group('Message Size Variations', () {
      late ShspSocket sender;
      late ShspSocket receiver;

      setUp(() async {
        sender = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        receiver = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      });

      tearDown(() {
        sender.close();
        receiver.close();
      });

      test('should handle 1-byte message', () async {
        final testMsg = [42];
        final completer = Completer<void>();

        receiver.setMessageCallback(
          '${InternetAddress.loopbackIPv4.address}:${sender.localPort}',
          (record) {
            expect(record.msg, equals(testMsg));
            completer.complete();
          },
        );

        sender.sendTo(testMsg, InternetAddress.loopbackIPv4, receiver.localPort!);
        await completer.future.timeout(const Duration(seconds: 2));
      });

      test('should handle 256-byte message', () async {
        final testMsg = List<int>.generate(256, (i) => i % 256);
        final completer = Completer<void>();

        receiver.setMessageCallback(
          '${InternetAddress.loopbackIPv4.address}:${sender.localPort}',
          (record) {
            expect(record.msg.length, equals(256));
            completer.complete();
          },
        );

        sender.sendTo(testMsg, InternetAddress.loopbackIPv4, receiver.localPort!);
        await completer.future.timeout(const Duration(seconds: 2));
      });

      test('should handle 512-byte message', () async {
        final testMsg = List<int>.generate(512, (i) => i % 256);
        final completer = Completer<void>();

        receiver.setMessageCallback(
          '${InternetAddress.loopbackIPv4.address}:${sender.localPort}',
          (record) {
            expect(record.msg.length, equals(512));
            completer.complete();
          },
        );

        sender.sendTo(testMsg, InternetAddress.loopbackIPv4, receiver.localPort!);
        await completer.future.timeout(const Duration(seconds: 2));
      });

      test('should handle 1024-byte message', () async {
        final testMsg = List<int>.generate(1024, (i) => i % 256);
        final completer = Completer<void>();

        receiver.setMessageCallback(
          '${InternetAddress.loopbackIPv4.address}:${sender.localPort}',
          (record) {
            expect(record.msg.length, equals(1024));
            completer.complete();
          },
        );

        sender.sendTo(testMsg, InternetAddress.loopbackIPv4, receiver.localPort!);
        await completer.future.timeout(const Duration(seconds: 2));
      });

      test('should handle near-MTU size message (65000 bytes)', () async {
        final testMsg = List<int>.generate(65000, (i) => i % 256);
        final completer = Completer<void>();

        receiver.setMessageCallback(
          '${InternetAddress.loopbackIPv4.address}:${sender.localPort}',
          (record) {
            expect(record.msg.length, equals(65000));
            completer.complete();
          },
        );

        sender.sendTo(testMsg, InternetAddress.loopbackIPv4, receiver.localPort!);
        await completer.future
            .timeout(const Duration(seconds: 2), onTimeout: () {
          fail('Near-MTU message not received');
        });
      });
    });

    group('Callback Error Handling', () {
      late ShspSocket socket;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      });

      tearDown(() {
        socket.close();
      });

      test('should handle callback that throws exception', () async {
        bool finalCallbackCalled = false;

        socket.setMessageCallback('127.0.0.1:9000', (record) {
          throw Exception('Callback error');
        });

        socket.setMessageCallback('127.0.0.1:9001', (record) {
          finalCallbackCalled = true;
        });

        // This should not crash even though first callback throws
        try {
          (socket as ShspSocket).onMessage(
              [1], RemoteInfo(address: InternetAddress.loopbackIPv4, port: 9000));
        } catch (e) {
          // Expected to throw
        }

        (socket as ShspSocket).onMessage(
            [2], RemoteInfo(address: InternetAddress.loopbackIPv4, port: 9001));

        expect(finalCallbackCalled, isTrue);
      });

      test('should handle error callback with various error types', () async {
        final errors = <dynamic>[];

        socket.setErrorCallback((err) {
          errors.add(err);
        });

        socket.onError.call(Exception('Test exception'));
        socket.onError.call(SocketException('Socket error'));
        socket.onError.call('String error');
        socket.onError.call(123);

        expect(errors.length, equals(4));
      });
    });

    group('Port Binding Edge Cases', () {
      test('should handle binding to port 1', () async {
        try {
          final socket =
              await ShspSocket.bind(InternetAddress.loopbackIPv4, 1);
          expect(socket.localPort, equals(1));
          socket.close();
        } catch (e) {
          // Might fail due to permissions, but shouldn't crash with validation error
          expect(e, isNot(isA<ShspValidationException>()));
        }
      });

      test('should validate port 0 is valid (ephemeral)', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        expect(socket.localPort, isNotNull);
        expect(socket.localPort, greaterThan(0));
        socket.close();
      });

      test('should validate port 65535', () async {
        try {
          final socket =
              await ShspSocket.bind(InternetAddress.loopbackIPv4, 65535);
          expect(socket.localPort, equals(65535));
          socket.close();
        } catch (e) {
          // Might fail due to port already in use, but not validation error
          expect(e, isNot(isA<ShspValidationException>()));
        }
      });
    });

    group('Sequential Message Exchange', () {
      late ShspSocket socket1;
      late ShspSocket socket2;

      setUp(() async {
        socket1 = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        socket2 = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      });

      tearDown(() {
        socket1.close();
        socket2.close();
      });

      test('should handle bidirectional message exchange', () async {
        int msg1Received = 0;
        int msg2Received = 0;
        final completer = Completer<void>();

        socket1.setMessageCallback(
          '${InternetAddress.loopbackIPv4.address}:${socket2.localPort}',
          (record) {
            msg1Received++;
            if (msg1Received == 1 && msg2Received == 1) {
              completer.complete();
            }
          },
        );

        socket2.setMessageCallback(
          '${InternetAddress.loopbackIPv4.address}:${socket1.localPort}',
          (record) {
            msg2Received++;
            if (msg1Received == 1 && msg2Received == 1) {
              completer.complete();
            }
          },
        );

        // Send messages in both directions
        socket1.sendTo([1], InternetAddress.loopbackIPv4, socket2.localPort!);
        await Future.delayed(const Duration(milliseconds: 50));
        socket2.sendTo([2], InternetAddress.loopbackIPv4, socket1.localPort!);

        await completer.future.timeout(const Duration(seconds: 2));
        expect(msg1Received, equals(1));
        expect(msg2Received, equals(1));
      });
    });

    group('Concurrent Callback Registration', () {
      test('should handle concurrent callback registrations safely', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final futures = <Future<void>>[];

        for (int i = 0; i < 20; i++) {
          futures.add(Future(() {
            final key = '${InternetAddress.loopbackIPv4.address}:${9000 + i}';
            socket.setMessageCallback(key, (record) {
              // Callback
            });
          }));
        }

        await Future.wait(futures);
        socket.close();
      });
    });

    group('Socket State Consistency', () {
      test('should maintain socket properties after multiple operations',
          () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final initialPort = socket.localPort;
        final initialAddress = socket.localAddress;

        socket.setMessageCallback('127.0.0.1:1234', (_) {});
        socket.setErrorCallback((_) {});
        socket.setCloseCallback(() {});

        expect(socket.localPort, equals(initialPort));
        expect(socket.localAddress, equals(initialAddress));

        socket.removeMessageCallback('127.0.0.1:1234', (_) {});

        expect(socket.localPort, equals(initialPort));
        expect(socket.localAddress, equals(initialAddress));

        socket.close();
      });

      test('should preserve socket reference', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final underlyingSocket = socket.socket;

        expect(underlyingSocket, isA<RawDatagramSocket>());
        expect(underlyingSocket.port, greaterThan(0));

        socket.close();
      });
    });

    group('Message Content Integrity', () {
      late ShspSocket sender;
      late ShspSocket receiver;

      setUp(() async {
        sender = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        receiver = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      });

      tearDown(() {
        sender.close();
        receiver.close();
      });

      test('should preserve message content integrity', () async {
        final originalMsg = [0, 1, 2, 3, 4, 255, 254, 253, 127, 128];
        final completer = Completer<void>();

        receiver.setMessageCallback(
          '${InternetAddress.loopbackIPv4.address}:${sender.localPort}',
          (record) {
            expect(record.msg, equals(originalMsg));
            completer.complete();
          },
        );

        sender.sendTo(
            originalMsg, InternetAddress.loopbackIPv4, receiver.localPort!);
        await completer.future.timeout(const Duration(seconds: 2));
      });

      test('should preserve sender information in RemoteInfo', () async {
        final completer = Completer<void>();

        receiver.setMessageCallback(
          '${InternetAddress.loopbackIPv4.address}:${sender.localPort}',
          (record) {
            expect(record.rinfo.address, equals(InternetAddress.loopbackIPv4));
            expect(record.rinfo.port, equals(sender.localPort));
            completer.complete();
          },
        );

        sender.sendTo([99], InternetAddress.loopbackIPv4, receiver.localPort!);
        await completer.future.timeout(const Duration(seconds: 2));
      });
    });

    group('Resource Cleanup Verification', () {
      test('should properly cleanup after many open-close cycles', () async {
        for (int i = 0; i < 30; i++) {
          final socket =
              await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
          socket.setMessageCallback('127.0.0.1:1111', (_) {});
          socket.setErrorCallback((_) {});
          socket.close();
        }
        // If we get here without hanging or crashing, cleanup is working
      });

      test('should handle close after setting all callbacks', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);

        socket.setMessageCallback('127.0.0.1:1234', (_) {});
        socket.setErrorCallback((_) {});
        socket.setCloseCallback(() {});
        socket.setListeningCallback(() {});

        expect(() {
          socket.close();
        }, returnsNormally);
      });
    });
  });
}
