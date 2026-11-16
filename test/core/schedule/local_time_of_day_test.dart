import 'package:capywake/core/schedule/local_time_of_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalTimeOfDay', () {
    test('fromMinutes round-trips toMinutes', () {
      for (final mins in const [0, 30, 7 * 60, 12 * 60 + 5, 23 * 60 + 59]) {
        final t = LocalTimeOfDay.fromMinutes(mins);
        expect(t.toMinutes(), mins);
      }
    });

    test('fromMinutes splits into hour/minute correctly', () {
      final t = LocalTimeOfDay.fromMinutes(7 * 60 + 5);
      expect(t.hour, 7);
      expect(t.minute, 5);
    });

    test('hour/minute constructor and accessors', () {
      const t = LocalTimeOfDay(hour: 23, minute: 59);
      expect(t.hour, 23);
      expect(t.minute, 59);
      expect(t.toMinutes(), 23 * 60 + 59);
    });

    test('rejects negative minutes', () {
      expect(
        () => LocalTimeOfDay.fromMinutes(-1),
        throwsArgumentError,
      );
    });

    test('rejects out-of-range minutes', () {
      expect(
        () => LocalTimeOfDay.fromMinutes(24 * 60),
        throwsArgumentError,
      );
      expect(
        () => LocalTimeOfDay.fromMinutes(99999),
        throwsArgumentError,
      );
    });

    test('toString pads zero', () {
      expect(LocalTimeOfDay.fromMinutes(0).toString(), '00:00');
      expect(LocalTimeOfDay.fromMinutes(7 * 60 + 5).toString(), '07:05');
      expect(LocalTimeOfDay.fromMinutes(23 * 60 + 59).toString(), '23:59');
    });

    test('value-equality + hashCode', () {
      final a = LocalTimeOfDay.fromMinutes(7 * 60);
      const b = LocalTimeOfDay(hour: 7, minute: 0);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == LocalTimeOfDay.fromMinutes(7 * 60 + 1), isFalse);
      // identical short-circuit
      expect(a, a);
    });

    test('compareTo orders by minute-of-day', () {
      final earlier = LocalTimeOfDay.fromMinutes(6 * 60);
      final later = LocalTimeOfDay.fromMinutes(7 * 60);
      expect(earlier.compareTo(later) < 0, isTrue);
      expect(later.compareTo(earlier) > 0, isTrue);
      expect(earlier.compareTo(LocalTimeOfDay.fromMinutes(6 * 60)), 0);
    });
  });
}
