import 'package:test/test.dart';
import 'package:shsp_interfaces/src/connection/i_shsp_handshake.dart';
import 'package:shsp_implementations/connection/handshake_time.dart';

void main() {
  group('HandshakeTime', () {
    test('constructor should set all values correctly', () {
      final startTime = DateTime(2024, 1, 1, 12, 0, 0);
      final endTime = DateTime(2024, 1, 1, 14, 0, 0);
      const timeframe = 30;
      const duration = 15;

      final handshake = HandshakeTime((
        handshakeTimeframe: timeframe,
        handshakeDuration: duration,
        startHandshakeTime: startTime,
        endHandshakeTime: endTime,
      ));

      expect(handshake.getHandshakeTimeframe(), equals(timeframe));
      expect(handshake.getHandshakeDuration(), equals(duration));
      expect(handshake.getStartHandshakeTime(), equals(startTime));
      expect(handshake.getEndHandshakeTime(), equals(endTime));
      expect(handshake.getSecondsToNextHandshake(), equals(-1));
    });

    test('should implement IHandshakeTime interface', () {
      final handshake = HandshakeTime((
        handshakeTimeframe: 20,
        handshakeDuration: 10,
        startHandshakeTime: DateTime.now(),
        endHandshakeTime: DateTime.now().add(const Duration(hours: 1)),
      ));

      expect(handshake, isA<IHandshakeTime>());
    });

    test('getSecondsToNextHandshake should always return -1', () {
      final handshake = HandshakeTime((
        handshakeTimeframe: 60,
        handshakeDuration: 30,
        startHandshakeTime: DateTime.now(),
        endHandshakeTime: DateTime.now().add(const Duration(hours: 2)),
      ));

      expect(handshake.getSecondsToNextHandshake(), equals(-1));
    });

    test('should handle zero values', () {
      final now = DateTime.now();

      final handshake = HandshakeTime((
        handshakeTimeframe: 0,
        handshakeDuration: 0,
        startHandshakeTime: now,
        endHandshakeTime: now,
      ));

      expect(handshake.getHandshakeTimeframe(), equals(0));
      expect(handshake.getHandshakeDuration(), equals(0));
      expect(handshake.getStartHandshakeTime(), equals(now));
      expect(handshake.getEndHandshakeTime(), equals(now));
    });

    test('should handle large values', () {
      final startTime = DateTime(2024, 1, 1);
      final endTime = DateTime(2025, 1, 1);
      const largeTimeframe = 86400; // 1 day in seconds
      const largeDuration = 3600; // 1 hour in seconds

      final handshake = HandshakeTime((
        handshakeTimeframe: largeTimeframe,
        handshakeDuration: largeDuration,
        startHandshakeTime: startTime,
        endHandshakeTime: endTime,
      ));

      expect(handshake.getHandshakeTimeframe(), equals(largeTimeframe));
      expect(handshake.getHandshakeDuration(), equals(largeDuration));
      expect(handshake.getStartHandshakeTime(), equals(startTime));
      expect(handshake.getEndHandshakeTime(), equals(endTime));
    });

    test('end time should be after start time in meaningful use case', () {
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(minutes: 30));

      final handshake = HandshakeTime((
        handshakeTimeframe: 20,
        handshakeDuration: 10,
        startHandshakeTime: startTime,
        endHandshakeTime: endTime,
      ));

      expect(
          handshake
              .getEndHandshakeTime()
              .isAfter(handshake.getStartHandshakeTime()),
          isTrue);
    });

    test('should handle same start and end times', () {
      final sameTime = DateTime.now();

      final handshake = HandshakeTime((
        handshakeTimeframe: 5,
        handshakeDuration: 3,
        startHandshakeTime: sameTime,
        endHandshakeTime: sameTime,
      ));

      expect(handshake.getStartHandshakeTime(),
          equals(handshake.getEndHandshakeTime()));
    });

    test('time difference calculation should be consistent', () {
      final startTime = DateTime(2024, 6, 15, 10, 30, 0);
      final endTime = DateTime(2024, 6, 15, 11, 30, 0); // 1 hour later

      final handshake = HandshakeTime((
        handshakeTimeframe: 300, // 5 minutes
        handshakeDuration: 60, // 1 minute
        startHandshakeTime: startTime,
        endHandshakeTime: endTime,
      ));

      final timeDiff = handshake
          .getEndHandshakeTime()
          .difference(handshake.getStartHandshakeTime());
      expect(timeDiff.inHours, equals(1));
      expect(timeDiff.inMinutes, equals(60));
    });

    // Note: createAsync test è commentato perché richiede NTP che potrebbe non essere disponibile in test
    /*
    test('createAsync should create HandshakeTime with NTP clock', () async {
      final input = (
        handshakeTimeframe: 25,
        handshakeDuration: 12,
        whenLastHandshake: 3600, // 1 hour
      );

      try {
        final handshake = await HandshakeTime.createAsync(input);
        expect(handshake, isA<HandshakeTime>());
        expect(handshake.getHandshakeTimeframe(), equals(25));
        expect(handshake.getHandshakeDuration(), equals(12));
        expect(handshake.getStartHandshakeTime(), isA<DateTime>());
        expect(handshake.getEndHandshakeTime(), isA<DateTime>());
        
        // End time should be about 1 hour after start time
        final duration = handshake.getEndHandshakeTime().difference(handshake.getStartHandshakeTime());
        expect(duration.inSeconds, closeTo(3600, 60)); // Allow 1 minute tolerance
      } catch (e) {
        // NTP might fail in test environment, this is acceptable
        expect(e, isA<Exception>());
      }
    });
    */
  });

  group('defaultHandshakeTimeInput', () {
    test('should have correct default values', () {
      expect(defaultHandshakeTimeInput.handshakeTimeframe, equals(20));
      expect(defaultHandshakeTimeInput.handshakeDuration, equals(10));
      expect(defaultHandshakeTimeInput.whenLastHandshake, equals(6000));
    });
  });
}
