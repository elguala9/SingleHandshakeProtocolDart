import 'dart:async';
import 'package:test/test.dart';
import 'package:shsp/shsp.dart';

void main() {
  group('KeepAliveTimer', () {
    group('KeepAliveTimer.from', () {
      test('wraps an active Timer: isActive is true initially', () async {
        final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {});
        addTearDown(timer.cancel);

        final kaTimer = KeepAliveTimer.from(timer);
        expect(kaTimer.isActive, isTrue);
      });

      test('wraps a cancelled Timer: isActive reflects the timer state', () async {
        final timer = Timer(const Duration(milliseconds: 10), () {});
        await Future.delayed(const Duration(milliseconds: 50));

        final kaTimer = KeepAliveTimer.from(timer);
        expect(kaTimer.isActive, isFalse);
      });

      test('cancel() on from() stops the timer', () async {
        var callCount = 0;
        final timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
          callCount++;
        });
        addTearDown(() {
          if (timer.isActive) timer.cancel();
        });

        final kaTimer = KeepAliveTimer.from(timer);
        await Future.delayed(const Duration(milliseconds: 80));
        final countBeforeCancel = callCount;

        kaTimer.cancel();
        await Future.delayed(const Duration(milliseconds: 100));
        expect(kaTimer.isActive, isFalse);
        expect(callCount, equals(countBeforeCancel));
      });

      test('tick starts at 0 when wrapping external timer', () async {
        final timer = Timer.periodic(const Duration(milliseconds: 50), (_) {});
        addTearDown(timer.cancel);

        final kaTimer = KeepAliveTimer.from(timer);
        expect(kaTimer.tick, equals(0));
      });
    });

    group('KeepAliveTimer.periodic', () {
      test('isActive is true immediately after construction', () async {
        final kaTimer = KeepAliveTimer.periodic(
          const Duration(milliseconds: 100),
          (_) {},
        );
        addTearDown(kaTimer.cancel);

        expect(kaTimer.isActive, isTrue);
      });

      test('tick starts at 0', () async {
        final kaTimer = KeepAliveTimer.periodic(
          const Duration(milliseconds: 100),
          (_) {},
        );
        addTearDown(kaTimer.cancel);

        expect(kaTimer.tick, equals(0));
      });

      test('callback fires at least once after one interval', () async {
        var callCount = 0;
        final kaTimer = KeepAliveTimer.periodic(
          const Duration(milliseconds: 50),
          (_) {
            callCount++;
          },
        );
        addTearDown(kaTimer.cancel);

        await Future.delayed(const Duration(milliseconds: 80));
        expect(callCount, greaterThanOrEqualTo(1));
      });

      test('tick increments by 1 each time callback fires', () async {
        final kaTimer = KeepAliveTimer.periodic(
          const Duration(milliseconds: 50),
          (_) {},
        );
        addTearDown(kaTimer.cancel);

        expect(kaTimer.tick, equals(0));
        await Future.delayed(const Duration(milliseconds: 80));
        expect(kaTimer.tick, greaterThanOrEqualTo(1));

        final tickAfterFirst = kaTimer.tick;
        await Future.delayed(const Duration(milliseconds: 80));
        expect(kaTimer.tick, greaterThan(tickAfterFirst));
      });

      test('cancel() stops further firings — tick does not increment after cancel', () async {
        final kaTimer = KeepAliveTimer.periodic(
          const Duration(milliseconds: 50),
          (_) {},
        );

        await Future.delayed(const Duration(milliseconds: 80));
        final tickBeforeCancel = kaTimer.tick;

        kaTimer.cancel();
        await Future.delayed(const Duration(milliseconds: 100));
        expect(kaTimer.tick, equals(tickBeforeCancel));
      });
    });

    group('cancel / stop', () {
      test('cancel() sets isActive to false', () async {
        final kaTimer = KeepAliveTimer.periodic(
          const Duration(milliseconds: 100),
          (_) {},
        );

        expect(kaTimer.isActive, isTrue);
        kaTimer.cancel();
        expect(kaTimer.isActive, isFalse);
      });

      test('stop() sets isActive to false (alias)', () async {
        final kaTimer = KeepAliveTimer.periodic(
          const Duration(milliseconds: 100),
          (_) {},
        );

        expect(kaTimer.isActive, isTrue);
        kaTimer.stop();
        expect(kaTimer.isActive, isFalse);
      });

      test('cancel() is idempotent — calling twice does not throw', () async {
        final kaTimer = KeepAliveTimer.periodic(
          const Duration(milliseconds: 100),
          (_) {},
        );

        kaTimer.cancel();
        expect(kaTimer.cancel, returnsNormally);
      });
    });

    group('resetTick', () {
      test('resetTick() after firing: next fire is delayed by a full interval', () async {
        var callCount = 0;
        final kaTimer = KeepAliveTimer.periodic(
          const Duration(milliseconds: 80),
          (_) {
            callCount++;
          },
        );
        addTearDown(kaTimer.cancel);

        // Wait 70ms — should not have fired yet (interval is 80ms)
        await Future.delayed(const Duration(milliseconds: 70));
        expect(kaTimer.tick, equals(0));

        // Call resetTick to postpone the fire
        kaTimer.resetTick();

        // Wait 60ms more — still within the new 80ms interval
        await Future.delayed(const Duration(milliseconds: 60));
        expect(kaTimer.tick, equals(0));

        // Wait 100ms more — now we're past the interval
        await Future.delayed(const Duration(milliseconds: 100));
        expect(kaTimer.tick, greaterThanOrEqualTo(1));
      });

      test('resetTick() on inactive timer is a no-op (does not throw)', () async {
        final kaTimer = KeepAliveTimer.periodic(
          const Duration(milliseconds: 50),
          (_) {},
        );
        kaTimer.cancel();

        expect(kaTimer.resetTick, returnsNormally);
      });

      test('resetTick() on timer without _duration is a no-op (from() path)', () async {
        final timer = Timer(const Duration(milliseconds: 10), () {});
        final kaTimer = KeepAliveTimer.from(timer);

        expect(kaTimer.resetTick, returnsNormally);
      });
    });
  });
}
