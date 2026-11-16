import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Build a deterministic [Alarm] for these unit tests.
Alarm _alarm({
  required int targetTimeMinutes,
  String id = 'a',
  bool enabled = true,
  Set<int> repeatWeekdays = const <int>{},
  int wakeWindowStartMinutesBefore = 0,
  WakeMode wakeMode = WakeMode.standard,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime.utc(2026, 5);
  return Alarm(
    id: id,
    label: '',
    enabled: enabled,
    targetTimeMinutes: targetTimeMinutes,
    repeatWeekdays: repeatWeekdays,
    wakeMode: wakeMode,
    wakeWindowStartMinutesBefore: wakeWindowStartMinutesBefore,
    soundId: 'default',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: DismissMethod.normalButton,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: now,
    updatedAt: now,
  );
}

AlarmOccurrence _skipped({
  required String alarmId,
  required DateTime scheduledUtc,
  String id = 's',
}) {
  return AlarmOccurrence(
    id: id,
    alarmId: alarmId,
    scheduledAt: scheduledUtc,
    softStartAt: null,
    status: AlarmStatus.skipped,
    triggeredAt: null,
    dismissedAt: null,
    snoozeCount: 0,
    note: '',
  );
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late tz.Location berlin;
  late tz.Location newYork;
  late tz.Location utc;

  setUp(() {
    berlin = tz.getLocation('Europe/Berlin');
    newYork = tz.getLocation('America/New_York');
    utc = tz.UTC;
  });

  group('AlarmScheduleService.computeNext (tz-aware)', () {
    test('returns null when there are no alarms', () {
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6);
      expect(
        AlarmScheduleService.computeNext(
          alarms: const [],
          now: now,
          location: berlin,
        ),
        isNull,
      );
    });

    test('returns null when every alarm is disabled', () {
      final a = _alarm(targetTimeMinutes: 7 * 60, enabled: false);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6);
      expect(
        AlarmScheduleService.computeNext(
          alarms: [a],
          now: now,
          location: berlin,
        ),
        isNull,
      );
    });

    test('one-time alarm later today fires today', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6, 30);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
      );
      expect(plan, isNotNull);
      expect(plan!.alarm.id, 'a');
      expect(plan.scheduled, tz.TZDateTime(berlin, 2026, 5, 21, 7));
    });

    test('one-time alarm whose target already passed fires tomorrow', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 8);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2026, 5, 22, 7));
    });

    test('one-time alarm at exactly "now" is treated as already passed', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 7);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2026, 5, 22, 7));
    });

    test('repeating alarm picks the nearest weekday in the future', () {
      // 2026-05-21 is a Thursday (weekday 4). Repeats {2,4,6}.
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {2, 4, 6},
      );
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2026, 5, 21, 7));
    });

    test('repeating alarm whose today already passed picks next match', () {
      // Thu 08:00, alarm Mon/Wed/Fri at 07:00 → next is Fri.
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 3, 5},
      );
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 8);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2026, 5, 22, 7));
      expect(plan.scheduled.weekday, 5);
    });

    test('repeating alarm wraps across the week boundary', () {
      // Sat 09:00, alarm only Mon → next Mon.
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1},
      );
      final now = tz.TZDateTime(berlin, 2026, 5, 23, 9);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2026, 5, 25, 7));
      expect(plan.scheduled.weekday, 1);
    });

    test('chooses the soonest of multiple alarms', () {
      final earlier = _alarm(id: 'early', targetTimeMinutes: 6 * 60);
      final later = _alarm(id: 'late', targetTimeMinutes: 7 * 60);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 5);
      final plan = AlarmScheduleService.computeNext(
        alarms: [later, earlier],
        now: now,
        location: berlin,
      );
      expect(plan!.alarm.id, 'early');
      expect(plan.scheduled, tz.TZDateTime(berlin, 2026, 5, 21, 6));
    });

    test('breaks tie on identical instant by createdAt (oldest wins)', () {
      final older = _alarm(
        id: 'older',
        targetTimeMinutes: 7 * 60,
        createdAt: DateTime.utc(2026, 4),
      );
      final newer = _alarm(
        id: 'newer',
        targetTimeMinutes: 7 * 60,
        createdAt: DateTime.utc(2026, 5),
      );
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6);
      final plan = AlarmScheduleService.computeNext(
        alarms: [newer, older],
        now: now,
        location: berlin,
      );
      expect(plan!.alarm.id, 'older');
    });

    test('skips disabled alarms', () {
      final off = _alarm(id: 'off', targetTimeMinutes: 6 * 60, enabled: false);
      final on = _alarm(id: 'on', targetTimeMinutes: 7 * 60);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 5);
      final plan = AlarmScheduleService.computeNext(
        alarms: [off, on],
        now: now,
        location: berlin,
      );
      expect(plan!.alarm.id, 'on');
    });

    test('every-day repeat fires today when today is still in the future', () {
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6, 30);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2026, 5, 21, 7));
    });

    test('a 23:30 one-time alarm at 23:00 fires tonight, not tomorrow', () {
      final a = _alarm(targetTimeMinutes: 23 * 60 + 30);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 23);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2026, 5, 21, 23, 30));
    });

    test('a 00:30 one-time alarm at 23:55 fires after midnight tomorrow', () {
      final a = _alarm(targetTimeMinutes: 30);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 23, 55);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2026, 5, 22, 0, 30));
    });
  });

  group('AlarmScheduleService.computeUpcomingForAlarm', () {
    test('returns empty when count <= 0', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6);
      expect(
        AlarmScheduleService.computeUpcomingForAlarm(
          alarm: a,
          now: now,
          location: berlin,
          count: 0,
        ),
        isEmpty,
      );
      expect(
        AlarmScheduleService.computeUpcomingForAlarm(
          alarm: a,
          now: now,
          location: berlin,
          count: -3,
        ),
        isEmpty,
      );
    });

    test('returns empty when alarm is disabled', () {
      final a = _alarm(targetTimeMinutes: 7 * 60, enabled: false);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6);
      expect(
        AlarmScheduleService.computeUpcomingForAlarm(
          alarm: a,
          now: now,
          location: berlin,
          count: 5,
        ),
        isEmpty,
      );
    });

    test('one-time alarm yields exactly one upcoming entry', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6);
      final upcoming = AlarmScheduleService.computeUpcomingForAlarm(
        alarm: a,
        now: now,
        location: berlin,
        count: 5,
      );
      expect(upcoming, hasLength(1));
      expect(upcoming.first.scheduled, tz.TZDateTime(berlin, 2026, 5, 21, 7));
    });

    test('repeating alarm yields N entries on consecutive matching days', () {
      // Mon..Fri at 07:00, starting Wed 06:00 → Wed, Thu, Fri, Mon, Tue.
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5},
      );
      final now = tz.TZDateTime(berlin, 2026, 5, 20, 6); // Wed
      final upcoming = AlarmScheduleService.computeUpcomingForAlarm(
        alarm: a,
        now: now,
        location: berlin,
        count: 5,
      );
      expect(upcoming, hasLength(5));
      expect(upcoming[0].scheduled, tz.TZDateTime(berlin, 2026, 5, 20, 7));
      expect(upcoming[1].scheduled, tz.TZDateTime(berlin, 2026, 5, 21, 7));
      expect(upcoming[2].scheduled, tz.TZDateTime(berlin, 2026, 5, 22, 7));
      expect(upcoming[3].scheduled, tz.TZDateTime(berlin, 2026, 5, 25, 7));
      expect(upcoming[4].scheduled, tz.TZDateTime(berlin, 2026, 5, 26, 7));
    });

    test('result list is unmodifiable', () {
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6);
      final upcoming = AlarmScheduleService.computeUpcomingForAlarm(
        alarm: a,
        now: now,
        location: berlin,
        count: 3,
      );
      expect(() => upcoming.add(upcoming.first), throwsUnsupportedError);
    });
  });

  group('AlarmScheduleService.computeNextForAlarm — wake-window trio', () {
    test('soft-start and final are derived from the wake window', () {
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        wakeWindowStartMinutesBefore: 15,
      );
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 5);
      final plan = AlarmScheduleService.computeNextForAlarm(
        alarm: a,
        now: now,
        location: berlin,
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2026, 5, 21, 7));
      expect(plan.softStart, tz.TZDateTime(berlin, 2026, 5, 21, 6, 45));
    });

    test('soft-start and final are null when the alarm has none', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 5);
      final plan = AlarmScheduleService.computeNextForAlarm(
        alarm: a,
        now: now,
        location: berlin,
      );
      expect(plan!.softStart, isNull);
    });
  });

  group('AlarmScheduleService skip-next handling', () {
    test('skipping the next occurrence yields the next-after one', () {
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5},
      );
      final now = tz.TZDateTime(berlin, 2026, 5, 20, 6); // Wed
      final wedScheduled = tz.TZDateTime(berlin, 2026, 5, 20, 7);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
        finishedOccurrences: [
          _skipped(alarmId: 'a', scheduledUtc: wedScheduled.toUtc()),
        ],
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2026, 5, 21, 7));
      expect(plan.scheduled.weekday, 4); // Thu
    });

    test('a skipped occurrence for a different alarm is ignored', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
        finishedOccurrences: [
          _skipped(
            alarmId: 'other',
            scheduledUtc: tz.TZDateTime(berlin, 2026, 5, 21, 7).toUtc(),
          ),
        ],
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2026, 5, 21, 7));
    });

    test('only skipped status entries are honoured', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6);
      final occ = AlarmOccurrence(
        id: 'o',
        alarmId: 'a',
        scheduledAt: tz.TZDateTime(berlin, 2026, 5, 21, 7).toUtc(),
        softStartAt: null,
        status: AlarmStatus.scheduled,
        triggeredAt: null,
        dismissedAt: null,
        snoozeCount: 0,
        note: '',
      );
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
        finishedOccurrences: [occ],
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2026, 5, 21, 7));
    });

    test('skipping every reachable occurrence returns null', () {
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6);
      final skipped = <AlarmOccurrence>[
        for (var d = 0; d <= AlarmScheduleService.searchHorizonDays; d++)
          _skipped(
            id: 's$d',
            alarmId: 'a',
            scheduledUtc: tz.TZDateTime(berlin, 2026, 5, 21 + d, 7).toUtc(),
          ),
      ];
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
        finishedOccurrences: skipped,
      );
      expect(plan, isNull);
    });
  });

  group('AlarmScheduleService DST', () {
    test('US spring-forward gap: 02:30 target rolls forward', () {
      // 2026-03-08 is a US "spring forward" date — clocks jump from
      // 02:00 to 03:00 in America/New_York, so 02:30 does not exist.
      // CapyWake's documented behaviour: fire at the next valid local
      // instant. The TZDateTime constructor projects the wall-clock to
      // the post-gap offset, so the resulting UTC instant matches the
      // first wall-clock minute after the gap.
      final a = _alarm(targetTimeMinutes: 2 * 60 + 30);
      final now = tz.TZDateTime(newYork, 2026, 3, 8);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: newYork,
      );
      // Constructing TZDateTime(newYork, 2026, 3, 8, 2, 30) returns a UTC
      // instant equal to TZDateTime(newYork, 2026, 3, 8, 3, 30).
      final post = tz.TZDateTime(newYork, 2026, 3, 8, 3, 30);
      expect(plan!.scheduled.toUtc(), post.toUtc());
      expect(plan.scheduled.isAfter(now), isTrue);
    });

    test(
      'US fall-back overlap: 01:30 target fires at the first occurrence',
      () {
        // 2026-11-01 is a US "fall back" date — clocks jump from 02:00 back
        // to 01:00 in America/New_York, so 01:30 happens twice. CapyWake
        // fires at the first occurrence.
        final a = _alarm(targetTimeMinutes: 1 * 60 + 30);
        // "now" is 00:30 EDT (still on summer time) on the fall-back day.
        final now = tz.TZDateTime(newYork, 2026, 11, 1, 0, 30);
        final plan = AlarmScheduleService.computeNext(
          alarms: [a],
          now: now,
          location: newYork,
        );
        // The first 01:30 of the day is at UTC 05:30 (EDT, UTC-4); the
        // second is at UTC 06:30 (EST, UTC-5). We expect the earlier one.
        final firstOccurrence = DateTime.utc(2026, 11, 1, 5, 30);
        expect(plan!.scheduled.toUtc(), firstOccurrence);
      },
    );

    test('non-DST timezone (UTC) is not affected by spring/fall', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = tz.TZDateTime(utc, 2026, 3, 8, 6, 30);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: utc,
      );
      expect(plan!.scheduled, tz.TZDateTime(utc, 2026, 3, 8, 7));
    });
  });

  group('AlarmScheduleService — timezone travel', () {
    test(
      'recomputing in a new location returns the next 07:00 in that zone',
      () {
        // The user sets a 07:00 alarm at home in Berlin, then flies to New
        // York. After landing, we recompute "now" as a New York
        // TZDateTime — the engine should return the next 07:00 wall clock
        // in New York (NOT a fixed UTC instant from when the alarm was
        // first scheduled).
        final a = _alarm(targetTimeMinutes: 7 * 60);
        final nowInNy = tz.TZDateTime(newYork, 2026, 5, 21, 6);
        final plan = AlarmScheduleService.computeNext(
          alarms: [a],
          now: nowInNy,
          location: newYork,
        );
        expect(plan!.scheduled, tz.TZDateTime(newYork, 2026, 5, 21, 7));
        // Sanity: the same alarm scheduled at home (Berlin) at the same
        // wall clock corresponds to a different UTC instant.
        final nowInBerlin = tz.TZDateTime(berlin, 2026, 5, 21, 6);
        final planBerlin = AlarmScheduleService.computeNext(
          alarms: [a],
          now: nowInBerlin,
          location: berlin,
        );
        expect(
          planBerlin!.scheduled.toUtc(),
          isNot(plan.scheduled.toUtc()),
        );
      },
    );
  });

  group('AlarmScheduleService — search horizon', () {
    test('skipping the first 13 candidates still finds the day-14 match', () {
      // With every-day repeat, candidates exist on each of days 0..14. By
      // skipping days 0..13 the only reachable candidate is day 14 — the
      // last one inside the horizon (loop bound is `<=`). We expect that
      // candidate to be returned, proving the inclusive boundary holds.
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final now = tz.TZDateTime(berlin, 2026, 5, 21, 6);
      final skipped = <AlarmOccurrence>[
        for (var d = 0; d < AlarmScheduleService.searchHorizonDays; d++)
          _skipped(
            id: 's$d',
            alarmId: 'a',
            scheduledUtc: tz.TZDateTime(berlin, 2026, 5, 21 + d, 7).toUtc(),
          ),
      ];
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
        finishedOccurrences: skipped,
      );
      expect(plan, isNotNull);
      expect(
        plan!.scheduled,
        tz.TZDateTime(
          berlin,
          2026,
          5,
          21 + AlarmScheduleService.searchHorizonDays,
          7,
        ),
      );
    });
  });

  group('AlarmScheduleService — leap day', () {
    test('Feb 29 fires correctly on a leap year', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = tz.TZDateTime(berlin, 2028, 2, 29, 6); // 2028 = leap
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2028, 2, 29, 7));
    });

    test('one-time alarm crossing a non-leap Feb 28 → Mar 1 boundary', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      // 23:00 on a non-leap-year Feb 28 → next 07:00 is Mar 1.
      final now = tz.TZDateTime(berlin, 2027, 2, 28, 23);
      final plan = AlarmScheduleService.computeNext(
        alarms: [a],
        now: now,
        location: berlin,
      );
      expect(plan!.scheduled, tz.TZDateTime(berlin, 2027, 3, 1, 7));
    });
  });

  group('AlarmOccurrencePlan value semantics', () {
    test('value-equality + timeUntil', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final scheduled = tz.TZDateTime(berlin, 2026, 5, 21, 7);
      final p1 = AlarmOccurrencePlan(
        alarm: a,
        scheduled: scheduled,
        softStart: null,
        location: berlin,
      );
      final p2 = AlarmOccurrencePlan(
        alarm: a,
        scheduled: tz.TZDateTime(berlin, 2026, 5, 21, 7),
        softStart: null,
        location: berlin,
      );
      expect(p1, p2);
      expect(p1.hashCode, p2.hashCode);
      expect(
        p1.timeUntil(tz.TZDateTime(berlin, 2026, 5, 21, 6, 30)),
        const Duration(minutes: 30),
      );
      expect(p1, p1); // identical short-circuit
    });

    test('different fields break equality', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final base = AlarmOccurrencePlan(
        alarm: a,
        scheduled: tz.TZDateTime(berlin, 2026, 5, 21, 7),
        softStart: null,
        location: berlin,
      );
      final differentTime = AlarmOccurrencePlan(
        alarm: a,
        scheduled: tz.TZDateTime(berlin, 2026, 5, 21, 8),
        softStart: null,
        location: berlin,
      );
      final differentSoft = AlarmOccurrencePlan(
        alarm: a,
        scheduled: tz.TZDateTime(berlin, 2026, 5, 21, 7),
        softStart: tz.TZDateTime(berlin, 2026, 5, 21, 6, 45),
        location: berlin,
      );
      final differentLocation = AlarmOccurrencePlan(
        alarm: a,
        scheduled: tz.TZDateTime(newYork, 2026, 5, 21, 7),
        softStart: null,
        location: newYork,
      );
      expect(base == differentTime, isFalse);
      expect(base == differentSoft, isFalse);
      expect(base == differentLocation, isFalse);
      // softStart equality null-vs-set both directions
      expect(differentSoft == base, isFalse);
    });

    test('UTC convenience getters', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final scheduled = tz.TZDateTime(berlin, 2026, 5, 21, 7);
      final soft = tz.TZDateTime(berlin, 2026, 5, 21, 6, 45);
      final plan = AlarmOccurrencePlan(
        alarm: a,
        scheduled: scheduled,
        softStart: soft,
        location: berlin,
      );
      expect(plan.scheduledUtc, scheduled.toUtc());
      expect(plan.softStartUtc, soft.toUtc());

      final planNoExtras = AlarmOccurrencePlan(
        alarm: a,
        scheduled: scheduled,
        softStart: null,
        location: berlin,
      );
      expect(planNoExtras.softStartUtc, isNull);
    });

    test('two plans with the same non-null softStart are equal', () {
      // Drives the both-non-null branch of the internal `_instantEqual`
      // helper for the soft-start comparison.
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final p1 = AlarmOccurrencePlan(
        alarm: a,
        scheduled: tz.TZDateTime(berlin, 2026, 5, 21, 7),
        softStart: tz.TZDateTime(berlin, 2026, 5, 21, 6, 45),
        location: berlin,
      );
      final p2 = AlarmOccurrencePlan(
        alarm: a,
        scheduled: tz.TZDateTime(berlin, 2026, 5, 21, 7),
        softStart: tz.TZDateTime(berlin, 2026, 5, 21, 6, 45),
        location: berlin,
      );
      expect(p1, p2);
      expect(p1.hashCode, p2.hashCode);
    });
  });

  group('finished occurrences', () {
    AlarmOccurrence finished({
      required AlarmStatus status,
      required DateTime target,
      String alarmId = 'daily',
    }) {
      return AlarmOccurrence(
        id: 'occ-${status.name}',
        alarmId: alarmId,
        scheduledAt: target,
        softStartAt: null,
        status: status,
        triggeredAt: null,
        dismissedAt: null,
        snoozeCount: 0,
        note: '',
      );
    }

    final daily = _alarm(
      id: 'daily',
      targetTimeMinutes: 7 * 60,
      repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      wakeWindowStartMinutesBefore: 15,
    );

    for (final status in AlarmStatus.values) {
      test('a ${status.name} row ${status.isTerminal ? "retires" : "leaves"} '
          'its candidate', () {
        // Asked at 06:50, inside the window leading to 07:00 — the only
        // moment where the answer is visible at all, because outside it the
        // target has already gone by and today is never a candidate.
        final plan = AlarmScheduleService.computeNextForAlarm(
          alarm: daily,
          now: tz.TZDateTime.utc(2026, 5, 21, 6, 50),
          location: tz.UTC,
          finishedOccurrences: [
            finished(status: status, target: DateTime.utc(2026, 5, 21, 7)),
          ],
        );
        expect(
          plan!.scheduledUtc,
          status.isTerminal
              ? DateTime.utc(2026, 5, 22, 7)
              : DateTime.utc(2026, 5, 21, 7),
        );
      });
    }

    test('a finished row for a different alarm is ignored', () {
      final plan = AlarmScheduleService.computeNextForAlarm(
        alarm: daily,
        now: tz.TZDateTime.utc(2026, 5, 21, 6, 50),
        location: tz.UTC,
        finishedOccurrences: [
          finished(
            status: AlarmStatus.dismissed,
            target: DateTime.utc(2026, 5, 21, 7),
            alarmId: 'someone-else',
          ),
        ],
      );
      expect(plan!.scheduledUtc, DateTime.utc(2026, 5, 21, 7));
    });

    test('consecutive finished mornings are all walked past', () {
      final plan = AlarmScheduleService.computeNextForAlarm(
        alarm: daily,
        now: tz.TZDateTime.utc(2026, 5, 21, 6, 50),
        location: tz.UTC,
        finishedOccurrences: [
          finished(
            status: AlarmStatus.dismissed,
            target: DateTime.utc(2026, 5, 21, 7),
          ),
          finished(
            status: AlarmStatus.skipped,
            target: DateTime.utc(2026, 5, 22, 7),
          ),
        ],
      );
      expect(plan!.scheduledUtc, DateTime.utc(2026, 5, 23, 7));
    });

    test('the match survives a change of timezone', () {
      // The row is written in UTC and the candidate is computed in Berlin.
      // Matching on the canonical instant is what keeps them the same
      // morning — a wall-clock comparison would not.
      final plan = AlarmScheduleService.computeNextForAlarm(
        alarm: daily,
        now: tz.TZDateTime(berlin, 2026, 5, 21, 6, 50),
        location: berlin,
        finishedOccurrences: [
          finished(
            status: AlarmStatus.dismissed,
            target: tz.TZDateTime(berlin, 2026, 5, 21, 7).toUtc(),
          ),
        ],
      );
      expect(
        plan!.scheduledUtc,
        tz.TZDateTime(berlin, 2026, 5, 22, 7).toUtc(),
      );
    });
  });

  group('AlarmScheduleService.targetForRing', () {
    Alarm windowed(int minutes) => _alarm(
      id: 'daily',
      targetTimeMinutes: 7 * 60,
      repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      wakeWindowStartMinutesBefore: minutes,
    );

    tz.TZDateTime target(Alarm alarm, tz.TZDateTime firedAt) =>
        AlarmScheduleService.targetForRing(
          alarm: alarm,
          firedAt: firedAt,
          location: tz.UTC,
        );

    test('a ring at the soft start resolves to the target', () {
      expect(
        target(windowed(15), tz.TZDateTime.utc(2026, 5, 21, 6, 45)),
        tz.TZDateTime.utc(2026, 5, 21, 7),
      );
    });

    test('a ring floored into an open window resolves to the target', () {
      // What actually happens when an unrelated write re-arms mid-ramp:
      // `arm` floors the 06:45 start to the clock, so the platform reports
      // 06:50 and the occurrence still has to name 07:00.
      expect(
        target(windowed(15), tz.TZDateTime.utc(2026, 5, 21, 6, 50)),
        tz.TZDateTime.utc(2026, 5, 21, 7),
      );
    });

    test('a ring at the target resolves to itself', () {
      expect(
        target(windowed(15), tz.TZDateTime.utc(2026, 5, 21, 7)),
        tz.TZDateTime.utc(2026, 5, 21, 7),
      );
    });

    test('an alarm without a window resolves to the fire instant', () {
      final firedAt = tz.TZDateTime.utc(2026, 5, 21, 7);
      expect(target(windowed(0), firedAt), firedAt);
    });

    test('a ring past the target has no window left to belong to', () {
      // A snooze re-ring, or the motion check's extra ring. Both are their
      // own thing and neither reopens the morning's ramp.
      final firedAt = tz.TZDateTime.utc(2026, 5, 21, 7, 9);
      expect(target(windowed(15), firedAt), firedAt);
    });

    test('a ring far outside any window resolves to itself', () {
      final firedAt = tz.TZDateTime.utc(2026, 5, 21, 12);
      expect(target(windowed(15), firedAt), firedAt);
    });

    test('a window crossing midnight reaches the next day', () {
      // 00:10 target with a thirty-minute window opens at 23:40 the evening
      // before, so the target the ring belongs to is tomorrow's.
      final midnightish = _alarm(
        id: 'daily',
        targetTimeMinutes: 10,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
        wakeWindowStartMinutesBefore: 30,
      );
      expect(
        target(midnightish, tz.TZDateTime.utc(2026, 5, 21, 23, 40)),
        tz.TZDateTime.utc(2026, 5, 22, 0, 10),
      );
    });

    test('a target on a day the alarm does not repeat is not claimed', () {
      // 2026-05-23 is a Saturday. A weekday alarm's window never opens into
      // it, so a ring then belongs to no morning but its own instant.
      final weekdays = _alarm(
        id: 'daily',
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5},
        wakeWindowStartMinutesBefore: 15,
      );
      final firedAt = tz.TZDateTime.utc(2026, 5, 23, 6, 45);
      expect(target(weekdays, firedAt), firedAt);
    });

    test('a window crossing midnight respects the repeat days', () {
      // 2026-05-25 is a Monday, so a weekday alarm's 00:10 window opens at
      // 23:40 on Sunday the 24th and belongs to Monday's ring.
      final weekdays = _alarm(
        id: 'daily',
        targetTimeMinutes: 10,
        repeatWeekdays: const {1, 2, 3, 4, 5},
        wakeWindowStartMinutesBefore: 30,
      );
      expect(
        target(weekdays, tz.TZDateTime.utc(2026, 5, 24, 23, 40)),
        tz.TZDateTime.utc(2026, 5, 25, 0, 10),
      );
      // The Friday-night equivalent has no Saturday ring to belong to.
      final fridayNight = tz.TZDateTime.utc(2026, 5, 29, 23, 40);
      expect(target(weekdays, fridayNight), fridayNight);
    });

    test('a one-time alarm claims whichever day the ring falls on', () {
      final once = _alarm(
        id: 'once',
        targetTimeMinutes: 7 * 60,
        wakeWindowStartMinutesBefore: 15,
      );
      expect(
        target(once, tz.TZDateTime.utc(2026, 5, 23, 6, 45)),
        tz.TZDateTime.utc(2026, 5, 23, 7),
      );
    });

    test('the target is resolved in the location it is asked for', () {
      final firedAt = tz.TZDateTime(berlin, 2026, 5, 21, 6, 45);
      final resolved = AlarmScheduleService.targetForRing(
        alarm: windowed(15),
        firedAt: firedAt,
        location: berlin,
      );
      expect(resolved, tz.TZDateTime(berlin, 2026, 5, 21, 7));
      expect(resolved.location, berlin);
    });
  });
}
