import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/alarm_puzzle_override.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Alarm _alarm({
  String id = 'a1',
  String label = 'Workdays',
  Set<int>? repeatWeekdays,
  WakeMode wakeMode = WakeMode.standard,
  DismissMethod dismissMethod = DismissMethod.normalButton,
  DismissChallengeDifficulty? dismissChallengeDifficulty,
  int? maxSnoozes = 5,
  int targetTimeMinutes = 7 * 60,
}) {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: id,
    label: label,
    enabled: true,
    targetTimeMinutes: targetTimeMinutes,
    repeatWeekdays: repeatWeekdays ?? {1, 2, 3, 4, 5},
    wakeMode: wakeMode,
    wakeWindowStartMinutesBefore: 15,
    soundId: 'sand',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: maxSnoozes,
    dismissMethod: dismissMethod,
    dismissChallengeDifficulty: dismissChallengeDifficulty,
    confirmationEnabled: false,
    createdAt: t,
    updatedAt: t,
  );
}

AlarmOccurrence _occ({
  String id = 'o1',
  String alarmId = 'a1',
  AlarmStatus status = AlarmStatus.scheduled,
  DateTime? scheduledAt,
  int snoozeCount = 0,
  String note = '',
}) {
  return AlarmOccurrence(
    id: id,
    alarmId: alarmId,
    scheduledAt: scheduledAt ?? DateTime.utc(2026, 5, 22, 7),
    softStartAt: DateTime.utc(2026, 5, 22, 6, 45),
    status: status,
    triggeredAt: null,
    dismissedAt: null,
    snoozeCount: snoozeCount,
    note: note,
  );
}

void main() {
  late AppDatabase db;
  late CapyWakeRepository repo;
  final fixedNow = DateTime.utc(2026, 5, 21, 12);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CapyWakeRepository(db);
  });

  tearDown(() async {
    // Close drains Drift's internal stream timers — required so tests stay
    // free of pending-timer leaks.
    await db.close();
  });

  group('Alarms — CRUD', () {
    test('upsert + getAlarm round-trips every field', () async {
      final alarm = _alarm(
        dismissMethod: DismissMethod.puzzle,
        dismissChallengeDifficulty: DismissChallengeDifficulty.medium,
        wakeMode: WakeMode.strict,
      );
      await repo.upsertAlarm(alarm);

      final fetched = await repo.getAlarm('a1');
      expect(fetched, equals(alarm));
    });

    test('getAlarm returns null for unknown ids', () async {
      expect(await repo.getAlarm('does-not-exist'), isNull);
    });

    test('listAlarms returns rows ordered by createdAt', () async {
      final a1 = _alarm().copyWith(
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final a2 = _alarm(id: 'a2').copyWith(
        createdAt: DateTime.utc(2026, 2),
        updatedAt: DateTime.utc(2026, 2),
      );
      await repo.upsertAlarm(a2);
      await repo.upsertAlarm(a1);

      final out = await repo.listAlarms();
      expect(out.map((a) => a.id), ['a1', 'a2']);
    });

    test(
      'upsert is idempotent — second write replaces the row in place',
      () async {
        final original = _alarm();
        await repo.upsertAlarm(original);
        final edited = original.copyWith(label: 'Weekdays');
        await repo.upsertAlarm(edited);

        final out = await repo.listAlarms();
        expect(out.length, 1);
        expect(out.single.label, 'Weekdays');
      },
    );

    test('deleteAlarm removes the alarm and cascades to occurrences', () async {
      await repo.upsertAlarm(_alarm());
      await repo.upsertOccurrence(_occ());
      await repo.upsertOccurrence(_occ(id: 'o2'));

      await repo.deleteAlarm('a1');

      expect(await repo.getAlarm('a1'), isNull);
      expect(await repo.listOccurrencesForAlarm('a1'), isEmpty);
    });

    test('weekday CSV round-trips order-independently', () async {
      // Insert {3,1,7} — repository encodes sorted; reading reconstructs the
      // same logical set.
      await repo.upsertAlarm(_alarm(repeatWeekdays: {3, 1, 7}));
      final fetched = await repo.getAlarm('a1');
      expect(fetched!.repeatWeekdays, equals({1, 3, 7}));
    });

    test('empty repeatWeekdays (one-time alarm) round-trips', () async {
      await repo.upsertAlarm(_alarm(repeatWeekdays: {}));
      final fetched = await repo.getAlarm('a1');
      expect(fetched!.repeatWeekdays, isEmpty);
    });

    test('null challenge difficulty round-trips', () async {
      // The default factory uses normalButton (no challenge), so the
      // difficulty column persists null.
      await repo.upsertAlarm(_alarm());
      final fetched = await repo.getAlarm('a1');
      expect(fetched!.dismissChallengeDifficulty, isNull);
    });

    test('null maxSnoozes (unlimited) round-trips', () async {
      await repo.upsertAlarm(_alarm(maxSnoozes: null));
      final fetched = await repo.getAlarm('a1');
      expect(fetched!.maxSnoozes, isNull);
    });
  });

  group('Alarms — watchAlarms stream', () {
    test('emits the latest list on every commit', () async {
      final stream = repo.watchAlarms();
      final emissions = <List<Alarm>>[];
      final sub = stream.listen(emissions.add);

      // Wait for the initial empty emission before mutating, otherwise drift
      // can coalesce the initial state with the first write and the stream
      // jumps straight to the post-write list.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await repo.upsertAlarm(_alarm());
      await repo.upsertAlarm(
        _alarm(id: 'a2').copyWith(
          createdAt: DateTime.utc(2026, 5, 22),
          updatedAt: DateTime.utc(2026, 5, 22),
        ),
      );
      await repo.deleteAlarm('a1');

      // Allow drift to flush its emissions before we close.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      // First emission is the empty initial set; the rest reflect each write.
      expect(emissions.first, isEmpty);
      expect(emissions.last.map((a) => a.id), ['a2']);
    });
  });

  group('Occurrences', () {
    setUp(() => repo.upsertAlarm(_alarm()));

    test('upsert + list round-trips, ordered by scheduledAt', () async {
      await repo.upsertOccurrence(
        _occ(scheduledAt: DateTime.utc(2026, 5, 22, 7)),
      );
      await repo.upsertOccurrence(
        _occ(id: 'o2', scheduledAt: DateTime.utc(2026, 5, 21, 7)),
      );
      final out = await repo.listOccurrencesForAlarm('a1');
      expect(out.map((o) => o.id), ['o2', 'o1']);
    });

    test('upsert replaces in place; status updates round-trip', () async {
      await repo.upsertOccurrence(_occ());
      await repo.upsertOccurrence(
        _occ(status: AlarmStatus.dismissed, snoozeCount: 1),
      );
      final out = await repo.listOccurrencesForAlarm('a1');
      expect(out.length, 1);
      expect(out.single.status, AlarmStatus.dismissed);
      expect(out.single.snoozeCount, 1);
    });

    test('deleteOccurrence removes a single row', () async {
      await repo.upsertOccurrence(_occ());
      await repo.upsertOccurrence(_occ(id: 'o2'));
      await repo.deleteOccurrence('o1');
      final out = await repo.listOccurrencesForAlarm('a1');
      expect(out.map((o) => o.id), ['o2']);
    });

    test('watchOccurrencesForAlarm emits on change', () async {
      final emissions = <List<AlarmOccurrence>>[];
      final sub = repo.watchOccurrencesForAlarm('a1').listen(emissions.add);

      // Wait for the initial empty emission to land before mutating.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await repo.upsertOccurrence(_occ());
      await repo.upsertOccurrence(_occ(id: 'o2'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(emissions.first, isEmpty);
      expect(emissions.last.length, 2);
    });

    test(
      'watchFinishedOccurrences emits every terminal row across alarms',
      () async {
        // Two alarms; every status represented. The stream must surface each
        // of the four terminal ones — a morning is over whether the user
        // skipped it ahead of time, got up and dismissed it, took the escape,
        // or never answered — and none of the live ones, ordered by
        // `scheduledAt`.
        await repo.upsertAlarm(_alarm(id: 'a2'));

        final emissions = <List<AlarmOccurrence>>[];
        final sub = repo.watchFinishedOccurrences().listen(emissions.add);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        await repo.upsertOccurrence(
          _occ(
            id: 'sched',
            // The default _occ status is `scheduled`; making this explicit
            // here is documentation, not redundancy — readers should see at
            // a glance that this row is *not* finished.
            // ignore: avoid_redundant_argument_values
            status: AlarmStatus.scheduled,
            scheduledAt: DateTime.utc(2026, 5, 22, 7),
          ),
        );
        await repo.upsertOccurrence(
          _occ(
            id: 'triggered',
            status: AlarmStatus.triggered,
            scheduledAt: DateTime.utc(2026, 5, 22, 7),
          ),
        );
        await repo.upsertOccurrence(
          _occ(
            id: 'snoozed',
            status: AlarmStatus.snoozed,
            scheduledAt: DateTime.utc(2026, 5, 22, 7),
          ),
        );
        await repo.upsertOccurrence(
          _occ(
            id: 'skip-a1',
            status: AlarmStatus.skipped,
            scheduledAt: DateTime.utc(2026, 5, 22, 7),
          ),
        );
        await repo.upsertOccurrence(
          _occ(
            id: 'skip-a2',
            alarmId: 'a2',
            status: AlarmStatus.skipped,
            scheduledAt: DateTime.utc(2026, 5, 21, 7),
          ),
        );
        await repo.upsertOccurrence(
          _occ(
            id: 'dismissed',
            status: AlarmStatus.dismissed,
            scheduledAt: DateTime.utc(2026, 5, 23, 7),
          ),
        );
        await repo.upsertOccurrence(
          _occ(
            id: 'escaped',
            status: AlarmStatus.escaped,
            scheduledAt: DateTime.utc(2026, 5, 24, 7),
          ),
        );
        await repo.upsertOccurrence(
          _occ(
            id: 'missed',
            status: AlarmStatus.missed,
            scheduledAt: DateTime.utc(2026, 5, 25, 7),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));
        await sub.cancel();

        expect(emissions.first, isEmpty);
        expect(emissions.last.map((o) => o.id), [
          'skip-a2',
          'skip-a1',
          'dismissed',
          'escaped',
          'missed',
        ]);
      },
    );

    test(
      'watchSnoozedOccurrences emits only `snoozed` rows across alarms',
      () async {
        // This stream is what carries a pressed Snooze to the platform, so
        // it has to be exactly the live snoozed rows: a scheduled row would
        // arm a duplicate of the ordinary ring, and a dismissed one would
        // arm a ring for a morning that is already over.
        await repo.upsertAlarm(_alarm(id: 'a2'));

        final emissions = <List<AlarmOccurrence>>[];
        final sub = repo.watchSnoozedOccurrences().listen(emissions.add);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        await repo.upsertOccurrence(
          _occ(
            id: 'sched',
            // The default `_occ` status is already `scheduled`; stating it
            // makes the contrast with the snoozed rows below readable.
            // ignore: avoid_redundant_argument_values
            status: AlarmStatus.scheduled,
            scheduledAt: DateTime.utc(2026, 5, 22, 7),
          ),
        );
        await repo.upsertOccurrence(
          _occ(
            id: 'snooze-a1',
            status: AlarmStatus.snoozed,
            scheduledAt: DateTime.utc(2026, 5, 22, 7, 9),
          ),
        );
        await repo.upsertOccurrence(
          _occ(
            id: 'snooze-a2',
            alarmId: 'a2',
            status: AlarmStatus.snoozed,
            scheduledAt: DateTime.utc(2026, 5, 21, 7, 9),
          ),
        );
        await repo.upsertOccurrence(
          _occ(
            id: 'dismissed',
            status: AlarmStatus.dismissed,
            scheduledAt: DateTime.utc(2026, 5, 23, 7),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));
        await sub.cancel();

        expect(emissions.first, isEmpty);
        expect(emissions.last.map((o) => o.id), ['snooze-a2', 'snooze-a1']);
      },
    );

    test('a snoozed row leaving `snoozed` drops out of the stream', () async {
      // Dismissing is what ends a snooze chain. If the row lingered in this
      // stream the coordinator would keep re-arming a ring for it on every
      // later write.
      final emissions = <List<AlarmOccurrence>>[];
      final sub = repo.watchSnoozedOccurrences().listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final snoozed = _occ(
        status: AlarmStatus.snoozed,
        scheduledAt: DateTime.utc(2026, 5, 22, 7, 9),
      );
      await repo.upsertOccurrence(snoozed);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emissions.last.map((o) => o.id), ['o1']);

      await repo.upsertOccurrence(
        snoozed.copyWith(
          status: AlarmStatus.dismissed,
          dismissedAt: DateTime.utc(2026, 5, 22, 7, 10),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(emissions.last, isEmpty);
    });
  });

  group('Settings singleton', () {
    test('getSettings returns initial defaults before any write', () async {
      expect(await repo.getSettings(), equals(UserSettings.initial));
    });

    test('saveSettings + getSettings round-trips every field', () async {
      final s = UserSettings.initial.copyWith(
        defaultWakeMode: WakeMode.strict,
        defaultSoundId: 'rain',
        defaultSnoozeMinutes: 5,
        timeFormat: TimeFormatPreference.h24,
        themeMode: ThemeModePreference.dark,
        reliabilityChecklistState: ReliabilityChecklistState.empty
            .copyWithItem(
              ReliabilityChecklistItem.notificationPermission,
              ChecklistItemState.ok,
            )
            .copyWithItem(
              ReliabilityChecklistItem.batteryOptimization,
              ChecklistItemState.actionRequired,
            ),
      );
      await repo.saveSettings(s, now: fixedNow);
      expect(await repo.getSettings(), equals(s));
    });

    test('watchSettings starts with initial then emits saved values', () async {
      final emissions = <UserSettings>[];
      final sub = repo.watchSettings().listen(emissions.add);

      // Wait for the initial emission to land before mutating.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await repo.saveSettings(
        UserSettings.initial.copyWith(defaultWakeMode: WakeMode.gentle),
        now: fixedNow,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(emissions.first, equals(UserSettings.initial));
      expect(emissions.last.defaultWakeMode, WakeMode.gentle);
    });
  });

  group('Pro status singleton', () {
    test('getProStatus returns initial defaults before any write', () async {
      expect(await repo.getProStatus(), equals(ProStatus.initial));
    });

    test('saveProStatus round-trips', () async {
      final pro = ProStatus(
        isPro: true,
        purchaseSource: ProPurchaseSource.purchase,
        updatedAt: fixedNow,
      );
      await repo.saveProStatus(pro, now: fixedNow);
      expect(await repo.getProStatus(), equals(pro));
    });

    test(
      'saveProStatus uses DateTime.now() when no clock is injected',
      () async {
        // Smoke-test the un-injected path so the production default is covered.
        final pro = ProStatus(
          isPro: true,
          purchaseSource: ProPurchaseSource.restore,
          updatedAt: DateTime.utc(2026),
        );
        await repo.saveProStatus(pro);
        final fetched = await repo.getProStatus();
        expect(fetched.isPro, isTrue);
        expect(fetched.purchaseSource, ProPurchaseSource.restore);
      },
    );

    test('watchProStatus emits saved values', () async {
      final emissions = <ProStatus>[];
      final sub = repo.watchProStatus().listen(emissions.add);

      // Wait for the initial emission to land before mutating.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await repo.saveProStatus(
        ProStatus(
          isPro: true,
          purchaseSource: ProPurchaseSource.promo,
          updatedAt: fixedNow,
        ),
        now: fixedNow,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(emissions.first, equals(ProStatus.initial));
      expect(emissions.last.isPro, isTrue);
    });
  });

  group('puzzle settings singleton', () {
    test('a fresh database reports the shipped defaults', () async {
      expect(await repo.getPuzzleSettings(), PuzzleSettings.defaults());
    });

    test('round-trips every field through the database', () async {
      final settings = PuzzleSettings(
        enabledTypes: const {
          PuzzleType.missingOperator,
          PuzzleType.spotTheChange,
        },
        taskCount: 5,
        difficulty: PuzzleDifficulty.easy,
        toleratedWrongAnswers: 9,
        escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
      );
      await repo.savePuzzleSettings(settings, now: fixedNow);
      expect(await repo.getPuzzleSettings(), settings);
    });

    test('a later save replaces the earlier one', () async {
      await repo.savePuzzleSettings(
        PuzzleSettings(enabledTypes: const {PuzzleType.arithmetic}),
        now: fixedNow,
      );
      await repo.savePuzzleSettings(
        PuzzleSettings(
          enabledTypes: const {PuzzleType.digitRecall},
          taskCount: 3,
        ),
        now: fixedNow,
      );
      final stored = await repo.getPuzzleSettings();
      expect(stored.enabledTypes, {PuzzleType.digitRecall});
      expect(stored.taskCount, 3);
    });

    test('the stream emits the defaults, then each save', () async {
      final emissions = <PuzzleSettings>[];
      final sub = repo.watchPuzzleSettings().listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await repo.savePuzzleSettings(
        PuzzleSettings(enabledTypes: const {PuzzleType.oddOneOutNumeric}),
        now: fixedNow,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(emissions.first, PuzzleSettings.defaults());
      expect(emissions.last.enabledTypes, {PuzzleType.oddOneOutNumeric});
    });

    test('is stored separately from the user settings', () async {
      await repo.savePuzzleSettings(
        PuzzleSettings(
          enabledTypes: const {PuzzleType.arithmetic},
          taskCount: 4,
        ),
        now: fixedNow,
      );
      await repo.saveSettings(
        UserSettings.initial.copyWith(defaultSnoozeMinutes: 12),
        now: fixedNow,
      );
      // Writing one singleton does not disturb the other.
      expect((await repo.getPuzzleSettings()).taskCount, 4);
      expect((await repo.getSettings()).defaultSnoozeMinutes, 12);
    });
  });

  group('per-alarm puzzle override', () {
    test('round-trips through the alarm row', () async {
      final override = AlarmPuzzleOverride(
        enabledTypes: const {PuzzleType.compareValues},
        taskCount: 2,
        toleratedWrongAnswers: 0,
        escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
      );
      await repo.upsertAlarm(
        _alarm(
          dismissMethod: DismissMethod.puzzle,
          dismissChallengeDifficulty: DismissChallengeDifficulty.easy,
        ).copyWith(puzzleOverride: override),
      );
      final stored = (await repo.listAlarms()).single;
      expect(stored.puzzleOverride, override);
      expect(
        stored.dismissChallengeDifficulty,
        DismissChallengeDifficulty.easy,
      );
    });

    test('a null override round-trips as null, not as an empty one', () async {
      await repo.upsertAlarm(_alarm(dismissMethod: DismissMethod.puzzle));
      expect((await repo.listAlarms()).single.puzzleOverride, isNull);
    });

    test('clearing an override persists the clear', () async {
      final alarm = _alarm(dismissMethod: DismissMethod.puzzle).copyWith(
        puzzleOverride: AlarmPuzzleOverride(taskCount: 2),
      );
      await repo.upsertAlarm(alarm);
      expect((await repo.listAlarms()).single.puzzleOverride, isNotNull);

      await repo.upsertAlarm(alarm.copyWith(clearPuzzleOverride: true));
      expect((await repo.listAlarms()).single.puzzleOverride, isNull);
    });
  });
}
