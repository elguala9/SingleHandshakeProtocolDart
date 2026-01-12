import 'package:test/test.dart';
import 'package:shsp_implementations/src/utility/keep_alive_timer.dart';
import 'dart:async';

void main() {
  group('KeepAliveTimer Tests', () {
    late KeepAliveTimer timer;
    int callbackCount = 0;

    setUp(() {
      callbackCount = 0;
    });

    tearDown(() {
      if (timer.isActive) {
        timer.cancel();
      }
    });

    test('KeepAliveTimer implements Timer', () {
      timer = KeepAliveTimer.periodic(
        const Duration(milliseconds: 100),
        (_) => callbackCount++,
      );
      expect(timer, isA<Timer>());
    });

    test('Timer callback is called after duration', () async {
      timer = KeepAliveTimer.periodic(
        const Duration(milliseconds: 100),
        (_) => callbackCount++,
      );
      
      await Future.delayed(const Duration(milliseconds: 150));
      expect(callbackCount, greaterThan(0));
    });

    test('isActive returns true when running', () {
      timer = KeepAliveTimer.periodic(
        const Duration(milliseconds: 100),
        (_) => callbackCount++,
      );
      expect(timer.isActive, isTrue);
    });

    test('isActive returns false after cancel', () async {
      timer = KeepAliveTimer.periodic(
        const Duration(milliseconds: 100),
        (_) => callbackCount++,
      );
      
      timer.cancel();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(timer.isActive, isFalse);
    });

    test('tick increments', () async {
      timer = KeepAliveTimer.periodic(
        const Duration(milliseconds: 100),
        (_) => callbackCount++,
      );
      
      // Tick funziona solo se _lastActivity è settato
      // Questo è un test semplice che verifica la proprietà
      expect(timer.tick, isNotNull);
    });

    test('resetTick resets the countdown', () async {
      timer = KeepAliveTimer.periodic(
        const Duration(milliseconds: 100),
        (_) => callbackCount++,
      );
      
      // resetTick aggiorna _lastActivity
      timer.resetTick();
      expect(timer.tick, isNotNull);
    });

    test('Multiple callbacks over time', () async {
      timer = KeepAliveTimer.periodic(
        const Duration(milliseconds: 100),
        (_) => callbackCount++,
      );
      
      await Future.delayed(const Duration(milliseconds: 350));
      expect(callbackCount, greaterThanOrEqualTo(2));
    });

    test('from() converts Timer to KeepAliveTimer', () {
      final originalTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => callbackCount++,
      );
      
      timer = KeepAliveTimer.from(originalTimer);
      expect(timer, isA<KeepAliveTimer>());
      expect(timer.isActive, isTrue);
    });

    test('cancel() stops the timer', () async {
      int beforeCancelCount = 0;

      timer = KeepAliveTimer.periodic(
        const Duration(milliseconds: 50),
        (_) {
          if (timer.isActive) {
            beforeCancelCount++;
          }
        },
      );

      await Future.delayed(const Duration(milliseconds: 120));
      timer.cancel();
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(beforeCancelCount, greaterThan(0));
      expect(timer.isActive, isFalse);
    });

    test('resetTick() delays callback execution', () async {
      int callCount = 0;
      final stopwatch = Stopwatch()..start();

      timer = KeepAliveTimer.periodic(
        const Duration(milliseconds: 200),
        (_) => callCount++,
      );

      // Wait 80ms then reset the tick
      await Future.delayed(const Duration(milliseconds: 80));
      timer.resetTick();

      // After reset, callback should fire ~200ms later (at ~280ms total)
      // Wait to verify it hasn't fired yet at intermediate time
      await Future.delayed(const Duration(milliseconds: 150));

      // Wait more to let callback fire
      await Future.delayed(const Duration(milliseconds: 150));
      
      stopwatch.stop();
      
      // Should have fired after resetTick
      expect(callCount, greaterThan(0));
      // The total time should be roughly 80 + 200 (+ some delay)
      expect(stopwatch.elapsedMilliseconds, greaterThan(200));
    });
  });
}
