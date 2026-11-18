import 'dart:math' as math;

import 'package:capywake/core/motion/motion_sensor.dart';

/// A physical direction on the screen: a tilt, an arrow, a step in a maze.
enum TiltDirection { up, down, left, right }

/// Reads which way the phone is tilted from the grip it started in, with
/// hysteresis. Angles, not m/s², so a lean reads the same at any grip.
class TiltReader {
  TiltReader({this.engageDegrees = 18, this.releaseDegrees = 9})
    : assert(
        releaseDegrees < engageDegrees,
        'a held tilt must release below where it engaged',
      );

  final double engageDegrees;
  final double releaseDegrees;
  ({double pitch, double roll, double facing})? _baseline;
  TiltDirection? _held;
  bool _waitingForLevel = false;

  /// The direction currently held, or `null` when the phone is level.
  TiltDirection? get held => _held;

  /// Drops the held direction and reads nothing until the phone is back near
  /// its starting grip, so letting go of a tilt is never read as the reverse.
  void suppressUntilLevel() {
    _held = null;
    _waitingForLevel = true;
  }

  /// The held direction after [sample]. The first reading is the level grip.
  TiltDirection? read(MotionSample sample) {
    final baseline = _baseline;
    if (baseline == null) {
      final facing = sample.z < 0 ? -1.0 : 1.0;
      _baseline = (
        pitch: _pitchOf(sample, facing),
        roll: _rollOf(sample),
        facing: facing,
      );
      return null;
    }
    final down = _wrap(_pitchOf(sample, baseline.facing) - baseline.pitch);
    final left = _rollOf(sample) - baseline.roll;
    final lean = math.max(down.abs(), left.abs());
    if (_waitingForLevel) {
      if (lean < releaseDegrees) _waitingForLevel = false;
      return null;
    }
    final held = _held;
    if (held != null && _lean(held, down: down, left: left) >= releaseDegrees) {
      return held;
    }
    _held = null;
    if (lean < engageDegrees) return null;
    return _held = down.abs() > left.abs()
        ? (down > 0 ? TiltDirection.down : TiltDirection.up)
        : (left > 0 ? TiltDirection.left : TiltDirection.right);
  }

  static double _lean(
    TiltDirection direction, {
    required double down,
    required double left,
  }) => switch (direction) {
    TiltDirection.down => down,
    TiltDirection.up => -down,
    TiltDirection.left => left,
    TiltDirection.right => -left,
  };

  static const double _degrees = 180 / math.pi;

  /// A full turn about the screen's left-right axis from the side it faced at
  /// the start: lowering the bottom edge raises it, even past upright.
  static double _pitchOf(MotionSample s, double facing) =>
      math.atan2(s.y, facing * s.z) * _degrees;

  /// How far the right edge points below level: right edge down is negative.
  static double _rollOf(MotionSample s) =>
      math.atan2(s.x, math.sqrt(s.y * s.y + s.z * s.z)) * _degrees;

  static double _wrap(double degrees) => (degrees + 180) % 360 - 180;
}
