import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/next_alarm.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build a deterministic [Alarm] for these unit tests.
///
/// `targetTimeMinutes` is required (every test in this file is about scheduling
/// at a specific minute-of-day, so making it explicit reads better and lets
/// the analyzer flag stray defaults).
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

/// Build a `skipped` occurrence row marking the next ring as skipped.
AlarmOccurrence _skipped({
  required String alarmId,
  required DateTime scheduledLocal,
  String id = 's',
}) {
  return AlarmOccurrence(
    id: id,
    alarmId: alarmId,
    scheduledAt: scheduledLocal.toUtc(),
    softStartAt: null,
    status: AlarmStatus.skipped,
    triggeredAt: null,
    dismissedAt: null,
    snoozeCount: 0,
    note: '',
  );
}

void main() {
  group('NextAlarmService.computeNext', () {
    test('returns null when there are no alarms', () {
      expect(
        NextAlarmService.computeNext(
          alarms: const [],
          now: DateTime(2026, 5, 21, 6),
        ),
        isNull,
      );
    });

    test('returns null when every alarm is disabled', () {
      final a = _alarm(targetTimeMinutes: 7 * 60, enabled: false);
      expect(
        NextAlarmService.computeNext(
          alarms: [a],
          now: DateTime(2026, 5, 21, 6),
        ),
        isNull,
      );
    });

    test('one-time alarm later today fires today', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = DateTime(2026, 5, 21, 6, 30); // before 07:00
      final info = NextAlarmService.computeNext(alarms: [a], now: now);
      expect(info, isNotNull);
      expect(info!.alarm.id, 'a');
      expect(info.scheduledLocal, DateTime(2026, 5, 21, 7));
    });

    test('one-time alarm whose target already passed fires tomorrow', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = DateTime(2026, 5, 21, 8); // after 07:00
      final info = NextAlarmService.computeNext(alarms: [a], now: now);
      expect(info, isNotNull);
      expect(info!.scheduledLocal, DateTime(2026, 5, 22, 7));
    });

    test('one-time alarm at exactly "now" is treated as already passed', () {
      // The ringing slot must be strictly *after* now, never identical.
      // Otherwise a freshly-saved alarm whose time is the current minute
      // would race the engine; honest behaviour is to fall through to the
      // next day.
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = DateTime(2026, 5, 21, 7);
      final info = NextAlarmService.computeNext(alarms: [a], now: now);
      expect(info!.scheduledLocal, DateTime(2026, 5, 22, 7));
    });

    test('repeating alarm picks the nearest weekday in the future', () {
      // 2026-05-21 is a Thursday (weekday 4). Repeats {2,4,6} → next ring
      // tomorrow? No, today's 07:00 hasn't passed yet, so today fires.
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {2, 4, 6},
      );
      final now = DateTime(2026, 5, 21, 6); // Thursday morning
      final info = NextAlarmService.computeNext(alarms: [a], now: now);
      expect(info!.scheduledLocal, DateTime(2026, 5, 21, 7));
    });

    test('repeating alarm whose today already passed picks next match', () {
      // Thursday 08:00, alarm {Mon=1, Wed=3, Fri=5} at 07:00 → next is Fri.
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 3, 5},
      );
      final now = DateTime(2026, 5, 21, 8); // Thursday post-target
      final info = NextAlarmService.computeNext(alarms: [a], now: now);
      expect(info!.scheduledLocal, DateTime(2026, 5, 22, 7));
      expect(info.scheduledLocal.weekday, 5); // Friday
    });

    test('repeating alarm wraps across the week boundary', () {
      // Saturday 09:00, alarm only on Monday → should land on next Monday.
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1},
      );
      final now = DateTime(2026, 5, 23, 9); // Saturday
      final info = NextAlarmService.computeNext(alarms: [a], now: now);
      expect(info!.scheduledLocal, DateTime(2026, 5, 25, 7));
      expect(info.scheduledLocal.weekday, 1); // Monday
    });

    test('chooses the soonest of multiple alarms', () {
      // 06:00 Wednesday alarm and 07:00 Wednesday alarm — pick 06:00.
      final earlier = _alarm(id: 'early', targetTimeMinutes: 6 * 60);
      final later = _alarm(id: 'late', targetTimeMinutes: 7 * 60);
      final now = DateTime(2026, 5, 21, 5); // Thursday 05:00
      final info = NextAlarmService.computeNext(
        alarms: [later, earlier],
        now: now,
      );
      expect(info!.alarm.id, 'early');
      expect(info.scheduledLocal, DateTime(2026, 5, 21, 6));
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
      final now = DateTime(2026, 5, 21, 6);
      final info = NextAlarmService.computeNext(
        alarms: [newer, older],
        now: now,
      );
      expect(info!.alarm.id, 'older');
    });

    test('skips a disabled alarm even if its ring would be sooner', () {
      final disabled = _alarm(
        id: 'off',
        targetTimeMinutes: 6 * 60,
        enabled: false,
      );
      final on = _alarm(id: 'on', targetTimeMinutes: 7 * 60);
      final now = DateTime(2026, 5, 21, 5);
      final info = NextAlarmService.computeNext(
        alarms: [disabled, on],
        now: now,
      );
      expect(info!.alarm.id, 'on');
    });

    test('ignores all-days-disabled (empty repeat with enabled=false)', () {
      final disabled = _alarm(
        targetTimeMinutes: 7 * 60,
        enabled: false,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      expect(
        NextAlarmService.computeNext(
          alarms: [disabled],
          now: DateTime(2026, 5, 21, 6),
        ),
        isNull,
      );
    });

    test('every-day repeat fires today when today is still in the future', () {
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final now = DateTime(2026, 5, 21, 6, 30);
      final info = NextAlarmService.computeNext(alarms: [a], now: now);
      expect(info!.scheduledLocal, DateTime(2026, 5, 21, 7));
    });

    test('a 23:30 one-time alarm at 23:00 fires tonight, not tomorrow', () {
      // Midnight-wrap edge case: the ring is 30 min from now, same calendar
      // day; we must not skip ahead a full day.
      final a = _alarm(targetTimeMinutes: 23 * 60 + 30);
      final now = DateTime(2026, 5, 21, 23);
      final info = NextAlarmService.computeNext(alarms: [a], now: now);
      expect(info!.scheduledLocal, DateTime(2026, 5, 21, 23, 30));
    });

    test('a 00:30 one-time alarm at 23:55 fires after midnight tomorrow', () {
      // Midnight-wrap the other way: 00:30 today is in the past, so we
      // schedule 00:30 tomorrow.
      final a = _alarm(targetTimeMinutes: 30); // 00:30
      final now = DateTime(2026, 5, 21, 23, 55);
      final info = NextAlarmService.computeNext(alarms: [a], now: now);
      expect(info!.scheduledLocal, DateTime(2026, 5, 22, 0, 30));
    });
  });

  group('NextAlarmService.computeNextForAlarm — soft-start / final', () {
    test('soft-start and final are derived from the wake window', () {
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        wakeWindowStartMinutesBefore: 15,
      );
      final now = DateTime(2026, 5, 21, 5);
      final info = NextAlarmService.computeNextForAlarm(alarm: a, now: now);
      expect(info!.scheduledLocal, DateTime(2026, 5, 21, 7));
      expect(info.softStartLocal, DateTime(2026, 5, 21, 6, 45));
    });

    test('soft-start and final are null when the alarm has none', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = DateTime(2026, 5, 21, 5);
      final info = NextAlarmService.computeNextForAlarm(alarm: a, now: now);
      expect(info!.softStartLocal, isNull);
    });
  });

  group('NextAlarmService skip-next handling', () {
    test('skipping the next occurrence yields the next-after one', () {
      // Mon-Fri alarm at 07:00. Today is Wed; we skip Wed → next is Thu.
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5},
      );
      final now = DateTime(2026, 5, 20, 6); // Wednesday
      final wedLocal = DateTime(2026, 5, 20, 7);
      final info = NextAlarmService.computeNext(
        alarms: [a],
        now: now,
        finishedOccurrences: [
          _skipped(alarmId: 'a', scheduledLocal: wedLocal),
        ],
      );
      expect(info!.scheduledLocal, DateTime(2026, 5, 21, 7));
      expect(info.scheduledLocal.weekday, 4); // Thursday
    });

    test('a skipped occurrence for a different alarm is ignored', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = DateTime(2026, 5, 21, 6);
      final info = NextAlarmService.computeNext(
        alarms: [a],
        now: now,
        finishedOccurrences: [
          _skipped(
            alarmId: 'other',
            scheduledLocal: DateTime(2026, 5, 21, 7),
          ),
        ],
      );
      expect(info!.scheduledLocal, DateTime(2026, 5, 21, 7));
    });

    test('only skipped status entries are honoured', () {
      // A "scheduled" or "dismissed" occurrence at the same instant must
      // NOT skip the ring. Skip is an explicit user act.
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = DateTime(2026, 5, 21, 6);
      final occ = AlarmOccurrence(
        id: 'o',
        alarmId: 'a',
        scheduledAt: DateTime(2026, 5, 21, 7).toUtc(),
        softStartAt: null,
        status: AlarmStatus.scheduled,
        triggeredAt: null,
        dismissedAt: null,
        snoozeCount: 0,
        note: '',
      );
      final info = NextAlarmService.computeNext(
        alarms: [a],
        now: now,
        finishedOccurrences: [occ],
      );
      expect(info!.scheduledLocal, DateTime(2026, 5, 21, 7));
    });

    test('skipping every reachable occurrence returns null', () {
      // One-time alarm whose only two candidates (today and tomorrow within
      // the horizon — actually it walks 14 days) are all skipped.
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      );
      final now = DateTime(2026, 5, 21, 6);
      final skipped = <AlarmOccurrence>[
        for (var d = 0; d <= NextAlarmService.searchHorizonDays; d++)
          _skipped(
            id: 's$d',
            alarmId: 'a',
            scheduledLocal: DateTime(2026, 5, 21 + d, 7),
          ),
      ];
      final info = NextAlarmService.computeNext(
        alarms: [a],
        now: now,
        finishedOccurrences: skipped,
      );
      expect(info, isNull);
    });
  });

  group('NextAlarmInfo value semantics', () {
    test('value-equality + timeUntil', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final info1 = NextAlarmInfo(
        alarm: a,
        scheduledLocal: DateTime(2026, 5, 21, 7),
        softStartLocal: null,
      );
      final info2 = NextAlarmInfo(
        alarm: a,
        scheduledLocal: DateTime(2026, 5, 21, 7),
        softStartLocal: null,
      );
      expect(info1, info2);
      expect(info1.hashCode, info2.hashCode);
      expect(
        info1.timeUntil(DateTime(2026, 5, 21, 6, 30)),
        const Duration(minutes: 30),
      );
    });

    test('different fields break equality', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final base = NextAlarmInfo(
        alarm: a,
        scheduledLocal: DateTime(2026, 5, 21, 7),
        softStartLocal: null,
      );
      final differentTime = NextAlarmInfo(
        alarm: a,
        scheduledLocal: DateTime(2026, 5, 21, 8),
        softStartLocal: null,
      );
      final differentSoft = NextAlarmInfo(
        alarm: a,
        scheduledLocal: DateTime(2026, 5, 21, 7),
        softStartLocal: DateTime(2026, 5, 21, 6, 45),
      );
      expect(base == differentTime, isFalse);
      expect(base == differentSoft, isFalse);
      expect(base, base); // identical short-circuit
    });
  });

  group('NextAlarmService DST edge cases (local-time fidelity)', () {
    test('spring-forward day still produces a valid next ring', () {
      // 2026-03-08 is the US "spring forward" date. We ask for the next
      // 07:00 from 06:30 on that date — the result must still be the
      // following local 07:00 instant. (The platform alarm engine picks
      // up timezone-aware scheduling in Phase 05 / 06; this service uses
      // local DateTime arithmetic so it follows whatever the device clock
      // does.)
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = DateTime(2026, 3, 8, 6, 30);
      final info = NextAlarmService.computeNext(alarms: [a], now: now);
      expect(info!.scheduledLocal.year, 2026);
      expect(info.scheduledLocal.month, 3);
      expect(info.scheduledLocal.day, 8);
      expect(info.scheduledLocal.hour, 7);
      expect(info.scheduledLocal.minute, 0);
    });

    test('leap day Feb 29 fires correctly on a leap year', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final now = DateTime(2028, 2, 29, 6); // 2028 is a leap year
      final info = NextAlarmService.computeNext(alarms: [a], now: now);
      expect(info!.scheduledLocal, DateTime(2028, 2, 29, 7));
    });
  });
}
