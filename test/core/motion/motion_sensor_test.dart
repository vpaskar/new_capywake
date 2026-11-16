import 'package:capywake/core/motion/fake_motion_sensor.dart';
import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MotionSample', () {
    test('magnitude is the length of the acceleration vector', () {
      const sample = MotionSample(x: 3, y: 4, z: 0);
      expect(sample.magnitude, closeTo(5, 1e-9));
    });

    test('magnitude ignores orientation', () {
      // The same phone at rest, lying flat and standing on its edge. CapyWake
      // must read both as "not moving", which is why only the length is used.
      const flat = MotionSample(x: 0, y: 0, z: 9.80665);
      const upright = MotionSample(x: 0, y: 9.80665, z: 0);
      expect(flat.magnitude, closeTo(upright.magnitude, 1e-9));
    });

    test('is value-equal on every axis', () {
      const a = MotionSample(x: 1, y: 2, z: 3);
      expect(a, const MotionSample(x: 1, y: 2, z: 3));
      expect(a.hashCode, const MotionSample(x: 1, y: 2, z: 3).hashCode);
      expect(a, isNot(const MotionSample(x: 9, y: 2, z: 3)));
      expect(a, isNot(const MotionSample(x: 1, y: 9, z: 3)));
      expect(a, isNot(const MotionSample(x: 1, y: 2, z: 9)));
      expect(a, isNot(const Object()));
    });

    test('toString names every axis', () {
      expect(
        const MotionSample(x: 1, y: 2, z: 3).toString(),
        'MotionSample(x: 1.0, y: 2.0, z: 3.0)',
      );
    });
  });

  group('FakeMotionSensor', () {
    test('delivers emitted samples to a listener', () async {
      final sensor = FakeMotionSensor();
      addTearDown(sensor.dispose);

      final seen = <MotionSample>[];
      final subscription = sensor.samples.listen(seen.add);
      addTearDown(subscription.cancel);

      sensor
        ..emit(FakeMotionSensor.still)
        ..emit(FakeMotionSensor.moving);
      await Future<void>.delayed(Duration.zero);

      expect(seen, [FakeMotionSensor.still, FakeMotionSensor.moving]);
    });

    test('tracks whether anything is listening', () async {
      final sensor = FakeMotionSensor();
      addTearDown(sensor.dispose);

      expect(sensor.hasListener, isFalse);
      final subscription = sensor.samples.listen((_) {});
      expect(sensor.hasListener, isTrue);
      await subscription.cancel();
      expect(sensor.hasListener, isFalse);
    });

    test('emitting after dispose is a quiet no-op', () async {
      final sensor = FakeMotionSensor();
      await sensor.dispose();
      expect(() => sensor.emit(FakeMotionSensor.still), returnsNormally);
    });

    test('dispose is idempotent', () async {
      final sensor = FakeMotionSensor();
      await sensor.dispose();
      await sensor.dispose();
      expect(sensor.hasListener, isFalse);
    });

    test('the still sample reads as gravity and moving does not', () {
      expect(FakeMotionSensor.still.magnitude, closeTo(9.80665, 1e-9));
      expect(FakeMotionSensor.moving.magnitude, closeTo(4, 1e-9));
    });
  });
}
