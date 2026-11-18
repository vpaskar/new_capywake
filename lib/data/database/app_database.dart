import 'dart:io';

import 'package:capywake/core/models/models.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// User-configured alarms (the source of truth for "what the user asked
/// for"). Each row maps 1:1 to an `Alarm` model.
///
/// Times are stored as integers — `targetTimeMinutes` is minutes since
/// midnight, durations are integer minutes — and only formatted to a clock
/// string at the UI boundary via `intl`.
@DataClassName('AlarmRow')
class Alarms extends Table {
  TextColumn get id => text()();
  TextColumn get label => text().withDefault(const Constant(''))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get targetTimeMinutes => integer()();

  /// ISO 8601 weekdays (1..7) joined by `,`. Empty string = one-time alarm.
  /// A `TEXT` CSV (rather than a separate join table) keeps a single-row
  /// read sufficient for the alarm list — the set is tiny (≤ 7 items).
  TextColumn get repeatWeekdaysCsv => text().withDefault(const Constant(''))();

  /// `WakeMode.name` ("gentle", "standard", "strict").
  TextColumn get wakeMode => text()();

  IntColumn get wakeWindowStartMinutesBefore =>
      integer().withDefault(const Constant(0))();

  TextColumn get soundId => text().withDefault(const Constant(''))();
  BoolColumn get vibrationEnabled =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get snoozeEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get snoozeDurationMinutes =>
      integer().withDefault(const Constant(9))();

  /// `null` = unlimited snoozes.
  IntColumn get maxSnoozes => integer().nullable()();

  /// `DismissMethod.name`.
  TextColumn get dismissMethod => text()();

  /// `DismissChallengeDifficulty.name`, or null to follow the app-wide
  /// puzzle difficulty.
  TextColumn get dismissChallengeDifficulty => text().nullable()();

  /// This alarm's departures from the app-wide puzzle settings, as the JSON
  /// blob `AlarmPuzzleOverrideMapper` writes — or null when the alarm simply
  /// follows them.
  TextColumn get puzzleOverrideJson => text().nullable()();

  BoolColumn get confirmationEnabled =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get motionConfirmationEnabled =>
      boolean().withDefault(const Constant(false))();

  /// `Alarm.artId`; null follows the alarm's place in the list.
  TextColumn get artId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Concrete fires of an [Alarms] row. One alarm yields many occurrences.
@DataClassName('AlarmOccurrenceRow')
class AlarmOccurrences extends Table {
  TextColumn get id => text()();
  TextColumn get alarmId => text().references(Alarms, #id)();

  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get softStartAt => dateTime().nullable()();

  /// `AlarmStatus.name`.
  TextColumn get status => text()();

  DateTimeColumn get triggeredAt => dateTime().nullable()();
  DateTimeColumn get dismissedAt => dateTime().nullable()();

  /// When a snoozed occurrence is due to ring again, kept separate from
  /// [scheduledAt] so an occurrence can still say which morning it belongs to.
  DateTimeColumn get snoozedUntil => dateTime().nullable()();

  IntColumn get snoozeCount => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Persisting this is what bounds the motion check to one extra ring even
  /// across a restart.
  BoolColumn get isMotionReRing =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One night of sleep read from Apple Health / Health Connect, cached so
/// History renders offline.
///
/// A cache of someone else's measurement, never a record CapyWake produced:
/// the app measures no sleep and writes nothing back. Dropped wholesale when
/// the user turns the feature off, because that withdraws consent.
///
/// `night` is the LOCAL-midnight date of the morning the sleeper woke on, so a
/// night shares its key with that morning's History row.
///
/// `totalAsleepMinutes` is the platform's own figure and deliberately NOT the
/// sum of the stage columns — real stage coverage is partial and overlapping,
/// so summing them would contradict the user's own Health app.
@DataClassName('SleepNightRow')
class SleepNights extends Table {
  DateTimeColumn get night => dateTime()();

  DateTimeColumn get asleepAt => dateTime()();
  DateTimeColumn get wokeAt => dateTime()();

  IntColumn get totalAsleepMinutes => integer()();
  IntColumn get timeInBedMinutes => integer()();

  IntColumn get asleepMinutes => integer().nullable()();
  IntColumn get deepMinutes => integer().nullable()();
  IntColumn get lightMinutes => integer().nullable()();
  IntColumn get remMinutes => integer().nullable()();
  IntColumn get awakeMinutes => integer().nullable()();
  IntColumn get inBedMinutes => integer().nullable()();
  IntColumn get unknownMinutes => integer().nullable()();

  /// Device or app that recorded the night, for attribution in the UI.
  TextColumn get sourceName => text().withDefault(const Constant(''))();

  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {night};
}

/// Settings + Pro singleton(s). The DB only ever holds one row per kind,
/// keyed by a fixed singleton-key sentinel — see
/// [AppDatabase.settingsSingletonKey] / [AppDatabase.proStatusSingletonKey].
/// `valueJson` is a hand-encoded JSON blob so we can evolve the shape
/// without churning the schema for every minor preference; per-field
/// extraction lives in the data-layer mapper.
@DataClassName('SingletonRow')
class Singletons extends Table {
  TextColumn get singletonKey => text()();
  TextColumn get valueJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {singletonKey};
}

/// CapyWake's local database.
///
/// Offline-first: no remote sync, no auth, no analytics. Tests open the DB
/// in-memory via [AppDatabase.forTesting]; production opens a file under the
/// platform's app-support directory.
@DriftDatabase(tables: [Alarms, AlarmOccurrences, SleepNights, Singletons])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test seam — pass an in-memory [QueryExecutor] so the suite stays
  /// headless and fast (no real file I/O, no platform plugins).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  /// A fresh database is the only supported origin. CapyWake shipped no
  /// earlier schema, so there is no version to upgrade from and deliberately
  /// no `onUpgrade` — see `test/data/migration_origin_test.dart`.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
  );

  /// Settings singleton key — the row in [Singletons] holding the JSON
  /// snapshot of [UserSettings].
  static const settingsSingletonKey = 'user_settings';

  /// Pro-status singleton key — the row in [Singletons] holding the JSON
  /// snapshot of [ProStatus].
  static const proStatusSingletonKey = 'pro_status';

  /// Wake-puzzle settings key — the row in [Singletons] holding the JSON
  /// snapshot of the app-wide `PuzzleSettings`.
  ///
  /// A singleton of its own rather than a field on the user-settings blob:
  /// `PuzzleSettings` validates on construction and so cannot be a `const`
  /// member of `UserSettings.initial`, and `ProStatus` already establishes
  /// "one concern, one singleton row" as the shape here.
  static const puzzleSettingsSingletonKey = 'puzzle_settings';

  /// Sleep-sync key — the row in [Singletons] holding the JSON snapshot of
  /// `SleepSyncState` (whether sleep reading is enabled, when it last
  /// succeeded, and the last failure category). One concern, one singleton
  /// row, as above.
  static const sleepSyncSingletonKey = 'sleep_sync';

  /// The QR Treasure Hunt checkpoint: a digest, never the code.
  static const qrCheckpointSingletonKey = 'qr_checkpoint';
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // `path_provider` is the standard Flutter way to find a writable
    // app-support directory. It is a no-op in our headless tests because
    // tests use `AppDatabase.forTesting` with an in-memory executor.
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'capywake.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
