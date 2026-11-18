import 'package:capywake/core/lifecycle/alarm_status_service.dart';
import 'package:capywake/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

AlarmOccurrence _occurrence({
  AlarmStatus status = AlarmStatus.scheduled,
  int snoozeCount = 0,
  DateTime? scheduledAt,
  DateTime? triggeredAt,
  DateTime? dismissedAt,
  DateTime? snoozedUntil,
}) {
  return AlarmOccurrence(
    id: 'o1',
    alarmId: 'a1',
    scheduledAt: scheduledAt ?? DateTime.utc(2026, 5, 21, 7),
    softStartAt: null,
    status: status,
    triggeredAt: triggeredAt,
    dismissedAt: dismissedAt,
    snoozeCount: snoozeCount,
    note: '',
    snoozedUntil: snoozedUntil,
  );
}

void main() {
  group('the morning survives the snooze chain', () {
    const service = AlarmStatusService();
    final morning = DateTime.utc(2026, 5, 21, 7);
    final ring = DateTime.utc(2026, 5, 21, 7, 9);

    AlarmOccurrence snoozedRow() => _occurrence(
      status: AlarmStatus.snoozed,
      triggeredAt: morning,
      snoozeCount: 1,
      snoozedUntil: ring,
    );

    test('snooze records the re-ring without moving the target', () {
      final updated = service.snooze(
        occurrence: _occurrence(
          status: AlarmStatus.triggered,
          triggeredAt: morning,
        ),
        newSnoozeCount: 1,
        nextRingAt: ring,
      );
      expect(updated.scheduledAt, morning);
      expect(updated.snoozedUntil, ring);
      expect(updated.nextRingAt, ring);
    });

    test('snooze normalises the re-ring to UTC', () {
      final updated = service.snooze(
        occurrence: _occurrence(
          status: AlarmStatus.triggered,
          triggeredAt: morning,
        ),
        newSnoozeCount: 1,
        nextRingAt: DateTime(2026, 5, 21, 7, 9),
      );
      expect(updated.snoozedUntil!.isUtc, isTrue);
    });

    test('the re-ring arriving clears the pending flag', () {
      final updated = service.trigger(
        occurrence: snoozedRow(),
        now: ring,
      );
      expect(updated.snoozedUntil, isNull);
      expect(updated.scheduledAt, morning);
    });

    test('every terminal transition clears the pending re-ring', () {
      // A row that has ended must not still claim a ring is coming — the
      // coordinator arms from exactly that field.
      for (final terminal in <AlarmOccurrence>[
        service.dismiss(occurrence: snoozedRow(), now: ring),
        service.escape(occurrence: snoozedRow(), now: ring),
        service.markMissed(occurrence: snoozedRow()),
      ]) {
        expect(terminal.status.isTerminal, isTrue);
        expect(terminal.snoozedUntil, isNull);
        // And each one still names the morning it belongs to, which is what
        // lets the schedule engine retire it.
        expect(terminal.scheduledAt, morning);
      }
    });
  });
  group('AlarmStatusService.trigger', () {
    const service = AlarmStatusService();
    final now = DateTime.utc(2026, 5, 21, 7);

    test('scheduled -> triggered records triggeredAt in UTC', () {
      final updated = service.trigger(
        occurrence: _occurrence(),
        now: now,
      );
      expect(updated.status, AlarmStatus.triggered);
      expect(updated.triggeredAt, now);
      expect(updated.triggeredAt!.isUtc, isTrue);
    });

    test('snoozed -> triggered is allowed (snooze ring)', () {
      final updated = service.trigger(
        occurrence: _occurrence(
          status: AlarmStatus.snoozed,
          triggeredAt: now,
          snoozeCount: 1,
        ),
        now: now.add(const Duration(minutes: 9)),
      );
      expect(updated.status, AlarmStatus.triggered);
      expect(updated.snoozeCount, 1);
    });

    test('triggering an already-dismissed occurrence throws', () {
      expect(
        () => service.trigger(
          occurrence: _occurrence(
            status: AlarmStatus.dismissed,
            dismissedAt: now,
          ),
          now: now,
        ),
        throwsA(isA<AlarmStateException>()),
      );
    });

    test('triggering a missed occurrence throws', () {
      expect(
        () => service.trigger(
          occurrence: _occurrence(status: AlarmStatus.missed),
          now: now,
        ),
        throwsA(isA<AlarmStateException>()),
      );
    });

    test('non-UTC now is converted to UTC', () {
      final local = DateTime(2026, 5, 21, 9);
      final updated = service.trigger(
        occurrence: _occurrence(),
        now: local,
      );
      expect(updated.triggeredAt, local.toUtc());
      expect(updated.triggeredAt!.isUtc, isTrue);
    });
  });

  group('AlarmStatusService.snooze', () {
    const service = AlarmStatusService();
    final now = DateTime.utc(2026, 5, 21, 7);

    test('triggered -> snoozed bumps snooze count', () {
      final updated = service.snooze(
        occurrence: _occurrence(
          status: AlarmStatus.triggered,
          triggeredAt: now,
        ),
        newSnoozeCount: 1,
        nextRingAt: now.add(const Duration(minutes: 9)),
      );
      expect(updated.status, AlarmStatus.snoozed);
      expect(updated.snoozeCount, 1);
    });

    test('throws when count does not increment', () {
      expect(
        () => service.snooze(
          occurrence: _occurrence(
            status: AlarmStatus.triggered,
            triggeredAt: now,
            snoozeCount: 1,
          ),
          newSnoozeCount: 1,
          nextRingAt: now.add(const Duration(minutes: 9)),
        ),
        throwsA(isA<AlarmStateException>()),
      );
    });

    test('throws when called from scheduled', () {
      expect(
        () => service.snooze(
          occurrence: _occurrence(),
          newSnoozeCount: 1,
          nextRingAt: now.add(const Duration(minutes: 9)),
        ),
        throwsA(isA<AlarmStateException>()),
      );
    });

    test('throws when called from snoozed', () {
      expect(
        () => service.snooze(
          occurrence: _occurrence(
            status: AlarmStatus.snoozed,
            triggeredAt: now,
            snoozeCount: 1,
          ),
          newSnoozeCount: 2,
          nextRingAt: now.add(const Duration(minutes: 9)),
        ),
        throwsA(isA<AlarmStateException>()),
      );
    });
  });

  group('AlarmStatusService.dismiss', () {
    const service = AlarmStatusService();
    final now = DateTime.utc(2026, 5, 21, 7, 5);

    test('triggered -> dismissed records dismissedAt', () {
      final updated = service.dismiss(
        occurrence: _occurrence(
          status: AlarmStatus.triggered,
          triggeredAt: now,
        ),
        now: now,
      );
      expect(updated.status, AlarmStatus.dismissed);
      expect(updated.dismissedAt, now);
    });

    test('snoozed -> dismissed is allowed', () {
      final updated = service.dismiss(
        occurrence: _occurrence(
          status: AlarmStatus.snoozed,
          triggeredAt: now,
          snoozeCount: 1,
        ),
        now: now,
      );
      expect(updated.status, AlarmStatus.dismissed);
    });

    test('dismissing a scheduled occurrence throws', () {
      expect(
        () => service.dismiss(
          occurrence: _occurrence(),
          now: now,
        ),
        throwsA(isA<AlarmStateException>()),
      );
    });

    test('non-UTC now is converted to UTC', () {
      final local = DateTime(2026, 5, 21, 9, 5);
      final updated = service.dismiss(
        occurrence: _occurrence(
          status: AlarmStatus.triggered,
          triggeredAt: local.toUtc(),
        ),
        now: local,
      );
      expect(updated.dismissedAt, local.toUtc());
      expect(updated.dismissedAt!.isUtc, isTrue);
    });
  });

  group('AlarmStatusService.escape', () {
    const service = AlarmStatusService();
    final now = DateTime.utc(2026, 5, 21, 7, 4);

    test('triggered -> escaped records the stop time', () {
      final result = service.escape(
        occurrence: _occurrence(status: AlarmStatus.triggered),
        now: now,
      );
      expect(result.status, AlarmStatus.escaped);
      expect(result.dismissedAt, now);
    });

    test('snoozed -> escaped is allowed', () {
      final result = service.escape(
        occurrence: _occurrence(status: AlarmStatus.snoozed, snoozeCount: 2),
        now: now,
      );
      expect(result.status, AlarmStatus.escaped);
      expect(result.snoozeCount, 2);
    });

    test('escaped is its own outcome, never a dismiss', () {
      final escaped = service.escape(
        occurrence: _occurrence(status: AlarmStatus.triggered),
        now: now,
      );
      expect(escaped.status, isNot(AlarmStatus.dismissed));
    });

    test('escaping a scheduled occurrence throws', () {
      expect(
        () => service.escape(occurrence: _occurrence(), now: now),
        throwsA(isA<AlarmStateException>()),
      );
    });

    test('escaped is terminal — nothing follows it', () {
      final escaped = _occurrence(status: AlarmStatus.escaped);
      expect(
        () => service.dismiss(occurrence: escaped, now: now),
        throwsA(isA<AlarmStateException>()),
      );
      expect(
        () => service.markMissed(occurrence: escaped),
        throwsA(isA<AlarmStateException>()),
      );
      expect(
        service.isMissed(occurrence: escaped, now: DateTime.utc(2030)),
        isFalse,
      );
      expect(
        service.evaluateMissed(occurrence: escaped, now: DateTime.utc(2030)),
        escaped,
      );
    });

    test('non-UTC now is converted to UTC', () {
      final result = service.escape(
        occurrence: _occurrence(status: AlarmStatus.triggered),
        now: DateTime(2026, 5, 21, 7, 4),
      );
      expect(result.dismissedAt!.isUtc, isTrue);
    });
  });

  group('AlarmStatusService.skip', () {
    const service = AlarmStatusService();

    test('scheduled -> skipped is allowed', () {
      final updated = service.skip(occurrence: _occurrence());
      expect(updated.status, AlarmStatus.skipped);
    });

    test('skipping a triggered occurrence throws', () {
      expect(
        () => service.skip(
          occurrence: _occurrence(
            status: AlarmStatus.triggered,
            triggeredAt: DateTime.utc(2026, 5, 21, 7),
          ),
        ),
        throwsA(isA<AlarmStateException>()),
      );
    });
  });

  group('AlarmStatusService.markMissed', () {
    const service = AlarmStatusService();

    test('scheduled -> missed', () {
      final updated = service.markMissed(occurrence: _occurrence());
      expect(updated.status, AlarmStatus.missed);
    });

    test('triggered -> missed', () {
      final updated = service.markMissed(
        occurrence: _occurrence(
          status: AlarmStatus.triggered,
          triggeredAt: DateTime.utc(2026, 5, 21, 7),
        ),
      );
      expect(updated.status, AlarmStatus.missed);
    });

    test('snoozed -> missed', () {
      final updated = service.markMissed(
        occurrence: _occurrence(
          status: AlarmStatus.snoozed,
          triggeredAt: DateTime.utc(2026, 5, 21, 7),
          snoozeCount: 1,
        ),
      );
      expect(updated.status, AlarmStatus.missed);
    });

    test('marking a dismissed occurrence missed throws', () {
      expect(
        () => service.markMissed(
          occurrence: _occurrence(
            status: AlarmStatus.dismissed,
            dismissedAt: DateTime.utc(2026, 5, 21, 7, 5),
          ),
        ),
        throwsA(isA<AlarmStateException>()),
      );
    });
  });

  group('AlarmStatusService.isMissed / evaluateMissed', () {
    const service = AlarmStatusService();

    test('terminal states are never reclassified missed', () {
      final occ = _occurrence(
        status: AlarmStatus.dismissed,
        dismissedAt: DateTime.utc(2026, 5, 21, 7, 5),
      );
      expect(
        service.isMissed(
          occurrence: occ,
          now: DateTime.utc(2030),
        ),
        isFalse,
      );
      // evaluateMissed returns the occurrence unchanged.
      expect(
        service.evaluateMissed(
          occurrence: occ,
          now: DateTime.utc(2030),
        ),
        equals(occ),
      );
    });

    test('scheduled anchors on scheduledAt', () {
      final occ = _occurrence(
        scheduledAt: DateTime.utc(2026, 5, 21, 7),
      );
      expect(
        service.isMissed(
          occurrence: occ,
          now: DateTime.utc(2026, 5, 21, 7, 30),
        ),
        isTrue,
      );
    });

    test('snoozed anchors on the pending re-ring, not the trigger', () {
      // Someone on their fourth nine-minute snooze is actively using the
      // alarm. Anchoring on `triggeredAt` would call that morning "missed"
      // while the phone is still counting down to the next ring.
      const customGrace = AlarmStatusService(
        missedAfter: Duration(minutes: 10),
      );
      final occ = _occurrence(
        status: AlarmStatus.snoozed,
        triggeredAt: DateTime.utc(2026, 5, 21, 7),
        snoozedUntil: DateTime.utc(2026, 5, 21, 7, 36),
      );
      expect(
        customGrace.isMissed(
          occurrence: occ,
          now: DateTime.utc(2026, 5, 21, 7, 45),
        ),
        isFalse,
      );
      expect(
        customGrace.isMissed(
          occurrence: occ,
          now: DateTime.utc(2026, 5, 21, 7, 46),
        ),
        isTrue,
      );
    });

    test('a snoozed row carried over from schema v4 anchors the same', () {
      // Before the `snoozedUntil` column existed the pending ring lived in
      // `scheduledAt`. Such a row survives an upgrade untouched, so the
      // missed-by deadline has to read the same instant out of it.
      const customGrace = AlarmStatusService(
        missedAfter: Duration(minutes: 10),
      );
      final legacy = _occurrence(
        status: AlarmStatus.snoozed,
        scheduledAt: DateTime.utc(2026, 5, 21, 7, 36),
        triggeredAt: DateTime.utc(2026, 5, 21, 7),
      );
      expect(
        customGrace.isMissed(
          occurrence: legacy,
          now: DateTime.utc(2026, 5, 21, 7, 45),
        ),
        isFalse,
      );
      expect(
        customGrace.isMissed(
          occurrence: legacy,
          now: DateTime.utc(2026, 5, 21, 7, 46),
        ),
        isTrue,
      );
    });

    test('triggered anchors on triggeredAt', () {
      const customGrace = AlarmStatusService(
        missedAfter: Duration(minutes: 10),
      );
      final occ = _occurrence(
        status: AlarmStatus.triggered,
        triggeredAt: DateTime.utc(2026, 5, 21, 7, 5),
      );
      expect(
        customGrace.isMissed(
          occurrence: occ,
          now: DateTime.utc(2026, 5, 21, 7, 14),
        ),
        isFalse,
      );
      expect(
        customGrace.isMissed(
          occurrence: occ,
          now: DateTime.utc(2026, 5, 21, 7, 15),
        ),
        isTrue,
      );
    });

    test('snoozed past deadline evaluates to missed copy', () {
      final occ = _occurrence(
        status: AlarmStatus.snoozed,
        triggeredAt: DateTime.utc(2026, 5, 21, 7),
        snoozeCount: 1,
      );
      final updated = service.evaluateMissed(
        occurrence: occ,
        now: DateTime.utc(2026, 5, 21, 8),
      );
      expect(updated.status, AlarmStatus.missed);
    });
  });

  group('AlarmStatusService.motionReRing', () {
    const service = AlarmStatusService();
    final dismissedAt = DateTime.utc(2026, 5, 21, 7, 1);
    final now = DateTime.utc(2026, 5, 21, 7, 3);

    test('dismissed -> triggered once, flagged, dismissal cleared', () {
      final updated = service.motionReRing(
        occurrence: _occurrence(
          status: AlarmStatus.dismissed,
          dismissedAt: dismissedAt,
        ),
        now: now,
      );
      expect(updated.status, AlarmStatus.triggered);
      expect(updated.isMotionReRing, isTrue);
      expect(updated.triggeredAt, now);
      expect(updated.dismissedAt, isNull);
      expect(updated.scheduledAt, DateTime.utc(2026, 5, 21, 7));
    });

    test('a row already re-rung cannot be re-opened', () {
      final again = _occurrence(
        status: AlarmStatus.dismissed,
        dismissedAt: dismissedAt,
      ).copyWith(isMotionReRing: true);
      expect(
        () => service.motionReRing(occurrence: again, now: now),
        throwsA(isA<AlarmStateException>()),
      );
    });

    test('only a dismissal can be re-opened — never an escape', () {
      for (final status in AlarmStatus.values) {
        if (status == AlarmStatus.dismissed) continue;
        expect(
          () => service.motionReRing(
            occurrence: _occurrence(status: status),
            now: now,
          ),
          throwsA(isA<AlarmStateException>()),
          reason: status.name,
        );
      }
    });
  });

  group('AlarmStateException', () {
    test('toString includes the diagnostic message', () {
      const exception = AlarmStateException('boom');
      expect(exception.toString(), contains('boom'));
    });
  });
}
