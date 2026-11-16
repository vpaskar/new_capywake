import 'dart:math' as math;

import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:meta/meta.dart';

/// Pure decision layer for the post-dismiss "still up?" motion check.
///
/// It answers one question — *did this phone move enough, for long enough,
/// after the alarm was stopped?* — from nothing but accelerometer readings and
/// elapsed time. There is no stream, no timer and no plugin here, so every
/// threshold below can be exercised with synthetic samples.
///
/// ## Sustained motion, not a shake
///
/// The window is sliced into fixed [bucket]s. A bucket counts as *moving* when
/// at least one reading in it deviates from gravity by more than
/// [movementEpsilon]; the check passes only once [requiredMovingBuckets] of
/// them have. That is the anti-cheat: one shake marks a single bucket and gets
/// nowhere, while genuinely being up and about marks bucket after bucket.
///
/// ## What this can and cannot know
///
/// It measures the **phone**, never the person. A phone left charging across
/// the room reports stillness however awake its owner is, and a phone left in
/// the bed reports the opposite of the truth. That limitation is the reason
/// the feature is off by default and the reason its copy says plainly that
/// CapyWake watches the phone.
@immutable
class MotionCheckService {
  /// Construct a check with the shipped thresholds, or narrower ones in tests.
  ///
  /// Not `const`: the bounds below compare [Duration]s, and Dart cannot
  /// evaluate that in a constant expression. Asserting the invariants is worth
  /// more than a canonicalised instance of a service the app builds once.
  // ignore: prefer_const_constructors_in_immutables
  MotionCheckService({
    this.window = defaultWindow,
    this.bucket = defaultBucket,
    this.movementEpsilon = defaultMovementEpsilon,
    this.requiredMovingFraction = defaultRequiredMovingFraction,
  }) : assert(window > Duration.zero, 'window must be positive.'),
       assert(bucket > Duration.zero, 'bucket must be positive.'),
       assert(bucket <= window, 'bucket must fit inside the window.'),
       assert(movementEpsilon > 0, 'movementEpsilon must be positive.'),
       assert(
         requiredMovingFraction > 0 && requiredMovingFraction <= 1,
         'requiredMovingFraction must be in (0, 1].',
       );

  /// How long CapyWake watches after the alarm is stopped.
  ///
  /// Ninety seconds is long enough that simply standing up and picking the
  /// phone up clears it, and short enough that the re-ring still lands while
  /// getting up is the thing the morning is about. It is not user-configurable
  /// in this phase.
  static const Duration defaultWindow = Duration(seconds: 90);

  /// The slice the window is counted in.
  static const Duration defaultBucket = Duration(seconds: 1);

  /// Earth's standard gravity (m/s²) — the magnitude a still phone reports in
  /// any orientation, and therefore the baseline movement is measured against.
  static const double standardGravity = 9.80665;

  /// How far (m/s²) a reading must sit from [standardGravity] to count.
  ///
  /// Tuned against the two readings that matter: a phone resting untouched on
  /// a hard surface, whose magnitude wanders only a few hundredths of a m/s²
  /// around gravity, and a phone carried in a hand or pocket by someone
  /// walking, which swings by several m/s² with every step. 1.5 clears sensor
  /// noise by an order of magnitude while sitting comfortably below ordinary
  /// walking, so neither a truck passing outside nor a nudged nightstand
  /// registers as being up.
  static const double defaultMovementEpsilon = 1.5;

  /// The share of buckets that must be moving for the check to pass.
  ///
  /// A majority, per the rule that duration — not intensity — is the
  /// anti-cheat: at the shipped window and bucket that is 45 separate seconds
  /// of movement out of 90. A shake, or dropping the phone back on the
  /// nightstand, cannot reach it; carrying the phone out of the bedroom does
  /// so without the user thinking about it.
  static const double defaultRequiredMovingFraction = 0.5;

  /// How long the check watches for. See [defaultWindow].
  final Duration window;

  /// The slice [window] is counted in. See [defaultBucket].
  final Duration bucket;

  /// Deviation from [standardGravity] that counts as movement.
  final double movementEpsilon;

  /// Share of buckets that must be moving. See
  /// [defaultRequiredMovingFraction].
  final double requiredMovingFraction;

  /// How many buckets [window] is divided into.
  int get bucketCount => (window.inMicroseconds / bucket.inMicroseconds).ceil();

  /// How many distinct buckets must contain movement for the check to pass.
  ///
  /// Never below one, so a caller that configures a very short window still
  /// has to see *something* rather than passing on an empty set.
  int get requiredMovingBuckets =>
      math.max(1, (bucketCount * requiredMovingFraction).ceil());

  /// Whether [sample] deviates from gravity by more than [movementEpsilon].
  bool isMovingSample(MotionSample sample) =>
      (sample.magnitude - standardGravity).abs() > movementEpsilon;

  /// The bucket [elapsed] falls in, or `null` when it lies outside [window].
  ///
  /// A reading that arrives before the window opened or after it closed is not
  /// evidence about the window, so it is dropped rather than clamped into an
  /// edge bucket it did not happen in.
  int? bucketIndexFor(Duration elapsed) {
    if (elapsed.isNegative || elapsed >= window) return null;
    return elapsed.inMicroseconds ~/ bucket.inMicroseconds;
  }

  /// Whether [movingBuckets] distinct moving buckets clear the bar.
  bool sawEnoughMotion(int movingBuckets) =>
      movingBuckets >= requiredMovingBuckets;

  /// Whether [elapsed] has reached the end of [window].
  bool isWindowComplete(Duration elapsed) => elapsed >= window;
}
