import 'package:capywake/core/motion/motion_sensor.dart';

/// Counts walking steps in accelerometer readings. Nothing counts until
/// [rhythmSteps] land in rhythm; then all of them at once, as a pedometer does.
class StepDetector {
  StepDetector({
    this.peakRise = defaultPeakRise,
    this.peakFall = defaultPeakFall,
    this.joltCeiling = defaultJoltCeiling,
    this.minGap = defaultMinGap,
    this.maxGap = defaultMaxGap,
    this.rhythmSteps = defaultRhythmSteps,
  }) : assert(peakFall < peakRise, 'a peak must end below where it began'),
       assert(rhythmSteps >= 2, 'a rhythm needs at least two steps'),
       assert(minGap < maxGap, 'the step window must not be empty');

  /// A step lifts a held phone 2–5 m/s² over gravity; a shake far more.
  static const double defaultPeakRise = 1.2;
  static const double defaultPeakFall = 0.2;
  static const double defaultJoltCeiling = 10;
  static const Duration defaultMinGap = Duration(milliseconds: 300);
  static const Duration defaultMaxGap = Duration(milliseconds: 2000);
  static const int defaultRhythmSteps = 4;

  /// Assumed spacing for readings without a timestamp: the game interval.
  static const Duration samplingPeriod = Duration(milliseconds: 20);
  static const double gravityBlend = 0.02;
  static const double smoothBlend = 0.3;

  final double peakRise;
  final double peakFall;
  final double joltCeiling;
  final Duration minGap;
  final Duration maxGap;
  final int rhythmSteps;

  Duration? _now;
  double? _gravity;
  double _smooth = 0;
  bool _inPeak = false;
  double _peakHeight = 0;
  Duration _peakAt = Duration.zero;
  Duration? _lastStepAt;
  int _pending = 0;
  bool _inRhythm = false;

  /// Steps [sample] releases: 0, 1, or [rhythmSteps] when a rhythm starts.
  int register(MotionSample sample) {
    final now = _advance(sample);
    final magnitude = sample.magnitude;
    final gravity = _gravity == null
        ? magnitude
        : _gravity! + gravityBlend * (magnitude - _gravity!);
    _gravity = gravity;
    _smooth += smoothBlend * (magnitude - gravity - _smooth);

    if (!_inPeak) {
      if (_smooth <= peakRise) return 0;
      _inPeak = true;
      _peakHeight = _smooth;
      _peakAt = now;
      return 0;
    }
    if (_smooth > _peakHeight) {
      _peakHeight = _smooth;
      _peakAt = now;
    }
    if (_smooth >= peakFall) return 0;
    _inPeak = false;
    return _footfall(_peakAt, _peakHeight);
  }

  Duration _advance(MotionSample sample) {
    final stamp = sample.timestamp;
    final now = stamp != null
        ? Duration(microseconds: stamp.microsecondsSinceEpoch)
        : (_now ?? Duration.zero) + samplingPeriod;
    _now = now;
    return now;
  }

  int _footfall(Duration at, double height) {
    if (height > joltCeiling) {
      _lastStepAt = null;
      _pending = 0;
      _inRhythm = false;
      return 0;
    }
    final last = _lastStepAt;
    if (last != null && at - last < minGap) return 0;
    _lastStepAt = at;
    if (last == null || at - last > maxGap) {
      _pending = 1;
      _inRhythm = false;
      return 0;
    }
    if (_inRhythm) return 1;
    _pending++;
    if (_pending < rhythmSteps) return 0;
    _inRhythm = true;
    final released = _pending;
    _pending = 0;
    return released;
  }
}
