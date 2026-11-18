import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/core/motion/shake_detector.dart';
import 'package:flutter_test/flutter_test.dart';

MotionSample _z(double z) => MotionSample(x: 0, y: 0, z: z);

const _still = MotionSample(x: 0, y: 0, z: 9.80665);

void main() {
  test('a jolt past 8 m/s² from gravity is a shake', () {
    expect(ShakeDetector().register(_z(9.80665 + 8.1)), isTrue);
    expect(ShakeDetector().register(_z(9.80665 - 8.1)), isTrue);
  });

  test('walking and noise are not shakes', () {
    final detector = ShakeDetector();
    for (final z in [9.80665, 12.5, 7.0, 14.8, 5.0, 17.8]) {
      expect(detector.register(_z(z)), isFalse, reason: '$z');
    }
  });

  test('one long jolt is one shake until a near-gravity reading', () {
    final detector = ShakeDetector();
    expect(detector.register(_z(25)), isTrue);
    expect(detector.register(_z(26)), isFalse);
    expect(detector.register(_z(15)), isFalse, reason: 'still 5 away');
    expect(detector.register(_z(24)), isFalse);
    expect(detector.register(_still), isFalse);
    expect(detector.register(_z(24)), isTrue);
  });

  test('a sideways shake counts by magnitude, whatever the axis', () {
    expect(
      ShakeDetector().register(const MotionSample(x: 15, y: 0, z: 9.8)),
      isTrue,
    );
  });

  test('re-arm must sit below the shake level', () {
    expect(
      () => ShakeDetector(shakeDeviation: 3.5),
      throwsAssertionError,
    );
  });
}
