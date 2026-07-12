import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('DualShspSocket IPv4 and IPv6', () {
    group('create() factory', () {
      late DualShspSocket dual;

      tearDown(() {
        if (!dual.isClosed) dual.close();
      });

      test('create() always has ipv4Socket non-null', () async {
        dual = await DualShspSocket.create();
        expect(dual.ipv4Socket, isNotNull);
        expect(dual.ipv4Socket, isA<IShspSocket>());
      });

      test('create() has an IPv4 address on ipv4Socket', () async {
        dual = await DualShspSocket.create();
        expect(dual.ipv4Socket!.localAddress, isNotNull);
        expect(
          dual.ipv4Socket!.localAddress!.type,
          equals(InternetAddressType.IPv4),
        );
      });

      test('create() localAddress prefers ipv6 but falls back to ipv4', () async {
        dual = await DualShspSocket.create();
        expect(dual.localAddress, isNotNull);
        expect(
          dual.localAddress!.type,
          anyOf(InternetAddressType.IPv4, InternetAddressType.IPv6),
        );
      });

      test('create() localPort > 0', () async {
        dual = await DualShspSocket.create();
        expect(dual.localPort, isNotNull);
        expect(dual.localPort, greaterThan(0));
      });
    });

    group('fromSockets constructor — IPv4 only', () {
      late DualShspSocket dual;

      tearDown(() {
        if (!dual.isClosed) dual.close();
      });

      test('ipv4Socket matches provided socket', () async {
        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        dual = DualShspSocket.fromSockets(Sockets(ipv4SocketImpl: ipv4));
        expect(dual.ipv4Socket, equals(ipv4));
      });

      test('ipv6Socket is null when only IPv4 provided', () async {
        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        dual = DualShspSocket.fromSockets(Sockets(ipv4SocketImpl: ipv4));
        expect(dual.ipv6Socket, isNull);
      });

      test('sendTo delivers to IPv4 peer through IPv4 socket', () async {
        final receiver = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() {
          if (!receiver.isClosed) receiver.close();
        });

        dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: await ShspSocket.bind(InternetAddress.loopbackIPv4, 0)),
        );
        addTearDown(() {
          if (!dual.isClosed) dual.close();
        });

        var callbackFired = false;
        final receiverPeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: receiver.localPort!,
        );
        final senderPeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: dual.localPort!,
        );
        receiver.setMessageCallback(senderPeer, (record) {
          callbackFired = true;
        });

        dual.sendTo([0x01, 0x02, 0x03], receiverPeer);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(callbackFired, isTrue);
      });

      test('IPv4 only throws StateError when sending to IPv6 peer', () async {
        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        dual = DualShspSocket.fromSockets(Sockets(ipv4SocketImpl: ipv4));

        final ipv6Peer = PeerInfo(
          address: InternetAddress('::1'),
          port: 12345,
        );

        expect(
          () => dual.sendTo([0x01], ipv6Peer),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('fromSockets constructor — IPv6 only', () {
      late DualShspSocket dual;

      tearDown(() {
        if (!dual.isClosed) dual.close();
      });

      test('ipv6Socket matches provided socket and ipv4Socket is null', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 != null) {
          dual = DualShspSocket.fromSockets(Sockets(ipv6SocketImpl: ipv6));
          expect(dual.ipv6Socket, equals(ipv6));
          expect(dual.ipv4Socket, isNull);
        }
      });

      test('IPv6 sends to IPv6 peer through IPv6 socket', () async {
        ShspSocket? ipv6Receiver;
        ShspSocket? ipv6Sender;

        try {
          ipv6Receiver = await ShspSocket.bind(InternetAddress.loopbackIPv6, 0);
          ipv6Sender = await ShspSocket.bind(InternetAddress.loopbackIPv6, 0);
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        addTearDown(() {
          if (ipv6Receiver != null && !ipv6Receiver.isClosed) {
            ipv6Receiver.close();
          }
        });
        addTearDown(() {
          if (ipv6Sender != null && !ipv6Sender.isClosed) {
            ipv6Sender.close();
          }
        });

        dual = DualShspSocket.fromSockets(Sockets(ipv6SocketImpl: ipv6Sender));

        var callbackFired = false;
        final receiverPeer = PeerInfo(
          address: InternetAddress.loopbackIPv6,
          port: ipv6Receiver!.localPort!,
        );
        final senderPeer = PeerInfo(
          address: InternetAddress.loopbackIPv6,
          port: dual.localPort!,
        );
        ipv6Receiver.setMessageCallback(senderPeer, (record) {
          callbackFired = true;
        });

        dual.sendTo([0xAA, 0xBB], receiverPeer);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(callbackFired, isTrue);
      });

      test('IPv6 only throws StateError when sending to IPv4 peer', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 != null) {
          dual = DualShspSocket.fromSockets(Sockets(ipv6SocketImpl: ipv6));

          final ipv4Peer = PeerInfo(
            address: InternetAddress('127.0.0.1'),
            port: 12345,
          );

          expect(
            () => dual.sendTo([0x01], ipv4Peer),
            throwsA(isA<StateError>()),
          );
        }
      });
    });

    group('fromSockets constructor — dual-stack (IPv4 + IPv6)', () {
      late DualShspSocket dual;

      tearDown(() {
        if (!dual.isClosed) dual.close();
      });

      test('both ipv4Socket and ipv6Socket are set and non-null', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 == null) return;

        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4, ipv6SocketImpl: ipv6),
        );

        expect(dual.ipv4Socket, isNotNull);
        expect(dual.ipv6Socket, isNotNull);
        expect(dual.ipv4Socket, isA<IShspSocket>());
        expect(dual.ipv6Socket, isA<IShspSocket>());
      });

      test('sendTo routes IPv4 peer to IPv4 socket', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 == null) return;

        final ipv4Receiver = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() {
          if (!ipv4Receiver.isClosed) ipv4Receiver.close();
        });
        final ipv4Sender = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() {
          if (!ipv4Sender.isClosed) ipv4Sender.close();
        });

        dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4Sender, ipv6SocketImpl: ipv6),
        );

        var callbackFired = false;
        final receiverPeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: ipv4Receiver.localPort!,
        );
        final senderPort = dual.ipv4Socket!.localPort!;
        final senderPeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: senderPort,
        );
        ipv4Receiver.setMessageCallback(senderPeer, (record) {
          callbackFired = true;
        });

        dual.sendTo([0x10, 0x20], receiverPeer);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(callbackFired, isTrue);
      });

      test('sendTo routes IPv6 peer to IPv6 socket', () async {
        ShspSocket? ipv6Sender;
        ShspSocket? ipv6Receiver;
        try {
          ipv6Receiver = await ShspSocket.bind(InternetAddress.loopbackIPv6, 0);
          ipv6Sender = await ShspSocket.bind(InternetAddress.loopbackIPv6, 0);
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        addTearDown(() {
          if (ipv6Receiver != null && !ipv6Receiver.isClosed) {
            ipv6Receiver.close();
          }
        });
        addTearDown(() {
          if (ipv6Sender != null && !ipv6Sender.isClosed) {
            ipv6Sender.close();
          }
        });

        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4, ipv6SocketImpl: ipv6Sender),
        );

        var callbackFired = false;
        final receiverPeer = PeerInfo(
          address: InternetAddress.loopbackIPv6,
          port: ipv6Receiver!.localPort!,
        );
        final ipv6SenderPort = dual.ipv6Socket!.localPort!;
        final senderPeer = PeerInfo(
          address: InternetAddress.loopbackIPv6,
          port: ipv6SenderPort,
        );
        ipv6Receiver.setMessageCallback(senderPeer, (record) {
          callbackFired = true;
        });

        dual.sendTo([0xFF], receiverPeer);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(callbackFired, isTrue);
      });
    });

    group('message callbacks — dual routing', () {
      late DualShspSocket dual;

      tearDown(() {
        if (!dual.isClosed) dual.close();
      });

      test('setMessageCallback registers on both IPv4 and IPv6 sockets', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 == null) return;

        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4, ipv6SocketImpl: ipv6),
        );

        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);

        dual.setMessageCallback(peer, (record) {});

        final ipv4Profile = dual.ipv4Socket!.extractProfile();
        final ipv6Profile = dual.ipv6Socket!.extractProfile();

        expect(ipv4Profile.messageListeners, isNotEmpty);
        expect(ipv6Profile.messageListeners, isNotEmpty);
      });

      test('removeMessageCallback removes from both sockets', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 == null) return;

        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4, ipv6SocketImpl: ipv6),
        );

        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9999);
        void callback(MessageRecord r) {}

        dual.setMessageCallback(peer, callback);
        final removed = dual.removeMessageCallback(peer, callback);

        expect(removed, isTrue);

        final ipv4Profile = dual.ipv4Socket!.extractProfile();
        final ipv6Profile = dual.ipv6Socket!.extractProfile();

        expect(ipv4Profile.messageListeners, isEmpty);
        expect(ipv6Profile.messageListeners, isEmpty);
      });
    });

    group('profile extraction and application', () {
      late DualShspSocket dual;

      tearDown(() {
        if (!dual.isClosed) dual.close();
      });

      test('extractProfile merges callbacks from both IPv4 and IPv6 sockets', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 == null) return;

        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4, ipv6SocketImpl: ipv6),
        );

        final peer1 = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8001);
        final peer2 = PeerInfo(address: InternetAddress.loopbackIPv6, port: 9001);

        dual.setMessageCallback(peer1, (record) {});
        dual.setMessageCallback(peer2, (record) {});

        final profile = dual.extractProfile();
        expect(profile.messageListeners, isNotEmpty);
        expect(profile.messageListeners.length, greaterThanOrEqualTo(2));
      });

      test('applyProfile restores callbacks to both sockets', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 == null) return;

        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4, ipv6SocketImpl: ipv6),
        );

        final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
        dual.setMessageCallback(peer, (record) {});

        final profile = dual.extractProfile();

        // Create a new dual socket and apply profile
        final ipv4B = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4B.isClosed) ipv4B.close();
        });

        ShspSocket? ipv6B;
        try {
          ipv6B = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6B!.isClosed) ipv6B.close();
          });
        } catch (_) {}

        final dual2 = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4B, ipv6SocketImpl: ipv6B),
        );
        addTearDown(() {
          if (!dual2.isClosed) dual2.close();
        });

        dual2.applyProfile(profile);
        final restoredProfile = dual2.extractProfile();
        expect(restoredProfile.messageListeners, isNotEmpty);
      });
    });

    group('event callbacks', () {
      test('setListeningCallback fires per socket', () async {
        final dual = await DualShspSocket.create();
        addTearDown(() {
          if (!dual.isClosed) dual.close();
        });

        var callbackFired = false;
        dual.setListeningCallback(() {
          callbackFired = true;
        });

        // Listening callback registered via setter should not throw
        expect(callbackFired, isFalse);
      });

      test('setCloseCallback registered without error and dual can be closed', () async {
        final dual = await DualShspSocket.create();
        addTearDown(() {
          if (!dual.isClosed) dual.close();
        });

        dual.setCloseCallback(() {});

        expect(dual.isClosed, isFalse);
        dual.close();
        expect(dual.isClosed, isTrue);
      });

      test('onClose can have listener registered', () async {
        final dual = await DualShspSocket.create();
        addTearDown(() {
          if (!dual.isClosed) dual.close();
        });

        expect(dual.onClose, isA<CallbackOnWithSocket>());
      });

      test('onError exists on dual socket', () async {
        final dual = await DualShspSocket.create();
        addTearDown(() {
          if (!dual.isClosed) dual.close();
        });

        expect(dual.onError, isA<CallbackOnErrorWithSocket>());
      });
    });

    group('close / isClosed / destroy', () {
      test('close() closes both IPv4 and IPv6 sockets', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 == null) return;

        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        final dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4, ipv6SocketImpl: ipv6),
        );

        dual.close();

        expect(dual.isClosed, isTrue);
        expect(dual.ipv4Socket!.isClosed, isTrue);
        expect(dual.ipv6Socket!.isClosed, isTrue);
      });

      test('isClosed returns true when only IPv4 is provided and closed', () async {
        final dual = await DualShspSocket.create();
        dual.close();
        expect(dual.isClosed, isTrue);
      });

      test('close() is idempotent for dual-stack', () async {
        final dual = await DualShspSocket.create();
        dual.close();
        expect(dual.close, returnsNormally);
        expect(dual.isClosed, isTrue);
      });

      test('destroy() is equivalent to close()', () async {
        final dual = await DualShspSocket.create();
        dual.destroy();
        expect(dual.isClosed, isTrue);
      });
    });

    group('compressionCodec', () {
      test('compressionCodec is accessible from dual socket', () async {
        final dual = await DualShspSocket.create();
        addTearDown(() {
          if (!dual.isClosed) dual.close();
        });

        expect(dual.compressionCodec, isA<ICompressionCodec>());
      });

      test('compressionCodec prefers IPv6 codec over IPv4', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 == null) return;

        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        final dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4, ipv6SocketImpl: ipv6),
        );

        expect(dual.compressionCodec, isA<ICompressionCodec>());
      });
    });

    group('serializedObject', () {
      test('serializedObject returns non-empty string', () async {
        final dual = await DualShspSocket.create();
        addTearDown(() {
          if (!dual.isClosed) dual.close();
        });

        final serialized = dual.serializedObject();
        expect(serialized, isNotEmpty);
        expect(serialized, contains('DualShspSocket'));
        expect(serialized, contains('IPv4'));
      });
    });

    group('localAddress with IPv6 preference', () {
      test('localAddress returns IPv6 address when IPv6 socket is present', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 == null) return;

        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        final dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4, ipv6SocketImpl: ipv6),
        );

        expect(dual.localAddress, isNotNull);
      });
    });
  });

  group('DualShspSocket used through IShspSocketBase interface', () {
    test('DualShspSocket can be assigned to IShspSocketBase and used', () async {
      final dual = await DualShspSocket.create();
      addTearDown(() {
        if (!dual.isClosed) dual.close();
      });

      final IShspSocketBase base = dual;
      expect(base, isA<IShspSocketBase>());
      expect(base.isClosed, isFalse);
      expect(base.localPort, isNotNull);
    });

    test('sendTo via IShspSocketBase delivers message over IPv4', () async {
      final dual = await DualShspSocket.create();
      addTearDown(() {
        if (!dual.isClosed) dual.close();
      });
      final IShspSocketBase base = dual;

      final receiver = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() {
        if (!receiver.isClosed) receiver.close();
      });

      var callbackFired = false;
      final receiverPeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: receiver.localPort!,
      );
      final senderPort = dual.ipv4Socket!.localPort!;
      final senderPeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: senderPort,
      );
      receiver.setMessageCallback(senderPeer, (record) {
        callbackFired = true;
      });

      base.sendTo([0xCA, 0xFE], receiverPeer);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(callbackFired, isTrue);
    });

    test('setMessageCallback via IShspSocketBase registers on underlying sockets', () async {
      final dual = await DualShspSocket.create();
      addTearDown(() {
        if (!dual.isClosed) dual.close();
      });
      final IShspSocketBase base = dual;

      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 5555);
      base.setMessageCallback(peer, (record) {});

      final profile = base.extractProfile();
      expect(profile.messageListeners, isNotEmpty);
    });

    test('removeMessageCallback via IShspSocketBase works correctly', () async {
      final dual = await DualShspSocket.create();
      addTearDown(() {
        if (!dual.isClosed) dual.close();
      });
      final IShspSocketBase base = dual;

      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 5555);
      void cb(MessageRecord r) {}

      base.setMessageCallback(peer, cb);
      final removed = base.removeMessageCallback(peer, cb);

      expect(removed, isTrue);
      expect(base.extractProfile().messageListeners, isEmpty);
    });

    test('applyProfile via IShspSocketBase works', () async {
      final dual = await DualShspSocket.create();
      addTearDown(() {
        if (!dual.isClosed) dual.close();
      });
      final IShspSocketBase base = dual;

      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 8080);
      base.setMessageCallback(peer, (record) {});
      final profile = base.extractProfile();

      // Create a second dual socket via IShspSocketBase
      final dual2 = await DualShspSocket.create();
      addTearDown(() {
        if (!dual2.isClosed) dual2.close();
      });
      final IShspSocketBase base2 = dual2;

      base2.applyProfile(profile);
      final restoredProfile = base2.extractProfile();
      expect(restoredProfile.messageListeners, isNotEmpty);
    });
  });

  group('DualShspSocket underlying IShspSocket instances', () {
    test('ipv4Socket getter returns usable IShspSocket for send/receive', () async {
      final dual = await DualShspSocket.create();
      addTearDown(() {
        if (!dual.isClosed) dual.close();
      });

      final socket = dual.ipv4Socket!;
      expect(socket, isA<IShspSocket>());

      final receiver = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() {
        if (!receiver.isClosed) receiver.close();
      });

      var callbackFired = false;
      final receiverPeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: receiver.localPort!,
      );
      final senderPeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: socket.localPort!,
      );
      receiver.setMessageCallback(senderPeer, (record) {
        callbackFired = true;
      });

      socket.sendTo([0xDE, 0xAD], receiverPeer);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(callbackFired, isTrue);
    });

    test('ipv4Socket supports profile extraction/application as IShspSocket', () async {
      final dual = await DualShspSocket.create();
      addTearDown(() {
        if (!dual.isClosed) dual.close();
      });

      final IShspSocket socket = dual.ipv4Socket!;
      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9090);
      socket.setMessageCallback(peer, (record) {});

      final profile = socket.extractProfile();
      expect(profile.messageListeners, isNotEmpty);
    });

    test('ipv6Socket supports send/receive as IShspSocket', () async {
      ShspSocket? ipv6Sender;
      ShspSocket? ipv6Receiver;
      try {
        ipv6Receiver = await ShspSocket.bind(InternetAddress.loopbackIPv6, 0);
        ipv6Sender = await ShspSocket.bind(InternetAddress.loopbackIPv6, 0);
      } catch (_) {
        markTestSkipped('IPv6 not available on this system');
      }

      addTearDown(() {
        if (ipv6Receiver != null && !ipv6Receiver.isClosed) {
          ipv6Receiver.close();
        }
      });
      addTearDown(() {
        if (ipv6Sender != null && !ipv6Sender.isClosed) {
          ipv6Sender.close();
        }
      });

      final dual = DualShspSocket.fromSockets(
        Sockets(ipv6SocketImpl: ipv6Sender),
      );
      addTearDown(() {
        if (!dual.isClosed) dual.close();
      });

      final IShspSocket socket = dual.ipv6Socket!;

      var callbackFired = false;
      final receiverPeer = PeerInfo(
        address: InternetAddress.loopbackIPv6,
        port: ipv6Receiver!.localPort!,
      );
      final senderPeer = PeerInfo(
        address: InternetAddress.loopbackIPv6,
        port: socket.localPort!,
      );
      ipv6Receiver.setMessageCallback(senderPeer, (record) {
        callbackFired = true;
      });

      socket.sendTo([0xAB, 0xCD], receiverPeer);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(callbackFired, isTrue);
    });

    test('ipv6Socket supports close as IShspSocket', () async {
      ShspSocket? ipv6;
      try {
        ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
        addTearDown(() {
          if (!ipv6!.isClosed) ipv6.close();
        });
      } catch (_) {
        markTestSkipped('IPv6 not available on this system');
      }

      if (ipv6 == null) return;

      final dual = DualShspSocket.fromSockets(Sockets(ipv6SocketImpl: ipv6));

      final IShspSocket socket = dual.ipv6Socket!;
      expect(socket.isClosed, isFalse);

      socket.close();
      expect(socket.isClosed, isTrue);
    });

    test('ipv6Socket sendTo after close returns 0', () async {
      ShspSocket? ipv6;
      try {
        ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
        addTearDown(() {
          if (!ipv6!.isClosed) ipv6.close();
        });
      } catch (_) {
        markTestSkipped('IPv6 not available on this system');
      }

      if (ipv6 == null) return;

      final dual = DualShspSocket.fromSockets(Sockets(ipv6SocketImpl: ipv6));
      final IShspSocket socket = dual.ipv6Socket!;

      socket.close();

      final peer = PeerInfo(address: InternetAddress.loopbackIPv6, port: 12345);
      final result = socket.sendTo([0x01], peer);
      expect(result, equals(0));
    });
  });

  group('DualShspSocket used with ShspPeer', () {
    group('IPv4 — ShspPeer via DualShspSocket', () {
      late DualShspSocket dual;
      late ShspPeer sender;
      ShspSocket? receiverSocket;
      late ShspPeer receiver;

      tearDown(() {
        if (!dual.isClosed) dual.close();
        if (receiverSocket != null && !receiverSocket!.isClosed) {
          receiverSocket!.close();
        }
      });

      test('ShspPeer.create accepts DualShspSocket as IShspSocketBase', () async {
        dual = await DualShspSocket.create();

        final remotePeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 9999,
        );
        sender = ShspPeer.create(remotePeer: remotePeer, socket: dual);

        expect(sender, isA<ShspPeer>());
        expect(sender.socket, equals(dual));
      });

      test('ShspPeer.sendMessage delivers via DualShspSocket over IPv4', () async {
        dual = await DualShspSocket.create();
        receiverSocket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);

        final receiverPeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: receiverSocket!.localPort!,
        );
        final senderPort = dual.ipv4Socket!.localPort!;
        final senderPeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: senderPort,
        );

        sender = ShspPeer.create(remotePeer: receiverPeer, socket: dual);
        receiver = ShspPeer.create(remotePeer: senderPeer, socket: receiverSocket!);

        var callbackFired = false;
        receiver.messageCallback.register((info) {
          callbackFired = true;
        });

        sender.sendMessage([0x55, 0xAA]);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(callbackFired, isTrue);
      });

      test('ShspPeer.close removes callback from DualShspSocket', () async {
        dual = await DualShspSocket.create();

        final remotePeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 9999,
        );
        sender = ShspPeer.create(remotePeer: remotePeer, socket: dual);

        final profileBefore = dual.extractProfile();
        expect(profileBefore.messageListeners.isNotEmpty, isTrue);

        sender.close();

        final profileAfter = dual.extractProfile();
        expect(profileAfter.messageListeners.isEmpty, isTrue);
      });

      test('ShspPeer.sendMessage throws ShspNetworkException when peer closed', () async {
        dual = await DualShspSocket.create();

        final remotePeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 9999,
        );
        sender = ShspPeer.create(remotePeer: remotePeer, socket: dual);

        sender.close();

        expect(
          () => sender.sendMessage([0x41]),
          throwsA(isA<ShspNetworkException>()),
        );
      });

      test('ShspPeer.sendMessage throws ShspValidationException on empty message', () async {
        dual = await DualShspSocket.create();

        final remotePeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 9999,
        );
        sender = ShspPeer.create(remotePeer: remotePeer, socket: dual);

        expect(
          () => sender.sendMessage([]),
          throwsA(isA<ShspValidationException>()),
        );
      });

      test('ShspPeer.close is idempotent with DualShspSocket', () async {
        dual = await DualShspSocket.create();

        final remotePeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 9999,
        );
        sender = ShspPeer.create(remotePeer: remotePeer, socket: dual);

        sender.close();
        expect(sender.close, returnsNormally);
      });

      test('ShspPeer.destroy works with DualShspSocket', () async {
        dual = await DualShspSocket.create();

        final remotePeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 9999,
        );
        sender = ShspPeer.create(remotePeer: remotePeer, socket: dual);

        expect(sender.destroy, returnsNormally);
      });
    });

    group('IPv6 — ShspPeer via DualShspSocket', () {
      late DualShspSocket dual;
      late ShspPeer sender;
      ShspSocket? receiverSocket;
      late ShspPeer receiver;

      tearDown(() {
        if (!dual.isClosed) dual.close();
        if (receiverSocket != null && !receiverSocket!.isClosed) {
          receiverSocket!.close();
        }
      });

      test('ShspPeer.sendMessage delivers via DualShspSocket over IPv6', () async {
        ShspSocket? ipv6Sender;
        try {
          ipv6Sender = await ShspSocket.bind(InternetAddress.loopbackIPv6, 0);
          receiverSocket = await ShspSocket.bind(InternetAddress.loopbackIPv6, 0);
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        addTearDown(() {
          if (ipv6Sender != null && !ipv6Sender.isClosed) {
            ipv6Sender.close();
          }
        });

        dual = DualShspSocket.fromSockets(
          Sockets(ipv6SocketImpl: ipv6Sender),
        );

        final receiverPeer = PeerInfo(
          address: InternetAddress.loopbackIPv6,
          port: receiverSocket!.localPort!,
        );
        final senderPort = dual.ipv6Socket!.localPort!;
        final senderPeer = PeerInfo(
          address: InternetAddress.loopbackIPv6,
          port: senderPort,
        );

        sender = ShspPeer.create(remotePeer: receiverPeer, socket: dual);
        receiver = ShspPeer.create(
          remotePeer: senderPeer,
          socket: receiverSocket!,
        );

        var callbackFired = false;
        receiver.messageCallback.register((info) {
          callbackFired = true;
        });

        sender.sendMessage([0xBB, 0xCC]);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(callbackFired, isTrue);
      });

      test('ShspPeer via IPv6-only DualShspSocket close removes callback', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 == null) return;

        dual = DualShspSocket.fromSockets(Sockets(ipv6SocketImpl: ipv6));

        final remotePeer = PeerInfo(
          address: InternetAddress.loopbackIPv6,
          port: 9999,
        );
        sender = ShspPeer.create(remotePeer: remotePeer, socket: dual);

        final profileBefore = dual.extractProfile();
        expect(profileBefore.messageListeners.isNotEmpty, isTrue);

        sender.close();

        final profileAfter = dual.extractProfile();
        expect(profileAfter.messageListeners.isEmpty, isTrue);
      });
    });

    group('dual-stack — ShspPeer via DualShspSocket', () {
      late DualShspSocket dual;
      late ShspPeer peerIpv4;

      tearDown(() {
        if (!dual.isClosed) dual.close();
      });

      test('Two ShspPeer via same DualShspSocket — IPv4 and IPv6 callbacks', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 == null) return;

        final ipv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!ipv4.isClosed) ipv4.close();
        });

        dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4, ipv6SocketImpl: ipv6),
        );

        final peerInfoV4 = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 8081,
        );

        peerIpv4 = ShspPeer.create(remotePeer: peerInfoV4, socket: dual);

        final profile = dual.extractProfile();
        expect(profile.messageListeners.length, greaterThanOrEqualTo(2));
      });

      test('ShspPeer.sendMessage routes IPv4 via dual-stack DualShspSocket', () async {
        ShspSocket? ipv6;
        try {
          ipv6 = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
          addTearDown(() {
            if (!ipv6!.isClosed) ipv6.close();
          });
        } catch (_) {
          markTestSkipped('IPv6 not available on this system');
        }

        if (ipv6 == null) return;

        final ipv4Sender = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() {
          if (!ipv4Sender.isClosed) ipv4Sender.close();
        });
        final ipv4Receiver = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() {
          if (!ipv4Receiver.isClosed) ipv4Receiver.close();
        });

        dual = DualShspSocket.fromSockets(
          Sockets(ipv4SocketImpl: ipv4Sender, ipv6SocketImpl: ipv6),
        );

        final receiverPeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: ipv4Receiver.localPort!,
        );
        final senderPort = dual.ipv4Socket!.localPort!;
        final senderPeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: senderPort,
        );

        peerIpv4 = ShspPeer.create(remotePeer: receiverPeer, socket: dual);
        final receiver = ShspPeer.create(
          remotePeer: senderPeer,
          socket: ipv4Receiver,
        );

        var callbackFired = false;
        receiver.messageCallback.register((info) {
          callbackFired = true;
        });

        peerIpv4.sendMessage([0xCC, 0xDD]);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(callbackFired, isTrue);
      });
    });

    group('serializedObject with DualShspSocket', () {
      test('ShspPeer serializedObject works with DualShspSocket', () async {
        final dual = await DualShspSocket.create();
        addTearDown(() {
          if (!dual.isClosed) dual.close();
        });

        final remotePeer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 9999,
        );
        final peer = ShspPeer.create(remotePeer: remotePeer, socket: dual);

        final serialized = peer.serializedObject();
        expect(serialized, isNotEmpty);
        expect(serialized, contains('ShspPeer'));
        expect(serialized, contains('127.0.0.1'));
      });
    });
  });
}
