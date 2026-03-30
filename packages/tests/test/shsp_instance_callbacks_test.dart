import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('ShspInstance callbacks', () {
    late ShspSocket socketA;
    late ShspSocket socketB;
    late PeerInfo peerInfoA;
    late PeerInfo peerInfoB;
    late ShspInstance instanceA;
    late ShspInstance instanceB;

    setUp(() async {
      final address = InternetAddress.loopbackIPv4;

      // Use ephemeral ports (0) to avoid conflicts when tests run in parallel
      socketA = await ShspSocket.bind(address, 0);
      socketB = await ShspSocket.bind(address, 0);

      // Read actual ports assigned by OS
      final portA = socketA.localPort!;
      final portB = socketB.localPort!;

      peerInfoA = PeerInfo(address: address, port: portA);
      peerInfoB = PeerInfo(address: address, port: portB);
      instanceA = ShspInstance(remotePeer: peerInfoB, socket: socketA);
      instanceB = ShspInstance(remotePeer: peerInfoA, socket: socketB);
    });

    tearDown(() async {
      socketA.close();
      socketB.close();
    });

    test('onHandshake callback is called when handshake is received', () async {
      bool handshakeCalled = false;
      int callCount = 0;

      // Register callback listener
      instanceA.onHandshake.register((_) {
        handshakeCalled = true;
        callCount++;
      });

      // Send handshake from B to A
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));

      expect(
        handshakeCalled,
        isTrue,
        reason:
            'onHandshake callback should be called when handshake is received',
      );
      expect(
        callCount,
        equals(1),
        reason: 'onHandshake callback should be called once',
      );
    });

    test('onOpen callback is called when connection is opened', () async {
      bool openCalled = false;
      int callCount = 0;

      // Register callback listener
      instanceA.onOpen.register((_) {
        openCalled = true;
        callCount++;
      });

      // Perform handshake to open connection (synchronized pattern)
      instanceA.sendHandshake();
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));
      instanceA.sendHandshake();
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));

      expect(
        openCalled,
        isTrue,
        reason: 'onOpen callback should be called when connection is opened',
      );
      expect(
        callCount,
        equals(1),
        reason: 'onOpen callback should be called once when connection opens',
      );
    });

    test(
      'onClosing callback is called when closing signal is received',
      () async {
        bool closingCalled = false;
        int callCount = 0;

        // First establish connection (synchronized pattern)
        instanceA.sendHandshake();
        instanceB.sendHandshake();
        await Future.delayed(const Duration(milliseconds: 500));
        instanceA.sendHandshake();
        instanceB.sendHandshake();
        await Future.delayed(const Duration(milliseconds: 500));

        // Register callback listener
        instanceA.onClosing.register((_) {
          closingCalled = true;
          callCount++;
        });

        // Send closing signal
        instanceB.sendClosing();
        await Future.delayed(const Duration(milliseconds: 500));

        expect(
          closingCalled,
          isTrue,
          reason:
              'onClosing callback should be called when closing signal is received',
        );
        expect(
          callCount,
          equals(1),
          reason: 'onClosing callback should be called once',
        );
      },
    );

    test('onClose callback is called when closed signal is received', () async {
      bool closeCalled = false;
      int callCount = 0;

      // First establish connection (synchronized pattern)
      instanceA.sendHandshake();
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));
      instanceA.sendHandshake();
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));

      // Register callback listener
      instanceA.onClose.register((_) {
        closeCalled = true;
        callCount++;
      });

      // Send closed signal
      instanceB.sendClosed();
      await Future.delayed(const Duration(milliseconds: 500));

      expect(
        closeCalled,
        isTrue,
        reason:
            'onClose callback should be called when closed signal is received',
      );
      expect(
        callCount,
        equals(1),
        reason: 'onClose callback should be called once',
      );
    });

    test('multiple callbacks can be registered on the same event', () async {
      int callCountCallback1 = 0;
      int callCountCallback2 = 0;

      // Register multiple callback listeners on same event
      instanceA.onHandshake.register((_) {
        callCountCallback1++;
      });
      instanceA.onHandshake.register((_) {
        callCountCallback2++;
      });

      // Send handshake from B to A
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));

      expect(
        callCountCallback1,
        equals(1),
        reason: 'First callback should be called once',
      );
      expect(
        callCountCallback2,
        equals(1),
        reason: 'Second callback should be called once',
      );
    });

    test('callbacks are called in the correct sequence', () async {
      final callSequence = <String>[];

      instanceA.onHandshake.register((_) {
        callSequence.add('handshake');
      });
      instanceA.onOpen.register((_) {
        callSequence.add('open');
      });
      instanceA.onClosing.register((_) {
        callSequence.add('closing');
      });
      instanceA.onClose.register((_) {
        callSequence.add('close');
      });

      // Handshake sequence (synchronized pattern)
      instanceA.sendHandshake();
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));
      instanceA.sendHandshake();
      instanceB.sendHandshake();
      await Future.delayed(const Duration(milliseconds: 500));

      // Closing sequence
      instanceB.sendClosing();
      await Future.delayed(const Duration(milliseconds: 500));
      instanceB.sendClosed();
      await Future.delayed(const Duration(milliseconds: 500));

      expect(
        callSequence,
        containsAll(['handshake', 'open', 'closing', 'close']),
        reason: 'All callbacks should be called',
      );
      // Verify order: handshake should come before open, closing before close
      expect(
        callSequence.indexOf('handshake'),
        lessThan(callSequence.indexOf('open')),
        reason: 'handshake callback should be called before open callback',
      );
      expect(
        callSequence.indexOf('closing'),
        lessThan(callSequence.indexOf('close')),
        reason: 'closing callback should be called before close callback',
      );
    });
  });
}
