import 'dart:math' as math;

import 'package:meta/meta.dart';

/// One accelerometer reading, in metres per second squared.
///
/// Pure value type — no plugin types cross the [MotionSensor] seam, exactly as
/// `RingingAlarm` keeps `package:alarm` out of the lifecycle layer. The axes
/// are the device's own, and CapyWake deliberately does not care which is
/// which: only [magnitude] is ever read, so a phone face-up on a nightstand
/// and one lying on its side produce the same "not moving" answer.
@immutable
class MotionSample {
  const MotionSample({required this.x, required this.y, required this.z});

  /// Acceleration along the device's x axis (m/s²).
  final double x;

  /// Acceleration along the device's y axis (m/s²).
  final double y;

  /// Acceleration along the device's z axis (m/s²).
  final double z;

  /// Length of the acceleration vector (m/s²).
  ///
  /// A phone at rest in any orientation reads approximately Earth's gravity;
  /// movement pushes this above or below it. See
  /// `MotionCheckService.isMovingSample`.
  double get magnitude => math.sqrt(x * x + y * y + z * z);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MotionSample &&
        other.x == x &&
        other.y == y &&
        other.z == z;
  }

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'MotionSample(x: $x, y: $y, z: $z)';
}

/// Platform-agnostic stream of accelerometer readings.
///
/// `lib/core/` and `lib/features/` import this; only `lib/data/` knows about
/// `sensors_plus`. `FakeMotionSensor` backs every test, so the suite stays
/// headless and no test waits on a real sensor.
///
/// Honesty boundary (this matters more here than anywhere else in the app):
/// an accelerometer reports **whether the phone moved**. It cannot report
/// whether a person got out of bed. Every string built on top of this
/// abstraction must say so — see `alarmMotionCheckDescription`.
abstract class MotionSensor {
  /// Readings from the device accelerometer.
  ///
  /// Implementations emit continuously while listened to, including when the
  /// device is perfectly still (a still phone still reads gravity). Callers
  /// must cancel their subscription as soon as they are done: a leaked
  /// accelerometer subscription is a battery bug.
  Stream<MotionSample> get samples;

  /// Release any platform resources. Idempotent, so it is safe to call from
  /// `ref.onDispose`.
  Future<void> dispose();
}
