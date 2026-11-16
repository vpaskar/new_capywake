import 'package:capywake/core/engine/alarm_engine.dart';
import 'package:capywake/core/engine/fake_alarm_engine.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Alarm _alarm(String id) {
  final created = DateTime.utc(2026);
  return Alarm(
    id: id,
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
    createdAt: created,
    updatedAt: created,
  );
}

AlarmOccurrencePlan _plan(String id, tz.TZDateTime scheduled) =>
    AlarmOccurrencePlan(
      alarm: _alarm(id),
      scheduled: scheduled,
      softStart: null,
      location: scheduled.location,
    );

void main() {
  setUpAll(tzdata.initializeTimeZones);
  final utc = tz.UTC;

  group('FakeAlarmEngine', () {
    test('arm stores the plan and increments the counter', () async {
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);

      await engine.arm(_plan('a', tz.TZDateTime(utc, 2026, 5, 22, 7)));

      expect(engine.armCallCount, 1);
      expect(engine.armedSnapshot, hasLength(1));
      expect(engine.armedSnapshot.containsKey('a'), isTrue);
    });

    test('cancel removes the plan and increments the counter', () async {
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);

      await engine.arm(_plan('a', tz.TZDateTime(utc, 2026, 5, 22, 7)));
      await engine.cancel('a');

      expect(engine.cancelCallCount, 1);
      expect(engine.armedSnapshot, isEmpty);
    });

    test('cancel for an unknown id is a no-op', () async {
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);

      await engine.cancel('nope');

      expect(engine.armedSnapshot, isEmpty);
    });

    test('rescheduleAll replaces the armed set', () async {
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);

      await engine.arm(_plan('a', tz.TZDateTime(utc, 2026, 5, 22, 7)));
      await engine.rescheduleAll([
        _plan('b', tz.TZDateTime(utc, 2026, 5, 23, 7)),
        _plan('c', tz.TZDateTime(utc, 2026, 5, 24, 7)),
      ]);

      expect(engine.rescheduleCallCount, 1);
      expect(engine.armedSnapshot.keys.toSet(), {'b', 'c'});
    });

    test('rescheduleAll with empty list cancels everything', () async {
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);

      await engine.arm(_plan('a', tz.TZDateTime(utc, 2026, 5, 22, 7)));
      await engine.rescheduleAll(const []);

      expect(engine.armedSnapshot, isEmpty);
    });

    test('arm is idempotent on the same id (overwrites the plan)', () async {
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);

      final t1 = tz.TZDateTime(utc, 2026, 5, 22, 7);
      final t2 = tz.TZDateTime(utc, 2026, 5, 22, 8);
      await engine.arm(_plan('a', t1));
      await engine.arm(_plan('a', t2));

      expect(engine.armedSnapshot, hasLength(1));
      expect(
        engine.armedSnapshot['a']!.scheduled.isAtSameMomentAs(t2),
        isTrue,
      );
    });

    test('failNextArm makes the next arm throw, then clears', () async {
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);

      engine.failNextArm = const AlarmEngineException('boom');
      await expectLater(
        engine.arm(_plan('a', tz.TZDateTime(utc, 2026, 5, 22, 7))),
        throwsA(isA<AlarmEngineException>()),
      );

      // Next call succeeds.
      await engine.arm(_plan('a', tz.TZDateTime(utc, 2026, 5, 22, 7)));
      expect(engine.armedSnapshot, hasLength(1));
    });

    test('failNextCancel makes the next cancel throw, then clears', () async {
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);

      engine.failNextCancel = const AlarmEngineException('boom');
      await expectLater(
        engine.cancel('a'),
        throwsA(isA<AlarmEngineException>()),
      );
      // Subsequent cancel succeeds.
      await engine.cancel('a');
      expect(engine.cancelCallCount, 2);
    });

    test(
      'failNextReschedule makes the next rescheduleAll throw, then clears',
      () async {
        final engine = FakeAlarmEngine();
        addTearDown(engine.dispose);

        engine.failNextReschedule = const AlarmEngineException('boom');
        await expectLater(
          engine.rescheduleAll(const []),
          throwsA(isA<AlarmEngineException>()),
        );
        // Subsequent rescheduleAll succeeds and arms the given plans.
        await engine.rescheduleAll([
          _plan('a', tz.TZDateTime(utc, 2026, 5, 22, 7)),
        ]);
        expect(engine.armedSnapshot.keys, contains('a'));
      },
    );

    test('fire emits a RingingAlarm on the stream', () async {
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);

      final events = <RingingAlarm>[];
      final sub = engine.ringingStream.listen(events.add);
      addTearDown(sub.cancel);

      engine.fire('a', firedAt: DateTime.utc(2026, 5, 22, 7));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.alarmId, 'a');
      expect(
        events.single.firedAt.isAtSameMomentAs(DateTime.utc(2026, 5, 22, 7)),
        isTrue,
      );
    });

    test('fire defaults firedAt to now', () async {
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);

      final events = <RingingAlarm>[];
      final sub = engine.ringingStream.listen(events.add);
      addTearDown(sub.cancel);

      final before = DateTime.now().toUtc();
      engine.fire('a');
      await Future<void>.delayed(Duration.zero);
      final after = DateTime.now().toUtc();

      expect(events, hasLength(1));
      final firedAt = events.single.firedAt;
      expect(
        !firedAt.isBefore(before) && !firedAt.isAfter(after),
        isTrue,
      );
    });

    test('dispose closes the stream and is idempotent', () async {
      final engine = FakeAlarmEngine();
      await engine.dispose();
      await engine.dispose();
    });
  });

  group('RingingAlarm', () {
    test('equality + hashCode', () {
      final a = RingingAlarm(
        alarmId: 'a',
        firedAt: DateTime.utc(2026, 5, 22, 7),
      );
      final b = RingingAlarm(
        alarmId: 'a',
        firedAt: DateTime.utc(2026, 5, 22, 7),
      );
      final c = RingingAlarm(
        alarmId: 'b',
        firedAt: DateTime.utc(2026, 5, 22, 7),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      // Identity branch.
      expect(a, a);
    });

    test('toString contains key fields', () {
      final r = RingingAlarm(
        alarmId: 'a',
        firedAt: DateTime.utc(2026, 5, 22, 7),
      );
      expect(r.toString(), contains('a'));
      expect(r.toString(), contains('2026'));
    });
  });

  group('AlarmEngineException', () {
    test('toString includes the message', () {
      const e = AlarmEngineException('boom');
      expect(e.toString(), contains('boom'));
    });

    test('toString includes the cause when set', () {
      const e = AlarmEngineException('boom', cause: 'underlying');
      expect(e.toString(), contains('underlying'));
    });
  });

  group('ringNow', () {
    test('records the call and surfaces it on the ringing stream', () async {
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);
      final seen = <RingingAlarm>[];
      final subscription = engine.ringingStream.listen(seen.add);
      addTearDown(subscription.cancel);

      await engine.ringNow(_alarm('a1'));
      await Future<void>.delayed(Duration.zero);

      expect(engine.ringNowCallCount, 1);
      expect(engine.ringNowAlarmIds, ['a1']);
      expect(seen.single.alarmId, 'a1');
    });

    test('stamps events with the injected clock', () async {
      final at = DateTime.utc(2026, 5, 21, 7);
      final engine = FakeAlarmEngine(now: () => at);
      addTearDown(engine.dispose);
      final seen = <RingingAlarm>[];
      final subscription = engine.ringingStream.listen(seen.add);
      addTearDown(subscription.cancel);

      await engine.ringNow(_alarm('a1'));
      await Future<void>.delayed(Duration.zero);

      expect(seen.single.firedAt, at);
    });

    test('a queued failure throws once, then clears', () async {
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);
      engine.failNextRingNow = const AlarmEngineException('nope');

      await expectLater(
        engine.ringNow(_alarm('a1')),
        throwsA(isA<AlarmEngineException>()),
      );
      expect(engine.ringNowCallCount, 1);
      expect(engine.ringNowAlarmIds, isEmpty);

      await engine.ringNow(_alarm('a1'));
      expect(engine.ringNowCallCount, 2);
      expect(engine.ringNowAlarmIds, ['a1']);
    });

    test('an immediate ring is not part of the armed schedule', () async {
      // The whole reason ringNow exists: rescheduleAll clears armed plans, and
      // an extra ring must not be swept away by an unrelated write.
      final engine = FakeAlarmEngine();
      addTearDown(engine.dispose);
      await engine.ringNow(_alarm('a1'));
      expect(engine.armedSnapshot, isEmpty);
    });
  });
}
