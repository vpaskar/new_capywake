import 'package:capywake/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

AlarmOccurrence _occ({
  String id = 'o1',
  String alarmId = 'a1',
  AlarmStatus status = AlarmStatus.scheduled,
  int snoozeCount = 0,
  String note = '',
  DateTime? softStartAt,
  DateTime? triggeredAt,
  DateTime? dismissedAt,
}) {
  return AlarmOccurrence(
    id: id,
    alarmId: alarmId,
    scheduledAt: DateTime.utc(2026, 5, 22, 7),
    softStartAt: softStartAt,
    status: status,
    triggeredAt: triggeredAt,
    dismissedAt: dismissedAt,
    snoozeCount: snoozeCount,
    note: note,
  );
}

void main() {
  group('AlarmOccurrence', () {
    test('equality on identical field values', () {
      expect(_occ(), equals(_occ()));
      expect(_occ().hashCode, equals(_occ().hashCode));
    });

    test('any field difference breaks equality', () {
      final base = _occ();
      expect(base, isNot(equals(_occ(id: 'o2'))));
      expect(base, isNot(equals(_occ(alarmId: 'aX'))));
      expect(base, isNot(equals(_occ(status: AlarmStatus.dismissed))));
      expect(base, isNot(equals(_occ(snoozeCount: 1))));
      expect(base, isNot(equals(_occ(note: 'late'))));
      expect(
        base,
        isNot(
          equals(_occ(softStartAt: DateTime.utc(2026, 5, 22, 6, 45))),
        ),
      );
      expect(
        base,
        isNot(
          equals(_occ(triggeredAt: DateTime.utc(2026, 5, 22, 7))),
        ),
      );
      expect(
        base,
        isNot(
          equals(_occ(dismissedAt: DateTime.utc(2026, 5, 22, 7, 1))),
        ),
      );
    });

    test('identical and unrelated-type equality short-circuits', () {
      final occ = _occ();
      expect(occ == occ, isTrue);
      // Intentional cross-type compare to exercise the type check in `==`.
      // ignore: unrelated_type_equality_checks
      expect(occ == 'string', isFalse);
    });

    test('copyWith updates the targeted fields', () {
      final base = _occ();
      final triggered = base.copyWith(
        status: AlarmStatus.triggered,
        triggeredAt: DateTime.utc(2026, 5, 22, 7, 1),
        snoozeCount: 1,
        note: 'Snoozed once',
      );
      expect(triggered.status, AlarmStatus.triggered);
      expect(triggered.triggeredAt, DateTime.utc(2026, 5, 22, 7, 1));
      expect(triggered.snoozeCount, 1);
      expect(triggered.note, 'Snoozed once');
      expect(triggered.id, base.id);
    });

    test('copyWith() with no arguments is equal', () {
      final base = _occ();
      expect(base.copyWith(), equals(base));
    });

    test('clear flags clear nullable fields', () {
      final base = _occ(
        softStartAt: DateTime.utc(2026, 5, 22, 6, 45),
        triggeredAt: DateTime.utc(2026, 5, 22, 7),
        dismissedAt: DateTime.utc(2026, 5, 22, 7, 5),
      );
      final cleared = base.copyWith(
        clearSoftStartAt: true,
        clearTriggeredAt: true,
        clearDismissedAt: true,
      );
      expect(cleared.softStartAt, isNull);
      expect(cleared.triggeredAt, isNull);
      expect(cleared.dismissedAt, isNull);
    });

    test('copyWith updates each replaceable field', () {
      final base = _occ();
      final next = base.copyWith(
        id: 'o2',
        alarmId: 'a2',
        scheduledAt: DateTime.utc(2026, 5, 23, 7),
        softStartAt: DateTime.utc(2026, 5, 23, 6, 45),
        status: AlarmStatus.snoozed,
        triggeredAt: DateTime.utc(2026, 5, 23, 7),
        dismissedAt: DateTime.utc(2026, 5, 23, 7, 5),
        snoozeCount: 2,
        note: 'Snoozed twice',
      );
      expect(next.id, 'o2');
      expect(next.alarmId, 'a2');
      expect(next.scheduledAt, DateTime.utc(2026, 5, 23, 7));
      expect(next.softStartAt, DateTime.utc(2026, 5, 23, 6, 45));
      expect(next.status, AlarmStatus.snoozed);
      expect(next.triggeredAt, DateTime.utc(2026, 5, 23, 7));
      expect(next.dismissedAt, DateTime.utc(2026, 5, 23, 7, 5));
      expect(next.snoozeCount, 2);
      expect(next.note, 'Snoozed twice');
    });
  });

  group('AlarmOccurrence.snoozedUntil', () {
    final morning = DateTime.utc(2026, 5, 22, 7);
    final ring = DateTime.utc(2026, 5, 22, 7, 9);

    AlarmOccurrence snoozed({DateTime? until}) => _occ().copyWith(
      status: AlarmStatus.snoozed,
      snoozedUntil: until ?? ring,
    );

    test('nextRingAt is the pending re-ring while snoozed', () {
      expect(snoozed().nextRingAt, ring);
      // And the morning is untouched, which is the whole point.
      expect(snoozed().scheduledAt, _occ().scheduledAt);
    });

    test('nextRingAt falls back to the morning when there is none', () {
      // A scheduled row, and a snoozed row carried over from schema v4 where
      // the pending ring lived in `scheduledAt`, read the same way.
      expect(_occ().nextRingAt, _occ().scheduledAt);
      expect(
        _occ().copyWith(status: AlarmStatus.snoozed).nextRingAt,
        _occ().scheduledAt,
      );
    });

    test('nextRingAt is always UTC', () {
      final local = _occ().copyWith(
        status: AlarmStatus.snoozed,
        snoozedUntil: DateTime(2026, 5, 22, 7, 9),
      );
      expect(local.nextRingAt.isUtc, isTrue);
    });

    test('clearSnoozedUntil drops it', () {
      final cleared = snoozed().copyWith(
        status: AlarmStatus.dismissed,
        clearSnoozedUntil: true,
      );
      expect(cleared.snoozedUntil, isNull);
      expect(cleared.nextRingAt, morning);
    });

    test('it participates in equality and hashCode', () {
      expect(snoozed(), snoozed());
      expect(snoozed().hashCode, snoozed().hashCode);
      expect(
        snoozed(),
        isNot(snoozed(until: DateTime.utc(2026, 5, 22, 7, 18))),
      );
    });

    test('a pending re-ring on a non-snoozed row is rejected', () {
      // The invariant that keeps `snoozedUntil` meaning one thing: a ring
      // that has not happened yet. A dismissed row carrying one would be a
      // silent claim that the alarm is still coming.
      expect(
        () => _occ().copyWith(snoozedUntil: ring),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
