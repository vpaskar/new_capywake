import 'package:capywake/core/sleep/sleep.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/database/mappers.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/data/sleep/repository_sleep_night_store.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

SleepNight _night({
  DateTime? day,
  Map<SleepStage, int> stages = const {},
  String source = 'Watch',
  int total = 480,
  int inBed = 500,
}) => SleepNight(
  night: day ?? DateTime(2026, 3, 10),
  asleepAt: DateTime.utc(2026, 3, 9, 23),
  wokeAt: DateTime.utc(2026, 3, 10, 7),
  totalAsleepMinutes: total,
  timeInBedMinutes: inBed,
  sourceName: source,
  stageMinutes: stages,
);

void main() {
  late AppDatabase db;
  late CapyWakeRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CapyWakeRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SleepNightMapper', () {
    test('round-trips a night with a full stage breakdown', () async {
      final night = _night(
        stages: const {
          SleepStage.deep: 90,
          SleepStage.light: 240,
          SleepStage.rem: 70,
          SleepStage.awake: 20,
          SleepStage.inBed: 15,
          SleepStage.asleep: 400,
          SleepStage.unknown: 5,
        },
      );

      await repo.upsertSleepNights([night]);
      final read = (await repo.listSleepNights()).single;

      expect(read.night, night.night);
      expect(read.asleepAt, night.asleepAt);
      expect(read.wokeAt, night.wokeAt);
      expect(read.totalAsleepMinutes, 480);
      expect(read.timeInBedMinutes, 500);
      expect(read.sourceName, 'Watch');
      for (final stage in night.stageMinutes.keys) {
        expect(read.minutesFor(stage), night.minutesFor(stage));
      }
    });

    test(
      'an unreported stage stays absent rather than becoming zero',
      () async {
        await repo.upsertSleepNights([
          _night(stages: const {SleepStage.deep: 90}),
        ]);

        final read = (await repo.listSleepNights()).single;
        expect(read.stageMinutes.containsKey(SleepStage.deep), isTrue);
        // NULL in the column, so the night knows the device said nothing about
        // REM — distinguishable from a device reporting zero REM.
        expect(read.stageMinutes.containsKey(SleepStage.rem), isFalse);
        expect(read.minutesFor(SleepStage.rem), 0);
      },
    );

    test('a zero-minute stage does not survive as a breakdown', () async {
      await repo.upsertSleepNights([
        _night(stages: const {SleepStage.deep: 0}),
      ]);

      final read = (await repo.listSleepNights()).single;
      expect(read.hasPhaseBreakdown, isFalse);
    });

    test('upserting the same night replaces it', () async {
      await repo.upsertSleepNights([_night(total: 400)]);
      await repo.upsertSleepNights([_night()]);

      final nights = await repo.listSleepNights();
      expect(nights, hasLength(1));
      expect(nights.single.totalAsleepMinutes, 480);
    });

    test('an empty list writes nothing', () async {
      await repo.upsertSleepNights(const []);
      expect(await repo.listSleepNights(), isEmpty);
    });

    test('nights come back oldest first', () async {
      await repo.upsertSleepNights([
        _night(day: DateTime(2026, 3, 12)),
        _night(day: DateTime(2026, 3, 10)),
        _night(day: DateTime(2026, 3, 11)),
      ]);

      expect(
        (await repo.listSleepNights()).map((n) => n.night),
        [DateTime(2026, 3, 10), DateTime(2026, 3, 11), DateTime(2026, 3, 12)],
      );
    });

    test('a companion carries the supplied sync stamp', () {
      final stamp = DateTime.utc(2026, 3, 15, 9);
      final companion = SleepNightMapper.toCompanion(_night(), now: stamp);
      expect(companion.syncedAt.value, stamp);
    });
  });

  group('pruneSleepNightsBefore', () {
    test('drops nights older than the boundary and keeps the rest', () async {
      await repo.upsertSleepNights([
        _night(day: DateTime(2026, 3, 2)),
        _night(day: DateTime(2026, 3, 10)),
        _night(day: DateTime(2026, 3, 20)),
      ]);

      await repo.pruneSleepNightsBefore(DateTime(2026, 3, 10));

      expect(
        (await repo.listSleepNights()).map((n) => n.night),
        [DateTime(2026, 3, 10), DateTime(2026, 3, 20)],
      );
    });

    test(
      'a far-future boundary clears the cache, as opting out does',
      () async {
        await repo.upsertSleepNights([_night()]);
        await repo.pruneSleepNightsBefore(DateTime(2100));
        expect(await repo.listSleepNights(), isEmpty);
      },
    );
  });

  group('watchSleepNights', () {
    test('emits on write', () async {
      final seen = <int>[];
      final sub = repo.watchSleepNights().listen((n) => seen.add(n.length));
      addTearDown(sub.cancel);

      await repo.upsertSleepNights([_night()]);
      await Future<void>.delayed(Duration.zero);
      await repo.upsertSleepNights([_night(day: DateTime(2026, 3, 11))]);
      await Future<void>.delayed(Duration.zero);

      expect(seen.last, 2);
    });
  });

  group('SleepSyncStateMapper', () {
    test('round-trips an enabled state', () async {
      final synced = DateTime.utc(2026, 3, 15, 9);
      await repo.saveSleepSyncState(
        SleepSyncState(
          enabled: true,
          lastSyncedAt: synced,
          lastError: SleepSyncError.timeout,
        ),
      );

      final read = await repo.getSleepSyncState();
      expect(read.enabled, isTrue);
      expect(read.lastSyncedAt, synced);
      expect(read.lastError, SleepSyncError.timeout);
    });

    test('an absent row reads as the off-by-default state', () async {
      final read = await repo.getSleepSyncState();
      expect(read, SleepSyncState.initial);
      expect(read.enabled, isFalse);
    });

    test('round-trips the initial state', () async {
      await repo.saveSleepSyncState(SleepSyncState.initial);
      final read = await repo.getSleepSyncState();
      expect(read.enabled, isFalse);
      expect(read.lastSyncedAt, isNull);
      expect(read.lastError, isNull);
    });

    test('an unrecognised stored error reads as no error', () {
      // A category retired in a later version, or a hand-edited database,
      // must not throw on the path that opens a settings screen.
      final state = SleepSyncStateMapper.fromJson(
        '{"enabled":true,"lastError":"somethingRetired"}',
      );
      expect(state.enabled, isTrue);
      expect(state.lastError, isNull);
    });

    test('an unparseable timestamp reads as never synced', () {
      final state = SleepSyncStateMapper.fromJson(
        '{"enabled":true,"lastSyncedAt":"not-a-date"}',
      );
      expect(state.lastSyncedAt, isNull);
    });

    test('a missing enabled flag defaults to off', () {
      expect(SleepSyncStateMapper.fromJson('{}').enabled, isFalse);
    });

    test('watchSleepSyncState emits the stored state', () async {
      final seen = <bool>[];
      final sub = repo.watchSleepSyncState().listen(
        (s) => seen.add(s.enabled),
      );
      addTearDown(sub.cancel);

      await repo.saveSleepSyncState(const SleepSyncState(enabled: true));
      await Future<void>.delayed(Duration.zero);

      expect(seen.last, isTrue);
    });
  });

  group('RepositorySleepNightStore', () {
    test('delegates every operation to the repository', () async {
      final store = RepositorySleepNightStore(repo);

      await store.writeSyncState(const SleepSyncState(enabled: true));
      expect((await store.readSyncState()).enabled, isTrue);

      await store.upsertNights([_night()]);
      expect(await repo.listSleepNights(), hasLength(1));

      await store.pruneNightsBefore(DateTime(2100));
      expect(await repo.listSleepNights(), isEmpty);
    });
  });
}
