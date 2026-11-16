import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests exercise the **naive local DateTime** variant of the
/// schedule service that the Today screen uses. The timezone-aware
/// variant is exhaustively tested in `alarm_schedule_service_test.dart`;
/// here we just verify the local-DateTime delegation paths so coverage
/// of the helper methods (`_buildLocalResult`, `_isSkippedLocal`) is
/// direct rather than going through `NextAlarmService`.
Alarm _alarm({
  required int targetTimeMinutes,
  String id = 'a',
  bool enabled = true,
  Set<int> repeatWeekdays = const <int>{},
  int wakeWindowStartMinutesBefore = 0,
}) {
  final t = DateTime.utc(2026, 5);
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
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  group('AlarmScheduleService.computeNextLocal', () {
    test('disabled alarm returns null', () {
      final a = _alarm(targetTimeMinutes: 7 * 60, enabled: false);
      expect(
        AlarmScheduleService.computeNextLocal(
          alarm: a,
          now: DateTime(2026, 5, 21, 6),
        ),
        isNull,
      );
    });

    test('one-time alarm fires today when target is in the future', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final result = AlarmScheduleService.computeNextLocal(
        alarm: a,
        now: DateTime(2026, 5, 21, 6),
      );
      expect(result!.scheduledLocal, DateTime(2026, 5, 21, 7));
    });

    test('repeating alarm honours weekday set', () {
      // Thu 08:00, alarm Mon/Wed/Fri at 07:00 → next is Fri.
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 3, 5},
      );
      final result = AlarmScheduleService.computeNextLocal(
        alarm: a,
        now: DateTime(2026, 5, 21, 8),
      );
      expect(result!.scheduledLocal, DateTime(2026, 5, 22, 7));
    });

    test('soft-start and final wake-window math', () {
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        wakeWindowStartMinutesBefore: 15,
      );
      final result = AlarmScheduleService.computeNextLocal(
        alarm: a,
        now: DateTime(2026, 5, 21, 5),
      );
      expect(result!.scheduledLocal, DateTime(2026, 5, 21, 7));
      expect(result.softStartLocal, DateTime(2026, 5, 21, 6, 45));
    });

    test('skipped occurrence pushes the next ring forward', () {
      final a = _alarm(
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {1, 2, 3, 4, 5},
      );
      final wedLocal = DateTime(2026, 5, 20, 7);
      final skipped = AlarmOccurrence(
        id: 's',
        alarmId: 'a',
        scheduledAt: wedLocal.toUtc(),
        softStartAt: null,
        status: AlarmStatus.skipped,
        triggeredAt: null,
        dismissedAt: null,
        snoozeCount: 0,
        note: '',
      );
      final result = AlarmScheduleService.computeNextLocal(
        alarm: a,
        now: DateTime(2026, 5, 20, 6),
        finishedOccurrences: [skipped],
      );
      expect(result!.scheduledLocal, DateTime(2026, 5, 21, 7));
    });
  });

  group('AlarmScheduleService.computeNextLocalAcross', () {
    test('returns null with no alarms', () {
      expect(
        AlarmScheduleService.computeNextLocalAcross(
          alarms: const [],
          now: DateTime(2026, 5, 21, 6),
        ),
        isNull,
      );
    });

    test('picks the soonest of multiple alarms', () {
      final earlier = _alarm(id: 'early', targetTimeMinutes: 6 * 60);
      final later = _alarm(id: 'late', targetTimeMinutes: 7 * 60);
      final result = AlarmScheduleService.computeNextLocalAcross(
        alarms: [later, earlier],
        now: DateTime(2026, 5, 21, 5),
      );
      expect(result!.alarm.id, 'early');
    });

    test('breaks ties by earlier createdAt', () {
      final older = Alarm(
        id: 'older',
        label: '',
        enabled: true,
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const <int>{},
        wakeMode: WakeMode.standard,
        wakeWindowStartMinutesBefore: 0,
        soundId: 'default',
        vibrationEnabled: true,
        snoozeEnabled: true,
        snoozeDurationMinutes: 9,
        maxSnoozes: 5,
        dismissMethod: DismissMethod.normalButton,
        dismissChallengeDifficulty: null,
        confirmationEnabled: false,
        createdAt: DateTime.utc(2026, 4),
        updatedAt: DateTime.utc(2026, 4),
      );
      final newer = older.copyWith(
        id: 'newer',
        createdAt: DateTime.utc(2026, 5),
        updatedAt: DateTime.utc(2026, 5),
      );
      final result = AlarmScheduleService.computeNextLocalAcross(
        alarms: [newer, older],
        now: DateTime(2026, 5, 21, 6),
      );
      expect(result!.alarm.id, 'older');
    });
  });

  group('AlarmScheduleResult value semantics', () {
    test('equality + hashCode + timeUntil', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final r1 = AlarmScheduleResult(
        alarm: a,
        scheduledLocal: DateTime(2026, 5, 21, 7),
        softStartLocal: null,
      );
      final r2 = AlarmScheduleResult(
        alarm: a,
        scheduledLocal: DateTime(2026, 5, 21, 7),
        softStartLocal: null,
      );
      expect(r1, r2);
      expect(r1.hashCode, r2.hashCode);
      expect(
        r1.timeUntil(DateTime(2026, 5, 21, 6, 30)),
        const Duration(minutes: 30),
      );
      expect(r1, r1); // identical
    });

    test('different fields break equality', () {
      final a = _alarm(targetTimeMinutes: 7 * 60);
      final base = AlarmScheduleResult(
        alarm: a,
        scheduledLocal: DateTime(2026, 5, 21, 7),
        softStartLocal: null,
      );
      expect(
        base ==
            AlarmScheduleResult(
              alarm: a,
              scheduledLocal: DateTime(2026, 5, 21, 8),
              softStartLocal: null,
            ),
        isFalse,
      );
      expect(
        base ==
            AlarmScheduleResult(
              alarm: a,
              scheduledLocal: DateTime(2026, 5, 21, 7),
              softStartLocal: DateTime(2026, 5, 21, 6, 45),
            ),
        isFalse,
      );
    });
  });

  group('finished occurrences on the Today path', () {
    // The card and the alarm engine have to agree about which ring is next.
    // If Today still says "rings today at 07:00" for a morning the user got
    // up and dismissed, the app is describing a ring that will not happen.
    AlarmOccurrence finished({
      required AlarmStatus status,
      required DateTime targetLocal,
    }) {
      return AlarmOccurrence(
        id: 'occ',
        alarmId: 'a',
        scheduledAt: targetLocal.toUtc(),
        softStartAt: null,
        status: status,
        triggeredAt: null,
        dismissedAt: null,
        snoozeCount: 0,
        note: '',
      );
    }

    final daily = _alarm(
      targetTimeMinutes: 7 * 60,
      repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      wakeWindowStartMinutesBefore: 15,
    );

    for (final status in AlarmStatus.values) {
      test('a ${status.name} row ${status.isTerminal ? "moves" : "leaves"} '
          'the card to the next morning', () {
        final result = AlarmScheduleService.computeNextLocal(
          alarm: daily,
          now: DateTime(2026, 5, 21, 6, 50),
          finishedOccurrences: [
            finished(status: status, targetLocal: DateTime(2026, 5, 21, 7)),
          ],
        );
        expect(
          result!.scheduledLocal,
          status.isTerminal
              ? DateTime(2026, 5, 22, 7)
              : DateTime(2026, 5, 21, 7),
        );
      });
    }

    test('computeNextLocalAcross honours them too', () {
      final other = _alarm(id: 'other', targetTimeMinutes: 8 * 60);
      final result = AlarmScheduleService.computeNextLocalAcross(
        alarms: [daily, other],
        now: DateTime(2026, 5, 21, 6, 50),
        finishedOccurrences: [
          finished(
            status: AlarmStatus.dismissed,
            targetLocal: DateTime(2026, 5, 21, 7),
          ),
        ],
      );
      // The 08:00 alarm is untouched, so it is now the soonest.
      expect(result!.alarm.id, 'other');
      expect(result.scheduledLocal, DateTime(2026, 5, 21, 8));
    });
  });
}
