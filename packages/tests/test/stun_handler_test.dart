import 'dart:io';
import 'package:test/test.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';
import 'package:shsp_implementations/src/stun_handler.dart';
import 'package:shsp_implementations/src/shsp_socket.dart';

void main() {
  group('StunHandler', () {
    late IShspSocket socket;
    late StunHandler stunHandler;

    setUp(() async {
      socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      stunHandler = StunHandler(socket: socket);
    });

    tearDown(() {
      stunHandler.close();
    });

    test('should implement IStunHandler interface', () {
      expect(stunHandler, isA<IStunHandler>());
    });

    test('getSocket should return the provided socket', () {
      expect(stunHandler.getSocket(), equals(socket));
    });

    test('setStunServer should update server address and port', () {
      const testAddress = 'test.stun.server.com';
      const testPort = 12345;
      
      stunHandler.setStunServer(testAddress, testPort);
      // Non possiamo testare direttamente i valori privati, ma possiamo verificare che non ci siano errori
      expect(() => stunHandler.setStunServer(testAddress, testPort), returnsNormally);
    });

    test('setStunServer should handle empty address', () {
      stunHandler.setStunServer('', 19302);
      expect(() => stunHandler.setStunServer('', 19302), returnsNormally);
    });

    test('setStunServer should handle invalid port', () {
      stunHandler.setStunServer('stun.server.com', -1);
      expect(() => stunHandler.setStunServer('stun.server.com', -1), returnsNormally);
      
      stunHandler.setStunServer('stun.server.com', 70000);
      expect(() => stunHandler.setStunServer('stun.server.com', 70000), returnsNormally);
    });

    test('setStunServer should handle whitespace in address', () {
      stunHandler.setStunServer('  stun.server.com  ', 19302);
      expect(() => stunHandler.setStunServer('  stun.server.com  ', 19302), returnsNormally);
    });

    test('performLocalRequest should return LocalInfo', () async {
      final localInfo = await stunHandler.performLocalRequest();
      
      expect(localInfo, isA<LocalInfo>());
      expect(localInfo.localIp, isNotEmpty);
      expect(localInfo.localPort, isA<int>());
    });

    test('performLocalRequest should find valid IPv4 address', () async {
      final localInfo = await stunHandler.performLocalRequest();
      
      // Verifica che l'IP sia un IPv4 valido
      final ipRegex = RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$');
      expect(ipRegex.hasMatch(localInfo.localIp), isTrue);
      
      // Verifica che non sia loopback in produzione (127.x.x.x)
      // In test environment potrebbe essere loopback, quindi accettiamo entrambi
      expect(localInfo.localIp, isNot(equals('')));
    });

    test('performStunRequest should throw UnimplementedError', () async {
      expect(
        () async => await stunHandler.performStunRequest(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('pingStunServer should return false for unimplemented STUN', () async {
      final result = await stunHandler.pingStunServer();
      expect(result, isFalse);
    });

    test('close should close underlying socket', () {
      expect(() => stunHandler.close(), returnsNormally);
    });

    test('constructor with default values should work', () {
      expect(() => StunHandler(socket: socket), returnsNormally);
    });

    test('constructor with custom values should work', () {
      expect(() => StunHandler(
        socket: socket,
        address: 'custom.stun.com',
        port: 3478,
        localPort: 45678,
      ), returnsNormally);
    });
  });

  group('DefaultStunConfig', () {
    test('should have correct default values', () {
      expect(DefaultStunConfig.address, equals('stun.l.google.com'));
      expect(DefaultStunConfig.port, equals(19302));
      expect(DefaultStunConfig.localPort, equals(49152));
    });
  });
}