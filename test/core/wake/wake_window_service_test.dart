import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/wake/wake_window_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build an [Alarm] with sensible defaults; the tests only override the
/// fields they need so each case stays readable.
Alarm _alarm({
  WakeMode wakeMode = WakeMode.standard,
  int wakeWindowStartMinutesBefore = 0,
}) {
  return Alarm(
    id: 'a',
    label: '',
    enabled: true,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const <int>{},
    wakeMode: wakeMode,
    wakeWindowStartMinutesBefore: wakeWindowStartMinutesBefore,
    soundId: 'default',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: DismissMethod.normalButton,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

void main() {
  group('WakeWindowService.forTarget', () {
    final target = DateTime(2026, 5, 21, 7);

    test('no soft-start → softStart is null', () {
      final w = WakeWindowService.forTarget(
        alarm: _alarm(),
        target: target,
      );
      expect(w.softStart, isNull);
      expect(w.target, target);
      expect(w.hasSoftStart, isFalse);
      expect(w.ramp, WakeRamp.flat);
    });

    test('soft-start subtracts minutes from target', () {
      final w = WakeWindowService.forTarget(
        alarm: _alarm(
          wakeMode: WakeMode.gentle,
          wakeWindowStartMinutesBefore: 15,
        ),
        target: target,
      );
      expect(w.softStart, target.subtract(const Duration(minutes: 15)));
      expect(w.hasSoftStart, isTrue);
      expect(w.ramp.curve, WakeRampCurve.easeIn);
    });
  });

  group('WakeWindowService.forMinutes', () {
    final target = DateTime(2026, 5, 21, 7);

    test('builds the same window as forTarget', () {
      final fromAlarm = WakeWindowService.forTarget(
        alarm: _alarm(
          wakeMode: WakeMode.gentle,
          wakeWindowStartMinutesBefore: 10,
        ),
        target: target,
      );
      final fromMinutes = WakeWindowService.forMinutes(
        target: target,
        wakeMode: WakeMode.gentle,
        softStartMinutesBefore: 10,
      );
      expect(fromMinutes, fromAlarm);
    });

    test('asserts on softStartMinutesBefore out of bounds', () {
      expect(
        () => WakeWindowService.forMinutes(
          target: target,
          wakeMode: WakeMode.standard,
          softStartMinutesBefore: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WakeWindowService.forMinutes(
          target: target,
          wakeMode: WakeMode.standard,
          softStartMinutesBefore: 31,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('WakeWindowService bounds', () {
    test('expose the form slider constants', () {
      expect(WakeWindowService.minSoftStartMinutes, 0);
      expect(WakeWindowService.maxSoftStartMinutes, 30);
    });
  });

  group('WakeWindow.volumeAt', () {
    final target = DateTime(2026, 5, 21, 7);

    test('flat ramp returns full volume at any time', () {
      final w = WakeWindowService.forTarget(
        alarm: _alarm(),
        target: target,
      );
      expect(w.volumeAt(target.subtract(const Duration(hours: 1))), 1);
      expect(w.volumeAt(target), 1);
      expect(w.volumeAt(target.add(const Duration(minutes: 1))), 1);
    });

    test('Gentle ramp before soft-start emits startVolume', () {
      final w = WakeWindowService.forTarget(
        alarm: _alarm(
          wakeMode: WakeMode.gentle,
          wakeWindowStartMinutesBefore: 10,
        ),
        target: target,
      );
      final before = target.subtract(const Duration(minutes: 30));
      expect(w.volumeAt(before), 0.05);
    });

    test('Gentle ramp at exact soft-start emits startVolume', () {
      final w = WakeWindowService.forTarget(
        alarm: _alarm(
          wakeMode: WakeMode.gentle,
          wakeWindowStartMinutesBefore: 10,
        ),
        target: target,
      );
      final start = target.subtract(const Duration(minutes: 10));
      expect(w.volumeAt(start), 0.05);
    });

    test('Gentle ramp at midpoint applies easeIn (quadratic)', () {
      final w = WakeWindowService.forTarget(
        alarm: _alarm(
          wakeMode: WakeMode.gentle,
          wakeWindowStartMinutesBefore: 10,
        ),
        target: target,
      );
      final mid = target.subtract(const Duration(minutes: 5));
      // progress = 0.5; eased = 0.25; v = 0.05 + (1 - 0.05) * 0.25 = 0.2875
      expect(w.volumeAt(mid), closeTo(0.2875, 1e-9));
    });

    test('Gentle ramp at target emits full volume', () {
      final w = WakeWindowService.forTarget(
        alarm: _alarm(
          wakeMode: WakeMode.gentle,
          wakeWindowStartMinutesBefore: 10,
        ),
        target: target,
      );
      expect(w.volumeAt(target), 1);
    });

    test('Gentle ramp after target stays at full volume', () {
      final w = WakeWindowService.forTarget(
        alarm: _alarm(
          wakeMode: WakeMode.gentle,
          wakeWindowStartMinutesBefore: 10,
        ),
        target: target,
      );
      expect(w.volumeAt(target.add(const Duration(minutes: 1))), 1);
    });

    test('Standard ramp at midpoint is linear', () {
      final w = WakeWindowService.forTarget(
        alarm: _alarm(
          wakeWindowStartMinutesBefore: 10,
        ),
        target: target,
      );
      final mid = target.subtract(const Duration(minutes: 5));
      // progress = 0.5; linear; v = 0.5 + 0.5 * 0.5 = 0.75
      expect(w.volumeAt(mid), closeTo(0.75, 1e-9));
    });
  });

  group('WakeWindow equality', () {
    final target = DateTime.utc(2026, 5, 21, 7);
    final softStart = target.subtract(const Duration(minutes: 5));

    test('equal windows are == and share hashCode', () {
      final a = WakeWindow(
        target: target,
        softStart: softStart,
        ramp: WakeRamp.flat,
      );
      final b = WakeWindow(
        target: target,
        softStart: softStart,
        ramp: WakeRamp.flat,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a, isTrue);
      // Asserting `==` against a String confirms equality is type-aware.
      // ignore: unrelated_type_equality_checks
      expect(a == 'foo', isFalse);
    });

    test('windows differ when fields differ', () {
      final a = WakeWindow(
        target: target,
        softStart: softStart,
        ramp: WakeRamp.flat,
      );
      final b = WakeWindow(
        target: target,
        softStart: null,
        ramp: WakeRamp.flat,
      );
      expect(a, isNot(b));
    });

    test('one null softStart and one non-null are not equal', () {
      final a = WakeWindow(
        target: target,
        softStart: softStart,
        ramp: WakeRamp.flat,
      );
      final b = WakeWindow(
        target: target,
        softStart: null,
        ramp: WakeRamp.flat,
      );
      expect(a == b, isFalse);
      // And the reverse direction (other null, this non-null).
      expect(b == a, isFalse);
    });
  });

  group('WakeRamp.fromMode', () {
    test('softStartMinutes 0 → flat for every mode', () {
      for (final mode in WakeMode.values) {
        final r = WakeRamp.fromMode(wakeMode: mode, softStartMinutes: 0);
        expect(r, WakeRamp.flat);
        expect(r.isFading, isFalse);
      }
    });

    test('Gentle with non-zero softStart → easeIn 0.05→1', () {
      final r = WakeRamp.fromMode(
        wakeMode: WakeMode.gentle,
        softStartMinutes: 10,
      );
      expect(r.startVolume, 0.05);
      expect(r.endVolume, 1);
      expect(r.curve, WakeRampCurve.easeIn);
      expect(r.isFading, isTrue);
    });

    test('Standard with non-zero softStart → linear 0.5→1', () {
      final r = WakeRamp.fromMode(
        wakeMode: WakeMode.standard,
        softStartMinutes: 10,
      );
      expect(r.startVolume, 0.5);
      expect(r.endVolume, 1);
      expect(r.curve, WakeRampCurve.linear);
      expect(r.isFading, isTrue);
    });

    test('Strict with non-zero softStart still flat', () {
      final r = WakeRamp.fromMode(
        wakeMode: WakeMode.strict,
        softStartMinutes: 10,
      );
      expect(r, WakeRamp.flat);
      expect(r.isFading, isFalse);
    });
  });

  group('WakeRamp.volumeAt', () {
    test('clamps progress < 0 to startVolume', () {
      final r = WakeRamp.fromMode(
        wakeMode: WakeMode.standard,
        softStartMinutes: 5,
      );
      expect(r.volumeAt(-1), 0.5);
    });

    test('clamps progress > 1 to endVolume', () {
      final r = WakeRamp.fromMode(
        wakeMode: WakeMode.standard,
        softStartMinutes: 5,
      );
      expect(r.volumeAt(2), 1);
    });

    test('linear midpoint', () {
      final r = WakeRamp.fromMode(
        wakeMode: WakeMode.standard,
        softStartMinutes: 5,
      );
      expect(r.volumeAt(0.5), closeTo(0.75, 1e-9));
    });

    test('easeIn midpoint is quadratic', () {
      final r = WakeRamp.fromMode(
        wakeMode: WakeMode.gentle,
        softStartMinutes: 5,
      );
      // 0.05 + (1-0.05) * 0.25 = 0.2875
      expect(r.volumeAt(0.5), closeTo(0.2875, 1e-9));
    });
  });

  group('WakeRamp equality', () {
    test('equal ramps share hashCode', () {
      const a = WakeRamp(
        startVolume: 0.1,
        endVolume: 0.9,
        curve: WakeRampCurve.linear,
      );
      const b = WakeRamp(
        startVolume: 0.1,
        endVolume: 0.9,
        curve: WakeRampCurve.linear,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a, isTrue);
      // Asserting `==` against a String confirms equality is type-aware.
      // ignore: unrelated_type_equality_checks
      expect(a == 'foo', isFalse);
    });

    test('differ when any field differs', () {
      const a = WakeRamp(
        startVolume: 0.1,
        endVolume: 0.9,
        curve: WakeRampCurve.linear,
      );
      const b = WakeRamp(
        startVolume: 0.2,
        endVolume: 0.9,
        curve: WakeRampCurve.linear,
      );
      const c = WakeRamp(
        startVolume: 0.1,
        endVolume: 0.95,
        curve: WakeRampCurve.linear,
      );
      const d = WakeRamp(
        startVolume: 0.1,
        endVolume: 0.9,
        curve: WakeRampCurve.easeIn,
      );
      expect(a == b, isFalse);
      expect(a == c, isFalse);
      expect(a == d, isFalse);
    });

    test('asserts on out-of-range volumes', () {
      expect(
        () => WakeRamp(
          startVolume: -0.1,
          endVolume: 1,
          curve: WakeRampCurve.linear,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WakeRamp(
          startVolume: 0.5,
          endVolume: 1.5,
          curve: WakeRampCurve.linear,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
