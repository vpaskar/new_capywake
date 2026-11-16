import 'dart:async';

import 'package:capywake/core/engine/alarm_engine.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';

/// Test double for [AlarmEngine].
///
/// Stores armed plans in-memory and emits ringing events through a
/// broadcast stream. Tests drive the fake directly — `arm`, `cancel`,
/// `rescheduleAll`, and the manual `fire(alarmId)` helper let the suite
/// exercise the lifecycle without a real device.
///
/// The fake is permissive on purpose: it accepts any plan unless
/// [failNextArm] / [failNextCancel] is set, in which case the next call
/// throws an [AlarmEngineException] (so tests can prove the caller
/// degrades honestly when the platform refuses).
class FakeAlarmEngine implements AlarmEngine {
  /// [now] is the clock [ringNow] and [fire] stamp events with. Tests that
  /// drive a fake clock pass their own so the emitted `firedAt` lines up with
  /// the occurrence rows they have written; the default is the wall clock,
  /// which is what the real adapter reports.
  FakeAlarmEngine({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  final Map<String, AlarmOccurrencePlan> _armed =
      <String, AlarmOccurrencePlan>{};
  final StreamController<RingingAlarm> _ringing =
      StreamController<RingingAlarm>.broadcast();

  /// When set, the next [arm] throws this exception (and clears it).
  AlarmEngineException? failNextArm;

  /// When set, the next [cancel] throws this exception (and clears it).
  AlarmEngineException? failNextCancel;

  /// When set, the next [rescheduleAll] throws this exception (and clears
  /// it). Lets tests prove the coordinator survives an engine-side failure
  /// (it logs and still schedules notifications).
  AlarmEngineException? failNextReschedule;

  /// Snapshot of currently-armed plans. Tests use this to assert "after
  /// rescheduleAll, exactly these alarms are armed".
  Map<String, AlarmOccurrencePlan> get armedSnapshot =>
      Map<String, AlarmOccurrencePlan>.unmodifiable(_armed);

  /// The instants successful [arm] and [rescheduleAll] calls were asked to
  /// ring at, in UTC and in call order.
  ///
  /// The armed plan alone does not say this: a plan carries both a target and
  /// a soft start, and which of the two the engine rings at is exactly the
  /// behaviour a wake-window test needs to pin. Recorded through
  /// [AlarmOccurrencePlan.ringAt], the ideal instant.
  ///
  /// The real adapter additionally floors that against the clock, so it never
  /// hands the platform a time that has gone by — see
  /// [AlarmOccurrencePlan.ringAtFrom], which is asserted directly rather than
  /// modelled here. Giving the fake a clock would only mean every test that
  /// plans a date had to keep two of them in step.
  final List<DateTime> armedRingInstantsUtc = <DateTime>[];

  /// Every instant ever handed to this engine, in call order and **never
  /// cleared** — including ones a later [rescheduleAll] replaced.
  ///
  /// [armedRingInstantsUtc] answers "what is armed now"; this answers "what
  /// was the platform ever asked for", and the difference matters because the
  /// platform cannot un-fire an alarm. A schedule that is briefly wrong and
  /// then corrected a few milliseconds later has already woken the user.
  final List<DateTime> everArmedRingInstantsUtc = <DateTime>[];

  /// Number of times [arm] has been called (including failed calls).
  int armCallCount = 0;

  /// Number of times [cancel] has been called.
  int cancelCallCount = 0;

  /// Number of times [rescheduleAll] has been called.
  int rescheduleCallCount = 0;

  @override
  Future<void> arm(AlarmOccurrencePlan plan) async {
    armCallCount++;
    final fail = failNextArm;
    if (fail != null) {
      failNextArm = null;
      throw fail;
    }
    _armed[plan.alarm.id] = plan;
    armedRingInstantsUtc.add(plan.ringAtUtc);
    everArmedRingInstantsUtc.add(plan.ringAtUtc);
  }

  /// When set, the next [ringNow] throws this exception (and clears it), so
  /// tests can prove the lifecycle layer survives a platform that refuses the
  /// motion re-ring.
  AlarmEngineException? failNextRingNow;

  /// Number of times [ringNow] has been called (including failed calls).
  int ringNowCallCount = 0;

  /// The alarm ids [ringNow] has been asked to ring, in order.
  final List<String> ringNowAlarmIds = <String>[];

  /// Whether [ringNow] also emits the ring on [ringingStream].
  ///
  /// True by default, mirroring a platform that honours the request. Set it
  /// false to model one that accepts the call and then never delivers — an iOS
  /// app backgrounded into silence, say — which is the case a caller must not
  /// be left waiting on forever.
  bool autoFireOnRingNow = true;

  @override
  Future<void> ringNow(Alarm alarm) async {
    ringNowCallCount++;
    final fail = failNextRingNow;
    if (fail != null) {
      failNextRingNow = null;
      throw fail;
    }
    ringNowAlarmIds.add(alarm.id);
    // Mirrors the real adapter: an immediate ring surfaces on the same stream
    // a scheduled one does, so the lifecycle layer has exactly one entry point
    // for "an alarm started ringing".
    if (autoFireOnRingNow) fire(alarm.id);
  }

  @override
  Future<void> cancel(String alarmId) async {
    cancelCallCount++;
    final fail = failNextCancel;
    if (fail != null) {
      failNextCancel = null;
      throw fail;
    }
    _armed.remove(alarmId);
  }

  @override
  Future<void> rescheduleAll(List<AlarmOccurrencePlan> plans) async {
    rescheduleCallCount++;
    final fail = failNextReschedule;
    if (fail != null) {
      failNextReschedule = null;
      throw fail;
    }
    _armed.clear();
    armedRingInstantsUtc.clear();
    for (final plan in plans) {
      _armed[plan.alarm.id] = plan;
      armedRingInstantsUtc.add(plan.ringAtUtc);
      everArmedRingInstantsUtc.add(plan.ringAtUtc);
    }
  }

  @override
  Stream<RingingAlarm> get ringingStream => _ringing.stream;

  /// Test helper: fire a ringing event for [alarmId] at [firedAt] (or
  /// `DateTime.now().toUtc()` if omitted).
  void fire(String alarmId, {DateTime? firedAt}) {
    _ringing.add(
      RingingAlarm(
        alarmId: alarmId,
        firedAt: (firedAt ?? _now()).toUtc(),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    if (!_ringing.isClosed) {
      await _ringing.close();
    }
  }
}
