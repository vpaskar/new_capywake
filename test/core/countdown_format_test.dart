import 'package:capywake/core/countdown_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CountdownFormat.until', () {
    test('splits a gap into whole hours and the remaining minutes', () {
      final now = DateTime(2026, 7, 28, 18, 41);
      final parts = CountdownFormat.until(
        now: now,
        target: now.add(const Duration(hours: 12, minutes: 19)),
      );

      expect(parts, const CountdownParts(hours: 12, minutes: 19));
      expect(parts!.isUnderAMinute, isFalse);
    });

    test('floors seconds away rather than rounding them up', () {
      // 19 minutes 59 seconds is still 19 minutes: the countdown never
      // promises the alarm is closer than it is.
      final now = DateTime(2026, 7, 28, 6, 40);
      final parts = CountdownFormat.until(
        now: now,
        target: now.add(const Duration(minutes: 19, seconds: 59)),
      );

      expect(parts, const CountdownParts(hours: 0, minutes: 19));
    });

    test('reports minutes only when the gap is under an hour', () {
      final now = DateTime(2026, 7, 28, 6, 40);
      final parts = CountdownFormat.until(
        now: now,
        target: now.add(const Duration(minutes: 45)),
      );

      expect(parts, const CountdownParts(hours: 0, minutes: 45));
    });

    test('reports a whole number of hours with zero minutes', () {
      final now = DateTime(2026, 7, 28, 7);
      final parts = CountdownFormat.until(
        now: now,
        target: now.add(const Duration(hours: 3)),
      );

      expect(parts, const CountdownParts(hours: 3, minutes: 0));
      expect(parts!.isUnderAMinute, isFalse);
    });

    test('flags a gap that floors to nothing as under a minute', () {
      final now = DateTime(2026, 7, 28, 6, 59, 30);
      final parts = CountdownFormat.until(
        now: now,
        target: now.add(const Duration(seconds: 20)),
      );

      expect(parts, const CountdownParts(hours: 0, minutes: 0));
      expect(parts!.isUnderAMinute, isTrue);
    });

    test('treats the exact moment of the alarm as under a minute', () {
      final now = DateTime(2026, 7, 28, 7);

      expect(
        CountdownFormat.until(now: now, target: now)!.isUnderAMinute,
        isTrue,
      );
    });

    test('returns null once the target has passed', () {
      final now = DateTime(2026, 7, 28, 7);

      expect(
        CountdownFormat.until(
          now: now,
          target: now.subtract(const Duration(seconds: 1)),
        ),
        isNull,
      );
    });

    test('returns null at exactly the 24-hour boundary', () {
      // The boundary is exclusive: the day line above the countdown already
      // answers "tomorrow", and "in 24 hours 0 minutes" adds nothing.
      final now = DateTime(2026, 7, 28, 7);

      expect(
        CountdownFormat.until(
          now: now,
          target: now.add(CountdownFormat.maxCountdown),
        ),
        isNull,
      );
    });

    test('still reports a gap one minute inside the boundary', () {
      final now = DateTime(2026, 7, 28, 7);
      final parts = CountdownFormat.until(
        now: now,
        target: now.add(const Duration(hours: 23, minutes: 59)),
      );

      expect(parts, const CountdownParts(hours: 23, minutes: 59));
    });

    test('returns null for an alarm several days out', () {
      final now = DateTime(2026, 7, 28, 7);

      expect(
        CountdownFormat.until(
          now: now,
          target: now.add(const Duration(days: 6)),
        ),
        isNull,
      );
    });

    test('compares absolute instants, so UTC and local agree', () {
      final localNow = DateTime(2026, 7, 28, 18, 41);
      final localTarget = localNow.add(const Duration(hours: 2, minutes: 5));

      expect(
        CountdownFormat.until(now: localNow, target: localTarget),
        CountdownFormat.until(
          now: localNow.toUtc(),
          target: localTarget.toUtc(),
        ),
      );
    });

    test('spans midnight without wrapping', () {
      final now = DateTime(2026, 7, 28, 22, 40);
      final parts = CountdownFormat.until(
        now: now,
        target: DateTime(2026, 7, 29, 7),
      );

      expect(parts, const CountdownParts(hours: 8, minutes: 20));
    });
  });

  group('CountdownParts', () {
    test('is value-equal', () {
      const a = CountdownParts(hours: 2, minutes: 5);
      const b = CountdownParts(hours: 2, minutes: 5);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('distinguishes hours from minutes', () {
      const base = CountdownParts(hours: 2, minutes: 5);

      expect(base, isNot(const CountdownParts(hours: 3, minutes: 5)));
      expect(base, isNot(const CountdownParts(hours: 2, minutes: 6)));
      // The comparison is deliberately ill-typed: it covers the `is` guard in
      // `operator ==`, which a same-type comparison never reaches.
      // ignore: unrelated_type_equality_checks
      expect(base == 'not a countdown', isFalse);
    });

    test('describes itself', () {
      expect(
        const CountdownParts(hours: 2, minutes: 5).toString(),
        'CountdownParts(hours: 2, minutes: 5)',
      );
    });

    test('rejects values that could not come from a real gap', () {
      expect(
        () => CountdownParts(hours: -1, minutes: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => CountdownParts(hours: 0, minutes: 60),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => CountdownParts(hours: 0, minutes: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
