import 'dart:async';

import 'package:capywake/core/engine/alarm_engine.dart';
import 'package:capywake/core/engine/fake_alarm_engine.dart';
import 'package:capywake/core/lifecycle/alarm_status_service.dart';
import 'package:capywake/core/lifecycle/snooze_service.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/motion/fake_motion_sensor.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/features/ringing/ringing_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../games/_motion.dart';

Alarm _alarm({
  String id = 'a1',
  bool motionCheck = false,
  bool snoozeEnabled = true,
  int? maxSnoozes = 3,
  DismissMethod dismissMethod = DismissMethod.normalButton,
  int windowBefore = 0,
}) {
  final now = DateTime.utc(2026);
  return Alarm(
    id: id,
    label: 'Morning',
    enabled: true,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const {},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: windowBefore,
    soundId: 'chimes',
    vibrationEnabled: true,
    snoozeEnabled: snoozeEnabled,
    snoozeDurationMinutes: 9,
    maxSnoozes: maxSnoozes,
    dismissMethod: dismissMethod,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    motionConfirmationEnabled: motionCheck,
    createdAt: now,
    updatedAt: now,
  );
}

/// An engine whose `cancel` blocks until the test releases it: with in-memory
/// fakes the mid-flight window closes in one microtask and is unobservable.
class _SlowCancelEngine implements AlarmEngine {
  _SlowCancelEngine(this._inner);

  final FakeAlarmEngine _inner;
  final _gate = Completer<void>();
  int cancelCalls = 0;

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<void> cancel(String alarmId) async {
    cancelCalls++;
    await _gate.future;
    await _inner.cancel(alarmId);
  }

  @override
  Future<void> arm(AlarmOccurrencePlan plan) => _inner.arm(plan);

  @override
  Future<void> ringNow(Alarm alarm) => _inner.ringNow(alarm);

  @override
  Future<void> rescheduleAll(List<AlarmOccurrencePlan> plans) =>
      _inner.rescheduleAll(plans);

  @override
  Stream<RingingAlarm> get ringingStream => _inner.ringingStream;

  @override
  Future<void> dispose() => _inner.dispose();
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late AppDatabase db;
  late CapyWakeRepository repository;
  late FakeAlarmEngine engine;
  late RingingController controller;
  late DateTime clock;
  late int uuidCounter;
  late tz.Location location;
  late FakeMotionSensor motion;

  DateTime now() => clock;

  Future<void> build({PuzzleSettings? puzzleSettings}) async {
    controller = RingingController(
      engine: engine,
      repository: repository,
      statusService: const AlarmStatusService(),
      snoozeService: const SnoozeService(),
      readPuzzleSettings: () => puzzleSettings ?? PuzzleSettings.defaults(),
      readLocation: () => location,
      uuid: () => 'occ-${uuidCounter++}',
      now: now,
      motionSensor: motion,
    );
  }

  setUp(() async {
    motion = FakeMotionSensor();
    location = tz.getLocation('Europe/Berlin');
    clock = DateTime.utc(2026, 11, 16, 6);
    uuidCounter = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CapyWakeRepository(db);
    engine = FakeAlarmEngine(now: now);
    await build();
  });

  tearDown(() async {
    await controller.dispose();
    await motion.dispose();
    await engine.dispose();
    await db.close();
  });

  Future<void> ring(Alarm alarm, {DateTime? at}) async {
    engine.fire(alarm.id, firedAt: at ?? clock);
    await pumpEventQueue();
  }

  group('ring', () {
    test(
      'a platform ring opens a session and triggers the occurrence',
      () async {
        final alarm = _alarm();
        await repository.upsertAlarm(alarm);

        await ring(alarm);

        final session = controller.currentSession;
        expect(session, isNotNull);
        expect(session!.alarm.id, alarm.id);
        expect(session.occurrence.status, AlarmStatus.triggered);
        expect(session.occurrence.triggeredAt, isNotNull);

        final rows = await repository.listOccurrencesForAlarm(alarm.id);
        expect(rows, hasLength(1));
        expect(rows.single.status, AlarmStatus.triggered);
      },
    );

    test('a ring for a deleted alarm is ignored, not crashed', () async {
      await ring(_alarm(id: 'gone'));

      expect(controller.currentSession, isNull);
      expect(await repository.listOccurrencesForAlarm('gone'), isEmpty);
    });

    test(
      'two ring events for one alarm create one occurrence, not two',
      () async {
        final alarm = _alarm();
        await repository.upsertAlarm(alarm);

        // Both events are delivered before either handler completes.
        engine
          ..fire(alarm.id, firedAt: clock)
          ..fire(alarm.id, firedAt: clock);
        await pumpEventQueue();

        final rows = await repository.listOccurrencesForAlarm(alarm.id);
        expect(rows, hasLength(1));
        expect(rows.single.status, AlarmStatus.triggered);
      },
    );

    test(
      'a re-ring after the handler settled reuses the same occurrence',
      () async {
        final alarm = _alarm();
        await repository.upsertAlarm(alarm);

        await ring(alarm);
        final firstId = controller.currentSession!.occurrence.id;
        await ring(alarm);

        final rows = await repository.listOccurrencesForAlarm(alarm.id);
        expect(rows, hasLength(1));
        expect(controller.currentSession!.occurrence.id, firstId);
      },
    );

    test('a ring for an already-terminal occurrence opens nothing', () async {
      final alarm = _alarm();
      await repository.upsertAlarm(alarm);
      await ring(alarm);
      await controller.dismiss();

      await ring(alarm);

      expect(controller.currentSession, isNull);
      final rows = await repository.listOccurrencesForAlarm(alarm.id);
      expect(rows, hasLength(1));
      expect(rows.single.status, AlarmStatus.dismissed);
    });
  });

  group('exactly once', () {
    test('two dismisses write one terminal row', () async {
      final alarm = _alarm();
      await repository.upsertAlarm(alarm);
      await ring(alarm);

      await Future.wait([controller.dismiss(), controller.dismiss()]);

      final rows = await repository.listOccurrencesForAlarm(alarm.id);
      expect(rows, hasLength(1));
      expect(rows.single.status, AlarmStatus.dismissed);
      expect(controller.currentSession, isNull);
    });

    test('two escapes write one terminal row', () async {
      final alarm = _alarm(dismissMethod: DismissMethod.puzzle);
      await repository.upsertAlarm(alarm);
      await ring(alarm);

      await Future.wait([controller.escape(), controller.escape()]);

      final rows = await repository.listOccurrencesForAlarm(alarm.id);
      expect(rows, hasLength(1));
      expect(rows.single.status, AlarmStatus.escaped);
    });

    test('a dismiss racing an escape produces one outcome, not two', () async {
      final alarm = _alarm(dismissMethod: DismissMethod.puzzle);
      await repository.upsertAlarm(alarm);
      await ring(alarm);

      await Future.wait([controller.dismiss(), controller.escape()]);

      final rows = await repository.listOccurrencesForAlarm(alarm.id);
      expect(rows, hasLength(1));
      expect(rows.single.status.isTerminal, isTrue);
      expect(rows.single.dismissedAt, isNotNull);
    });

    test(
      'a second dismiss after the first settled is a no-op, not a throw',
      () async {
        final alarm = _alarm();
        await repository.upsertAlarm(alarm);
        await ring(alarm);

        await controller.dismiss();
        await expectLater(controller.dismiss(), completes);

        final rows = await repository.listOccurrencesForAlarm(alarm.id);
        expect(rows.single.status, AlarmStatus.dismissed);
      },
    );

    test('an action with no live session is a no-op', () async {
      await expectLater(controller.dismiss(), completes);
      await expectLater(controller.escape(), completes);
      await expectLater(controller.snooze(), completes);
    });

    test('two snoozes advance the count by one, not two', () async {
      final alarm = _alarm();
      await repository.upsertAlarm(alarm);
      await ring(alarm);

      await Future.wait([controller.snooze(), controller.snooze()]);

      final rows = await repository.listOccurrencesForAlarm(alarm.id);
      expect(rows, hasLength(1));
      expect(rows.single.snoozeCount, 1);
      expect(rows.single.status, AlarmStatus.snoozed);
    });
  });

  group('escape', () {
    test(
      'writes escaped, never dismissed, and cancels the platform alarm',
      () async {
        final alarm = _alarm(dismissMethod: DismissMethod.puzzle);
        await repository.upsertAlarm(alarm);
        await ring(alarm);

        await controller.escape();

        final rows = await repository.listOccurrencesForAlarm(alarm.id);
        expect(rows.single.status, AlarmStatus.escaped);
        expect(rows.single.status, isNot(AlarmStatus.dismissed));
        expect(engine.armedSnapshot.containsKey(alarm.id), isFalse);
      },
    );

    test('is available even on an alarm that is not puzzle-backed', () async {
      final alarm = _alarm();
      await repository.upsertAlarm(alarm);
      await ring(alarm);

      await controller.escape();

      final rows = await repository.listOccurrencesForAlarm(alarm.id);
      expect(rows.single.status, AlarmStatus.escaped);
    });
  });

  group('snooze', () {
    test('records the next ring and ends the session', () async {
      final alarm = _alarm();
      await repository.upsertAlarm(alarm);
      await ring(alarm);

      await controller.snooze();

      final rows = await repository.listOccurrencesForAlarm(alarm.id);
      expect(rows.single.status, AlarmStatus.snoozed);
      expect(rows.single.snoozeCount, 1);
      expect(rows.single.snoozedUntil, isNotNull);
      expect(rows.single.note, 'snoozed:1');
      expect(controller.currentSession, isNull);
    });

    test('is refused when the alarm has snooze off', () async {
      final alarm = _alarm(snoozeEnabled: false);
      await repository.upsertAlarm(alarm);
      await ring(alarm);

      expect(controller.currentSession!.snoozeAvailable, isFalse);
      await controller.snooze();

      final rows = await repository.listOccurrencesForAlarm(alarm.id);
      expect(rows.single.status, AlarmStatus.triggered);
    });

    test(
      'an alarm with snooze off is not announced as a final alarm',
      () async {
        final alarm = _alarm(snoozeEnabled: false);
        await repository.upsertAlarm(alarm);
        await ring(alarm);

        final session = controller.currentSession!;
        expect(session.snoozeAvailable, isFalse);
        expect(session.isFinalAlarm, isFalse);
      },
    );

    test('an uncapped alarm never reports a final alarm', () async {
      final alarm = _alarm(maxSnoozes: null);
      await repository.upsertAlarm(alarm);
      await ring(alarm);

      expect(controller.currentSession!.snoozeAvailable, isTrue);
      expect(controller.currentSession!.isFinalAlarm, isFalse);
    });

    test('the ring that reaches the cap is the final alarm', () async {
      final alarm = _alarm(maxSnoozes: 1);
      await repository.upsertAlarm(alarm);
      await ring(alarm);
      await controller.snooze();

      clock = clock.add(const Duration(minutes: 9));
      await ring(alarm, at: clock);

      final session = controller.currentSession!;
      expect(session.isFinalAlarm, isTrue);
      expect(session.snoozeAvailable, isFalse);
    });
  });

  group('a second alarm ringing', () {
    test(
      'supersedes the session and leaves the first row non-terminal',
      () async {
        final first = _alarm();
        final second = _alarm(id: 'a2');
        await repository.upsertAlarm(first);
        await repository.upsertAlarm(second);

        await ring(first);
        await ring(second);

        expect(controller.currentSession!.alarm.id, 'a2');

        final firstRows = await repository.listOccurrencesForAlarm('a1');
        expect(firstRows.single.status, AlarmStatus.triggered);
        expect(firstRows.single.status.isTerminal, isFalse);
      },
    );

    test(
      'a dismiss writes the alarm now in front, not the superseded one',
      () async {
        final first = _alarm();
        final second = _alarm(id: 'a2');
        await repository.upsertAlarm(first);
        await repository.upsertAlarm(second);

        await ring(first);
        await ring(second);
        await controller.dismiss();

        final firstRows = await repository.listOccurrencesForAlarm('a1');
        final secondRows = await repository.listOccurrencesForAlarm('a2');
        expect(firstRows.single.status, AlarmStatus.triggered);
        expect(secondRows.single.status, AlarmStatus.dismissed);
      },
    );
  });

  group('motion check after dismiss', () {
    Future<Alarm> armCheck({bool global = true, Alarm? alarm}) async {
      final a = alarm ?? _alarm(motionCheck: true);
      await repository.upsertAlarm(a);
      await repository.saveSettings(
        UserSettings.initial.copyWith(motionConfirmationEnabled: global),
      );
      return a;
    }

    Future<void> ringAndDismiss(Alarm alarm) async {
      await ring(alarm);
      await controller.dismiss();
      await pumpEventQueue();
    }

    /// One reading per second for [seconds], moving or still.
    Future<void> feed(int seconds, {required bool moving}) async {
      for (var i = 0; i < seconds; i++) {
        clock = clock.add(const Duration(seconds: 1));
        motion.emit(moving ? FakeMotionSensor.moving : FakeMotionSensor.still);
        await pumpEventQueue();
      }
    }

    /// The morning that rang first: a later unclaimed ring opens its own row.
    Future<AlarmOccurrence> morning() async =>
        (await repository.listOccurrencesForAlarm('a1')).firstWhere(
          (o) => o.scheduledAt.isAtSameMomentAs(DateTime.utc(2026, 11, 16, 6)),
        );

    test('a still phone rings once more and re-opens the morning', () async {
      final alarm = await armCheck();
      await ringAndDismiss(alarm);
      expect(controller.motionCheckRunning, isTrue);
      expect(motion.hasListener, isTrue);

      await feed(89, moving: false);
      expect(engine.ringNowCallCount, 0);
      await feed(1, moving: false);

      expect(engine.ringNowAlarmIds, ['a1']);
      expect(motion.hasListener, isFalse);
      final row = await morning();
      expect(row.status, AlarmStatus.triggered);
      expect(row.isMotionReRing, isTrue);
      expect(controller.currentSession?.occurrence.id, row.id);
    });

    test('dismissing the re-ring opens no second window', () async {
      final alarm = await armCheck();
      await ringAndDismiss(alarm);
      await feed(90, moving: false);
      await controller.dismiss();
      await pumpEventQueue();

      expect(controller.motionCheckRunning, isFalse);
      expect((await morning()).status, AlarmStatus.dismissed);
      await feed(120, moving: false);
      expect(engine.ringNowCallCount, 1);
    });

    test('moving in 45 separate seconds is enough: nothing happens', () async {
      final alarm = await armCheck();
      await ringAndDismiss(alarm);
      await feed(45, moving: true);
      expect(controller.motionCheckRunning, isFalse);
      expect(motion.hasListener, isFalse);
      await feed(60, moving: false);
      expect(engine.ringNowCallCount, 0);
      expect((await morning()).status, AlarmStatus.dismissed);
    });

    test('a silent sensor never invents a ring', () async {
      final alarm = await armCheck();
      await ringAndDismiss(alarm);
      clock = clock.add(const Duration(minutes: 10));
      await pumpEventQueue();
      expect(engine.ringNowCallCount, 0);
    });

    test("Settings' switch wins: off means no window", () async {
      final alarm = await armCheck(global: false);
      await ringAndDismiss(alarm);
      expect(controller.motionCheckRunning, isFalse);
      expect(motion.hasListener, isFalse);
    });

    test("the alarm's own switch off means no window", () async {
      await armCheck(alarm: _alarm());
      await ringAndDismiss(_alarm());
      expect(controller.motionCheckRunning, isFalse);
    });

    test('the escape never opens a window', () async {
      final alarm = await armCheck();
      await ring(alarm);
      await controller.escape();
      await pumpEventQueue();
      expect(controller.motionCheckRunning, isFalse);
    });

    test('a snooze never opens a window', () async {
      final alarm = await armCheck();
      await ring(alarm);
      await controller.snooze();
      await pumpEventQueue();
      expect(controller.motionCheckRunning, isFalse);
    });

    test('turned off in Settings mid-window: no ring (M1)', () async {
      final alarm = await armCheck();
      await ringAndDismiss(alarm);
      await repository.saveSettings(UserSettings.initial);
      await feed(90, moving: false);
      expect(engine.ringNowCallCount, 0);
    });

    test(
      'deleted, disabled or switched off mid-window: no ring (M1)',
      () async {
        for (final change in <Future<void> Function()>[
          () => repository.deleteAlarm('a1'),
          () => repository.upsertAlarm(
            _alarm(motionCheck: true).copyWith(enabled: false),
          ),
          () => repository.upsertAlarm(_alarm()),
        ]) {
          await db.delete(db.alarmOccurrences).go();
          final alarm = await armCheck();
          await ringAndDismiss(alarm);
          await change();
          await feed(90, moving: false);
          expect(engine.ringNowCallCount, 0);
        }
      },
    );

    test('a ring that starts during the dismissal opens no window', () async {
      final alarm = await armCheck();
      final other = _alarm(id: 'a2');
      await repository.upsertAlarm(other);
      await ring(alarm);
      final dismissing = controller.dismiss();
      engine.fire('a2', firedAt: clock);
      await dismissing;
      await pumpEventQueue();
      expect(controller.currentSession?.alarm.id, 'a2');
      expect(controller.motionCheckRunning, isFalse);
    });

    test('another ring closes the window', () async {
      final alarm = await armCheck();
      await ringAndDismiss(alarm);
      final other = _alarm(id: 'a2');
      await repository.upsertAlarm(other);
      await ring(other);
      expect(controller.motionCheckRunning, isFalse);
      expect(motion.hasListener, isFalse);
    });

    test('a sensor error leaves the watch open and harmless', () async {
      final failing = FailingMotionSensor();
      addTearDown(failing.dispose);
      await controller.dispose();
      controller = RingingController(
        engine: engine,
        repository: repository,
        statusService: const AlarmStatusService(),
        snoozeService: const SnoozeService(),
        readPuzzleSettings: PuzzleSettings.defaults,
        readLocation: () => location,
        uuid: () => 'occ-${uuidCounter++}',
        now: now,
        motionSensor: failing,
      );
      final alarm = await armCheck();
      await ringAndDismiss(alarm);
      failing.fail();
      await pumpEventQueue();
      expect(controller.motionCheckRunning, isTrue);
      expect(engine.ringNowCallCount, 0);
    });

    test('disposing mid-window releases the sensor', () async {
      final alarm = await armCheck();
      await ringAndDismiss(alarm);
      await controller.dispose();
      expect(motion.hasListener, isFalse);
    });

    test('a refused re-ring is logged, not retried, claims no ring', () async {
      final alarm = await armCheck();
      await ringAndDismiss(alarm);
      engine.failNextRingNow = const AlarmEngineException('refused');
      await feed(90, moving: false);
      await feed(120, moving: false);
      expect(engine.ringNowCallCount, 1);
      expect((await morning()).status, AlarmStatus.dismissed);
      expect(controller.currentSession, isNull);
    });

    test('a ring long after the dismissal re-opens nothing', () async {
      final alarm = await armCheck();
      await ringAndDismiss(alarm);
      engine.autoFireOnRingNow = false;
      await feed(90, moving: false);
      clock = clock.add(
        RingingController.reRingClaimWindow + const Duration(seconds: 1),
      );
      await ring(alarm);
      expect((await morning()).status, AlarmStatus.dismissed);
      expect(controller.currentSession?.occurrence.isMotionReRing, isFalse);
    });

    test(
      'the re-ring still finds its morning after another alarm rang',
      () async {
        final alarm = await armCheck();
        await ringAndDismiss(alarm);
        engine.autoFireOnRingNow = false;
        await feed(90, moving: false);
        final other = _alarm(id: 'a2');
        await repository.upsertAlarm(other);
        await ring(other);
        await controller.dismiss();
        await ring(alarm);
        expect((await morning()).isMotionReRing, isTrue);
        expect((await morning()).status, AlarmStatus.triggered);
      },
    );

    test('a ring of an alarm without the check is never a re-ring', () async {
      final alarm = await armCheck(alarm: _alarm());
      await ringAndDismiss(alarm);
      clock = clock.add(const Duration(seconds: 30));
      await ring(alarm);
      expect((await morning()).status, AlarmStatus.dismissed);
    });

    test(
      'a re-ring that arrives after a restart still finds its morning',
      () async {
        final alarm = await armCheck();
        await ringAndDismiss(alarm);
        engine.autoFireOnRingNow = false;
        await feed(90, moving: false);
        await controller.dispose();
        await build();
        await ring(alarm);
        expect((await morning()).isMotionReRing, isTrue);
        await controller.dismiss();
        await pumpEventQueue();
        expect(controller.motionCheckRunning, isFalse, reason: 'one re-ring');
      },
    );
  });

  group('escape visibility', () {
    PuzzleSettings tolerant(int tolerated) => PuzzleSettings(
      enabledTypes: const {PuzzleType.arithmetic},
      toleratedWrongAnswers: tolerated,
    );

    test('starts available and is never hidden', () async {
      await build(puzzleSettings: tolerant(3));
      final alarm = _alarm(dismissMethod: DismissMethod.puzzle);
      await repository.upsertAlarm(alarm);
      await ring(alarm);

      expect(
        controller.currentSession!.escapeVisibility,
        PuzzleEscapeVisibility.available,
      );
    });

    test('raising it is idempotent', () async {
      await build(puzzleSettings: tolerant(3));
      final alarm = _alarm(dismissMethod: DismissMethod.puzzle);
      await repository.upsertAlarm(alarm);
      await ring(alarm);

      controller
        ..raiseEscapeVisibility()
        ..raiseEscapeVisibility();

      expect(
        controller.currentSession!.escapeVisibility,
        PuzzleEscapeVisibility.prominent,
      );
    });

    test('once prominent it survives a snooze and the next ring', () async {
      await build(puzzleSettings: tolerant(0));
      final alarm = _alarm(dismissMethod: DismissMethod.puzzle);
      await repository.upsertAlarm(alarm);
      await ring(alarm);

      controller.raiseEscapeVisibility();
      expect(
        controller.currentSession!.escapeVisibility,
        PuzzleEscapeVisibility.prominent,
      );

      await controller.snooze();
      clock = clock.add(const Duration(minutes: 9));
      await ring(alarm, at: clock);

      expect(
        controller.currentSession!.escapeVisibility,
        PuzzleEscapeVisibility.prominent,
        reason: 'a fresh round must not demote the escape mid-occurrence',
      );
    });

    test('raising with no live session is a no-op', () async {
      expect(controller.raiseEscapeVisibility, returnsNormally);
    });
  });

  group('lifecycle', () {
    test('the session stream emits the ring and the end of it', () async {
      final alarm = _alarm();
      await repository.upsertAlarm(alarm);
      final seen = <String?>[];
      controller.sessionStream.listen(
        (s) => seen.add(s?.occurrence.status.name),
      );

      await ring(alarm);
      await controller.dismiss();
      await pumpEventQueue();

      expect(seen, ['triggered', null]);
    });

    test('dispose is idempotent', () async {
      await controller.dispose();
      await expectLater(controller.dispose(), completes);
    });
  });

  group('self-review #2 probes', () {
    test(
      'a dismiss arriving mid-flight is refused while the first awaits',
      () async {
        await controller.dispose();
        final slow = _SlowCancelEngine(engine);
        final alarm = _alarm();
        await repository.upsertAlarm(alarm);

        final slowController = RingingController(
          engine: slow,
          repository: repository,
          statusService: const AlarmStatusService(),
          snoozeService: const SnoozeService(),
          readPuzzleSettings: PuzzleSettings.defaults,
          readLocation: () => location,
          uuid: () => 'occ-slow',
          now: now,
          motionSensor: FakeMotionSensor(),
        );
        addTearDown(slowController.dispose);

        engine.fire(alarm.id, firedAt: clock);
        await pumpEventQueue();

        // The first dismiss is now parked inside `cancel`.
        final first = slowController.dismiss();
        await pumpEventQueue();
        expect(slow.cancelCalls, 1);

        // The second arrives while the first has not returned.
        final second = slowController.dismiss();
        await pumpEventQueue();
        expect(
          slow.cancelCalls,
          1,
          reason: 'the in-flight latch must refuse it before any platform call',
        );

        slow.release();
        await Future.wait([first, second]);

        final rows = await repository.listOccurrencesForAlarm(alarm.id);
        expect(rows, hasLength(1));
        expect(rows.single.status, AlarmStatus.dismissed);
      },
    );

    test('an escape arriving mid-dismiss is refused the same way', () async {
      await controller.dispose();
      final slow = _SlowCancelEngine(engine);
      final alarm = _alarm(dismissMethod: DismissMethod.puzzle);
      await repository.upsertAlarm(alarm);

      final slowController = RingingController(
        engine: slow,
        repository: repository,
        statusService: const AlarmStatusService(),
        snoozeService: const SnoozeService(),
        readPuzzleSettings: PuzzleSettings.defaults,
        readLocation: () => location,
        uuid: () => 'occ-slow-2',
        now: now,
        motionSensor: FakeMotionSensor(),
      );
      addTearDown(slowController.dispose);

      engine.fire(alarm.id, firedAt: clock);
      await pumpEventQueue();

      final dismissing = slowController.dismiss();
      await pumpEventQueue();
      final escaping = slowController.escape();
      await pumpEventQueue();

      expect(slow.cancelCalls, 1);
      slow.release();
      await Future.wait([dismissing, escaping]);

      final rows = await repository.listOccurrencesForAlarm(alarm.id);
      expect(rows, hasLength(1));
      expect(rows.single.status, AlarmStatus.dismissed);
    });

    test('the stored snooze note is the shape Stats will parse', () async {
      final alarm = _alarm();
      await repository.upsertAlarm(alarm);
      await ring(alarm);
      await controller.snooze();

      final rows = await repository.listOccurrencesForAlarm(alarm.id);
      expect(
        rows.single.note,
        'snoozed:1',
        reason: 'locale-free stored shape; Stats (Phase 08) re-pluralises it',
      );
    });
  });
}
