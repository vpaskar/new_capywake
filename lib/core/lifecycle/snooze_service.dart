import 'package:capywake/core/models/models.dart';
import 'package:meta/meta.dart';

/// Outcome of pressing **Snooze** on a ringing alarm.
///
/// Pure value type returned by [SnoozeService.snooze]. The caller (the
/// ringing controller in `lib/features/ringing/`) persists an occurrence
/// carrying [nextRingAt]; `AlarmScheduleCoordinator` picks that row up and
/// arms the platform ring. When [isFinalAlarm] is true the ring it arms is
/// the **final alarm** — the last one, offered without a Snooze button.
@immutable
class SnoozeOutcome {
  const SnoozeOutcome({
    required this.nextRingAt,
    required this.snoozeCount,
    required this.snoozeDurationMinutes,
    required this.isFinalAlarm,
  }) : assert(snoozeCount >= 1, 'snoozeCount must be >= 1.'),
       assert(
         snoozeDurationMinutes >= 1,
         'snoozeDurationMinutes must be >= 1.',
       );

  /// UTC instant the alarm should ring next.
  final DateTime nextRingAt;

  /// Updated total snooze count for the occurrence (1 after the first
  /// snooze, 2 after the second, …).
  final int snoozeCount;

  /// The actual minutes used for *this* snooze step. May be smaller than
  /// the configured base if "shrinking snoozes" kicks in for strict mode.
  final int snoozeDurationMinutes;

  /// `true` when this snooze step is the **last** one — the next ring is
  /// the final alarm. The UI should stop offering a Snooze button once the
  /// occurrence reaches this state.
  final bool isFinalAlarm;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SnoozeOutcome &&
        other.nextRingAt.isAtSameMomentAs(nextRingAt) &&
        other.snoozeCount == snoozeCount &&
        other.snoozeDurationMinutes == snoozeDurationMinutes &&
        other.isFinalAlarm == isFinalAlarm;
  }

  @override
  int get hashCode => Object.hash(
    nextRingAt.millisecondsSinceEpoch,
    snoozeCount,
    snoozeDurationMinutes,
    isFinalAlarm,
  );
}

/// Why a snooze attempt was refused.
enum SnoozeDeniedReason {
  /// The alarm has `snoozeEnabled == false`. Snooze was never offered.
  snoozeDisabled,

  /// `snoozeCount` already equals the configured `maxSnoozes`. The next
  /// ring is the final alarm; only dismiss is offered.
  capReached,
}

/// Pure-Dart snooze math.
///
/// Given a ringing [Alarm] and the current [AlarmOccurrence], computes the
/// next ring time, enforces the cap, optionally shrinks subsequent snooze
/// durations for strict mode, and surfaces the no-snooze final alarm
/// boundary.
///
/// **This is the only "final alarm" CapyWake has.** It is the ring that
/// takes the occurrence to `alarm.maxSnoozes`, and the ringing screen offers
/// no Snooze button on it. The legacy had a second, clock-anchored final
/// alarm was configurable on the form and shown on the Today card; nothing
/// ever armed a ring at it, so it was removed rather than built.
///
/// No I/O, no Flutter, no providers — every output is a pure function of
/// the inputs so it can be unit-tested at ~100% coverage.
///
/// **Strict-mode shrinking:** strict mode users opted into "wake me up";
/// piling on nine-minute snoozes defeats the point. The shrinking rule is
/// deterministic and conservative — every additional snooze in strict mode
/// shaves one minute off the configured base, floored at 1 minute. Gentle
/// and standard modes are not shrunk (the user picked the duration).
class SnoozeService {
  /// Construct a [SnoozeService]. Stateless; safe to share across calls.
  const SnoozeService();

  /// Whether the user can press Snooze right now.
  ///
  /// Returns `true` only when the alarm allows snoozing AND the occurrence
  /// has not yet hit the configured cap. The ringing UI uses this to hide
  /// the Snooze button after the cap is reached.
  bool canSnooze({required Alarm alarm, required AlarmOccurrence occurrence}) {
    if (!alarm.snoozeEnabled) return false;
    final cap = alarm.maxSnoozes;
    if (cap == null) return true; // unlimited
    return occurrence.snoozeCount < cap;
  }

  /// Whether the ring happening right now **is** the final alarm.
  ///
  /// This is deliberately not the negation of [canSnooze]. `canSnooze` is
  /// false for two different reasons, and only one of them is a final
  /// alarm:
  ///
  /// - the alarm has snooze switched off entirely — there was never a
  ///   Snooze button, no cap was reached, and nothing about this ring is
  ///   "final"; it is simply how that alarm always rings;
  /// - the occurrence has reached `alarm.maxSnoozes` — the snoozes ran
  ///   out, and this ring is the last one.
  ///
  /// Only the second returns true. An alarm with snooze off, or one with
  /// an unlimited cap, never has a final alarm to announce.
  bool isFinalAlarm({
    required Alarm alarm,
    required AlarmOccurrence occurrence,
  }) {
    if (!alarm.snoozeEnabled) return false;
    final cap = alarm.maxSnoozes;
    if (cap == null) return false; // unlimited — no last ring exists
    return occurrence.snoozeCount >= cap;
  }

  /// Compute the next snooze step.
  ///
  /// Returns a [SnoozeOutcome] when snooze is allowed; returns a
  /// [SnoozeDeniedReason] when the alarm forbids it (snooze disabled, or
  /// the cap is already reached).
  ///
  /// The returned `isFinalAlarm` flag is **true** when this snooze
  /// transition will leave the occurrence with no further snoozes
  /// available — i.e. `newSnoozeCount == cap` for a capped alarm. Final
  /// alarms have no snooze button, only dismiss.
  ({SnoozeOutcome? outcome, SnoozeDeniedReason? deniedReason}) snooze({
    required Alarm alarm,
    required AlarmOccurrence occurrence,
    required DateTime now,
  }) {
    if (!alarm.snoozeEnabled) {
      return (outcome: null, deniedReason: SnoozeDeniedReason.snoozeDisabled);
    }
    final cap = alarm.maxSnoozes;
    if (cap != null && occurrence.snoozeCount >= cap) {
      return (outcome: null, deniedReason: SnoozeDeniedReason.capReached);
    }

    final newCount = occurrence.snoozeCount + 1;
    final duration = _durationFor(
      alarm: alarm,
      newSnoozeCount: newCount,
    );
    final nextRingAt = now.toUtc().add(Duration(minutes: duration));
    final isFinal = cap != null && newCount >= cap;

    return (
      outcome: SnoozeOutcome(
        nextRingAt: nextRingAt,
        snoozeCount: newCount,
        snoozeDurationMinutes: duration,
        isFinalAlarm: isFinal,
      ),
      deniedReason: null,
    );
  }

  /// The duration applied for the [newSnoozeCount]-th snooze. Strict mode
  /// shrinks one minute per additional snooze; other modes keep the
  /// configured value.
  int _durationFor({required Alarm alarm, required int newSnoozeCount}) {
    final base = alarm.snoozeDurationMinutes;
    if (alarm.wakeMode != WakeMode.strict) return base;
    // Shrink only after the first snooze. The first one stays at base —
    // a half-asleep user gets the duration they configured, then it
    // tightens. Floor at 1 minute so we never produce a 0-minute snooze.
    final shrinkBy = (newSnoozeCount - 1).clamp(0, base - 1);
    final shrunk = base - shrinkBy;
    return shrunk < 1 ? 1 : shrunk;
  }
}
