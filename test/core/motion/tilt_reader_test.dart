import 'dart:math' as math;

import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/core/motion/tilt_reader.dart';
import 'package:flutter_test/flutter_test.dart';

const _g = 9.80665;

/// Gravity as `sensors_plus` reports it for a phone pitched [pitch]° up from
/// flat (bottom edge lowered) and rolled [roll]° (right edge lowered).
MotionSample _attitude({double pitch = 0, double roll = 0}) {
  final p = pitch * math.pi / 180;
  final r = roll * math.pi / 180;
  return MotionSample(
    x: -_g * math.sin(r),
    y: _g * math.cos(r) * math.sin(p),
    z: _g * math.cos(r) * math.cos(p),
  );
}

TiltReader _levelAt({double pitch = 0, double roll = 0}) =>
    TiltReader()..read(_attitude(pitch: pitch, roll: roll));

void main() {
  test('the first reading is level, whatever the grip', () {
    final reader = TiltReader();
    expect(reader.read(_attitude(pitch: 70)), isNull);
    expect(reader.held, isNull);
  });

  test('each way engages at 18° from the baseline', () {
    for (final (pitch, roll, direction) in [
      (19.0, 0.0, TiltDirection.down),
      (-19.0, 0.0, TiltDirection.up),
      (0.0, 19.0, TiltDirection.right),
      (0.0, -19.0, TiltDirection.left),
    ]) {
      expect(
        _levelAt().read(_attitude(pitch: pitch, roll: roll)),
        direction,
        reason: '$pitch/$roll',
      );
      expect(_levelAt().read(_attitude(pitch: pitch * 0.9)), isNull);
    }
  });

  test('works held upright: 60° → 80° is a downward tilt', () {
    final reader = _levelAt(pitch: 60);
    expect(reader.read(_attitude(pitch: 80)), TiltDirection.down);
    expect(_levelAt(pitch: 60).read(_attitude(pitch: 40)), TiltDirection.up);
  });

  test('face down above the face, lowering the bottom edge is down', () {
    MotionSample faceDown(double lowered) {
      final p = lowered * math.pi / 180;
      return MotionSample(x: 0, y: _g * math.sin(p), z: -_g * math.cos(p));
    }

    final reader = TiltReader()..read(faceDown(0));
    expect(reader.read(faceDown(22)), TiltDirection.down);
    final wrap = TiltReader()..read(faceDown(-2));
    expect(wrap.read(faceDown(2)), isNull, reason: 'no wrap at 180°');
  });

  test('holds until the lean falls under 9°, then releases', () {
    final reader = _levelAt();
    expect(reader.read(_attitude(roll: 20)), TiltDirection.right);
    expect(reader.read(_attitude(roll: 10)), TiltDirection.right);
    expect(reader.read(_attitude(roll: 8)), isNull);
    expect(reader.held, isNull);
  });

  test('the stronger axis wins, and a held tilt can turn', () {
    expect(
      _levelAt().read(_attitude(pitch: 25, roll: 20)),
      TiltDirection.down,
    );
    final reader = _levelAt();
    expect(reader.read(_attitude(roll: -20)), TiltDirection.left);
    expect(reader.read(_attitude(pitch: -25)), TiltDirection.up);
  });

  test('after letting go, nothing reads until the grip is level again', () {
    final reader = _levelAt()..read(_attitude(pitch: 30));
    expect(reader.held, TiltDirection.down);
    reader.suppressUntilLevel();
    expect(reader.held, isNull);
    expect(reader.read(_attitude(pitch: 30)), isNull, reason: 'still tilted');
    expect(reader.read(_attitude()), isNull, reason: 'level is not "up"');
    expect(reader.read(_attitude(pitch: 25)), TiltDirection.down);
  });

  test('near upright, tilting further still reads down (no saturation)', () {
    for (final grip in [60.0, 75.0, 80.0, 88.0]) {
      for (final lean in [20.0, 30.0, 40.0]) {
        expect(
          _levelAt(pitch: grip).read(_attitude(pitch: grip + lean)),
          TiltDirection.down,
          reason: '$grip° + $lean°',
        );
      }
      expect(
        _levelAt(pitch: grip).read(_attitude(pitch: grip - 25)),
        TiltDirection.up,
        reason: '$grip° - 25°',
      );
    }
  });

  test('upright and rolled, the bottom edge still reads as down', () {
    final reader = _levelAt(pitch: 70, roll: 10);
    expect(reader.read(_attitude(pitch: 92, roll: 10)), TiltDirection.down);
  });

  test('release must sit below engage', () {
    expect(
      () => TiltReader(engageDegrees: 5, releaseDegrees: 6),
      throwsAssertionError,
    );
  });
}
