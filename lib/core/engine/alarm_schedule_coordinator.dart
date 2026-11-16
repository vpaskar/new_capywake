import 'dart:async';
import 'dart:developer' as developer;

import 'package:capywake/core/engine/alarm_engine.dart';
import 'package:capywake/core/engine/notification_schedule_calculator.dart';
import 'package:capywake/core/engine/notification_service.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// Coordinates the alarms list ↔ platform alarm scheduler.
///
/// The coordinator is the single seam where Drift state ([Alarm]s, plus
/// the finished and snoozed [AlarmOccurrence]s that bend the schedule)
/// becomes platform action: it flattens the upcoming schedule into
/// [AlarmOccurrencePlan]s, arms each via [AlarmEngine], and pushes the
/// corresponding pre-alarm reminders through [NotificationService]
/// (after the iOS 64-cap is enforced by
/// [NotificationScheduleCalculator]).
///
/// It lives in `lib/core/` because it is pure orchestration over
/// abstractions — there are no plugin imports here. Tests inject
/// `FakeAlarmEngine` / `FakeNotificationService` / `FakeClock` /
/// `tz.UTC` and assert on what was armed.
///
/// Reliability honesty: when the engine throws, we do **not** silently
/// retry. We log via `dart:developer` and continue with the remaining
/// plans — the reliability surface (driven by permissions +
/// `ReliabilityCopyService`) is the user-facing truth, not optimistic
/// retries here.
class AlarmScheduleCoordinator {
  // Dart cannot pass a private named initializing formal (`this._engine`), so
  // the fields are assigned in the initializer list instead.
  // ignore_for_file: prefer_initializing_formals
  AlarmScheduleCoordinator({
    required AlarmEngine engine,
    required NotificationService notifications,
    required tz.Location location,
    required DateTime Function() now,
    tz.Location Function()? readLocation,
    int upcomingPerAlarm = 4,
  }) : _engine = engine,
       _notifications = notifications,
       _readLocation = readLocation ?? (() => location),
       _now = now,
       _upcomingPerAlarm = upcomingPerAlarm;

  final AlarmEngine _engine;
  final NotificationService _notifications;
  final tz.Location Function() _readLocation;
  final DateTime Function() _now;
  final int _upcomingPerAlarm;
  Future<void> _pending = Future<void>.value();
  final _scheduleFailures = StreamController<bool>.broadcast();
  bool scheduleFailed = false;

  Stream<bool> get scheduleFailures => _scheduleFailures.stream;

  void dispose() {
    unawaited(_scheduleFailures.close());
  }

  void _reportScheduleFailure({required bool failed}) {
    if (scheduleFailed == failed || _scheduleFailures.isClosed) return;
    scheduleFailed = failed;
    _scheduleFailures.add(failed);
  }

  /// Recompute the full upcoming schedule from [alarms] (walking past the
  /// rings [finished] covers, honouring [snoozed]) and reflect it on the
  /// platform:
  /// cancel everything previously armed, arm the next-occurrence per
  /// enabled alarm, schedule pre-alarm notifications
  /// (calculator-truncated to the iOS 64-cap).
  ///
  /// This is the only mutator. Save / delete / setEnabled / skip / snooze in
  /// the repository all funnel through here.
  ///
  /// **Snooze.** Pressing Snooze writes a `snoozed` occurrence carrying the
  /// instant the alarm is due to ring again, and that write re-emits the
  /// occurrence streams — which lands right back here. So the snooze ring is
  /// not armed ad hoc anywhere; it is part of what this method computes, and
  /// therefore survives every later resync. Anything armed outside the
  /// computed set would be swept away by the next unrelated write, because
  /// arming starts by cancelling everything.
  ///
  /// **Dismiss.** The same write-then-recompute path runs when an occurrence
  /// terminates, and [finished] is what stops the recompute handing the
  /// morning straight back. A dismiss can land inside an open wake window —
  /// the user got up at 06:50 of a ramp that began at 06:45 — and the 07:00
  /// target it belongs to has *not* passed, so without this input the engine
  /// would arm that plan again, `arm` would floor its 06:45 start to the
  /// clock, and the alarm would sound seconds after being silenced.
  Future<void> sync({
    required List<Alarm> alarms,
    List<AlarmOccurrence> finished = const <AlarmOccurrence>[],
    List<AlarmOccurrence> snoozed = const <AlarmOccurrence>[],
  }) {
    final result = _pending.then((_) => _sync(alarms, finished, snoozed));
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _sync(
    List<Alarm> alarms,
    List<AlarmOccurrence> finished,
    List<AlarmOccurrence> snoozed,
  ) async {
    final now = _now().toUtc();
    final location = _readLocation();
    final nowTz = tz.TZDateTime.from(now, location);

    // Pull the next-occurrence per enabled alarm (one ring per alarm at
    // a time — the alarm package can only arm one platform alarm per id;
    // re-arming on dismiss is the lifecycle layer's job).
    final ringPlans = <AlarmOccurrencePlan>[];
    final notificationPlans = <AlarmOccurrencePlan>[];
    for (final alarm in alarms) {
      if (!alarm.enabled) continue;
      final next = AlarmScheduleService.computeNextForAlarm(
        alarm: alarm,
        now: nowTz,
        location: location,
        finishedOccurrences: finished,
      );
      final snoozePlan = _snoozePlanFor(
        alarm: alarm,
        snoozed: snoozed,
        now: now,
        location: location,
      );
      final ring = _earlier(snoozePlan, next);
      if (ring != null) {
        ringPlans.add(ring);
      }
      // For pre-alarm reminders we look further ahead — a repeating
      // alarm benefits from queuing the next few days so the user sees
      // a calm soft-wake nudge even if they skip a day.
      final upcoming = AlarmScheduleService.computeUpcomingForAlarm(
        alarm: alarm,
        now: nowTz,
        location: location,
        finishedOccurrences: finished,
        count: _upcomingPerAlarm,
      );
      notificationPlans.addAll(upcoming);
    }

    final pending = NotificationScheduleCalculator.compute(
      plans: notificationPlans,
      now: _now(),
    );

    try {
      await _engine.rescheduleAll(ringPlans);
      _reportScheduleFailure(failed: false);
    } on Object catch (error, stack) {
      _reportScheduleFailure(failed: true);
      developer.log(
        'AlarmScheduleCoordinator.sync arm failed',
        name: 'capywake.coordinator',
        error: error,
        stackTrace: stack,
      );
    }
    try {
      await _notifications.scheduleAll(pending);
    } on Object catch (error, stack) {
      developer.log(
        'AlarmScheduleCoordinator.sync notifications failed',
        name: 'capywake.coordinator',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// The live snooze ring for [alarm], or `null` when it has none pending.
  ///
  /// A snoozed row stays `snoozed` until the occurrence terminates, so one
  /// whose instant has already gone by is not a ring waiting to happen — it is
  /// a ring that already happened, or one the app was not running for. Arming
  /// it would be actively harmful: Android's `setAlarmClock` fires a past
  /// trigger immediately, and `package:alarm`'s launch check stops any stored
  /// alarm whose time has passed. Hence the strict `isAfter(now)`.
  ///
  /// The plan carries **no soft start**, whatever the alarm's wake mode. A
  /// wake window is a property of the morning the user chose, not of a nine-
  /// minute snooze; fading a snooze ring in over fifteen minutes would answer
  /// "wake me again shortly" with most of that time in near-silence. Same
  /// reasoning as [AlarmEngine.ringNow].
  AlarmOccurrencePlan? _snoozePlanFor({
    required Alarm alarm,
    required List<AlarmOccurrence> snoozed,
    required DateTime now,
    required tz.Location location,
  }) {
    DateTime? soonest;
    for (final occ in snoozed) {
      if (occ.alarmId != alarm.id) continue;
      if (occ.status != AlarmStatus.snoozed) continue;
      final at = occ.nextRingAt;
      if (!at.isAfter(now)) continue;
      if (soonest == null || at.isBefore(soonest)) {
        soonest = at;
      }
    }
    if (soonest == null) return null;
    return AlarmOccurrencePlan(
      alarm: alarm,
      scheduled: tz.TZDateTime.from(soonest, location),
      softStart: null,
      location: location,
    );
  }

  /// Whichever of [a] / [b] is due first, tolerating nulls on either side.
  ///
  /// Only one platform alarm can be armed per alarm id, so a pending snooze
  /// and the next scheduled occurrence have to be reconciled rather than both
  /// armed. In practice the snooze is minutes away and the scheduled ring is
  /// hours, but the comparison is done properly rather than assumed: a long
  /// snooze on an alarm that repeats soon must not push the scheduled ring
  /// off the platform.
  ///
  /// The comparison is on [AlarmOccurrencePlan.scheduled] — the **target** —
  /// and not on `ringAt`, which is where this went wrong the first time. A
  /// wake window makes `ringAt` the soft start, and the soft start of the
  /// occurrence the user is *currently snoozing* is already in the past. Ranked
  /// by `ringAt` that stale 06:45 beats a snooze due at 06:55, and arming it
  /// floors to the clock — so pressing Snooze during a Gentle ramp would set
  /// the alarm off again two seconds later. Targets are the honest comparison:
  /// a window is one ring that begins early, so the moment it is *for* is what
  /// decides which of two candidates comes first.
  static AlarmOccurrencePlan? _earlier(
    AlarmOccurrencePlan? a,
    AlarmOccurrencePlan? b,
  ) {
    if (a == null) return b;
    if (b == null) return a;
    return a.scheduled.isAfter(b.scheduled) ? b : a;
  }

  /// Cancel everything (used when notification permission is revoked
  /// or the user signs out of Pro features that depended on it). The
  /// repository state is unchanged — calling [sync] again re-arms.
  Future<void> cancelAll() {
    final result = _pending.then((_) => _cancelAll());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _cancelAll() async {
    try {
      await _engine.rescheduleAll(const <AlarmOccurrencePlan>[]);
    } on Object catch (error, stack) {
      developer.log(
        'AlarmScheduleCoordinator.cancelAll engine failed',
        name: 'capywake.coordinator',
        error: error,
        stackTrace: stack,
      );
    }
    try {
      await _notifications.cancelAll();
    } on Object catch (error, stack) {
      developer.log(
        'AlarmScheduleCoordinator.cancelAll notifications failed',
        name: 'capywake.coordinator',
        error: error,
        stackTrace: stack,
      );
    }
  }
}
