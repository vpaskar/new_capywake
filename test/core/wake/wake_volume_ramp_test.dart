import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/wake/wake_volume_ramp.dart';
import 'package:capywake/core/wake/wake_window_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _window = Duration(minutes: 15);

List<VolumeRampStep> _stepsForMode(WakeMode mode, {int minutes = 15}) =>
    WakeVolumeRamp.stepsFor(
      ramp: WakeRamp.fromMode(wakeMode: mode, softStartMinutes: minutes),
      duration: Duration(minutes: minutes),
    );

void main() {
  group('VolumeRampStep', () {
    test('is value-equal', () {
      const a = VolumeRampStep(offset: Duration(minutes: 1), volume: 0.5);
      const b = VolumeRampStep(offset: Duration(minutes: 1), volume: 0.5);
      const c = VolumeRampStep(offset: Duration(minutes: 2), volume: 0.5);
      const d = VolumeRampStep(offset: Duration(minutes: 1), volume: 0.6);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a, isNot(d));
    });

    test('reads clearly in a failure message', () {
      // Built from non-constant values on purpose: a `const` invocation is
      // canonicalised, so the constructor never runs and never registers.
      final step = VolumeRampStep(
        offset: Duration(minutes: DateTime(2026).month),
        volume: 1 / 2,
      );
      expect(step.toString(), contains('0.5'));
      expect(step.toString(), startsWith('VolumeRampStep('));
    });
  });

  group('stepsFor', () {
    test('samples the curve into sampleCount + 1 stops', () {
      final steps = _stepsForMode(WakeMode.gentle);
      expect(steps, hasLength(WakeVolumeRamp.sampleCount + 1));
    });

    test('starts at offset zero and ends exactly on the target', () {
      // "Exactly" matters: the promise is full volume *at* the alarm time, not
      // a few seconds either side of it.
      final steps = _stepsForMode(WakeMode.gentle);
      expect(steps.first.offset, Duration.zero);
      expect(steps.last.offset, _window);
    });

    test('gentle runs 5% to 100% and never falls back', () {
      final steps = _stepsForMode(WakeMode.gentle);
      expect(steps.first.volume, closeTo(0.05, 1e-9));
      expect(steps.last.volume, 1.0);
      for (var i = 1; i < steps.length; i++) {
        expect(steps[i].volume, greaterThan(steps[i - 1].volume));
        expect(steps[i].offset, greaterThan(steps[i - 1].offset));
      }
    });

    test('gentle spends most of the window quiet', () {
      // The ease-in shape, asserted as behaviour rather than as arithmetic:
      // at the halfway point a quadratic curve is a quarter of the way up.
      final steps = _stepsForMode(WakeMode.gentle);
      final mid = steps[WakeVolumeRamp.sampleCount ~/ 2];
      expect(mid.offset, const Duration(minutes: 7, seconds: 30));
      expect(mid.volume, closeTo(0.05 + 0.95 * 0.25, 1e-9));
    });

    test('standard runs 50% to 100% in a straight line', () {
      final steps = _stepsForMode(WakeMode.standard);
      expect(steps.first.volume, closeTo(0.5, 1e-9));
      expect(steps.last.volume, 1.0);
      final mid = steps[WakeVolumeRamp.sampleCount ~/ 2];
      expect(mid.volume, closeTo(0.75, 1e-9));
    });

    test('strict produces no fade at all', () {
      // The rule, not an oversight: Strict users opted into "wake me up", and
      // starting them quiet would be the app overriding a stated choice.
      expect(_stepsForMode(WakeMode.strict), isEmpty);
    });

    test('a zero-minute window produces no fade in any mode', () {
      for (final mode in WakeMode.values) {
        expect(_stepsForMode(mode, minutes: 0), isEmpty);
      }
    });

    test('a flat ramp produces no steps even across a real duration', () {
      expect(
        WakeVolumeRamp.stepsFor(ramp: WakeRamp.flat, duration: _window),
        isEmpty,
      );
    });

    test('a fading ramp across zero duration produces no steps', () {
      final ramp = WakeRamp.fromMode(
        wakeMode: WakeMode.gentle,
        softStartMinutes: 15,
      );
      expect(
        WakeVolumeRamp.stepsFor(ramp: ramp, duration: Duration.zero),
        isEmpty,
      );
      expect(
        WakeVolumeRamp.stepsFor(
          ramp: ramp,
          duration: const Duration(minutes: -5),
        ),
        isEmpty,
      );
    });

    test('honours a caller-chosen resolution', () {
      final steps = WakeVolumeRamp.stepsFor(
        ramp: WakeRamp.fromMode(
          wakeMode: WakeMode.standard,
          softStartMinutes: 15,
        ),
        duration: _window,
        samples: 3,
      );
      expect(steps, hasLength(4));
      expect(steps.map((s) => s.offset), [
        Duration.zero,
        const Duration(minutes: 5),
        const Duration(minutes: 10),
        _window,
      ]);
    });

    test('returns an unmodifiable list', () {
      final steps = _stepsForMode(WakeMode.gentle);
      expect(
        () => steps.add(
          const VolumeRampStep(offset: Duration.zero, volume: 1),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects a non-positive resolution', () {
      expect(
        () => WakeVolumeRamp.stepsFor(
          ramp: WakeRamp.fromMode(
            wakeMode: WakeMode.gentle,
            softStartMinutes: 15,
          ),
          duration: _window,
          samples: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('every emitted volume is inside [0, 1]', () {
      for (final minutes in [1, 15, WakeWindowService.maxSoftStartMinutes]) {
        for (final mode in WakeMode.values) {
          for (final step in _stepsForMode(mode, minutes: minutes)) {
            expect(step.volume, inInclusiveRange(0, 1));
            expect(step.offset, greaterThanOrEqualTo(Duration.zero));
          }
        }
      }
    });

    test('rejects a volume outside [0, 1]', () {
      expect(
        () => VolumeRampStep(offset: Duration.zero, volume: 1 + 0.5),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
