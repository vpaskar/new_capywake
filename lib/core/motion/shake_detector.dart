import 'package:capywake/core/motion/motion_check_service.dart';
import 'package:capywake/core/motion/motion_sensor.dart';

/// Counts shakes in accelerometer readings. One jolt is one shake: after a
/// shake the detector waits for a near-gravity reading before it counts again.
class ShakeDetector {
  ShakeDetector({
    this.shakeDeviation = defaultShakeDeviation,
    this.rearmDeviation = defaultRearmDeviation,
  }) : assert(
         rearmDeviation < shakeDeviation,
         'the re-arm level must sit below the shake level',
       );

  /// A brisk wrist shake from bed; walking with the phone stays under ~5.
  static const double defaultShakeDeviation = 8;
  static const double defaultRearmDeviation = 4;

  final double shakeDeviation;
  final double rearmDeviation;
  bool _armed = true;

  /// Whether [sample] is a new shake.
  bool register(MotionSample sample) {
    final deviation = (sample.magnitude - MotionCheckService.standardGravity)
        .abs();
    if (!_armed) {
      if (deviation < rearmDeviation) _armed = true;
      return false;
    }
    if (deviation <= shakeDeviation) return false;
    _armed = false;
    return true;
  }
}
