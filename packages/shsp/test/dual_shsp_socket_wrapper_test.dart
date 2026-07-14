import 'dart:io';

import 'package:shsp/shsp.dart';
import 'package:test/test.dart';

void main() {
  group('DualShspSocketWrapper', () {
    group('default constructor', () {
      test(
        'accessing a delegated member before internalSocket is set throws',
        () {
          final wrapper = DualShspSocketWrapper();
          expect(() => wrapper.ipv4Socket, throwsA(isA<Error>()));
        },
      );

      test('delegates correctly once internalSocket is assigned', () async {
        final ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final auto = DualShspSocketAuto(Sockets(ipv4SocketImpl: ipv4Socket));
        addTearDown(auto.close);

        final wrapper = DualShspSocketWrapper();
        wrapper.internalSocket = auto;

        expect(wrapper.ipv4Socket, same(auto.ipv4Socket));
        expect(wrapper.isClosed, isFalse);
      });
    });

    group('emptyForDI constructor', () {
      test(
        'accessing a delegated member before internalSocket is set throws',
        () {
          final wrapper = DualShspSocketWrapper.emptyForDI();
          expect(() => wrapper.ipv4Socket, throwsA(isA<Error>()));
        },
      );

      test('delegates correctly once internalSocket is assigned', () async {
        final ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        final auto = DualShspSocketAuto(Sockets(ipv4SocketImpl: ipv4Socket));
        addTearDown(auto.close);

        final wrapper = DualShspSocketWrapper.emptyForDI();
        wrapper.internalSocket = auto;

        expect(wrapper.ipv4Socket, same(auto.ipv4Socket));
        expect(wrapper.isClosed, isFalse);
      });
    });

    group('createFromSocket constructor', () {
      late ShspSocket ipv4Socket;
      late ShspSocket? ipv6Socket;
      late DualShspSocketAuto auto;
      late DualShspSocketWrapper wrapper;

      setUp(() async {
        ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        ipv6Socket = await ShspSocket.bindIfPossible(
          InternetAddress.anyIPv6,
          0,
        );
        auto = DualShspSocketAuto(
          Sockets(ipv4SocketImpl: ipv4Socket, ipv6SocketImpl: ipv6Socket),
        );
        wrapper = DualShspSocketWrapper.createFromSocket(auto);
      });

      tearDown(() {
        auto.close();
      });

      test('delegates immediately without calling internalSocket', () {
        expect(wrapper.ipv4Socket, same(auto.ipv4Socket));
      });

      test('ipv4Socket / ipv6Socket delegate to distinct sockets', () {
        if (ipv6Socket == null) return;
        expect(wrapper.ipv4Socket, same(auto.ipv4Socket));
        expect(wrapper.ipv6Socket, same(auto.ipv6Socket));
        expect(wrapper.ipv6Socket, isNot(same(wrapper.ipv4Socket)));
      });

      test(
        'ipv4SocketImpl / ipv6SocketImpl getters delegate to distinct sockets',
        () {
          if (ipv6Socket == null) return;
          expect(wrapper.ipv4SocketImpl, same(auto.ipv4SocketImpl));
          expect(wrapper.ipv6SocketImpl, same(auto.ipv6SocketImpl));
          expect(wrapper.ipv6SocketImpl, isNot(same(wrapper.ipv4SocketImpl)));
        },
      );

      test(
        'ipv4SocketImpl setter forwards to the underlying dualSocket',
        () async {
          final newIpv4 = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
          addTearDown(() {
            if (!newIpv4.isClosed) newIpv4.close();
          });

          wrapper.ipv4SocketImpl = newIpv4;

          expect(auto.ipv4SocketImpl, same(newIpv4));
        },
      );

      test(
        'ipv6SocketImpl setter forwards to the underlying dualSocket',
        () async {
          final newIpv6 = await ShspSocket.bindIfPossible(
            InternetAddress.anyIPv6,
            0,
          );
          if (newIpv6 == null) return;
          addTearDown(() {
            if (!newIpv6.isClosed) newIpv6.close();
          });

          wrapper.ipv6SocketImpl = newIpv6;

          expect(auto.ipv6SocketImpl, same(newIpv6));
          expect(auto.ipv6SocketImpl, isNot(same(auto.ipv4SocketImpl)));
        },
      );

      test(
        'ipv4SocketForMessages / ipv6SocketForMessages delegate to distinct sockets',
        () {
          if (ipv6Socket == null) return;
          expect(
            wrapper.ipv4SocketForMessages,
            same(auto.ipv4SocketForMessages),
          );
          expect(
            wrapper.ipv6SocketForMessages,
            same(auto.ipv6SocketForMessages),
          );
          expect(
            wrapper.ipv6SocketForMessages,
            isNot(same(wrapper.ipv4SocketForMessages)),
          );
        },
      );

      test(
        'ipv4SocketForProfile / ipv6SocketForProfile delegate to distinct sockets',
        () {
          if (ipv6Socket == null) return;
          expect(wrapper.ipv4SocketForProfile, same(auto.ipv4SocketForProfile));
          expect(wrapper.ipv6SocketForProfile, same(auto.ipv6SocketForProfile));
          expect(
            wrapper.ipv6SocketForProfile,
            isNot(same(wrapper.ipv4SocketForProfile)),
          );
        },
      );

      test(
        'ipv4SocketWrapper / ipv6SocketWrapper delegate to distinct wrappers',
        () {
          if (ipv6Socket == null) return;
          expect(wrapper.ipv4SocketWrapper, same(auto.ipv4SocketWrapper));
          expect(wrapper.ipv6SocketWrapper, same(auto.ipv6SocketWrapper));
          expect(
            wrapper.ipv6SocketWrapper,
            isNot(same(wrapper.ipv4SocketWrapper)),
          );
        },
      );

      test('socket delegates to the underlying dualSocket', () {
        expect(wrapper.socket, same(auto.socket));
      });

      test('compressionCodec delegates to the underlying dualSocket', () {
        expect(wrapper.compressionCodec, same(auto.compressionCodec));
      });

      test('isClosed delegates to the underlying dualSocket', () {
        expect(wrapper.isClosed, isFalse);
        auto.close();
        expect(wrapper.isClosed, isTrue);
      });

      test(
        'localAddress / localPort delegate to the underlying dualSocket',
        () {
          expect(wrapper.localAddress, equals(auto.localAddress));
          expect(wrapper.localPort, equals(auto.localPort));
        },
      );

      test(
        'onClose / onError / onListening delegate to the same callback handlers',
        () {
          expect(wrapper.onClose, same(auto.onClose));
          expect(wrapper.onError, same(auto.onError));
          expect(wrapper.onListening, same(auto.onListening));
        },
      );

      test('migrateSocketIpv4 forwards to the underlying dualSocket', () async {
        final oldPort = auto.ipv4Socket!.localPort;
        final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
        addTearDown(() {
          if (!newSocket.isClosed) newSocket.close();
        });

        wrapper.migrateSocketIpv4(newSocket);

        expect(auto.ipv4Socket!.localPort, equals(newSocket.localPort));
        expect(auto.ipv4Socket!.localPort, isNot(equals(oldPort)));
      });

      test('migrateSocketIpv6 forwards to the underlying dualSocket', () async {
        if (ipv6Socket == null) return;
        final oldPort = auto.ipv6Socket!.localPort;
        final newSocket = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
        addTearDown(() {
          if (!newSocket.isClosed) newSocket.close();
        });

        wrapper.migrateSocketIpv6(newSocket);

        expect(auto.ipv6Socket!.localPort, equals(newSocket.localPort));
        expect(auto.ipv6Socket!.localPort, isNot(equals(oldPort)));
      });

      test('refreshSocketIpv4 forwards to the underlying dualSocket', () {
        final result = wrapper.refreshSocketIpv4();
        expect(result, isA<IShspSocket>());
      });

      test('refreshSocketIpv6 forwards to the underlying dualSocket', () {
        if (ipv6Socket == null) return;
        final result = wrapper.refreshSocketIpv6();
        expect(result, isA<IShspSocket>());
      });

      test('refreshSockets forwards to the underlying dualSocket', () {
        final result = wrapper.refreshSockets();
        expect(result, isA<Sockets>());
        expect(result.ipv4SocketImpl, isA<IShspSocket>());
      });

      test(
        'setMessageCallback / removeMessageCallback forward to the underlying dualSocket',
        () {
          final peer = PeerInfo(
            address: InternetAddress.loopbackIPv4,
            port: 9091,
          );
          void cb(MessageRecord record) {}

          wrapper.setMessageCallback(peer, cb);
          final profile = wrapper.extractProfile();
          expect(profile.messageListeners, isNotEmpty);

          final removed = wrapper.removeMessageCallback(peer, cb);
          expect(removed, isTrue);
        },
      );

      test(
        'applyProfile / extractProfile forward to the underlying dualSocket',
        () {
          final peer = PeerInfo(
            address: InternetAddress.loopbackIPv4,
            port: 9092,
          );
          void cb(MessageRecord record) {}
          wrapper.setMessageCallback(peer, cb);

          final extractedByWrapper = wrapper.extractProfile();
          final extractedByAuto = auto.extractProfile();
          expect(
            extractedByWrapper.messageListeners.length,
            equals(extractedByAuto.messageListeners.length),
          );
        },
      );

      test('sendTo forwards to the underlying dualSocket', () {
        final peer = PeerInfo(
          address: InternetAddress.loopbackIPv4,
          port: 9093,
        );
        final result = wrapper.sendTo([0x01, 0x02], peer);
        expect(result, greaterThan(0));
      });

      test('serializedObject delegates to the underlying dualSocket', () {
        expect(wrapper.serializedObject(), equals(auto.serializedObject()));
      });

      test(
        'setCloseCallback / setErrorCallback / setListeningCallback forward without throwing',
        () {
          expect(() => wrapper.setCloseCallback(() {}), returnsNormally);
          expect(() => wrapper.setErrorCallback((_) {}), returnsNormally);
          expect(() => wrapper.setListeningCallback(() {}), returnsNormally);
        },
      );

      test('close forwards to the underlying dualSocket', () {
        wrapper.close();
        expect(auto.isClosed, isTrue);
      });

      test('destroy forwards to the underlying dualSocket', () {
        wrapper.destroy();
        expect(auto.isClosed, isTrue);
      });
    });
  });
}
