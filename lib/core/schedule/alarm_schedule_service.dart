import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/local_time_of_day.dart';
import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

/// Pure scheduling engine: given an `Alarm` and a `now`, when does it next
/// fire? Deterministic given (alarms, now, location, finished).
///
/// Finished occurrences are rows in a terminal state — skipped, or dismissed /
/// escaped / missed once they rang — and the engine walks past the ring each
/// one belongs to. Without that, a wake window dismissed at 06:50 recomputes
/// as "today at 07:00, from 06:45", armed against an instant already gone by,
/// and the platform sounds it again on the spot.
///
/// DST and timezone behaviour, all three tested:
///
/// - **Spring-forward gap** — a target like 02:30 that does not exist on the
///   day the clock leaps to 03:00: fire at the next valid local instant. The
///   user asked to be woken at 02:30, the system lost 02:30, 03:00 is the next
///   thing that exists.
/// - **Fall-back overlap** — a target like 01:30 that happens twice: fire at
///   the first. Both choices ring once; the first is the calmer default.
/// - **Travel** — the schedule is a wall-clock rule, so recomputing with a new
///   `tz.Location` returns the next 07:00 in the new timezone.
abstract final class AlarmScheduleService {
  /// Maximum number of forward days searched before giving up. A repeating-
  /// weekday alarm always fires within 7 days, and a one-time alarm within
  /// 1 day; 14 leaves comfortable headroom for skipped runs without ever
  /// looping forever.
  ///
  /// Public so callers (incl. `NextAlarmService` and tests) can describe
  /// the horizon without re-deriving the constant.
  static const int searchHorizonDays = 14;

  /// Compute the next [AlarmOccurrencePlan] across all enabled alarms in
  /// [location], sorted by scheduled UTC instant (earliest wins; ties
  /// broken by earliest [Alarm.createdAt] for deterministic ordering).
  ///
  /// Returns `null` when no enabled alarm has a candidate within
  /// [searchHorizonDays].
  static AlarmOccurrencePlan? computeNext({
    required List<Alarm> alarms,
    required tz.TZDateTime now,
    required tz.Location location,
    List<AlarmOccurrence> finishedOccurrences = const <AlarmOccurrence>[],
  }) {
    AlarmOccurrencePlan? best;
    for (final alarm in alarms) {
      final plan = computeNextForAlarm(
        alarm: alarm,
        now: now,
        location: location,
        finishedOccurrences: finishedOccurrences,
      );
      if (plan == null) continue;
      if (best == null) {
        best = plan;
        continue;
      }
      if (plan.scheduled.isBefore(best.scheduled)) {
        best = plan;
      } else if (plan.scheduled.isAtSameMomentAs(best.scheduled) &&
          plan.alarm.createdAt.isBefore(best.alarm.createdAt)) {
        best = plan;
      }
    }
    return best;
  }

  /// Compute the next [AlarmOccurrencePlan] for a single [alarm] in
  /// [location], or `null` if the alarm is disabled or no candidate exists
  /// within [searchHorizonDays].
  static AlarmOccurrencePlan? computeNextForAlarm({
    required Alarm alarm,
    required tz.TZDateTime now,
    required tz.Location location,
    List<AlarmOccurrence> finishedOccurrences = const <AlarmOccurrence>[],
  }) {
    final upcoming = computeUpcomingForAlarm(
      alarm: alarm,
      now: now,
      location: location,
      finishedOccurrences: finishedOccurrences,
    );
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// Compute the next [count] [AlarmOccurrencePlan]s for [alarm], in
  /// chronological order, starting strictly after [now]. The Phase 06
  /// alarm engine arms the platform alarm + pre-alarm notifications from
  /// this list (the iOS 64-cap is enforced by the notification calculator,
  /// not here).
  ///
  /// For a one-time alarm (empty repeat-weekday set) the result is at most
  /// one entry — once it has fired, the lifecycle layer disables the
  /// alarm, so it cannot produce a second occurrence.
  static List<AlarmOccurrencePlan> computeUpcomingForAlarm({
    required Alarm alarm,
    required tz.TZDateTime now,
    required tz.Location location,
    List<AlarmOccurrence> finishedOccurrences = const <AlarmOccurrence>[],
    int count = 1,
  }) {
    if (count <= 0) return const <AlarmOccurrencePlan>[];
    if (!alarm.enabled) return const <AlarmOccurrencePlan>[];

    final time = LocalTimeOfDay.fromMinutes(alarm.targetTimeMinutes);
    final results = <AlarmOccurrencePlan>[];
    final live = _liveFinished(finishedOccurrences, now);

    for (var dayOffset = 0; dayOffset <= searchHorizonDays; dayOffset++) {
      // Build the candidate at the calendar-date of `now + dayOffset`,
      // dropped to the alarm's wall-clock target. Constructing through
      // `tz.TZDateTime(location, ...)` resolves the wall clock to a real
      // UTC instant, applying the timezone's DST rules:
      //
      // - During a spring-forward gap, the constructor's
      //   `_utcFromLocalDateTime` algorithm projects the requested
      //   wall-clock to the post-gap offset, so e.g. asking for 02:30
      //   on a US "spring forward" Sunday returns the 03:30 instant
      //   (the wall clock the user actually sees the moment after).
      //   CapyWake's product semantic is "if your target time does not
      //   exist, fire at the next valid instant"; this wraps that
      //   behaviour without a special case.
      // - During a fall-back overlap, the same algorithm chooses the
      //   first occurrence (the pre-fall-back instant) — see the
      //   constructor's `localOffset != adjustedOffset` branch. That
      //   matches our documented "first occurrence wins" rule.
      final base = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: dayOffset));
      final candidate = tz.TZDateTime(
        location,
        base.year,
        base.month,
        base.day,
        time.hour,
        time.minute,
      );
      if (!_dayMatches(alarm: alarm, candidate: candidate)) continue;
      if (!candidate.isAfter(now)) continue;
      if (_retires(
        alarmId: alarm.id,
        scheduledUtc: candidate.toUtc(),
        live: live,
      )) {
        continue;
      }
      results.add(
        _buildPlan(
          alarm: alarm,
          scheduled: candidate,
          location: location,
        ),
      );
      if (results.length >= count) break;
      if (alarm.repeatWeekdays.isEmpty) break; // one-time → at most one
    }
    return List.unmodifiable(results);
  }

  /// The target of the ring that [firedAt] belongs to.
  ///
  /// The platform reports only "alarm X started ringing, now". For an alarm
  /// with a wake window that instant is *not* the target — it is the soft
  /// start, or wherever inside the window arming floored to — so an
  /// occurrence created from it alone could not say which morning it was
  /// for. The schedule engine matches finished occurrences by exactly that,
  /// which is why the ringing layer resolves it here rather than storing the
  /// fire time and hoping.
  ///
  /// Returns the alarm's own wall-clock target when [firedAt] falls inside
  /// the window leading up to it, and [firedAt] itself otherwise: an alarm
  /// with no wake window rings at its target, and a ring arriving after the
  /// target — a late platform, a snooze, the motion check's extra ring — has
  /// no window left to belong to.
  static tz.TZDateTime targetForRing({
    required Alarm alarm,
    required tz.TZDateTime firedAt,
    required tz.Location location,
  }) {
    final window = Duration(minutes: alarm.wakeWindowStartMinutesBefore);
    if (window == Duration.zero) return firedAt;
    final time = LocalTimeOfDay.fromMinutes(alarm.targetTimeMinutes);
    // A wake window is capped at 30 minutes (`WakeWindowService
    // .maxSoftStartMinutes`), so the target it leads to is on the ring's own
    // local date or the next one — a window can pull a ring back across
    // midnight, never further.
    for (var dayOffset = 0; dayOffset <= 1; dayOffset++) {
      final base = tz.TZDateTime(
        location,
        firedAt.year,
        firedAt.month,
        firedAt.day,
      ).add(Duration(days: dayOffset));
      final candidate = tz.TZDateTime(
        location,
        base.year,
        base.month,
        base.day,
        time.hour,
        time.minute,
      );
      if (!_dayMatches(alarm: alarm, candidate: candidate)) continue;
      if (candidate.isBefore(firedAt)) continue;
      if (candidate.difference(firedAt) > window) continue;
      return candidate;
    }
    return firedAt;
  }

  /// Naive-local-DateTime variant used by the Today screen, which holds a
  /// plain [DateTime] from `DateTime.now().toLocal()` — no `tz.Location`
  /// in scope. Behaviour matches [computeNextForAlarm] except that
  /// arithmetic is done with the system's `DateTime` (so DST behaviour is
  /// whatever the platform's `DateTime.add` does — Today never tries to
  /// schedule a real ring, just to *describe* the next one).
  ///
  /// The Phase-06 alarm engine MUST use the timezone-aware variant to
  /// arm platform alarms; this one is the "what should we paint on the
  /// Today card?" path only.
  static AlarmScheduleResult? computeNextLocal({
    required Alarm alarm,
    required DateTime now,
    List<AlarmOccurrence> finishedOccurrences = const <AlarmOccurrence>[],
  }) {
    if (!alarm.enabled) return null;

    final time = LocalTimeOfDay.fromMinutes(alarm.targetTimeMinutes);
    final live = _liveFinished(finishedOccurrences, now);

    for (var dayOffset = 0; dayOffset <= searchHorizonDays; dayOffset++) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day + dayOffset,
        time.hour,
        time.minute,
      );
      if (alarm.repeatWeekdays.isNotEmpty &&
          !alarm.repeatWeekdays.contains(candidate.weekday)) {
        continue;
      }
      if (!candidate.isAfter(now)) continue;
      if (_retires(
        alarmId: alarm.id,
        scheduledUtc: candidate.toUtc(),
        live: live,
      )) {
        continue;
      }
      return _buildLocalResult(alarm: alarm, scheduledLocal: candidate);
    }
    return null;
  }

  /// Naive-local-DateTime variant of [computeNext] for the Today screen.
  /// Picks the soonest [AlarmScheduleResult] across all enabled alarms;
  /// ties broken by earliest [Alarm.createdAt].
  static AlarmScheduleResult? computeNextLocalAcross({
    required List<Alarm> alarms,
    required DateTime now,
    List<AlarmOccurrence> finishedOccurrences = const <AlarmOccurrence>[],
  }) {
    AlarmScheduleResult? best;
    for (final alarm in alarms) {
      final result = computeNextLocal(
        alarm: alarm,
        now: now,
        finishedOccurrences: finishedOccurrences,
      );
      if (result == null) continue;
      if (best == null) {
        best = result;
        continue;
      }
      if (result.scheduledLocal.isBefore(best.scheduledLocal)) {
        best = result;
      } else if (result.scheduledLocal.isAtSameMomentAs(best.scheduledLocal) &&
          result.alarm.createdAt.isBefore(best.alarm.createdAt)) {
        best = result;
      }
    }
    return best;
  }

  static AlarmScheduleResult _buildLocalResult({
    required Alarm alarm,
    required DateTime scheduledLocal,
  }) {
    final softStart = alarm.wakeWindowStartMinutesBefore > 0
        ? scheduledLocal.subtract(
            Duration(minutes: alarm.wakeWindowStartMinutesBefore),
          )
        : null;
    return AlarmScheduleResult(
      alarm: alarm,
      scheduledLocal: scheduledLocal,
      softStartLocal: softStart,
    );
  }

  /// The rows in [finished] that can still retire a candidate.
  ///
  /// Every candidate is strictly after [now], so a terminal occurrence whose
  /// morning has already gone by can never match one. That matters because
  /// the caller's list is every ring the user has *ever* dealt with — it
  /// grows by one a day per alarm and is never pruned — while the rings it
  /// can retire number at most one per alarm, during the half hour a wake
  /// window is open. Narrowing once here keeps the per-candidate scan
  /// proportional to what is live rather than to the whole history, on a
  /// path that reruns on every write to the alarms table.
  static List<AlarmOccurrence> _liveFinished(
    List<AlarmOccurrence> finished,
    DateTime now,
  ) {
    final nowUtc = now.toUtc();
    return <AlarmOccurrence>[
      for (final occ in finished)
        if (occ.status.isTerminal && occ.scheduledAt.toUtc().isAfter(nowUtc))
          occ,
    ];
  }

  /// True when [candidate]'s ISO weekday matches the alarm's repeat-set, or
  /// the alarm is one-time (any day inside the horizon is fine).
  static bool _dayMatches({
    required Alarm alarm,
    required tz.TZDateTime candidate,
  }) {
    if (alarm.repeatWeekdays.isEmpty) return true;
    return alarm.repeatWeekdays.contains(candidate.weekday);
  }

  /// True when one of [live] is the ring at [scheduledUtc] for [alarmId], so
  /// that ring is already over and must not be offered again.
  ///
  /// The key is `AlarmOccurrence.scheduledAt` — the morning the occurrence is
  /// for — compared as a canonical UTC instant, so a DST shift or a change of
  /// timezone between the row being written and the candidate being computed
  /// cannot make the two drift apart. It is an exact match rather than a
  /// tolerance window on purpose: "same morning" has a precise answer, and a
  /// fuzzy one is wrong in exactly the places (spring-forward, travel) where
  /// being wrong means an alarm rings that should not, or does not ring when
  /// it should.
  ///
  /// This is why `scheduledAt` had to stop moving under a snooze chain. While
  /// it doubled as the pending re-ring, a snoozed-then-dismissed row carried
  /// the last snooze instant and could not be matched to its own morning at
  /// all.
  ///
  /// [live] is expected to have come from [_liveFinished].
  static bool _retires({
    required String alarmId,
    required DateTime scheduledUtc,
    required List<AlarmOccurrence> live,
  }) {
    for (final occ in live) {
      if (occ.alarmId != alarmId) continue;
      if (occ.scheduledAt.toUtc().isAtSameMomentAs(scheduledUtc)) {
        return true;
      }
    }
    return false;
  }

  static AlarmOccurrencePlan _buildPlan({
    required Alarm alarm,
    required tz.TZDateTime scheduled,
    required tz.Location location,
  }) {
    final softStart = alarm.wakeWindowStartMinutesBefore > 0
        ? scheduled.subtract(
            Duration(minutes: alarm.wakeWindowStartMinutesBefore),
          )
        : null;
    return AlarmOccurrencePlan(
      alarm: alarm,
      scheduled: scheduled,
      softStart: softStart,
      location: location,
    );
  }
}

/// Pure value-type description of a single planned alarm fire.
///
/// The schedule engine emits these; the Phase 06 alarm engine /
/// notification calculator consume them. The Today card maps the same
/// fields onto its visible lines (via the Phase-04 `NextAlarmInfo`
/// adapter). Always-UTC instants are exposed via [scheduledUtc] etc. so
/// downstream code can store them in Drift without re-deriving.
@immutable
class AlarmOccurrencePlan {
  const AlarmOccurrencePlan({
    required this.alarm,
    required this.scheduled,
    required this.softStart,
    required this.location,
  });

  /// The alarm this fire belongs to.
  final Alarm alarm;

  /// The scheduled ring instant. A [tz.TZDateTime] in [location], so the
  /// wall clock the user sees and the underlying UTC are both available.
  final tz.TZDateTime scheduled;

  /// Soft-start (wake-window opens). `null` if the alarm has no soft-start.
  final tz.TZDateTime? softStart;

  /// The timezone location this plan is anchored to.
  final tz.Location location;

  /// Convenience: canonical UTC instant for storage and instant
  /// comparisons (matches `AlarmOccurrence.scheduledAt`'s contract).
  DateTime get scheduledUtc => scheduled.toUtc();

  /// `softStart.toUtc()` or `null`.
  DateTime? get softStartUtc => softStart?.toUtc();

  /// The instant the alarm actually starts making noise.
  ///
  /// [softStart] when the alarm has a wake window, [scheduled] otherwise. A
  /// wake window is one ring that *begins* early and rises to full volume at
  /// the target — not a separate quiet alarm followed by a real one. That is
  /// what the Today card already tells the user ("Starts quietly at 06:45"),
  /// it needs one platform id rather than two, and it costs nothing extra
  /// against the iOS pending-notification cap.
  tz.TZDateTime get ringAt => softStart ?? scheduled;

  /// `ringAt.toUtc()`.
  DateTime get ringAtUtc => ringAt.toUtc();

  /// How long the volume ramp has to climb — [ringAt] to [scheduled].
  ///
  /// [Duration.zero] when there is no wake window. Measured between the two
  /// instants rather than from the alarm's minute field on purpose: across a
  /// DST boundary the wall-clock gap and the elapsed time differ, and the
  /// platform fades in elapsed time.
  Duration get rampWindow => scheduled.difference(ringAt);

  /// [ringAt], never earlier than [notBefore].
  ///
  /// A wake window opens up to thirty minutes ahead of the target, and the
  /// schedule is recomputed on every write to the alarms table, on every
  /// skip, and on every launch. So arming is routinely asked for *inside* an
  /// open window — and handing the platform an instant that has already
  /// passed is not a rounding error: Android's `setAlarmClock` fires a past
  /// trigger immediately, so toggling an unrelated alarm at 06:50 would set
  /// the 07:00 alarm off on the spot, and `package:alarm`'s own launch check
  /// quietly *stops* any stored alarm whose time has gone by.
  ///
  /// The honest answer inside an open window is to join it: ring from here
  /// and let [rampWindowFrom] cover what is left, so the alarm still reaches
  /// full volume at the target. Past the target the occurrence is over and
  /// there is nothing left to join, so the target itself is the floor.
  tz.TZDateTime ringAtFrom(tz.TZDateTime notBefore) {
    final ideal = ringAt;
    if (!ideal.isBefore(notBefore)) return ideal;
    return notBefore.isBefore(scheduled) ? notBefore : scheduled;
  }

  /// [rampWindow] measured from [ringAtFrom], so a window joined late ramps
  /// across the time that is actually left rather than a window that has
  /// already partly gone.
  Duration rampWindowFrom(tz.TZDateTime notBefore) {
    final remaining = scheduled.difference(ringAtFrom(notBefore));
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Convenience: how long until [scheduled] from `now` (in the same
  /// location). Useful for the Today card's "in 6 hours" copy, but the
  /// formatter lives in the UI layer so locale plural rules stay there.
  Duration timeUntil(tz.TZDateTime now) => scheduled.difference(now);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlarmOccurrencePlan &&
        other.alarm == alarm &&
        other.scheduled.isAtSameMomentAs(scheduled) &&
        _instantEqual(other.softStart, softStart) &&
        identical(other.location, location);
  }

  @override
  int get hashCode => Object.hash(
    alarm,
    scheduled.millisecondsSinceEpoch,
    softStart?.millisecondsSinceEpoch,
    location,
  );
}

bool _instantEqual(tz.TZDateTime? a, tz.TZDateTime? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.isAtSameMomentAs(b);
}

/// Pure value-type result of [AlarmScheduleService.computeNextLocal].
///
/// The Today screen consumes this directly (rendered as the calm
/// next-alarm card). Phase 06 / data-layer code uses the timezone-aware
/// [AlarmOccurrencePlan] instead so DST shifts are correct.
@immutable
class AlarmScheduleResult {
  const AlarmScheduleResult({
    required this.alarm,
    required this.scheduledLocal,
    required this.softStartLocal,
  });

  /// The alarm this fire belongs to.
  final Alarm alarm;

  /// The scheduled ring instant (a naive local [DateTime]).
  final DateTime scheduledLocal;

  /// Soft-start (wake-window opens). `null` if the alarm has no soft-start.
  final DateTime? softStartLocal;

  /// Convenience: how long until [scheduledLocal] from `now`. Useful for
  /// the Today card's "in 6 hours" copy; the formatter lives in the UI
  /// layer so locale plural rules stay there.
  Duration timeUntil(DateTime now) => scheduledLocal.difference(now);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlarmScheduleResult &&
        other.alarm == alarm &&
        other.scheduledLocal == scheduledLocal &&
        other.softStartLocal == softStartLocal;
  }

  @override
  int get hashCode => Object.hash(alarm, scheduledLocal, softStartLocal);
}
