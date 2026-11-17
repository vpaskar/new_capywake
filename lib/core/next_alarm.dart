import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:meta/meta.dart';

/// Pure next-alarm calculation — Today-screen adapter over
/// [AlarmScheduleService].
///
/// `NextAlarmService` is a thin Phase-04 shim: it forwards to the Phase-05
/// schedule engine ([AlarmScheduleService.computeNextLocal] /
/// [AlarmScheduleService.computeNextLocalAcross]) and wraps the result in
/// the Today-friendly [NextAlarmInfo] value type. Centralising the
/// next-occurrence math in `AlarmScheduleService` means the Today card
/// and the Phase-06 alarm engine share one source of truth.
///
/// Time semantics:
///
/// - `now` is a **local** [DateTime]. The Today screen computes "now" from
///   the device wall clock and passes it in unchanged. The schedule
///   engine has a richer timezone-aware variant for the Phase-06 alarm
///   layer; the Today card never needs to *fire* an alarm, only describe
///   it, so this wrapper stays in plain local-DateTime land.
///
/// Finished occurrences:
///
/// - The data layer persists "I want to skip the next ring of this alarm"
///   as an [AlarmOccurrence] row with [AlarmStatus.skipped], and every ring
///   the user has dealt with ends up terminal too. The Today screen passes
///   those rows in via `finishedOccurrences`; the schedule engine walks past
///   them, so the card describes the next ring the user has *not* already
///   handled — the same rule the alarm engine arms by.
abstract final class NextAlarmService {
  /// Maximum number of forward days searched before giving up. Re-exported
  /// from [AlarmScheduleService.searchHorizonDays] so existing call sites
  /// (and tests) keep working.
  static const int searchHorizonDays = AlarmScheduleService.searchHorizonDays;

  /// Compute the very next [NextAlarmInfo] across all enabled alarms.
  static NextAlarmInfo? computeNext({
    required List<Alarm> alarms,
    required DateTime now,
    List<AlarmOccurrence> finishedOccurrences = const <AlarmOccurrence>[],
  }) {
    final result = AlarmScheduleService.computeNextLocalAcross(
      alarms: alarms,
      now: now,
      finishedOccurrences: finishedOccurrences,
    );
    return result == null ? null : _info(result);
  }

  /// Compute the next [NextAlarmInfo] for a single [alarm], or `null` if
  /// the alarm is disabled or no candidate exists within
  /// [searchHorizonDays].
  static NextAlarmInfo? computeNextForAlarm({
    required Alarm alarm,
    required DateTime now,
    List<AlarmOccurrence> finishedOccurrences = const <AlarmOccurrence>[],
  }) {
    final result = AlarmScheduleService.computeNextLocal(
      alarm: alarm,
      now: now,
      finishedOccurrences: finishedOccurrences,
    );
    return result == null ? null : _info(result);
  }

  static NextAlarmInfo _info(AlarmScheduleResult result) {
    return NextAlarmInfo(
      alarm: result.alarm,
      scheduledLocal: result.scheduledLocal,
      softStartLocal: result.softStartLocal,
    );
  }
}

/// A computed "what will fire next" snapshot. Pure value type — no
/// schedule-engine state, no Drift rows. The Today card maps the fields
/// here directly into its visible lines; History and the engine read
/// [AlarmOccurrencePlan] instead.
@immutable
class NextAlarmInfo {
  const NextAlarmInfo({
    required this.alarm,
    required this.scheduledLocal,
    required this.softStartLocal,
  });

  /// The alarm this fire belongs to.
  final Alarm alarm;

  /// When the alarm rings (the target time). Local time.
  final DateTime scheduledLocal;

  /// When the wake window opens, if any. `null` when there is no soft-start.
  /// Always strictly before [scheduledLocal] when set.
  final DateTime? softStartLocal;

  /// Convenience: `scheduledLocal.difference(now)`. Useful for the Today
  /// card's "in 6 hours 30 minutes" copy; the formatter lives in the UI
  /// layer so locale plural rules are handled there, not here.
  Duration timeUntil(DateTime now) => scheduledLocal.difference(now);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NextAlarmInfo &&
        other.alarm == alarm &&
        other.scheduledLocal == scheduledLocal &&
        other.softStartLocal == softStartLocal;
  }

  @override
  int get hashCode => Object.hash(alarm, scheduledLocal, softStartLocal);
}
