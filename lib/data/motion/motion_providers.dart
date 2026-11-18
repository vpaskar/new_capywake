import 'package:capywake/core/motion/fake_motion_sensor.dart';
import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/data/motion/platform_motion_sensor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// The accelerometer. Defaults to a silent [FakeMotionSensor] so no test
/// reaches a real sensor; production applies [platformMotionOverride].
final motionSensorProvider = Provider<MotionSensor>((ref) {
  final sensor = FakeMotionSensor();
  ref.onDispose(sensor.dispose);
  return sensor;
}, dependencies: const []);

Override platformMotionOverride() =>
    motionSensorProvider.overrideWith((ref) => PlatformMotionSensor());
