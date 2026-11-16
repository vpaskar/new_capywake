import 'package:capywake/core/models/models.dart';
import 'package:meta/meta.dart';

/// Pure-Dart soft-start / target window math.
///
/// `WakeWindowService` is a thin, focused calculator that turns an [Alarm]
/// (whose target and window durations live as integer minutes) into a
/// concrete [WakeWindow] anchored on a given target instant. Phase 05's
/// scheduling engine emits the target instant; this service describes the
/// soft-start ramp leading up to it.
///
/// Why a separate service when the schedule engine already returns
/// `softStartLocal`? Two reasons:
///
/// 1. The Today card and the alarm form both want to *describe* the window
///    in plain English ("Soft wake starts 06:45") without re-running the
///    scheduling engine. They hold a target [DateTime] and just need the
///    deltas applied — that's this service.
/// 2. The volume fade-in itself is mode-dependent, and keeping that math
///    here, in `lib/core/`, means it stays Flutter-free and fully
///    unit-tested at ~100% coverage. `WakeVolumeRamp` samples [WakeRamp]
///    into the stepped curve the platform alarm adapter arms with — the
///    only place in the app where a real volume curve is applied.
///
/// **Reliability honesty:** the soft-start ramp CapyWake schedules is a
/// volume fade-in on the alarm sound — not a "wake during light sleep"
/// detector. There is no sleep-stage detection. The user-facing copy
/// surfaces this honestly via `ReliabilityCopyService` and the alarm
/// form's window-explanation copy.
abstract final class WakeWindowService {
  /// Lower bound on a meaningful soft-start ramp. `0` means "no ramp" —
  /// the alarm just rings at the target with no fade-in.
  static const int minSoftStartMinutes = 0;

  /// Upper bound on the soft-start ramp. The wake-window is "the gentle
  /// minutes leading up to the target"; capped at 30 minutes so the form
  /// stays a single slider.
  static const int maxSoftStartMinutes = 30;

  /// Compute a [WakeWindow] from [alarm] anchored at the local [target]
  /// instant. The target is whatever the schedule engine has emitted (or
  /// what the form is currently previewing).
  static WakeWindow forTarget({
    required Alarm alarm,
    required DateTime target,
  }) {
    final softStart = alarm.wakeWindowStartMinutesBefore > 0
        ? target.subtract(
            Duration(minutes: alarm.wakeWindowStartMinutesBefore),
          )
        : null;
    return WakeWindow(
      target: target,
      softStart: softStart,
      ramp: WakeRamp.fromMode(
        wakeMode: alarm.wakeMode,
        softStartMinutes: alarm.wakeWindowStartMinutesBefore,
      ),
    );
  }

  /// Compute the same window from individual minute fields. Useful for
  /// the alarm form, which previews the window without first writing an
  /// [Alarm] row.
  ///
  /// Asserts that the minute value is within the `min*` / `max*` bounds —
  /// the form's slider clamps to these.
  static WakeWindow forMinutes({
    required DateTime target,
    required WakeMode wakeMode,
    required int softStartMinutesBefore,
  }) {
    assert(
      softStartMinutesBefore >= minSoftStartMinutes &&
          softStartMinutesBefore <= maxSoftStartMinutes,
      'softStartMinutesBefore out of [min, max] bounds.',
    );
    final softStart = softStartMinutesBefore > 0
        ? target.subtract(Duration(minutes: softStartMinutesBefore))
        : null;
    return WakeWindow(
      target: target,
      softStart: softStart,
      ramp: WakeRamp.fromMode(
        wakeMode: wakeMode,
        softStartMinutes: softStartMinutesBefore,
      ),
    );
  }
}

/// Pure value type describing a single alarm's wake window.
///
/// `WakeWindow` is the answer to "given the alarm and the next target
/// instant, what does the soft-start ramp look like?". Read [softStart] for
/// the ramp start (`null` = no ramp), [target] for the alarm itself, and
/// [ramp] for the volume curve applied across the two.
@immutable
class WakeWindow {
  const WakeWindow({
    required this.target,
    required this.softStart,
    required this.ramp,
  });

  /// The main alarm instant — when the alarm "really" rings.
  final DateTime target;

  /// When the soft-start ramp begins. `null` when the alarm has no soft
  /// start (the ramp duration is 0 minutes — Standard / Strict default).
  final DateTime? softStart;

  /// The volume ramp applied during the soft-start window (a flat 100%
  /// when there is no soft-start).
  final WakeRamp ramp;

  /// Whether the alarm has a meaningful soft-start ramp.
  bool get hasSoftStart => softStart != null;

  /// Returns the volume the ramp would emit at instant [now] (in `[0, 1]`).
  ///
  /// Convenience around [WakeRamp.volumeAt] that also handles the
  /// pre-ramp ("not yet ramping → 0") and post-target ("full volume")
  /// regions, so a caller holding absolute instants does not have to
  /// re-derive the boundary cases.
  ///
  /// The platform path does not come through here: `package:alarm` wants
  /// offsets from the moment the ring starts, not wall-clock instants, so
  /// `WakeVolumeRamp` samples [ramp] directly.
  double volumeAt(DateTime now) {
    final start = softStart;
    if (start == null) return 1;
    if (!now.isAfter(start)) return ramp.startVolume;
    if (!now.isBefore(target)) return 1;
    final total = target.difference(start).inMilliseconds;
    if (total <= 0) return 1;
    final elapsed = now.difference(start).inMilliseconds;
    final progress = elapsed / total;
    return ramp.volumeAt(progress);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WakeWindow &&
        other.target.isAtSameMomentAs(target) &&
        _instantEqual(other.softStart, softStart) &&
        other.ramp == ramp;
  }

  @override
  int get hashCode => Object.hash(
    target.millisecondsSinceEpoch,
    softStart?.millisecondsSinceEpoch,
    ramp,
  );
}

bool _instantEqual(DateTime? a, DateTime? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.isAtSameMomentAs(b);
}

/// The volume curve applied during the soft-start ramp.
///
/// Pure data. `WakeVolumeRamp.stepsFor` samples this into the stepped
/// curve `PlatformAlarmEngine` hands the platform; tests verify the curve
/// shape directly, on both sides of that boundary.
///
/// **Reliability honesty:** the ramp is a real volume fade applied by
/// the platform alarm engine — not a sleep-stage-aware wake. We keep
/// the language honest: "a soft volume ramp leading up to the target".
@immutable
class WakeRamp {
  const WakeRamp({
    required this.startVolume,
    required this.endVolume,
    required this.curve,
  }) : assert(
         startVolume >= 0 && startVolume <= 1,
         'startVolume must be in [0, 1].',
       ),
       assert(
         endVolume >= 0 && endVolume <= 1,
         'endVolume must be in [0, 1].',
       );

  /// Pick a ramp from the wake mode + the configured soft-start length.
  ///
  /// - `softStartMinutes == 0` → [flat] (no ramp at all).
  /// - Gentle → quiet 5% start ramping smoothly to 100% (an `easeIn`
  ///   curve so the loudest stretch is the *last* couple of minutes,
  ///   matching how a real sunrise feels).
  /// - Standard → 50% to 100% linear — Standard with a manual soft-start
  ///   is "starts a touch quieter, hits full at the target".
  /// - Strict → flat (Strict users opted into "wake me up"; we don't
  ///   silently start them quiet).
  factory WakeRamp.fromMode({
    required WakeMode wakeMode,
    required int softStartMinutes,
  }) {
    if (softStartMinutes <= 0) return flat;
    switch (wakeMode) {
      case WakeMode.gentle:
        return const WakeRamp(
          startVolume: 0.05,
          endVolume: 1,
          curve: WakeRampCurve.easeIn,
        );
      case WakeMode.standard:
        return const WakeRamp(
          startVolume: 0.5,
          endVolume: 1,
          curve: WakeRampCurve.linear,
        );
      case WakeMode.strict:
        return flat;
    }
  }

  /// The flat-100%, no-ramp default (Standard / Strict modes, or any mode
  /// when the user has set the soft-start to 0 minutes).
  static const flat = WakeRamp(
    startVolume: 1,
    endVolume: 1,
    curve: WakeRampCurve.linear,
  );

  /// Volume at the start of the ramp (`progress == 0`).
  final double startVolume;

  /// Volume at the end of the ramp (`progress == 1`).
  final double endVolume;

  /// Curve applied between [startVolume] and [endVolume].
  final WakeRampCurve curve;

  /// Whether this ramp does anything (i.e. it actually fades).
  bool get isFading => startVolume != endVolume;

  /// Volume at fractional ramp [progress] in `[0, 1]`. Out-of-range
  /// inputs are clamped — the data layer can call this on any instant
  /// without first checking the boundary.
  double volumeAt(double progress) {
    final p = progress.clamp(0.0, 1.0);
    final eased = _ease(p, curve);
    return startVolume + (endVolume - startVolume) * eased;
  }

  static double _ease(double t, WakeRampCurve curve) {
    switch (curve) {
      case WakeRampCurve.linear:
        return t;
      case WakeRampCurve.easeIn:
        // Quadratic ease-in: spend more time quiet, ramp faster near
        // the end. Matches the "gentle dawn" feel.
        return t * t;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WakeRamp &&
        other.startVolume == startVolume &&
        other.endVolume == endVolume &&
        other.curve == curve;
  }

  @override
  int get hashCode => Object.hash(startVolume, endVolume, curve);
}

/// Easing curve applied to the volume ramp.
enum WakeRampCurve {
  /// Constant rate of change — used for Standard mode's mild ramp.
  linear,

  /// Slow start, faster finish — used for Gentle mode so the loudest
  /// stretch falls in the last couple of minutes.
  easeIn,
}
