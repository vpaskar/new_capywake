import 'package:capywake/core/engine/notification_schedule_calculator.dart';
import 'package:capywake/core/engine/notification_service.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Alarm _alarm({String id = 'a', int targetTimeMinutes = 7 * 60}) {
  final created = DateTime.utc(2026);
  return Alarm(
    id: id,
    label: '',
    enabled: true,
    targetTimeMinutes: targetTimeMinutes,
    repeatWeekdays: const <int>{},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 15,
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

AlarmOccurrencePlan _plan({
  required String id,
  required tz.TZDateTime scheduled,
  tz.TZDateTime? softStart,
}) {
  return AlarmOccurrencePlan(
    alarm: _alarm(id: id),
    scheduled: scheduled,
    softStart: softStart,
    location: scheduled.location,
  );
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  final utc = tz.UTC;
  final now = tz.TZDateTime.utc(2026, 5, 21, 6);

  group('NotificationScheduleCalculator.compute', () {
    test('emits one notification per plan that has a softStart', () {
      final p1 = _plan(
        id: 'a',
        scheduled: tz.TZDateTime(utc, 2026, 5, 22, 7),
        softStart: tz.TZDateTime(utc, 2026, 5, 22, 6, 45),
      );
      final p2 = _plan(
        id: 'b',
        scheduled: tz.TZDateTime(utc, 2026, 5, 22, 8),
        softStart: tz.TZDateTime(utc, 2026, 5, 22, 7, 50),
      );

      final pending = NotificationScheduleCalculator.compute(
        plans: [p1, p2],
        now: now,
      );

      expect(pending, hasLength(2));
      expect(
        pending.every((n) => n.kind == NotificationKind.softWakeStart),
        isTrue,
      );
    });

    test('drops plans without a softStart', () {
      final p = _plan(
        id: 'a',
        scheduled: tz.TZDateTime(utc, 2026, 5, 22, 7),
      );

      final pending = NotificationScheduleCalculator.compute(
        plans: [p],
        now: now,
      );

      expect(pending, isEmpty);
    });

    test('drops plans whose softStart is already in the past', () {
      final past = _plan(
        id: 'a',
        scheduled: tz.TZDateTime(utc, 2026, 5, 21, 7),
        softStart: tz.TZDateTime(utc, 2026, 5, 21, 5, 45),
      );

      final pending = NotificationScheduleCalculator.compute(
        plans: [past],
        now: now,
      );

      expect(pending, isEmpty);
    });

    test('returns an empty list for an empty input', () {
      final pending = NotificationScheduleCalculator.compute(
        plans: const [],
        now: now,
      );
      expect(pending, isEmpty);
    });

    test('sorts ascending by scheduledUtc, ties broken by alarmId', () {
      final later = _plan(
        id: 'z',
        scheduled: tz.TZDateTime(utc, 2026, 5, 24, 7),
        softStart: tz.TZDateTime(utc, 2026, 5, 24, 6, 45),
      );
      final earlier = _plan(
        id: 'a',
        scheduled: tz.TZDateTime(utc, 2026, 5, 22, 7),
        softStart: tz.TZDateTime(utc, 2026, 5, 22, 6, 45),
      );
      final tieB = _plan(
        id: 'b',
        scheduled: tz.TZDateTime(utc, 2026, 5, 22, 8),
        softStart: tz.TZDateTime(utc, 2026, 5, 22, 6, 45),
      );

      final pending = NotificationScheduleCalculator.compute(
        plans: [later, tieB, earlier],
        now: now,
      );

      expect(pending.map((n) => n.alarmId).toList(), ['a', 'b', 'z']);
    });

    test('truncates to the iOS 64-pending cap, keeping the soonest', () {
      final plans = List<AlarmOccurrencePlan>.generate(80, (i) {
        final scheduled = tz.TZDateTime(
          utc,
          2026,
          5,
          22,
        ).add(Duration(minutes: i));
        return _plan(
          id: 'a${i.toString().padLeft(3, '0')}',
          scheduled: scheduled,
          softStart: scheduled.subtract(const Duration(minutes: 15)),
        );
      });

      final pending = NotificationScheduleCalculator.compute(
        plans: plans,
        now: now,
      );

      expect(pending, hasLength(NotificationScheduleCalculator.iosPendingCap));
      expect(pending.first.alarmId, 'a000');
      expect(pending.last.alarmId, 'a063');
    });

    test('keeps exactly cap entries when input length equals cap', () {
      final plans = List<AlarmOccurrencePlan>.generate(64, (i) {
        final scheduled = tz.TZDateTime(
          utc,
          2026,
          5,
          22,
        ).add(Duration(minutes: i));
        return _plan(
          id: 'a${i.toString().padLeft(3, '0')}',
          scheduled: scheduled,
          softStart: scheduled.subtract(const Duration(minutes: 15)),
        );
      });

      final pending = NotificationScheduleCalculator.compute(
        plans: plans,
        now: now,
      );

      expect(pending, hasLength(64));
    });

    test('respects custom cap', () {
      final plans = List<AlarmOccurrencePlan>.generate(10, (i) {
        final scheduled = tz.TZDateTime(
          utc,
          2026,
          5,
          22,
        ).add(Duration(minutes: i));
        return _plan(
          id: 'a${i.toString().padLeft(2, '0')}',
          scheduled: scheduled,
          softStart: scheduled.subtract(const Duration(minutes: 15)),
        );
      });

      final pending = NotificationScheduleCalculator.compute(
        plans: plans,
        now: now,
        cap: 3,
      );

      expect(pending, hasLength(3));
      expect(pending.first.alarmId, 'a00');
    });

    test('produces stable ids for the same (alarmId, kind, scheduledUtc)', () {
      final plan = _plan(
        id: 'stable',
        scheduled: tz.TZDateTime(utc, 2026, 5, 22, 7),
        softStart: tz.TZDateTime(utc, 2026, 5, 22, 6, 45),
      );

      final p1 = NotificationScheduleCalculator.compute(
        plans: [plan],
        now: now,
      );
      final p2 = NotificationScheduleCalculator.compute(
        plans: [plan],
        now: now,
      );

      expect(p1.single.id, p2.single.id);
      expect(p1.single.id, isNonNegative);
    });

    test('returns an unmodifiable list', () {
      final plan = _plan(
        id: 'a',
        scheduled: tz.TZDateTime(utc, 2026, 5, 22, 7),
        softStart: tz.TZDateTime(utc, 2026, 5, 22, 6, 45),
      );
      final pending = NotificationScheduleCalculator.compute(
        plans: [plan],
        now: now,
      );

      expect(() => pending.add(pending.first), throwsUnsupportedError);
    });

    test('payload alarm time matches the plan scheduled instant', () {
      final scheduled = tz.TZDateTime(utc, 2026, 5, 22, 7);
      final plan = _plan(
        id: 'a',
        scheduled: scheduled,
        softStart: tz.TZDateTime(utc, 2026, 5, 22, 6, 45),
      );

      final pending = NotificationScheduleCalculator.compute(
        plans: [plan],
        now: now,
      );

      expect(
        pending.single.payloadAlarmTimeUtc.isAtSameMomentAs(scheduled.toUtc()),
        isTrue,
      );
    });
  });
}
