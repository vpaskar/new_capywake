import 'package:capywake/core/motion/motion_sensor.dart';

const gravity = 9.80665;
const sampleMs = 20;

/// Readings of a phone carried for [steps] footfalls, one every [periodMs]:
/// flat, then a [lift] over gravity for [bumpMs], once per period.
List<MotionSample> walk({
  required int steps,
  int periodMs = 500,
  double lift = 3,
  int bumpMs = 120,
  int startMs = 0,
  bool stamped = true,
  int tailMs = 200,
}) => [
  for (var t = 0; t < steps * periodMs + tailMs; t += sampleMs)
    MotionSample(
      x: 0,
      y: 0,
      z: gravity + (_inBump(t, periodMs, bumpMs, steps) ? lift : 0),
      timestamp: stamped
          ? DateTime.fromMicrosecondsSinceEpoch((startMs + t) * 1000)
          : null,
    ),
];

bool _inBump(int t, int periodMs, int bumpMs, int steps) {
  if (t ~/ periodMs >= steps) return false;
  final phase = t % periodMs;
  return phase >= 200 && phase < 200 + bumpMs;
}

/// Flat readings for [ms], stamped from [startMs].
List<MotionSample> still({required int ms, int startMs = 0}) => [
  for (var t = 0; t < ms; t += sampleMs)
    MotionSample(
      x: 0,
      y: 0,
      z: gravity,
      timestamp: DateTime.fromMicrosecondsSinceEpoch((startMs + t) * 1000),
    ),
];
