import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// The device accelerometer. The only file that imports `sensors_plus`.
class PlatformMotionSensor implements MotionSensor {
  /// A shake peak lasts ~100 ms; the plugin's default 200 ms would miss it.
  static const Duration samplingPeriod = SensorInterval.gameInterval;

  @override
  Stream<MotionSample> get samples =>
      accelerometerEventStream(samplingPeriod: samplingPeriod).map(
        (event) => MotionSample(x: event.x, y: event.y, z: event.z),
      );

  /// The plugin stops the sensor when the last listener cancels.
  @override
  Future<void> dispose() async {}
}
