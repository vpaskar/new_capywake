import 'package:capywake/core/engine/fake_notification_service.dart';
import 'package:capywake/core/engine/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

PendingNotification _n({
  int id = 1,
  String alarmId = 'a',
  NotificationKind kind = NotificationKind.softWakeStart,
  DateTime? scheduledUtc,
  DateTime? payloadAlarmTimeUtc,
}) {
  return PendingNotification(
    id: id,
    alarmId: alarmId,
    kind: kind,
    scheduledUtc: scheduledUtc ?? DateTime.utc(2026, 5, 22, 6, 45),
    payloadAlarmTimeUtc: payloadAlarmTimeUtc ?? DateTime.utc(2026, 5, 22, 7),
  );
}

void main() {
  group('FakeNotificationService', () {
    test(
      'scheduleAll replaces the pending queue and bumps the counter',
      () async {
        final svc = FakeNotificationService();

        await svc.scheduleAll([_n(), _n(id: 2, alarmId: 'b')]);
        expect(svc.scheduleCallCount, 1);
        expect(svc.pending.map((n) => n.id), [1, 2]);

        await svc.scheduleAll([_n(id: 3, alarmId: 'c')]);
        expect(svc.scheduleCallCount, 2);
        expect(svc.pending.map((n) => n.id), [3]);
      },
    );

    test('cancelAll clears the queue and bumps the counter', () async {
      final svc = FakeNotificationService();

      await svc.scheduleAll([_n()]);
      await svc.cancelAll();

      expect(svc.cancelAllCallCount, 1);
      expect(svc.pending, isEmpty);
    });

    test('pending getter returns an unmodifiable view', () async {
      final svc = FakeNotificationService();
      await svc.scheduleAll([_n()]);
      expect(() => svc.pending.add(_n(id: 99)), throwsUnsupportedError);
    });

    test(
      'failNextSchedule makes the next scheduleAll throw, then clears',
      () async {
        final svc = FakeNotificationService();
        addTearDown(svc.dispose);
        svc.failNextSchedule = Exception('boom');
        await expectLater(svc.scheduleAll([_n()]), throwsException);
        // Cleared — the following call succeeds.
        await svc.scheduleAll([_n()]);
        expect(svc.pending, hasLength(1));
      },
    );

    test(
      'failNextCancelAll makes the next cancelAll throw, then clears',
      () async {
        final svc = FakeNotificationService();
        addTearDown(svc.dispose);
        svc.failNextCancelAll = Exception('boom');
        await expectLater(svc.cancelAll(), throwsException);
        await svc.cancelAll();
        expect(svc.cancelAllCallCount, 2);
      },
    );

    test('dispose marks the service as disposed', () async {
      final svc = FakeNotificationService();
      expect(svc.isDisposed, isFalse);
      await svc.dispose();
      expect(svc.isDisposed, isTrue);
    });
  });

  group('PendingNotification', () {
    test('equality + hashCode', () {
      final a = _n();
      final b = _n();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('inequality when any field differs', () {
      final base = _n();
      expect(base, isNot(_n(id: 99)));
      expect(base, isNot(_n(alarmId: 'b')));
      expect(
        base,
        isNot(_n(scheduledUtc: DateTime.utc(2030))),
      );
      expect(
        base,
        isNot(_n(payloadAlarmTimeUtc: DateTime.utc(2030))),
      );
    });

    test('toString contains key fields', () {
      final n = _n(id: 42, alarmId: 'foo');
      expect(n.toString(), contains('42'));
      expect(n.toString(), contains('foo'));
    });

    test('equal instances handle the identity branch', () {
      final a = _n();
      // ignore: unrelated_type_equality_checks, exercising the identity
      // branch of the custom == operator.
      expect(a == a, isTrue);
    });
  });
}
