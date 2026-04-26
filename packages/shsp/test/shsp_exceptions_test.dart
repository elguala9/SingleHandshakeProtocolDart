import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('ShspProtocolException', () {
    test('stores message', () {
      final ex = ShspProtocolException('test error');
      expect(ex.message, equals('test error'));
    });

    test('messageType defaults to null', () {
      final ex = ShspProtocolException('test error');
      expect(ex.messageType, isNull);
    });

    test('context defaults to null', () {
      final ex = ShspProtocolException('test error');
      expect(ex.context, isNull);
    });

    test('stores optional messageType', () {
      final ex = ShspProtocolException('test error', messageType: '0x01');
      expect(ex.messageType, equals('0x01'));
    });

    test('stores optional context map', () {
      final context = {'key': 'value'};
      final ex = ShspProtocolException('test error', context: context);
      expect(ex.context, equals(context));
    });

    test('toString includes class name and message', () {
      final ex = ShspProtocolException('test error');
      expect(ex.toString(), equals('ShspProtocolException: test error'));
    });

    test('toString includes messageType when set', () {
      final ex = ShspProtocolException('test error', messageType: '0x01');
      expect(ex.toString(), equals('ShspProtocolException: test error (messageType: 0x01)'));
    });

    test('toString includes context when set and non-empty', () {
      final context = {'key': 'value'};
      final ex = ShspProtocolException('test error', context: context);
      final str = ex.toString();
      expect(str, contains('ShspProtocolException: test error'));
      expect(str, contains('context:'));
      expect(str, contains('key'));
    });

    test('toString does not include context suffix when context is empty map', () {
      final ex = ShspProtocolException('test error', context: {});
      expect(ex.toString(), equals('ShspProtocolException: test error'));
    });

    test('toString includes both messageType and context together', () {
      final context = {'key': 'value'};
      final ex = ShspProtocolException('test error', messageType: '0x01', context: context);
      final str = ex.toString();
      expect(str, contains('messageType: 0x01'));
      expect(str, contains('context:'));
    });
  });

  group('ShspNetworkException', () {
    test('stores message', () {
      final ex = ShspNetworkException('network error');
      expect(ex.message, equals('network error'));
    });

    test('address defaults to null', () {
      final ex = ShspNetworkException('network error');
      expect(ex.address, isNull);
    });

    test('port defaults to null', () {
      final ex = ShspNetworkException('network error');
      expect(ex.port, isNull);
    });

    test('cause defaults to null', () {
      final ex = ShspNetworkException('network error');
      expect(ex.cause, isNull);
    });

    test('stores optional address, port, cause', () {
      final cause = Exception('inner');
      final ex = ShspNetworkException('network error', address: '192.168.1.1', port: 8080, cause: cause);
      expect(ex.address, equals('192.168.1.1'));
      expect(ex.port, equals(8080));
      expect(ex.cause, equals(cause));
    });

    test('toString plain message has no parenthetical section', () {
      final ex = ShspNetworkException('network error');
      expect(ex.toString(), equals('ShspNetworkException: network error'));
    });

    test('toString includes address only when address is set but port is null', () {
      final ex = ShspNetworkException('network error', address: '192.168.1.1');
      expect(ex.toString(), equals('ShspNetworkException: network error (address: 192.168.1.1)'));
    });

    test('toString includes port only when port is set but address is null', () {
      final ex = ShspNetworkException('network error', port: 8080);
      expect(ex.toString(), equals('ShspNetworkException: network error (port: 8080)'));
    });

    test('toString includes both address and port', () {
      final ex = ShspNetworkException('network error', address: '192.168.1.1', port: 8080);
      expect(ex.toString(), equals('ShspNetworkException: network error (address: 192.168.1.1, port: 8080)'));
    });

    test('toString includes cause when set', () {
      final cause = Exception('inner error');
      final ex = ShspNetworkException('network error', cause: cause);
      final str = ex.toString();
      expect(str, contains('ShspNetworkException: network error'));
      expect(str, contains('caused by:'));
    });
  });

  group('ShspValidationException', () {
    test('stores message', () {
      final ex = ShspValidationException('validation error');
      expect(ex.message, equals('validation error'));
    });

    test('field defaults to null', () {
      final ex = ShspValidationException('validation error');
      expect(ex.field, isNull);
    });

    test('value defaults to null', () {
      final ex = ShspValidationException('validation error');
      expect(ex.value, isNull);
    });

    test('stores optional field and value', () {
      final ex = ShspValidationException('validation error', field: 'port', value: 99999);
      expect(ex.field, equals('port'));
      expect(ex.value, equals(99999));
    });

    test('toString plain message has no parenthetical section', () {
      final ex = ShspValidationException('validation error');
      expect(ex.toString(), equals('ShspValidationException: validation error'));
    });

    test('toString includes field when set', () {
      final ex = ShspValidationException('validation error', field: 'port');
      expect(ex.toString(), equals('ShspValidationException: validation error (field: port)'));
    });

    test('toString includes both field and value when both set', () {
      final ex = ShspValidationException('validation error', field: 'port', value: 99999);
      expect(ex.toString(), equals('ShspValidationException: validation error (field: port, value: 99999)'));
    });
  });

  group('ShspHandshakeException', () {
    test('stores message', () {
      final ex = ShspHandshakeException('handshake failed');
      expect(ex.message, equals('handshake failed'));
    });

    test('peerInfo defaults to null', () {
      final ex = ShspHandshakeException('handshake failed');
      expect(ex.peerInfo, isNull);
    });

    test('stage defaults to null', () {
      final ex = ShspHandshakeException('handshake failed');
      expect(ex.stage, isNull);
    });

    test('stores optional peerInfo and stage', () {
      final ex = ShspHandshakeException('handshake failed', peerInfo: '192.168.1.1:8080', stage: 'phase1');
      expect(ex.peerInfo, equals('192.168.1.1:8080'));
      expect(ex.stage, equals('phase1'));
    });

    test('toString plain message shows no parenthetical section', () {
      final ex = ShspHandshakeException('handshake failed');
      expect(ex.toString(), equals('ShspHandshakeException: handshake failed'));
    });

    test('toString includes stage when set but peerInfo is null', () {
      final ex = ShspHandshakeException('handshake failed', stage: 'phase1');
      expect(ex.toString(), equals('ShspHandshakeException: handshake failed (stage: phase1)'));
    });

    test('toString includes peer-only branch when only peerInfo is set', () {
      final ex = ShspHandshakeException('handshake failed', peerInfo: '192.168.1.1:8080');
      expect(ex.toString(), equals('ShspHandshakeException: handshake failed (peer: 192.168.1.1:8080)'));
    });

    test('toString includes both stage and peer when both set', () {
      final ex = ShspHandshakeException('handshake failed', peerInfo: '192.168.1.1:8080', stage: 'phase1');
      expect(ex.toString(), equals('ShspHandshakeException: handshake failed (stage: phase1, peer: 192.168.1.1:8080)'));
    });
  });

  group('ShspInstanceException', () {
    test('stores message', () {
      final ex = ShspInstanceException('instance error');
      expect(ex.message, equals('instance error'));
    });

    test('instanceId defaults to null', () {
      final ex = ShspInstanceException('instance error');
      expect(ex.instanceId, isNull);
    });

    test('stores optional instanceId', () {
      final ex = ShspInstanceException('instance error', instanceId: 'inst-123');
      expect(ex.instanceId, equals('inst-123'));
    });

    test('toString plain form has no parenthetical section', () {
      final ex = ShspInstanceException('instance error');
      expect(ex.toString(), equals('ShspInstanceException: instance error'));
    });

    test('toString includes instanceId suffix when set', () {
      final ex = ShspInstanceException('instance error', instanceId: 'inst-123');
      expect(ex.toString(), equals('ShspInstanceException: instance error (instance: inst-123)'));
    });
  });

  group('ShspConfigurationException', () {
    test('stores message', () {
      final ex = ShspConfigurationException('config error');
      expect(ex.message, equals('config error'));
    });

    test('configKey defaults to null', () {
      final ex = ShspConfigurationException('config error');
      expect(ex.configKey, isNull);
    });

    test('stores optional configKey', () {
      final ex = ShspConfigurationException('config error', configKey: 'max_retries');
      expect(ex.configKey, equals('max_retries'));
    });

    test('toString plain form has no parenthetical section', () {
      final ex = ShspConfigurationException('config error');
      expect(ex.toString(), equals('ShspConfigurationException: config error'));
    });

    test('toString includes configKey suffix when set', () {
      final ex = ShspConfigurationException('config error', configKey: 'max_retries');
      expect(ex.toString(), equals('ShspConfigurationException: config error (config: max_retries)'));
    });
  });

  group('IShspException interface compliance', () {
    test('ShspProtocolException implements IShspException', () {
      final ex = ShspProtocolException('test') as IShspException;
      expect(ex.message, equals('test'));
    });

    test('ShspNetworkException implements IShspException', () {
      final ex = ShspNetworkException('test') as IShspException;
      expect(ex.message, equals('test'));
    });

    test('ShspValidationException implements IShspException', () {
      final ex = ShspValidationException('test') as IShspException;
      expect(ex.message, equals('test'));
    });

    test('ShspHandshakeException implements IShspException', () {
      final ex = ShspHandshakeException('test') as IShspException;
      expect(ex.message, equals('test'));
    });

    test('ShspInstanceException implements IShspException', () {
      final ex = ShspInstanceException('test') as IShspException;
      expect(ex.message, equals('test'));
    });

    test('ShspConfigurationException implements IShspException', () {
      final ex = ShspConfigurationException('test') as IShspException;
      expect(ex.message, equals('test'));
    });
  });
}
