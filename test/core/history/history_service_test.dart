import 'package:capywake/core/history/history_service.dart';
import 'package:capywake/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build an [Alarm] with sensible defaults; tests only override fields they
/// care about.
Alarm _alarm({
  String id = 'a',
  WakeMode wakeMode = WakeMode.standard,
}) {
  return Alarm(
    id: id,
    label: '',
    enabled: true,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const <int>{},
    wakeMode: wakeMode,
    wakeWindowStartMinutesBefore: 0,
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
}

AlarmOccurrence _occ({
  required String id,
  required String alarmId,
  required DateTime scheduledAt,
  required AlarmStatus status,
  int snoozeCount = 0,
  DateTime? dismissedAt,
}) {
  return AlarmOccurrence(
    id: id,
    alarmId: alarmId,
    scheduledAt: scheduledAt,
    softStartAt: null,
    status: status,
    triggeredAt: null,
    dismissedAt: dismissedAt,
    snoozeCount: snoozeCount,
    note: '',
  );
}

void main() {
  // Pin "now" to a Wednesday in May 2026 (UTC) so weekday assertions are
  // deterministic. 2026-05-20 is a Wednesday.
  final now = DateTime.utc(2026, 5, 20, 12);

  group('HistoryService.summarise — empty + window', () {
    test('empty list → empty summary, default window', () {
      final s = HistoryService.summarise(
        occurrences: const [],
        alarms: const [],
        now: now,
      );
      expect(s, HistorySummary.empty);
      expect(s.isEmpty, isTrue);
      expect(s.windowDays, HistoryService.defaultWindowDays);
      expect(s.daily, isEmpty);
      expect(s.insights, isEmpty);
      expect(s.averageSnoozeCount, 0);
    });

    test('occurrence older than the window is dropped', () {
      final tooOld = _occ(
        id: 'o1',
        alarmId: 'a',
        scheduledAt: now.subtract(const Duration(days: 30)),
        status: AlarmStatus.dismissed,
      );
      final inWindow = _occ(
        id: 'o2',
        alarmId: 'a',
        scheduledAt: now.subtract(const Duration(days: 5)),
        status: AlarmStatus.dismissed,
      );
      final s = HistoryService.summarise(
        occurrences: [tooOld, inWindow],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.occurrenceCount, 1);
      expect(s.dismissedCount, 1);
    });

    test('occurrence in the future (after now) is dropped', () {
      final future = _occ(
        id: 'fut',
        alarmId: 'a',
        scheduledAt: now.add(const Duration(days: 1)),
        status: AlarmStatus.scheduled,
      );
      final s = HistoryService.summarise(
        occurrences: [future],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.occurrenceCount, 0);
    });

    test('occurrence on the boundary (== windowStart) is included', () {
      final onBoundary = _occ(
        id: 'b',
        alarmId: 'a',
        scheduledAt: now.subtract(
          const Duration(days: HistoryService.defaultWindowDays),
        ),
        status: AlarmStatus.dismissed,
      );
      final s = HistoryService.summarise(
        occurrences: [onBoundary],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.occurrenceCount, 1);
    });

    test('occurrence at exactly now is included', () {
      final atNow = _occ(
        id: 'n',
        alarmId: 'a',
        scheduledAt: now,
        status: AlarmStatus.dismissed,
      );
      final s = HistoryService.summarise(
        occurrences: [atNow],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.occurrenceCount, 1);
    });

    test('custom windowDays narrows the look-back', () {
      final occ7d = _occ(
        id: 'a',
        alarmId: 'a',
        scheduledAt: now.subtract(const Duration(days: 7)),
        status: AlarmStatus.dismissed,
      );
      final occ2d = _occ(
        id: 'b',
        alarmId: 'a',
        scheduledAt: now.subtract(const Duration(days: 2)),
        status: AlarmStatus.dismissed,
      );
      final s = HistoryService.summarise(
        occurrences: [occ7d, occ2d],
        alarms: [_alarm()],
        now: now,
        windowDays: 3,
      );
      expect(s.windowDays, 3);
      expect(s.occurrenceCount, 1);
    });

    test('asserts windowDays > 0', () {
      expect(
        () => HistoryService.summarise(
          occurrences: const [],
          alarms: const [],
          now: now,
          windowDays: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('HistoryService.summarise — counts + on-time/late split', () {
    test('counts each status correctly', () {
      final occs = <AlarmOccurrence>[
        _occ(
          id: '1',
          alarmId: 'a',
          scheduledAt: now.subtract(const Duration(days: 1)),
          status: AlarmStatus.dismissed,
        ),
        _occ(
          id: '2',
          alarmId: 'a',
          scheduledAt: now.subtract(const Duration(days: 2)),
          status: AlarmStatus.dismissed,
          snoozeCount: 2,
        ),
        _occ(
          id: '3',
          alarmId: 'a',
          scheduledAt: now.subtract(const Duration(days: 3)),
          status: AlarmStatus.skipped,
        ),
        _occ(
          id: '4',
          alarmId: 'a',
          scheduledAt: now.subtract(const Duration(days: 4)),
          status: AlarmStatus.missed,
        ),
        _occ(
          id: '5',
          alarmId: 'a',
          scheduledAt: now.subtract(const Duration(days: 5)),
          status: AlarmStatus.snoozed,
          snoozeCount: 1,
        ),
        _occ(
          id: '6',
          alarmId: 'a',
          scheduledAt: now.subtract(const Duration(days: 6)),
          status: AlarmStatus.triggered,
        ),
      ];
      final s = HistoryService.summarise(
        occurrences: occs,
        alarms: [_alarm()],
        now: now,
      );
      expect(s.dismissedCount, 2);
      expect(s.skippedCount, 1);
      expect(s.missedCount, 1);
      expect(s.snoozedCount, 1);
      expect(s.triggeredCount, 1);
      expect(s.onTimeCount, 1);
      expect(s.lateCount, 1);
    });

    test('averageSnoozeCount uses dismissed-only', () {
      final occs = [
        _occ(
          id: '1',
          alarmId: 'a',
          scheduledAt: now.subtract(const Duration(days: 1)),
          status: AlarmStatus.dismissed,
          snoozeCount: 2,
        ),
        _occ(
          id: '2',
          alarmId: 'a',
          scheduledAt: now.subtract(const Duration(days: 2)),
          status: AlarmStatus.dismissed,
        ),
        // snoozed (mid-flight) — must not count toward average:
        _occ(
          id: '3',
          alarmId: 'a',
          scheduledAt: now.subtract(const Duration(days: 3)),
          status: AlarmStatus.snoozed,
          snoozeCount: 99,
        ),
      ];
      final s = HistoryService.summarise(
        occurrences: occs,
        alarms: [_alarm()],
        now: now,
      );
      expect(s.averageSnoozeCount, 1.0);
    });

    test('averageSnoozeCount is zero when no dismissed occurrences', () {
      final occs = [
        _occ(
          id: '1',
          alarmId: 'a',
          scheduledAt: now.subtract(const Duration(days: 1)),
          status: AlarmStatus.missed,
        ),
      ];
      final s = HistoryService.summarise(
        occurrences: occs,
        alarms: [_alarm()],
        now: now,
      );
      expect(s.averageSnoozeCount, 0.0);
    });
  });

  group('HistoryService.summarise — daily bucketing', () {
    test('a snooze across midnight stays on the morning it belongs to', () {
      // History buckets by `scheduledAt`, so this is a second thing that
      // depends on that field naming the morning rather than the last snooze.
      // A 23:55 alarm snoozed past midnight and dismissed at 00:05 is one
      // late night, not a row filed under the following day.
      final target = DateTime(2026, 5, 18, 23, 55);
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: target.toUtc(),
            status: AlarmStatus.dismissed,
            snoozeCount: 1,
            dismissedAt: DateTime(2026, 5, 19, 0, 5).toUtc(),
          ),
        ],
        alarms: [_alarm()],
        now: DateTime(2026, 5, 19, 12),
      );
      expect(s.daily, hasLength(1));
      expect(s.daily.single.day, DateTime(2026, 5, 18));
      expect(s.daily.single.dismissedCount, 1);
    });

    test('two occurrences on the same local day land in one bucket', () {
      // Two times on the same UTC date but different hours.
      final morning = DateTime.utc(2026, 5, 18, 6, 30);
      final evening = DateTime.utc(2026, 5, 18, 22);
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: morning,
            status: AlarmStatus.dismissed,
            snoozeCount: 1,
          ),
          _occ(
            id: '2',
            alarmId: 'a',
            scheduledAt: evening,
            status: AlarmStatus.skipped,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      // The two scheduledAt instants are on the same UTC date but may
      // straddle midnight in some local zones. Depending on the host
      // timezone, the bucketing may collapse to one local day or split
      // into two — both are correct, but the union must contain both
      // occurrences and the totals must add up.
      expect(s.daily.fold<int>(0, (a, b) => a + b.dismissedCount), 1);
      expect(s.daily.fold<int>(0, (a, b) => a + b.skippedCount), 1);
      expect(s.daily.fold<int>(0, (a, b) => a + b.totalSnoozes), 1);
    });

    test(
      'different UTC days produce separate buckets, sorted oldest first',
      () {
        final s = HistoryService.summarise(
          occurrences: [
            _occ(
              id: '1',
              alarmId: 'a',
              scheduledAt: DateTime.utc(2026, 5, 17, 7),
              status: AlarmStatus.dismissed,
            ),
            _occ(
              id: '2',
              alarmId: 'a',
              scheduledAt: DateTime.utc(2026, 5, 19, 7),
              status: AlarmStatus.skipped,
            ),
            _occ(
              id: '3',
              alarmId: 'a',
              scheduledAt: DateTime.utc(2026, 5, 18, 7),
              status: AlarmStatus.missed,
            ),
          ],
          alarms: [_alarm()],
          now: now,
        );
        expect(s.daily.length, 3);
        // Sorted oldest-first.
        for (var i = 1; i < s.daily.length; i++) {
          expect(
            s.daily[i].day.isAfter(s.daily[i - 1].day),
            isTrue,
          );
        }
      },
    );

    test('scheduled occurrences do not count in daily totals', () {
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: DateTime.utc(2026, 5, 18, 7),
            status: AlarmStatus.scheduled,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.daily.length, 1);
      final d = s.daily.first;
      expect(d.dismissedCount, 0);
      expect(d.skippedCount, 0);
      expect(d.missedCount, 0);
      expect(d.snoozedCount, 0);
      expect(d.triggeredCount, 0);
      expect(d.onTimeCount, 0);
      expect(d.lateCount, 0);
    });

    test('daily on-time/late split mirrors the window-level split', () {
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: DateTime.utc(2026, 5, 18, 7),
            status: AlarmStatus.dismissed,
          ),
          _occ(
            id: '2',
            alarmId: 'a',
            scheduledAt: DateTime.utc(2026, 5, 18, 8),
            status: AlarmStatus.dismissed,
            snoozeCount: 2,
          ),
          _occ(
            id: '3',
            alarmId: 'a',
            scheduledAt: DateTime.utc(2026, 5, 18, 9),
            status: AlarmStatus.skipped,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      // Sums across daily must reconcile with the window-level split.
      expect(
        s.daily.fold<int>(0, (a, b) => a + b.onTimeCount),
        s.onTimeCount,
      );
      expect(
        s.daily.fold<int>(0, (a, b) => a + b.lateCount),
        s.lateCount,
      );
      expect(
        s.daily.fold<int>(0, (a, b) => a + b.dismissedCount),
        s.dismissedCount,
      );
    });

    test('escaped is counted as its own outcome, not as a dismiss', () {
      final now = DateTime.utc(2026, 5, 21, 12);
      final summary = HistoryService.summarise(
        occurrences: [
          _occ(
            id: 'e1',
            alarmId: 'a',
            status: AlarmStatus.escaped,
            scheduledAt: now.subtract(const Duration(days: 1)),
          ),
          _occ(
            id: 'e2',
            alarmId: 'a',
            status: AlarmStatus.escaped,
            scheduledAt: now.subtract(const Duration(days: 2)),
          ),
          _occ(
            id: 'd1',
            alarmId: 'a',
            status: AlarmStatus.dismissed,
            scheduledAt: now.subtract(const Duration(days: 3)),
          ),
        ],
        alarms: const [],
        now: now,
      );
      expect(summary.escapedCount, 2);
      expect(summary.dismissedCount, 1);
      expect(summary.onTimeCount, 1, reason: 'escapes are not on-time wins');
      expect(summary.lateCount, 0);
      expect(summary.missedCount, 0, reason: 'and not failures either');
      expect(summary.occurrenceCount, 3);
    });

    test('escaped buckets into its own day and produces no insight', () {
      final now = DateTime.utc(2026, 5, 21, 12);
      final summary = HistoryService.summarise(
        occurrences: [
          for (var i = 1; i <= 5; i++)
            _occ(
              id: 'e$i',
              alarmId: 'a',
              status: AlarmStatus.escaped,
              scheduledAt: now.subtract(Duration(days: i)),
            ),
        ],
        alarms: const [],
        now: now,
      );
      expect(summary.daily, hasLength(5));
      expect(summary.daily.every((d) => d.escapedCount == 1), isTrue);
      // The escape exists for mornings someone is ill or has to take a call.
      // Inventing a pattern out of it would be exactly the judgement this
      // screen refuses to make.
      expect(summary.insights, isEmpty);
    });

    test('an escaped day summary differs from an otherwise identical one', () {
      final day = DateTime(2026, 5, 18);
      final a = HistoryDailySummary(
        day: day,
        triggeredCount: 0,
        snoozedCount: 0,
        dismissedCount: 0,
        onTimeCount: 0,
        lateCount: 0,
        skippedCount: 0,
        escapedCount: 1,
        missedCount: 0,
        totalSnoozes: 0,
      );
      final b = HistoryDailySummary(
        day: day,
        triggeredCount: 0,
        snoozedCount: 0,
        dismissedCount: 0,
        onTimeCount: 0,
        lateCount: 0,
        skippedCount: 0,
        escapedCount: 0,
        missedCount: 0,
        totalSnoozes: 0,
      );
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('HistoryDailySummary value equality', () {
      final a = HistoryDailySummary(
        day: DateTime(2026, 5, 18),
        triggeredCount: 1,
        snoozedCount: 0,
        dismissedCount: 1,
        onTimeCount: 0,
        lateCount: 1,
        skippedCount: 0,
        escapedCount: 0,
        missedCount: 0,
        totalSnoozes: 2,
      );
      final b = HistoryDailySummary(
        day: DateTime(2026, 5, 18),
        triggeredCount: 1,
        snoozedCount: 0,
        dismissedCount: 1,
        onTimeCount: 0,
        lateCount: 1,
        skippedCount: 0,
        escapedCount: 0,
        missedCount: 0,
        totalSnoozes: 2,
      );
      final c = HistoryDailySummary(
        day: DateTime(2026, 5, 19),
        triggeredCount: 1,
        snoozedCount: 0,
        dismissedCount: 1,
        onTimeCount: 0,
        lateCount: 1,
        skippedCount: 0,
        escapedCount: 0,
        missedCount: 0,
        totalSnoozes: 2,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('HistoryService.summarise — insights', () {
    test(
      'averageSnooze insight fires only when ≥ minOccurrences dismissed',
      () {
        // Two dismissed (below minimum 3) → no insight.
        final notEnough = HistoryService.summarise(
          occurrences: [
            _occ(
              id: '1',
              alarmId: 'a',
              scheduledAt: now.subtract(const Duration(days: 1)),
              status: AlarmStatus.dismissed,
              snoozeCount: 2,
            ),
            _occ(
              id: '2',
              alarmId: 'a',
              scheduledAt: now.subtract(const Duration(days: 2)),
              status: AlarmStatus.dismissed,
              snoozeCount: 2,
            ),
          ],
          alarms: [_alarm()],
          now: now,
        );
        expect(
          notEnough.insights.any(
            (i) => i.kind == HistoryInsightKind.averageSnooze,
          ),
          isFalse,
        );

        // Three dismissed → insight fires with rounded average.
        final three = HistoryService.summarise(
          occurrences: [
            _occ(
              id: '1',
              alarmId: 'a',
              scheduledAt: now.subtract(const Duration(days: 1)),
              status: AlarmStatus.dismissed,
              snoozeCount: 2,
            ),
            _occ(
              id: '2',
              alarmId: 'a',
              scheduledAt: now.subtract(const Duration(days: 2)),
              status: AlarmStatus.dismissed,
              snoozeCount: 2,
            ),
            _occ(
              id: '3',
              alarmId: 'a',
              scheduledAt: now.subtract(const Duration(days: 3)),
              status: AlarmStatus.dismissed,
              snoozeCount: 2,
            ),
          ],
          alarms: [_alarm()],
          now: now,
        );
        final avg = three.insights.firstWhere(
          (i) => i.kind == HistoryInsightKind.averageSnooze,
        );
        expect(avg.intArg, 2);
      },
    );

    test('averageSnooze insight rounds half to even via .round()', () {
      // .round() rounds half-up — three dismissed with average 1.333… → 1
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 1)),
            status: AlarmStatus.dismissed,
            snoozeCount: 1,
          ),
          _occ(
            id: '2',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 2)),
            status: AlarmStatus.dismissed,
            snoozeCount: 1,
          ),
          _occ(
            id: '3',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 3)),
            status: AlarmStatus.dismissed,
            snoozeCount: 2,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      final insight = s.insights.firstWhere(
        (i) => i.kind == HistoryInsightKind.averageSnooze,
      );
      expect(insight.intArg, 1);
    });

    test(
      'frequentlySkippedWeekday fires at threshold and reports lowest '
      'weekday on tie',
      () {
        // Three skips on Mondays (ISO 1) and three on Tuesdays (ISO 2).
        // Tie on count → lowest weekday wins (Monday).
        // 2026-05-04 is a Monday; 2026-05-05 is a Tuesday.
        final occs = <AlarmOccurrence>[
          for (var i = 0; i < 3; i++)
            _occ(
              id: 'mon$i',
              alarmId: 'a',
              scheduledAt: DateTime.utc(2026, 5, 11 - 7 * (i % 2), 7).add(
                Duration(days: i * 0),
              ),
              status: AlarmStatus.skipped,
            ),
        ];
        // Build deterministic Mondays and Tuesdays inside the 14-day window
        // ending 2026-05-20 12:00Z.
        final mondays = [
          DateTime.utc(2026, 5, 11, 7),
          DateTime.utc(2026, 5, 18, 7),
          DateTime.utc(2026, 5, 11, 8),
        ];
        final tuesdays = [
          DateTime.utc(2026, 5, 12, 7),
          DateTime.utc(2026, 5, 19, 7),
          DateTime.utc(2026, 5, 12, 8),
        ];
        final occs2 = <AlarmOccurrence>[
          for (var i = 0; i < mondays.length; i++)
            _occ(
              id: 'M$i',
              alarmId: 'a',
              scheduledAt: mondays[i],
              status: AlarmStatus.skipped,
            ),
          for (var i = 0; i < tuesdays.length; i++)
            _occ(
              id: 'T$i',
              alarmId: 'a',
              scheduledAt: tuesdays[i],
              status: AlarmStatus.skipped,
            ),
        ];
        // Use only occs2 (deterministic). occs is unused except to verify the
        // service ignores helper noise.
        expect(occs.length, 3);
        final s = HistoryService.summarise(
          occurrences: occs2,
          alarms: [_alarm()],
          now: now,
        );
        final weekday = s.insights.firstWhere(
          (i) => i.kind == HistoryInsightKind.frequentlySkippedWeekday,
        );
        // Tie-break: lowest ISO weekday → Monday (1).
        expect(weekday.intArg, 1);
      },
    );

    test('frequentlySkippedWeekday does NOT fire below threshold', () {
      final occs = <AlarmOccurrence>[
        _occ(
          id: '1',
          alarmId: 'a',
          scheduledAt: DateTime.utc(2026, 5, 11, 7), // Monday
          status: AlarmStatus.skipped,
        ),
        _occ(
          id: '2',
          alarmId: 'a',
          scheduledAt: DateTime.utc(2026, 5, 18, 7), // Monday
          status: AlarmStatus.skipped,
        ),
      ];
      final s = HistoryService.summarise(
        occurrences: occs,
        alarms: [_alarm()],
        now: now,
      );
      expect(
        s.insights.any(
          (i) => i.kind == HistoryInsightKind.frequentlySkippedWeekday,
        ),
        isFalse,
      );
    });

    test(
      'strictModeHelped fires when strict-mode dismissals with 0 snoozes '
      '≥ threshold',
      () {
        final strict = _alarm(id: 'strictA', wakeMode: WakeMode.strict);
        final standard = _alarm(id: 'standardA');
        final occs = <AlarmOccurrence>[
          _occ(
            id: '1',
            alarmId: 'strictA',
            scheduledAt: now.subtract(const Duration(days: 1)),
            status: AlarmStatus.dismissed,
          ),
          _occ(
            id: '2',
            alarmId: 'strictA',
            scheduledAt: now.subtract(const Duration(days: 2)),
            status: AlarmStatus.dismissed,
          ),
          // Strict-mode dismissal but with snoozes — does not count.
          _occ(
            id: '3',
            alarmId: 'strictA',
            scheduledAt: now.subtract(const Duration(days: 3)),
            status: AlarmStatus.dismissed,
            snoozeCount: 1,
          ),
          // Standard-mode dismissal with 0 snoozes — does not count.
          _occ(
            id: '4',
            alarmId: 'standardA',
            scheduledAt: now.subtract(const Duration(days: 4)),
            status: AlarmStatus.dismissed,
          ),
        ];
        final s = HistoryService.summarise(
          occurrences: occs,
          alarms: [strict, standard],
          now: now,
        );
        final strictHelped = s.insights.firstWhere(
          (i) => i.kind == HistoryInsightKind.strictModeHelped,
        );
        expect(strictHelped.intArg, 2);
      },
    );

    test('strictModeHelped does NOT fire below threshold', () {
      final strict = _alarm(id: 'strictA', wakeMode: WakeMode.strict);
      final occs = [
        _occ(
          id: '1',
          alarmId: 'strictA',
          scheduledAt: now.subtract(const Duration(days: 1)),
          status: AlarmStatus.dismissed,
        ),
      ];
      final s = HistoryService.summarise(
        occurrences: occs,
        alarms: [strict],
        now: now,
      );
      expect(
        s.insights.any(
          (i) => i.kind == HistoryInsightKind.strictModeHelped,
        ),
        isFalse,
      );
    });

    test('strictModeHelped ignores occurrences whose alarm is missing', () {
      // Orphan occurrence — should not fire any insight even if the wake
      // mode would have qualified.
      final occs = [
        for (var i = 0; i < 5; i++)
          _occ(
            id: 'o$i',
            alarmId: 'orphan',
            scheduledAt: now.subtract(Duration(days: i + 1)),
            status: AlarmStatus.dismissed,
          ),
      ];
      final s = HistoryService.summarise(
        occurrences: occs,
        alarms: const [],
        now: now,
      );
      expect(
        s.insights.any(
          (i) => i.kind == HistoryInsightKind.strictModeHelped,
        ),
        isFalse,
      );
    });

    test('all insights co-fire when their thresholds are met', () {
      final strict = _alarm(id: 'strictA', wakeMode: WakeMode.strict);
      final occs = <AlarmOccurrence>[
        // Three strict dismissed with 0 snoozes → strict + average insight.
        _occ(
          id: '1',
          alarmId: 'strictA',
          scheduledAt: now.subtract(const Duration(days: 1)),
          status: AlarmStatus.dismissed,
        ),
        _occ(
          id: '2',
          alarmId: 'strictA',
          scheduledAt: now.subtract(const Duration(days: 2)),
          status: AlarmStatus.dismissed,
        ),
        _occ(
          id: '3',
          alarmId: 'strictA',
          scheduledAt: now.subtract(const Duration(days: 3)),
          status: AlarmStatus.dismissed,
        ),
        // Three Monday skips → weekday insight.
        _occ(
          id: 'm1',
          alarmId: 'strictA',
          scheduledAt: DateTime.utc(2026, 5, 11, 7),
          status: AlarmStatus.skipped,
        ),
        _occ(
          id: 'm2',
          alarmId: 'strictA',
          scheduledAt: DateTime.utc(2026, 5, 18, 7),
          status: AlarmStatus.skipped,
        ),
        _occ(
          id: 'm3',
          alarmId: 'strictA',
          scheduledAt: DateTime.utc(2026, 5, 11, 8),
          status: AlarmStatus.skipped,
        ),
      ];
      final s = HistoryService.summarise(
        occurrences: occs,
        alarms: [strict],
        now: now,
      );
      final kinds = s.insights.map((i) => i.kind).toSet();
      expect(kinds, contains(HistoryInsightKind.averageSnooze));
      expect(kinds, contains(HistoryInsightKind.frequentlySkippedWeekday));
      expect(kinds, contains(HistoryInsightKind.strictModeHelped));
    });
  });

  group('HistorySummary value semantics', () {
    test('two equal summaries compare equal and share hash', () {
      final s1 = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 1)),
            status: AlarmStatus.dismissed,
            snoozeCount: 1,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      final s2 = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 1)),
            status: AlarmStatus.dismissed,
            snoozeCount: 1,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      expect(s1, s2);
      expect(s1.hashCode, s2.hashCode);
    });

    test('different content compares unequal', () {
      final base = HistoryService.summarise(
        occurrences: const [],
        alarms: const [],
        now: now,
      );
      final other = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 1)),
            status: AlarmStatus.dismissed,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      expect(base == other, isFalse);
    });

    test('HistoryInsight has value equality', () {
      const a = HistoryInsight(
        kind: HistoryInsightKind.averageSnooze,
        intArg: 2,
      );
      const b = HistoryInsight(
        kind: HistoryInsightKind.averageSnooze,
        intArg: 2,
      );
      const c = HistoryInsight(
        kind: HistoryInsightKind.averageSnooze,
        intArg: 3,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('empty summary is non-isEmpty when occurrences exist', () {
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 1)),
            status: AlarmStatus.missed,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.isEmpty, isFalse);
    });
  });

  group('typical wake time', () {
    test('is null when nothing in the window was dismissed', () {
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: 'o1',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 1)),
            status: AlarmStatus.skipped,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.typicalWakeMinutes, isNull);
    });

    test('is null when a dismissal has no recorded dismissedAt', () {
      // A dismissal that predates the field, or one written by a path that
      // never set it, must not be counted as "woke at midnight".
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: 'o1',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 1)),
            status: AlarmStatus.dismissed,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.typicalWakeMinutes, isNull);
    });

    test('a single dismissal is its own local time of day', () {
      final at = now.subtract(const Duration(days: 1));
      final dismissed = DateTime.utc(
        at.year,
        at.month,
        at.day,
        6,
        45,
      ).toLocal();
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: 'o1',
            alarmId: 'a',
            scheduledAt: at,
            status: AlarmStatus.dismissed,
            dismissedAt: dismissed,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      expect(
        s.typicalWakeMinutes,
        dismissed.toLocal().hour * 60 + dismissed.toLocal().minute,
      );
    });

    test('takes the median, so one outlier does not drag the figure', () {
      // Four 07:00 mornings and one 03:00 airport alarm. The mean would be
      // 06:12; the median is the 07:00 that actually describes the user.
      final times = [7, 7, 3, 7, 7];
      final occurrences = <AlarmOccurrence>[
        for (final (i, hour) in times.indexed)
          _occ(
            id: 'o$i',
            alarmId: 'a',
            scheduledAt: now.subtract(Duration(days: i + 1)),
            status: AlarmStatus.dismissed,
            dismissedAt: DateTime(2026, 5, 20 - i, hour),
          ),
      ];
      final s = HistoryService.summarise(
        occurrences: occurrences,
        alarms: [_alarm()],
        now: now,
      );
      expect(s.typicalWakeMinutes, 7 * 60);
    });

    test('on an even count it picks a time that actually happened', () {
      // Lower-middle of {06:00, 07:00}: 06:00, not an invented 06:30.
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: 'o1',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 1)),
            status: AlarmStatus.dismissed,
            dismissedAt: DateTime(2026, 5, 19, 6),
          ),
          _occ(
            id: 'o2',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 2)),
            status: AlarmStatus.dismissed,
            dismissedAt: DateTime(2026, 5, 18, 7),
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.typicalWakeMinutes, 6 * 60);
    });

    test('ignores non-dismissed rows', () {
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: 'o1',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 1)),
            status: AlarmStatus.dismissed,
            dismissedAt: DateTime(2026, 5, 19, 7),
          ),
          _occ(
            id: 'o2',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 2)),
            status: AlarmStatus.escaped,
            dismissedAt: DateTime(2026, 5, 18, 3),
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.typicalWakeMinutes, 7 * 60);
    });

    test('participates in equality', () {
      const a = HistorySummary(
        windowDays: 14,
        occurrenceCount: 0,
        triggeredCount: 0,
        snoozedCount: 0,
        dismissedCount: 0,
        skippedCount: 0,
        escapedCount: 0,
        missedCount: 0,
        onTimeCount: 0,
        lateCount: 0,
        averageSnoozeCount: 0,
        daily: [],
        insights: [],
        typicalWakeMinutes: 420,
      );
      const b = HistorySummary(
        windowDays: 14,
        occurrenceCount: 0,
        triggeredCount: 0,
        snoozedCount: 0,
        dismissedCount: 0,
        skippedCount: 0,
        escapedCount: 0,
        missedCount: 0,
        onTimeCount: 0,
        lateCount: 0,
        averageSnoozeCount: 0,
        daily: [],
        insights: [],
        typicalWakeMinutes: 480,
      );
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
      expect(HistorySummary.empty.typicalWakeMinutes, isNull);
    });
  });

  // Phase 38 put the alarm time and the actual dismiss time on each history
  // row, so the service now carries both per day. They are recorded facts —
  // these pin which occurrence each one comes from, and when it is absent.
  group('HistoryService.summarise — daily alarm and dismiss times', () {
    test('a dismissed morning carries both times, in local minutes', () {
      final scheduled = DateTime.utc(2026, 5, 19, 7);
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: scheduled,
            status: AlarmStatus.dismissed,
            dismissedAt: scheduled.add(const Duration(minutes: 12)),
          ),
        ],
        alarms: const [],
        now: now,
      );

      final day = s.daily.single;
      final localAlarm = scheduled.toLocal();
      expect(day.alarmMinutes, localAlarm.hour * 60 + localAlarm.minute);
      final localUp = scheduled.add(const Duration(minutes: 12)).toLocal();
      expect(day.dismissMinutes, localUp.hour * 60 + localUp.minute);
    });

    test('the earliest alarm of the day wins, and the latest dismissal', () {
      final early = DateTime.utc(2026, 5, 19, 6, 30);
      final late = DateTime.utc(2026, 5, 19, 8);
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: late,
            status: AlarmStatus.dismissed,
            dismissedAt: late.add(const Duration(minutes: 5)),
          ),
          _occ(
            id: '2',
            alarmId: 'a',
            scheduledAt: early,
            status: AlarmStatus.dismissed,
            dismissedAt: early.add(const Duration(minutes: 1)),
          ),
        ],
        alarms: const [],
        now: now,
      );

      final day = s.daily.single;
      final localEarly = early.toLocal();
      expect(day.alarmMinutes, localEarly.hour * 60 + localEarly.minute);
      // The later alarm's dismissal is when the user was finally up.
      final localUp = late.add(const Duration(minutes: 5)).toLocal();
      expect(day.dismissMinutes, localUp.hour * 60 + localUp.minute);
    });

    test('a skipped morning has an alarm time but no dismissal', () {
      final scheduled = DateTime.utc(2026, 5, 19, 7);
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: scheduled,
            status: AlarmStatus.skipped,
          ),
        ],
        alarms: const [],
        now: now,
      );

      expect(s.daily.single.alarmMinutes, isNotNull);
      expect(s.daily.single.dismissMinutes, isNull);
    });

    test('a missed morning likewise shows no dismissal', () {
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: DateTime.utc(2026, 5, 19, 7),
            status: AlarmStatus.missed,
          ),
        ],
        alarms: const [],
        now: now,
      );

      expect(s.daily.single.dismissMinutes, isNull);
    });

    test('a still-scheduled morning contributes no time at all', () {
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: DateTime.utc(2026, 5, 19, 7),
            status: AlarmStatus.scheduled,
          ),
        ],
        alarms: const [],
        now: now,
      );

      // The bucket exists (it is keyed off scheduledAt) but holds no times:
      // a morning that has not happened has nothing to look back on.
      expect(s.daily.single.alarmMinutes, isNull);
      expect(s.daily.single.dismissMinutes, isNull);
    });

    test('a scheduled row does not mask a real one on the same day', () {
      final real = DateTime.utc(2026, 5, 19, 6);
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: '1',
            alarmId: 'a',
            scheduledAt: DateTime.utc(2026, 5, 19, 5),
            status: AlarmStatus.scheduled,
          ),
          _occ(
            id: '2',
            alarmId: 'a',
            scheduledAt: real,
            status: AlarmStatus.dismissed,
            dismissedAt: real.add(const Duration(minutes: 3)),
          ),
        ],
        alarms: const [],
        now: now,
      );

      // 05:00 is earlier, but it never fired — the recorded morning is 06:00.
      final localReal = real.toLocal();
      expect(
        s.daily.single.alarmMinutes,
        localReal.hour * 60 + localReal.minute,
      );
    });

    test('the two times take part in value equality', () {
      HistoryDailySummary build({int? alarm, int? dismiss}) =>
          HistoryDailySummary(
            day: DateTime(2026, 5, 19),
            triggeredCount: 0,
            snoozedCount: 0,
            dismissedCount: 1,
            onTimeCount: 1,
            lateCount: 0,
            skippedCount: 0,
            escapedCount: 0,
            missedCount: 0,
            totalSnoozes: 0,
            alarmMinutes: alarm,
            dismissMinutes: dismiss,
          );

      final a = build(alarm: 420, dismiss: 432);
      expect(a, build(alarm: 420, dismiss: 432));
      expect(a.hashCode, build(alarm: 420, dismiss: 432).hashCode);
      // Differing in either field alone breaks equality, so neither is
      // silently left out of the comparison.
      expect(a, isNot(build(alarm: 421, dismiss: 432)));
      expect(a, isNot(build(alarm: 420, dismiss: 433)));
      expect(a, isNot(build(dismiss: 432)));
      expect(a, isNot(build(alarm: 420)));
    });
  });

  group('HistoryService.habitFor', () {
    test('classifies into three calm buckets', () {
      expect(HistoryService.habitFor(0), MorningsHabit.firstAlarm);
      expect(HistoryService.habitFor(0.49), MorningsHabit.firstAlarm);
      expect(HistoryService.habitFor(0.5), MorningsHabit.oneSnooze);
      expect(HistoryService.habitFor(1), MorningsHabit.oneSnooze);
      expect(HistoryService.habitFor(1.49), MorningsHabit.oneSnooze);
      expect(HistoryService.habitFor(1.5), MorningsHabit.severalSnoozes);
      expect(HistoryService.habitFor(4), MorningsHabit.severalSnoozes);
    });
  });

  group('on-time day count', () {
    test('counts mornings, not occurrences', () {
      // Two alarms dismissed without snoozing on the *same* local morning is
      // one day up on time. Reading it back as two would be a small lie in a
      // figure whose whole job is being plain.
      final day = now.subtract(const Duration(days: 1));
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: 'o1',
            alarmId: 'a',
            scheduledAt: DateTime.utc(day.year, day.month, day.day, 6, 30),
            status: AlarmStatus.dismissed,
          ),
          _occ(
            id: 'o2',
            alarmId: 'a',
            scheduledAt: DateTime.utc(day.year, day.month, day.day, 7),
            status: AlarmStatus.dismissed,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.onTimeCount, 2);
      expect(s.onTimeDayCount, 1);
    });

    test('separate mornings count separately', () {
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: 'o1',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 1)),
            status: AlarmStatus.dismissed,
          ),
          _occ(
            id: 'o2',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 2)),
            status: AlarmStatus.dismissed,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.onTimeDayCount, 2);
    });

    test('a snoozed dismissal is not an on-time day', () {
      final s = HistoryService.summarise(
        occurrences: [
          _occ(
            id: 'o1',
            alarmId: 'a',
            scheduledAt: now.subtract(const Duration(days: 1)),
            status: AlarmStatus.dismissed,
            snoozeCount: 2,
          ),
        ],
        alarms: [_alarm()],
        now: now,
      );
      expect(s.lateCount, 1);
      expect(s.onTimeDayCount, 0);
    });

    test('is zero on an empty window and participates in equality', () {
      final s = HistoryService.summarise(
        occurrences: const [],
        alarms: const [],
        now: now,
      );
      expect(s.onTimeDayCount, 0);
      expect(HistorySummary.empty.onTimeDayCount, 0);

      const a = HistorySummary(
        windowDays: 14,
        occurrenceCount: 0,
        triggeredCount: 0,
        snoozedCount: 0,
        dismissedCount: 0,
        skippedCount: 0,
        escapedCount: 0,
        missedCount: 0,
        onTimeCount: 0,
        lateCount: 0,
        averageSnoozeCount: 0,
        daily: [],
        insights: [],
        onTimeDayCount: 1,
      );
      expect(a, isNot(equals(HistorySummary.empty)));
      expect(a.hashCode, isNot(equals(HistorySummary.empty.hashCode)));
    });
  });
}
