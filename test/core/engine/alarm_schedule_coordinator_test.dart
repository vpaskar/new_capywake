import 'package:capywake/core/engine/alarm_engine.dart';
import 'package:capywake/core/engine/alarm_schedule_coordinator.dart';
import 'package:capywake/core/engine/fake_alarm_engine.dart';
import 'package:capywake/core/engine/fake_notification_service.dart';
import 'package:capywake/core/engine/notification_schedule_calculator.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Alarm _alarm({
  required String id,
  required int targetTimeMinutes,
  bool enabled = true,
  Set<int> repeatWeekdays = const <int>{},
  int wakeWindowStartMinutesBefore = 15,
}) {
  final created = DateTime.utc(2026);
  return Alarm(
    id: id,
    label: '',
    enabled: enabled,
    targetTimeMinutes: targetTimeMinutes,
    repeatWeekdays: repeatWeekdays,
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: wakeWindowStartMinutesBefore,
    soundId: 'default',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: DismissMethod.normalButton,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: created,
    updatedAt: created,
  );
}

/// A snoozed occurrence in the shape the app writes: `scheduledAt` names the
/// morning, `snoozedUntil` carries the ring it is waiting for.
AlarmOccurrence _snoozedOcc({
  required String alarmId,
  required DateTime ringAt,
  String id = 'snz',
  AlarmStatus status = AlarmStatus.snoozed,
  int snoozeCount = 1,
}) {
  return AlarmOccurrence(
    id: id,
    alarmId: alarmId,
    scheduledAt: DateTime.utc(2026, 5, 21, 7),
    softStartAt: null,
    status: status,
    triggeredAt: DateTime.utc(2026, 5, 21, 7),
    dismissedAt: null,
    snoozeCount: snoozeCount,
    note: '',
    snoozedUntil: status == AlarmStatus.snoozed ? ringAt : null,
  );
}

/// A finished occurrence for the ring at [target].
AlarmOccurrence _finishedOcc({
  required String alarmId,
  required DateTime target,
  required AlarmStatus status,
  String id = 'fin',
  DateTime? triggeredAt,
  DateTime? dismissedAt,
  int snoozeCount = 0,
}) {
  return AlarmOccurrence(
    id: id,
    alarmId: alarmId,
    scheduledAt: target,
    softStartAt: null,
    status: status,
    triggeredAt: triggeredAt,
    dismissedAt: dismissedAt,
    snoozeCount: snoozeCount,
    note: '',
  );
}

void main() {
  setUpAll(tzdata.initializeTimeZones);
  final utc = tz.UTC;

  group('AlarmScheduleCoordinator.sync', () {
    late FakeAlarmEngine engine;
    late FakeNotificationService notifications;

    setUp(() {
      engine = FakeAlarmEngine();
      notifications = FakeNotificationService();
    });

    tearDown(() async {
      await engine.dispose();
      await notifications.dispose();
    });

    test('arms the next occurrence per enabled alarm', () async {
      final coordinator = AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => DateTime.utc(2026, 5, 21, 6),
      );

      final morning = _alarm(id: 'morning', targetTimeMinutes: 7 * 60);
      final evening = _alarm(id: 'evening', targetTimeMinutes: 22 * 60);

      await coordinator.sync(alarms: [morning, evening]);

      expect(engine.rescheduleCallCount, 1);
      expect(engine.armedSnapshot.keys.toSet(), {'morning', 'evening'});
    });

    test('skips disabled alarms', () async {
      final coordinator = AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => DateTime.utc(2026, 5, 21, 6),
      );

      final on = _alarm(id: 'on', targetTimeMinutes: 7 * 60);
      final off = _alarm(
        id: 'off',
        targetTimeMinutes: 8 * 60,
        enabled: false,
      );

      await coordinator.sync(alarms: [on, off]);

      expect(engine.armedSnapshot.keys, ['on']);
    });

    test('arms nothing when every alarm is disabled', () async {
      final coordinator = AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => DateTime.utc(2026, 5, 21, 6),
      );

      final off = _alarm(
        id: 'off',
        targetTimeMinutes: 8 * 60,
        enabled: false,
      );

      await coordinator.sync(alarms: [off]);

      expect(engine.armedSnapshot, isEmpty);
      expect(notifications.pending, isEmpty);
    });

    test('schedules pre-alarm reminders for soft-wake plans', () async {
      final coordinator = AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => DateTime.utc(2026, 5, 21, 6),
      );

      final repeating = _alarm(
        id: 'r',
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );

      await coordinator.sync(alarms: [repeating]);

      // Default upcomingPerAlarm == 4, all should produce one
      // softWakeStart reminder.
      expect(notifications.pending, hasLength(4));
      expect(
        notifications.pending.every(
          (n) =>
              n.alarmId == 'r' &&
              n.scheduledUtc.isAfter(
                DateTime.utc(2026, 5, 21, 6),
              ),
        ),
        isTrue,
      );
    });

    test(
      'continues scheduling notifications even if engine.rescheduleAll throws',
      () async {
        final coordinator = AlarmScheduleCoordinator(
          engine: engine,
          notifications: notifications,
          location: utc,
          now: () => DateTime.utc(2026, 5, 21, 6),
        );

        // The engine side fails; the coordinator must log and still schedule
        // notifications (the two sides are independent).
        engine.failNextReschedule = const AlarmEngineException('boom');
        final morning = _alarm(id: 'morning', targetTimeMinutes: 7 * 60);

        await coordinator.sync(alarms: [morning]);

        expect(engine.rescheduleCallCount, 1);
        expect(notifications.scheduleCallCount, 1);
      },
    );

    test(
      'survives a notification.scheduleAll failure (engine still armed)',
      () async {
        final coordinator = AlarmScheduleCoordinator(
          engine: engine,
          notifications: notifications,
          location: utc,
          now: () => DateTime.utc(2026, 5, 21, 6),
        );

        // The notification side fails; the coordinator must log and the
        // engine arming must be unaffected.
        notifications.failNextSchedule = Exception('notif boom');
        final morning = _alarm(id: 'morning', targetTimeMinutes: 7 * 60);

        await coordinator.sync(alarms: [morning]);

        expect(notifications.scheduleCallCount, 1);
        expect(engine.armedSnapshot.keys, contains('morning'));
      },
    );

    test('upcomingPerAlarm bounds the per-alarm queue', () async {
      final coordinator = AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => DateTime.utc(2026, 5, 21, 6),
        upcomingPerAlarm: 2,
      );

      final repeating = _alarm(
        id: 'r',
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );

      await coordinator.sync(alarms: [repeating]);

      expect(notifications.pending, hasLength(2));
    });

    test('respects skipped occurrences when computing the next ring', () async {
      final now = DateTime.utc(2026, 5, 21, 6);
      final coordinator = AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => now,
      );

      final daily = _alarm(
        id: 'daily',
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );

      // Skip the immediate next occurrence (today @ 07:00 UTC).
      final skip = AlarmOccurrence(
        id: 'skip',
        alarmId: 'daily',
        scheduledAt: DateTime.utc(2026, 5, 21, 7),
        softStartAt: null,
        status: AlarmStatus.skipped,
        triggeredAt: null,
        dismissedAt: null,
        snoozeCount: 0,
        note: '',
      );

      await coordinator.sync(alarms: [daily], finished: [skip]);

      final armed = engine.armedSnapshot['daily']!;
      expect(
        armed.scheduledUtc.isAtSameMomentAs(DateTime.utc(2026, 5, 22, 7)),
        isTrue,
      );
    });

    test('cap-truncates pending notifications across many alarms', () async {
      final coordinator = AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => DateTime.utc(2026, 5, 21, 6),
      );

      // 20 daily alarms × 4 upcoming = 80 plans, capped at 64.
      final alarms = List<Alarm>.generate(
        20,
        (i) => _alarm(
          id: 'a${i.toString().padLeft(2, '0')}',
          targetTimeMinutes: 7 * 60 + i,
          repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
        ),
      );

      await coordinator.sync(alarms: alarms);

      expect(
        notifications.pending,
        hasLength(NotificationScheduleCalculator.iosPendingCap),
      );
    });

    test('arms a windowed alarm at its soft start, not its target', () async {
      // The wake window is one ring that begins early and rises to full volume
      // at the target. Arming at the target instead is what made the whole
      // feature — sold as Pro — do nothing at runtime.
      final coordinator = AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => DateTime.utc(2026, 5, 21, 6),
      );

      await coordinator.sync(
        alarms: [
          // The helper already defaults to a 15-minute window; naming it here
          // would be a redundant argument, and the assertions below say what
          // the window is anyway.
          _alarm(id: 'morning', targetTimeMinutes: 7 * 60),
        ],
      );

      expect(engine.armedRingInstantsUtc, [DateTime.utc(2026, 5, 21, 6, 45)]);
      expect(
        engine.armedSnapshot['morning']!.scheduledUtc,
        DateTime.utc(2026, 5, 21, 7),
      );
      expect(
        engine.armedSnapshot['morning']!.rampWindow,
        const Duration(minutes: 15),
      );
    });

    test('arms an alarm without a window at its target, as before', () async {
      final coordinator = AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => DateTime.utc(2026, 5, 21, 6),
      );

      await coordinator.sync(
        alarms: [
          _alarm(
            id: 'morning',
            targetTimeMinutes: 7 * 60,
            wakeWindowStartMinutesBefore: 0,
          ),
        ],
      );

      expect(engine.armedRingInstantsUtc, [DateTime.utc(2026, 5, 21, 7)]);
      expect(engine.armedSnapshot['morning']!.rampWindow, Duration.zero);
    });
  });

  group('AlarmScheduleCoordinator.cancelAll', () {
    late FakeAlarmEngine engine;
    late FakeNotificationService notifications;

    setUp(() {
      engine = FakeAlarmEngine();
      notifications = FakeNotificationService();
    });

    tearDown(() async {
      await engine.dispose();
      await notifications.dispose();
    });

    test('clears engine + notifications', () async {
      final coordinator = AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => DateTime.utc(2026, 5, 21, 6),
      );

      final morning = _alarm(id: 'morning', targetTimeMinutes: 7 * 60);
      await coordinator.sync(alarms: [morning]);
      expect(engine.armedSnapshot, isNotEmpty);

      await coordinator.cancelAll();
      expect(engine.armedSnapshot, isEmpty);
      expect(notifications.cancelAllCallCount, 1);
    });

    test('logs but completes when engine.rescheduleAll throws', () async {
      // Wrap engine in a thin failing version. We do this inline because
      // FakeAlarmEngine is permissive on rescheduleAll.
      final failingEngine = _FailingEngine();
      addTearDown(failingEngine.dispose);

      final coordinator = AlarmScheduleCoordinator(
        engine: failingEngine,
        notifications: notifications,
        location: utc,
        now: () => DateTime.utc(2026, 5, 21, 6),
      );

      await coordinator.cancelAll();
      expect(notifications.cancelAllCallCount, 1);
    });

    test('logs but completes when notifications.cancelAll throws', () async {
      final coordinator = AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => DateTime.utc(2026, 5, 21, 6),
      );

      // The notification side fails on cancel; the coordinator must log and
      // still clear the engine.
      notifications.failNextCancelAll = Exception('cancel boom');
      final morning = _alarm(id: 'morning', targetTimeMinutes: 7 * 60);
      await coordinator.sync(alarms: [morning]);

      await coordinator.cancelAll();
      expect(engine.armedSnapshot, isEmpty);
      expect(notifications.cancelAllCallCount, 1);
    });
  });

  group('AlarmScheduleCoordinator.sync — the snooze ring', () {
    late FakeAlarmEngine engine;
    late FakeNotificationService notifications;

    setUp(() {
      engine = FakeAlarmEngine();
      notifications = FakeNotificationService();
    });

    tearDown(() async {
      await engine.dispose();
      await notifications.dispose();
    });

    AlarmScheduleCoordinator build({DateTime? now}) {
      return AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => now ?? DateTime.utc(2026, 5, 21, 7, 2),
      );
    }

    test("a pending snooze is armed instead of tomorrow's ring", () async {
      // The whole point of the phase: pressing Snooze writes this row, the
      // write lands back here, and the platform is asked to ring in nine
      // minutes. Before Phase 32 the row was written and nothing was armed.
      final daily = _alarm(
        id: 'daily',
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final snooze = _snoozedOcc(
        alarmId: 'daily',
        ringAt: DateTime.utc(2026, 5, 21, 7, 11),
      );

      await build().sync(alarms: [daily], snoozed: [snooze]);

      final armed = engine.armedSnapshot['daily']!;
      expect(armed.ringAt.toUtc(), DateTime.utc(2026, 5, 21, 7, 11));
      expect(armed.scheduledUtc, DateTime.utc(2026, 5, 21, 7, 11));
    });

    test('the snooze ring has no volume ramp, whatever the mode', () async {
      // A wake window belongs to the morning the user chose, not to a nine-
      // minute snooze. Gentle would otherwise fade a snooze in from 5%.
      final gentle = Alarm(
        id: 'gentle',
        label: '',
        enabled: true,
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
        wakeMode: WakeMode.gentle,
        wakeWindowStartMinutesBefore: 15,
        soundId: 'default',
        vibrationEnabled: true,
        snoozeEnabled: true,
        snoozeDurationMinutes: 9,
        maxSnoozes: 5,
        dismissMethod: DismissMethod.normalButton,
        dismissChallengeDifficulty: null,
        confirmationEnabled: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final snooze = _snoozedOcc(
        alarmId: 'gentle',
        ringAt: DateTime.utc(2026, 5, 21, 7, 11),
      );

      await build().sync(alarms: [gentle], snoozed: [snooze]);

      final armed = engine.armedSnapshot['gentle']!;
      expect(armed.softStart, isNull);
      expect(armed.rampWindow, Duration.zero);
    });

    test('a snooze instant that has passed is never armed', () async {
      // Android fires a past `setAlarmClock` trigger on the spot, and
      // `package:alarm` stops a stored alarm whose time has gone by. A
      // snoozed row the app was not running for must not resurrect at launch.
      final daily = _alarm(
        id: 'daily',
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final stale = _snoozedOcc(
        alarmId: 'daily',
        ringAt: DateTime.utc(2026, 5, 21, 7, 1),
      );

      await build(now: DateTime.utc(2026, 5, 21, 9)).sync(
        alarms: [daily],
        snoozed: [stale],
      );

      final armed = engine.armedSnapshot['daily']!;
      expect(armed.scheduledUtc, DateTime.utc(2026, 5, 22, 7));
    });

    test('a snooze instant exactly now is treated as passed', () async {
      final daily = _alarm(
        id: 'daily',
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final now = DateTime.utc(2026, 5, 21, 7, 11);
      final boundary = _snoozedOcc(alarmId: 'daily', ringAt: now);

      await build(now: now).sync(alarms: [daily], snoozed: [boundary]);

      expect(engine.armedSnapshot['daily']!.scheduledUtc, isNot(now));
    });

    test('a snoozed row for a disabled alarm arms nothing', () async {
      final off = _alarm(
        id: 'off',
        targetTimeMinutes: 7 * 60,
        enabled: false,
      );
      final snooze = _snoozedOcc(
        alarmId: 'off',
        ringAt: DateTime.utc(2026, 5, 21, 7, 11),
      );

      await build().sync(alarms: [off], snoozed: [snooze]);

      expect(engine.armedSnapshot, isEmpty);
    });

    test('a snoozed row belonging to another alarm does not leak', () async {
      final mine = _alarm(
        id: 'mine',
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final theirs = _snoozedOcc(
        alarmId: 'someone-else',
        ringAt: DateTime.utc(2026, 5, 21, 7, 11),
      );

      await build().sync(alarms: [mine], snoozed: [theirs]);

      expect(
        engine.armedSnapshot['mine']!.scheduledUtc,
        DateTime.utc(2026, 5, 22, 7),
      );
    });

    test('a non-snoozed row in the list is ignored', () async {
      // Defensive: the stream is filtered in SQL, but the coordinator is a
      // public API and a caller passing the wrong list must not arm a ring at
      // a dismissed occurrence's instant.
      final daily = _alarm(
        id: 'daily',
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final dismissed = _snoozedOcc(
        alarmId: 'daily',
        ringAt: DateTime.utc(2026, 5, 21, 7, 11),
        status: AlarmStatus.dismissed,
      );

      await build().sync(alarms: [daily], snoozed: [dismissed]);

      expect(
        engine.armedSnapshot['daily']!.scheduledUtc,
        DateTime.utc(2026, 5, 22, 7),
      );
    });

    test('the soonest of several snoozed rows wins', () async {
      final daily = _alarm(
        id: 'daily',
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final later = _snoozedOcc(
        id: 'later',
        alarmId: 'daily',
        ringAt: DateTime.utc(2026, 5, 21, 7, 20),
      );
      final sooner = _snoozedOcc(
        id: 'sooner',
        alarmId: 'daily',
        ringAt: DateTime.utc(2026, 5, 21, 7, 11),
      );

      await build().sync(alarms: [daily], snoozed: [later, sooner]);

      expect(
        engine.armedSnapshot['daily']!.scheduledUtc,
        DateTime.utc(2026, 5, 21, 7, 11),
      );
    });

    test('a scheduled ring sooner than the snooze wins', () async {
      // Only one platform alarm exists per alarm id, so the two candidates
      // are reconciled rather than both armed. A long snooze must not push a
      // nearer scheduled ring off the platform.
      final daily = _alarm(
        id: 'daily',
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
        wakeWindowStartMinutesBefore: 0,
      );
      final snooze = _snoozedOcc(
        alarmId: 'daily',
        ringAt: DateTime.utc(2026, 5, 22, 8),
      );

      await build(now: DateTime.utc(2026, 5, 21, 23)).sync(
        alarms: [daily],
        snoozed: [snooze],
      );

      expect(
        engine.armedSnapshot['daily']!.scheduledUtc,
        DateTime.utc(2026, 5, 22, 7),
      );
    });

    test('snoozing inside an open wake window honours the snooze', () async {
      // The regression this ordering exists for. A Gentle alarm's window
      // opened at 06:45 and it is 06:46; today's 07:00 occurrence is still in
      // the future, so the scheduler still offers it — with a `ringAt` of
      // 06:45, which has passed. Ranked by ring instant that stale soft start
      // wins, and arming it floors to the clock: the alarm would go off again
      // two seconds after the user pressed Snooze.
      final gentle = Alarm(
        id: 'gentle',
        label: '',
        enabled: true,
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
        wakeMode: WakeMode.gentle,
        wakeWindowStartMinutesBefore: 15,
        soundId: 'default',
        vibrationEnabled: true,
        snoozeEnabled: true,
        snoozeDurationMinutes: 9,
        maxSnoozes: null,
        dismissMethod: DismissMethod.normalButton,
        dismissChallengeDifficulty: null,
        confirmationEnabled: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final snooze = _snoozedOcc(
        alarmId: 'gentle',
        ringAt: DateTime.utc(2026, 5, 21, 6, 55),
      );

      await build(now: DateTime.utc(2026, 5, 21, 6, 46)).sync(
        alarms: [gentle],
        snoozed: [snooze],
      );

      final armed = engine.armedSnapshot['gentle']!;
      expect(armed.ringAt.toUtc(), DateTime.utc(2026, 5, 21, 6, 55));
      expect(armed.rampWindow, Duration.zero);
    });

    test('an alarm with no upcoming ring still arms its snooze', () async {
      // A one-time alarm whose target has passed computes no next occurrence.
      // The snooze it is mid-way through is still owed a ring.
      final oneTime = _alarm(id: 'once', targetTimeMinutes: 7 * 60);
      final snooze = _snoozedOcc(
        alarmId: 'once',
        ringAt: DateTime.utc(2026, 5, 21, 7, 11),
      );

      await build(now: DateTime.utc(2026, 5, 21, 7, 2)).sync(
        alarms: [oneTime],
        snoozed: [snooze],
      );

      expect(
        engine.armedSnapshot['once']!.scheduledUtc,
        DateTime.utc(2026, 5, 21, 7, 11),
      );
    });

    test('pre-alarm reminders still follow the schedule, not the '
        'snooze', () async {
      // A nine-minute snooze does not deserve a "your alarm is coming up"
      // notification, and it must not consume an iOS pending slot.
      final daily = _alarm(
        id: 'daily',
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final snooze = _snoozedOcc(
        alarmId: 'daily',
        ringAt: DateTime.utc(2026, 5, 21, 7, 11),
      );

      await build().sync(alarms: [daily], snoozed: [snooze]);

      expect(
        notifications.pending.every(
          (n) =>
              n.scheduledUtc != DateTime.utc(2026, 5, 21, 7, 11) &&
              n.payloadAlarmTimeUtc != DateTime.utc(2026, 5, 21, 7, 11),
        ),
        isTrue,
      );
    });
  });

  group('a finished ring is not armed again', () {
    late FakeAlarmEngine engine;
    late FakeNotificationService notifications;

    setUp(() {
      engine = FakeAlarmEngine();
      notifications = FakeNotificationService();
    });

    tearDown(() async {
      await engine.dispose();
      await notifications.dispose();
    });

    AlarmScheduleCoordinator build(DateTime now) {
      return AlarmScheduleCoordinator(
        engine: engine,
        notifications: notifications,
        location: utc,
        now: () => now,
      );
    }

    Alarm daily({int window = 15}) => _alarm(
      id: 'daily',
      targetTimeMinutes: 7 * 60,
      repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      wakeWindowStartMinutesBefore: window,
    );

    test('dismissing inside an open wake window arms tomorrow', () async {
      // The defect this phase exists for, driven end to end. A Gentle 07:00
      // alarm with a fifteen-minute window starts ringing at 06:45; the user
      // gets up and dismisses at 06:50. The dismiss re-emits the occurrence
      // streams, which lands here — and today's 07:00 target has *not* passed
      // yet, so before the fix the engine happily armed it again. Its ring
      // instant is 06:45, five minutes gone, and `arm` floors a past instant
      // to the clock: the alarm sounded seconds after being silenced.
      final now = DateTime.utc(2026, 5, 21, 6, 50);
      final dismissed = _finishedOcc(
        alarmId: 'daily',
        target: DateTime.utc(2026, 5, 21, 7),
        status: AlarmStatus.dismissed,
        triggeredAt: DateTime.utc(2026, 5, 21, 6, 45),
        dismissedAt: now,
      );

      await build(now).sync(alarms: [daily()], finished: [dismissed]);

      final armed = engine.armedSnapshot['daily']!;
      expect(armed.scheduledUtc, DateTime.utc(2026, 5, 22, 7));
      // The assertion that actually names the harm: nothing is armed at an
      // instant the platform would treat as "now".
      expect(armed.ringAtUtc.isAfter(now), isTrue);
    });

    test('the end of a snooze chain is not armed again', () async {
      // Same shape, reached the other way. A thirty-minute window opens at
      // 06:30, the user snoozes at 06:35 and dismisses the 06:44 re-ring at
      // 06:45 — with 07:00 still ahead. This is the case that made the fix
      // more than a filter: the row has been through `snooze`, and only
      // because `scheduledAt` stopped moving does it still name 07:00.
      final now = DateTime.utc(2026, 5, 21, 6, 45);
      final dismissed = _finishedOcc(
        alarmId: 'daily',
        target: DateTime.utc(2026, 5, 21, 7),
        status: AlarmStatus.dismissed,
        triggeredAt: DateTime.utc(2026, 5, 21, 6, 44),
        dismissedAt: now,
        snoozeCount: 1,
      );

      await build(
        now,
      ).sync(alarms: [daily(window: 30)], finished: [dismissed]);

      final armed = engine.armedSnapshot['daily']!;
      expect(armed.scheduledUtc, DateTime.utc(2026, 5, 22, 7));
      expect(armed.ringAtUtc.isAfter(now), isTrue);
    });

    for (final status in AlarmStatus.values.where((s) => s.isTerminal)) {
      test('a ${status.name} occurrence retires its morning', () async {
        // Every terminal state means the same thing to the schedule: this
        // morning is over. Escaped especially — someone who took the wake
        // puzzle's emergency escape has said they need quiet, and ringing at
        // them again would be the loudest possible way to ignore that.
        final now = DateTime.utc(2026, 5, 21, 6, 50);
        final finished = _finishedOcc(
          alarmId: 'daily',
          target: DateTime.utc(2026, 5, 21, 7),
          status: status,
        );

        await build(now).sync(alarms: [daily()], finished: [finished]);

        expect(
          engine.armedSnapshot['daily']!.scheduledUtc,
          DateTime.utc(2026, 5, 22, 7),
        );
      });
    }

    test('a live occurrence does not retire its morning', () async {
      // The mirror image, and the reason the filter asks about the status
      // rather than merely the instant. A `triggered` row is an alarm that is
      // ringing *right now* — retiring its morning would cancel it.
      final now = DateTime.utc(2026, 5, 21, 6, 50);
      final ringing = _finishedOcc(
        alarmId: 'daily',
        target: DateTime.utc(2026, 5, 21, 7),
        status: AlarmStatus.triggered,
        triggeredAt: DateTime.utc(2026, 5, 21, 6, 45),
      );

      await build(now).sync(alarms: [daily()], finished: [ringing]);

      expect(
        engine.armedSnapshot['daily']!.scheduledUtc,
        DateTime.utc(2026, 5, 21, 7),
      );
    });

    test("another alarm's dismiss does not retire this one", () async {
      final now = DateTime.utc(2026, 5, 21, 6, 50);
      final other = _finishedOcc(
        alarmId: 'someone-else',
        target: DateTime.utc(2026, 5, 21, 7),
        status: AlarmStatus.dismissed,
      );

      await build(now).sync(alarms: [daily()], finished: [other]);

      expect(
        engine.armedSnapshot['daily']!.scheduledUtc,
        DateTime.utc(2026, 5, 21, 7),
      );
    });

    test('pre-alarm reminders skip the finished morning too', () async {
      // The reminder is "your alarm is coming up". For a ring that has
      // already been dealt with it is not just noise, it is wrong.
      final now = DateTime.utc(2026, 5, 21, 6, 50);
      final dismissed = _finishedOcc(
        alarmId: 'daily',
        target: DateTime.utc(2026, 5, 21, 7),
        status: AlarmStatus.dismissed,
        dismissedAt: now,
      );

      await build(now).sync(alarms: [daily()], finished: [dismissed]);

      expect(
        notifications.pending.every(
          (n) => n.payloadAlarmTimeUtc != DateTime.utc(2026, 5, 21, 7),
        ),
        isTrue,
      );
    });

    test('a pending snooze still outranks the retired morning', () async {
      // Finished rows and snoozed rows arrive together on every resync. The
      // finished one must not take the snooze down with it: dismissing
      // *yesterday* has nothing to do with the ring due in four minutes.
      final now = DateTime.utc(2026, 5, 21, 6, 50);
      final yesterday = _finishedOcc(
        alarmId: 'daily',
        target: DateTime.utc(2026, 5, 20, 7),
        status: AlarmStatus.dismissed,
      );
      final snooze = _snoozedOcc(
        alarmId: 'daily',
        ringAt: DateTime.utc(2026, 5, 21, 6, 54),
      );

      await build(now).sync(
        alarms: [daily()],
        finished: [yesterday],
        snoozed: [snooze],
      );

      expect(
        engine.armedSnapshot['daily']!.scheduledUtc,
        DateTime.utc(2026, 5, 21, 6, 54),
      );
    });
  });
}

class _FailingEngine implements AlarmEngine {
  @override
  Future<void> arm(AlarmOccurrencePlan plan) =>
      throw const AlarmEngineException('arm');

  @override
  Future<void> ringNow(Alarm alarm) => throw const AlarmEngineException('ring');

  @override
  Future<void> cancel(String alarmId) async {}

  @override
  Future<void> rescheduleAll(List<AlarmOccurrencePlan> plans) =>
      throw const AlarmEngineException('reschedule');

  @override
  Stream<RingingAlarm> get ringingStream => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
