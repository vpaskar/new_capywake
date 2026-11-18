import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/core/motion/step_detector.dart';
import 'package:flutter_test/flutter_test.dart';

import '_walk.dart';

int _count(StepDetector detector, Iterable<MotionSample> samples) =>
    samples.fold(0, (sum, s) => sum + detector.register(s));

void main() {
  test('a steady walk counts every footfall', () {
    expect(_count(StepDetector(), walk(steps: 12)), 12);
  });

  test('nothing counts until four steps fall in rhythm, then all four', () {
    final detector = StepDetector();
    final releases = [
      for (final s in walk(steps: 5)) detector.register(s),
    ].where((n) => n > 0).toList();
    expect(releases, [4, 1]);
  });

  test('three steps are not a walk', () {
    expect(_count(StepDetector(), walk(steps: 3)), 0);
  });

  test('a phone lying still counts nothing', () {
    expect(_count(StepDetector(), still(ms: 10000)), 0);
  });

  test('a shake is a jolt, not a step, and breaks the rhythm', () {
    final detector = StepDetector();
    expect(_count(detector, walk(steps: 3)), 0);
    expect(_count(detector, walk(steps: 1, lift: 30, startMs: 1700)), 0);
    expect(
      _count(detector, walk(steps: 3, startMs: 2400)),
      0,
      reason: 'the jolt reset the rhythm, so three more steps are not four',
    );
  });

  test('a peak inside the minimum gap is one footfall, not two', () {
    final detector = StepDetector();
    expect(
      _count(detector, walk(steps: 8, periodMs: 250)),
      4,
      reason: 'every other bump falls 250 ms after the last step',
    );
  });

  test('a pause longer than the window restarts the rhythm', () {
    final detector = StepDetector();
    expect(_count(detector, walk(steps: 6)), 6);
    expect(_count(detector, still(ms: 2600, startMs: 3200)), 0);
    expect(_count(detector, walk(steps: 3, startMs: 5800)), 0);
    expect(_count(detector, walk(steps: 1, startMs: 7300)), 4);
  });

  test('readings without a timestamp assume the game interval', () {
    expect(_count(StepDetector(), walk(steps: 10, stamped: false)), 10);
  });

  test('a lift under the rise threshold is not a step', () {
    expect(_count(StepDetector(), walk(steps: 10, lift: 1)), 0);
  });

  test('a lift over the jolt ceiling never counts', () {
    expect(_count(StepDetector(), walk(steps: 10, lift: 25)), 0);
  });

  test('the defaults are the named constants', () {
    final d = StepDetector();
    expect(d.peakRise, StepDetector.defaultPeakRise);
    expect(d.peakFall, StepDetector.defaultPeakFall);
    expect(d.joltCeiling, StepDetector.defaultJoltCeiling);
    expect(d.minGap, StepDetector.defaultMinGap);
    expect(d.maxGap, StepDetector.defaultMaxGap);
    expect(d.rhythmSteps, StepDetector.defaultRhythmSteps);
  });

  test('rejects thresholds that cannot work', () {
    expect(() => StepDetector(peakFall: 2, peakRise: 1), throwsAssertionError);
    expect(() => StepDetector(rhythmSteps: 1), throwsAssertionError);
    expect(
      () => StepDetector(
        minGap: const Duration(seconds: 2),
        maxGap: const Duration(seconds: 1),
      ),
      throwsAssertionError,
    );
  });
}
