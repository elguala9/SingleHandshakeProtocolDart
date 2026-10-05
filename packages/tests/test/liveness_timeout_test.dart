import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

/// Tests for the optional liveness timeout (Section 7 of the spec): a
/// session MAY be configured with a duration after which, if no message
/// (data, control or keep-alive) was received from the peer, the session is
/// closed locally on its own, following the same procedure as a local
/// close(), without waiting for a peer response.
void main() {
  group('ShspInstance liveness timeout', () {
    late ShspSocket socketA;
    late ShspSocket socketB;
    late PeerInfo peerInfoA;
    late PeerInfo peerInfoB;

    setUp(() async {
      final address = InternetAddress.loopbackIPv4;

      // Use ephemeral ports (0) to avoid conflicts when tests run in parallel
      socketA = await ShspSocket.bind(address, 0);
      socketB = await ShspSocket.bind(address, 0);

      final portA = socketA.localPort!;
      final portB = socketB.localPort!;

      peerInfoA = PeerInfo(address: address, port: portA);
      peerInfoB = PeerInfo(address: address, port: portB);
    });

    tearDown(() async {
      socketA.close();
      socketB.close();
    });

    test(
      'session closes itself after the liveness timeout with no incoming '
      'messages',
      () async {
        // B has liveness disabled so only A's self-close (triggered by its
        // own liveness timeout) is under test.
        final instanceA = ShspInstance(
          remotePeer: peerInfoB,
          socket: socketA,
          livenessTimeoutSeconds: 1,
        );
        final instanceB = ShspInstance(
          remotePeer: peerInfoA,
          socket: socketB,
          livenessTimeoutSeconds: null,
        );

        instanceB.sendHandshake();
        instanceA.sendHandshake();
        await Future.delayed(const Duration(milliseconds: 300));
        instanceB.sendHandshake();
        instanceA.sendHandshake();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(instanceA.open, isTrue);

        // No further message is sent by either peer: A must close itself
        // locally once its liveness timeout elapses.
        await Future.delayed(const Duration(milliseconds: 1300));

        expect(instanceA.open, isFalse);
      },
    );

    test(
      'liveness timeout resets on receiving any message type, not only '
      'keep-alive',
      () async {
        final instanceA = ShspInstance(
          remotePeer: peerInfoB,
          socket: socketA,
          livenessTimeoutSeconds: 1,
        );
        final instanceB = ShspInstance(
          remotePeer: peerInfoA,
          socket: socketB,
          livenessTimeoutSeconds: null,
        );

        // Complete the handshake so data messages can be exchanged.
        instanceB.sendHandshake();
        instanceA.sendHandshake();
        await Future.delayed(const Duration(milliseconds: 300));
        instanceB.sendHandshake();
        instanceA.sendHandshake();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(instanceA.open, isTrue);

        // Keep sending plain data messages (not keep-alive) from B to A more
        // often than A's 1s liveness timeout, for longer than that timeout,
        // and confirm A is never closed by it.
        for (var i = 0; i < 4; i++) {
          instanceB.sendMessage([i]);
          await Future.delayed(const Duration(milliseconds: 500));
        }
        expect(instanceA.open, isTrue);

        // Now stop sending anything and confirm A eventually closes itself.
        await Future.delayed(const Duration(milliseconds: 1300));
        expect(instanceA.open, isFalse);
      },
    );

    test(
      'session never closes itself for liveness when the timeout is '
      'disabled (null)',
      () async {
        final instanceA = ShspInstance(
          remotePeer: peerInfoB,
          socket: socketA,
          livenessTimeoutSeconds: null,
        );
        final instanceB = ShspInstance(
          remotePeer: peerInfoA,
          socket: socketB,
          livenessTimeoutSeconds: null,
        );

        instanceB.sendHandshake();
        instanceA.sendHandshake();
        await Future.delayed(const Duration(milliseconds: 300));
        instanceB.sendHandshake();
        instanceA.sendHandshake();
        await Future.delayed(const Duration(milliseconds: 300));
        expect(instanceA.open, isTrue);

        // Wait well past the short timeout used in the other tests above,
        // with no further messages: with liveness disabled nothing should
        // trigger a local self-close.
        await Future.delayed(const Duration(milliseconds: 1500));

        expect(instanceA.open, isTrue);
      },
    );
  });
}
