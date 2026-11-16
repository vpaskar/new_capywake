import 'package:capywake/core/lifecycle/snooze_service.dart';
import 'package:capywake/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Alarm _alarm({
  bool snoozeEnabled = true,
  int snoozeDurationMinutes = 9,
  int? maxSnoozes = 3,
  WakeMode wakeMode = WakeMode.standard,
}) {
  return Alarm(
    id: 'a1',
    label: 'Workdays',
    enabled: true,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const {1, 2, 3, 4, 5},
    wakeMode: wakeMode,
    wakeWindowStartMinutesBefore: 15,
    soundId: 'sand',
    vibrationEnabled: true,
    snoozeEnabled: snoozeEnabled,
    snoozeDurationMinutes: snoozeDurationMinutes,
    maxSnoozes: maxSnoozes,
    dismissMethod: DismissMethod.normalButton,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: DateTime.utc(2026, 5, 21, 8),
    updatedAt: DateTime.utc(2026, 5, 21, 8),
  );
}

AlarmOccurrence _occurrence({
  int snoozeCount = 0,
  AlarmStatus status = AlarmStatus.triggered,
}) {
  return AlarmOccurrence(
    id: 'o1',
    alarmId: 'a1',
    scheduledAt: DateTime.utc(2026, 5, 21, 7),
    softStartAt: DateTime.utc(2026, 5, 21, 6, 45),
    status: status,
    triggeredAt: DateTime.utc(2026, 5, 21, 7),
    dismissedAt: null,
    snoozeCount: snoozeCount,
    note: '',
  );
}

void main() {
  group('SnoozeService.canSnooze', () {
    const service = SnoozeService();

    test('returns false when snooze is disabled', () {
      expect(
        service.canSnooze(
          alarm: _alarm(snoozeEnabled: false),
          occurrence: _occurrence(),
        ),
        isFalse,
      );
    });

    test('returns true while count is below the cap', () {
      expect(
        service.canSnooze(
          alarm: _alarm(),
          occurrence: _occurrence(snoozeCount: 2),
        ),
        isTrue,
      );
    });

    test('returns false when the cap is reached', () {
      expect(
        service.canSnooze(
          alarm: _alarm(),
          occurrence: _occurrence(snoozeCount: 3),
        ),
        isFalse,
      );
    });

    test('returns true forever when cap is null (unlimited)', () {
      expect(
        service.canSnooze(
          alarm: _alarm(maxSnoozes: null),
          occurrence: _occurrence(snoozeCount: 99),
        ),
        isTrue,
      );
    });
  });

  group('SnoozeService.isFinalAlarm', () {
    const service = SnoozeService();

    test('is true on the ring that reaches the cap', () {
      expect(
        service.isFinalAlarm(
          alarm: _alarm(),
          occurrence: _occurrence(snoozeCount: 3),
        ),
        isTrue,
      );
    });

    test('stays true past the cap', () {
      // Defensive: a row should never exceed its cap, but if one does the
      // ring is still the last one rather than silently ordinary.
      expect(
        service.isFinalAlarm(
          alarm: _alarm(),
          occurrence: _occurrence(snoozeCount: 4),
        ),
        isTrue,
      );
    });

    test('is false below the cap', () {
      expect(
        service.isFinalAlarm(
          alarm: _alarm(),
          occurrence: _occurrence(snoozeCount: 2),
        ),
        isFalse,
      );
    });

    test('is false on the first ring', () {
      expect(
        service.isFinalAlarm(
          alarm: _alarm(),
          occurrence: _occurrence(),
        ),
        isFalse,
      );
    });

    test('is false when snooze is disabled, even at a nominal cap', () {
      // The divergence from `canSnooze`, and the reason this method
      // exists. Both refuse a snooze here; only one of them is a ring
      // that ran out of snoozes.
      final alarm = _alarm(snoozeEnabled: false);
      final occurrence = _occurrence(snoozeCount: 3);
      expect(service.canSnooze(alarm: alarm, occurrence: occurrence), isFalse);
      expect(
        service.isFinalAlarm(alarm: alarm, occurrence: occurrence),
        isFalse,
      );
    });

    test('is false for an uncapped alarm however many snoozes are spent', () {
      expect(
        service.isFinalAlarm(
          alarm: _alarm(maxSnoozes: null),
          occurrence: _occurrence(snoozeCount: 99),
        ),
        isFalse,
      );
    });

    test('agrees with the outcome flag the snooze that produced it set', () {
      // The two must not drift: the snooze step that reports
      // `isFinalAlarm` is exactly the one whose resulting occurrence this
      // method calls final.
      final alarm = _alarm(maxSnoozes: 2);
      final result = service.snooze(
        alarm: alarm,
        occurrence: _occurrence(snoozeCount: 1),
        now: DateTime.utc(2026, 5, 21, 7),
      );
      expect(result.outcome!.isFinalAlarm, isTrue);
      expect(
        service.isFinalAlarm(
          alarm: alarm,
          occurrence: _occurrence(snoozeCount: result.outcome!.snoozeCount),
        ),
        isTrue,
      );
    });
  });

  group('SnoozeService.snooze', () {
    const service = SnoozeService();
    final now = DateTime.utc(2026, 5, 21, 7);

    test('first snooze returns base duration and increments count', () {
      final result = service.snooze(
        alarm: _alarm(),
        occurrence: _occurrence(),
        now: now,
      );
      expect(result.deniedReason, isNull);
      expect(result.outcome, isNotNull);
      expect(result.outcome!.snoozeCount, 1);
      expect(result.outcome!.snoozeDurationMinutes, 9);
      expect(
        result.outcome!.nextRingAt,
        DateTime.utc(2026, 5, 21, 7, 9),
      );
      expect(result.outcome!.isFinalAlarm, isFalse);
    });

    test('snooze hitting the cap marks isFinalAlarm true', () {
      final result = service.snooze(
        alarm: _alarm(),
        occurrence: _occurrence(snoozeCount: 2),
        now: now,
      );
      expect(result.outcome!.snoozeCount, 3);
      expect(result.outcome!.isFinalAlarm, isTrue);
    });

    test('snooze beyond the cap is denied', () {
      final result = service.snooze(
        alarm: _alarm(),
        occurrence: _occurrence(snoozeCount: 3),
        now: now,
      );
      expect(result.outcome, isNull);
      expect(result.deniedReason, SnoozeDeniedReason.capReached);
    });

    test('snooze when disabled returns snoozeDisabled', () {
      final result = service.snooze(
        alarm: _alarm(snoozeEnabled: false),
        occurrence: _occurrence(),
        now: now,
      );
      expect(result.outcome, isNull);
      expect(result.deniedReason, SnoozeDeniedReason.snoozeDisabled);
    });

    test('unlimited snooze never sets isFinalAlarm', () {
      final result = service.snooze(
        alarm: _alarm(maxSnoozes: null),
        occurrence: _occurrence(snoozeCount: 99),
        now: now,
      );
      expect(result.outcome!.isFinalAlarm, isFalse);
    });

    test('strict-mode shrinking shaves a minute per additional snooze', () {
      final alarm = _alarm(
        wakeMode: WakeMode.strict,
        maxSnoozes: null,
      );
      final s1 = service.snooze(
        alarm: alarm,
        occurrence: _occurrence(),
        now: now,
      );
      final s2 = service.snooze(
        alarm: alarm,
        occurrence: _occurrence(snoozeCount: 1),
        now: now,
      );
      final s3 = service.snooze(
        alarm: alarm,
        occurrence: _occurrence(snoozeCount: 2),
        now: now,
      );
      expect(s1.outcome!.snoozeDurationMinutes, 9);
      expect(s2.outcome!.snoozeDurationMinutes, 8);
      expect(s3.outcome!.snoozeDurationMinutes, 7);
    });

    test('strict-mode shrinking floors at 1 minute', () {
      final alarm = _alarm(
        wakeMode: WakeMode.strict,
        snoozeDurationMinutes: 3,
        maxSnoozes: null,
      );
      final result = service.snooze(
        alarm: alarm,
        occurrence: _occurrence(snoozeCount: 20),
        now: now,
      );
      expect(result.outcome!.snoozeDurationMinutes, 1);
    });

    test('gentle mode does not shrink', () {
      final alarm = _alarm(
        wakeMode: WakeMode.gentle,
        maxSnoozes: null,
      );
      final result = service.snooze(
        alarm: alarm,
        occurrence: _occurrence(snoozeCount: 5),
        now: now,
      );
      expect(result.outcome!.snoozeDurationMinutes, 9);
    });

    test('snooze converts non-UTC now to UTC', () {
      final local = DateTime(2026, 5, 21, 9);
      final result = service.snooze(
        alarm: _alarm(snoozeDurationMinutes: 5),
        occurrence: _occurrence(),
        now: local,
      );
      expect(result.outcome!.nextRingAt.isUtc, isTrue);
      expect(
        result.outcome!.nextRingAt,
        local.toUtc().add(const Duration(minutes: 5)),
      );
    });
  });

  group('SnoozeOutcome value semantics', () {
    test('two outcomes with identical fields are value-equal', () {
      final a = SnoozeOutcome(
        nextRingAt: DateTime.utc(2026, 5, 21, 7, 9),
        snoozeCount: 1,
        snoozeDurationMinutes: 9,
        isFinalAlarm: false,
      );
      final b = SnoozeOutcome(
        nextRingAt: DateTime.utc(2026, 5, 21, 7, 9),
        snoozeCount: 1,
        snoozeDurationMinutes: 9,
        isFinalAlarm: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different field values break equality', () {
      final base = SnoozeOutcome(
        nextRingAt: DateTime.utc(2026, 5, 21, 7, 9),
        snoozeCount: 1,
        snoozeDurationMinutes: 9,
        isFinalAlarm: false,
      );
      final other = SnoozeOutcome(
        nextRingAt: DateTime.utc(2026, 5, 21, 7, 9),
        snoozeCount: 2,
        snoozeDurationMinutes: 9,
        isFinalAlarm: false,
      );
      expect(base, isNot(equals(other)));
    });
  });
}
