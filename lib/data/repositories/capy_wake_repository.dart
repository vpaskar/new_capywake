import 'dart:convert';

import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/sleep/sleep.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/database/mappers.dart';
import 'package:drift/drift.dart';

/// Single read/write entry-point for the persisted CapyWake state.
///
/// Wraps the Drift [AppDatabase] and keeps the data-layer mapping concerns
/// (rows ↔ core models, JSON for singletons) out of the rest of the app.
/// `lib/core` and `lib/features` should depend only on this class — never on
/// Drift directly.
class CapyWakeRepository {
  CapyWakeRepository(this._db);

  final AppDatabase _db;

  // ---------- Alarms ----------

  /// One-shot read of every alarm, oldest first by [Alarm.createdAt].
  Future<List<Alarm>> listAlarms() async {
    final rows = await (_db.select(
      _db.alarms,
    )..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
    return rows.map(AlarmMapper.fromRow).toList();
  }

  /// Reactive stream of every alarm. Drift emits an event on every commit
  /// that touches the `alarms` table — what the alarm-list screen and the
  /// Today screen will subscribe to.
  Stream<List<Alarm>> watchAlarms() {
    return (_db.select(_db.alarms)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch()
        .map((rows) => rows.map(AlarmMapper.fromRow).toList());
  }

  /// Fetch a single alarm by id, or `null` when the row no longer exists
  /// (e.g. the user deleted it on another device — won't happen in MVP, but
  /// the API stays honest).
  Future<Alarm?> getAlarm(String id) async {
    final row = await (_db.select(
      _db.alarms,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : AlarmMapper.fromRow(row);
  }

  /// Insert-or-update by primary key. Used by both "create alarm" and
  /// "edit alarm" without changing the API surface.
  Future<void> upsertAlarm(Alarm alarm) async {
    await _db
        .into(_db.alarms)
        .insertOnConflictUpdate(AlarmMapper.toCompanion(alarm));
  }

  /// Delete an alarm by id. Cascades to its occurrences in [deleteAlarm] —
  /// the schema does not declare an `ON DELETE CASCADE` so we do it here in
  /// a single transaction (predictable; trivial to test).
  Future<void> deleteAlarm(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.alarmOccurrences,
      )..where((t) => t.alarmId.equals(id))).go();
      await (_db.delete(_db.alarms)..where((t) => t.id.equals(id))).go();
    });
  }

  // ---------- Occurrences ----------

  Future<List<AlarmOccurrence>> listOccurrencesForAlarm(
    String alarmId, {
    Set<AlarmStatus>? statuses,
  }) async {
    final rows =
        await (_db.select(_db.alarmOccurrences)
              ..where((t) {
                final alarm = t.alarmId.equals(alarmId);
                if (statuses == null) return alarm;
                return alarm &
                    t.status.isIn(statuses.map((status) => status.name));
              })
              ..orderBy([(t) => OrderingTerm(expression: t.scheduledAt)]))
            .get();
    return rows.map(AlarmOccurrenceMapper.fromRow).toList();
  }

  Stream<List<AlarmOccurrence>> watchOccurrencesForAlarm(String alarmId) {
    return (_db.select(_db.alarmOccurrences)
          ..where((t) => t.alarmId.equals(alarmId))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledAt)]))
        .watch()
        .map((rows) => rows.map(AlarmOccurrenceMapper.fromRow).toList());
  }

  /// Reactive stream of every **finished** occurrence (across alarms), oldest
  /// first — the terminal states, so skipped ahead of time as well as
  /// dismissed, escaped and missed once they rang.
  ///
  /// Both the Today card and `AlarmScheduleCoordinator` read this and pass it
  /// to the schedule engine, which walks past the ring each row belongs to.
  /// One stream rather than a skipped-only one because "this morning is over"
  /// is a single fact: a ring the user pre-emptively skipped and a ring they
  /// got up and dismissed both mean the engine must look further ahead.
  Stream<List<AlarmOccurrence>> watchFinishedOccurrences() {
    final terminal = AlarmStatus.values
        .where((s) => s.isTerminal)
        .map((s) => s.name)
        .toList();
    return (_db.select(_db.alarmOccurrences)
          ..where((t) => t.status.isIn(terminal))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledAt)]))
        .watch()
        .map((rows) => rows.map(AlarmOccurrenceMapper.fromRow).toList());
  }

  /// Reactive stream of every `snoozed` [AlarmOccurrence] across alarms,
  /// oldest first by the instant it is due to ring again.
  ///
  /// A snoozed row is the *live* next ring for its alarm — sooner than
  /// anything the schedule engine computes — so
  /// `AlarmScheduleCoordinator.sync` folds this in and arms it instead of the
  /// alarm's next scheduled occurrence. Without it the ring the user asked for
  /// by pressing Snooze never reaches the platform: writing the row re-emits
  /// the occurrence streams, which makes the coordinator reschedule, and
  /// rescheduling clears everything previously armed.
  ///
  /// Rows are *not* filtered by time here. Whether a snooze instant has
  /// already passed is a decision about the clock, and the clock belongs to
  /// the coordinator (which holds the injected `now`); a `where` on
  /// `scheduledAt` would also only be re-evaluated when the table changed, so
  /// a row could silently go stale without the stream noticing.
  Stream<List<AlarmOccurrence>> watchSnoozedOccurrences() {
    return (_db.select(_db.alarmOccurrences)
          ..where((t) => t.status.equals(AlarmStatus.snoozed.name))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledAt)]))
        .watch()
        .map((rows) => rows.map(AlarmOccurrenceMapper.fromRow).toList());
  }

  /// Reactive stream of every occurrence (across alarms), oldest first by
  /// scheduled time. The History screen subscribes to this and aggregates
  /// the rows into a calm, non-judgmental summary.
  Stream<List<AlarmOccurrence>> watchAllOccurrences() {
    return (_db.select(_db.alarmOccurrences)
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledAt)]))
        .watch()
        .map((rows) => rows.map(AlarmOccurrenceMapper.fromRow).toList());
  }

  Future<void> upsertOccurrence(AlarmOccurrence occurrence) async {
    await _db
        .into(_db.alarmOccurrences)
        .insertOnConflictUpdate(AlarmOccurrenceMapper.toCompanion(occurrence));
  }

  Future<void> deleteOccurrence(String id) async {
    await (_db.delete(
      _db.alarmOccurrences,
    )..where((t) => t.id.equals(id))).go();
  }

  // ---------- Settings (singleton) ----------

  Future<UserSettings> getSettings() async {
    final row = await _readSingleton(AppDatabase.settingsSingletonKey);
    if (row == null) return UserSettings.initial;
    return UserSettingsMapper.fromJson(row.valueJson);
  }

  Stream<UserSettings> watchSettings() {
    return _watchSingleton(AppDatabase.settingsSingletonKey).map(
      (row) => row == null
          ? UserSettings.initial
          : UserSettingsMapper.fromJson(row.valueJson),
    );
  }

  Future<void> saveSettings(UserSettings settings, {DateTime? now}) async {
    await _writeSingleton(
      AppDatabase.settingsSingletonKey,
      UserSettingsMapper.toJson(settings),
      now,
    );
  }

  // ---------- Wake-puzzle settings (singleton) ----------

  Future<PuzzleSettings> getPuzzleSettings() async {
    final row = await _readSingleton(AppDatabase.puzzleSettingsSingletonKey);
    if (row == null) return PuzzleSettings.defaults();
    return PuzzleSettingsMapper.fromJson(row.valueJson);
  }

  Stream<PuzzleSettings> watchPuzzleSettings() {
    return _watchSingleton(AppDatabase.puzzleSettingsSingletonKey).map(
      (row) => row == null
          ? PuzzleSettings.defaults()
          : PuzzleSettingsMapper.fromJson(row.valueJson),
    );
  }

  Future<void> savePuzzleSettings(
    PuzzleSettings settings, {
    DateTime? now,
  }) async {
    await _writeSingleton(
      AppDatabase.puzzleSettingsSingletonKey,
      PuzzleSettingsMapper.toJson(settings),
      now,
    );
  }

  // ---------- QR Treasure Hunt checkpoint (singleton) ----------

  Future<QrCheckpoint?> getQrCheckpoint() async => _qrCheckpointOf(
    await _readSingleton(AppDatabase.qrCheckpointSingletonKey),
  );

  Stream<QrCheckpoint?> watchQrCheckpoint() => _watchSingleton(
    AppDatabase.qrCheckpointSingletonKey,
  ).map(_qrCheckpointOf);

  Future<void> saveQrCheckpoint(QrCheckpoint checkpoint, {DateTime? now}) =>
      _writeSingleton(
        AppDatabase.qrCheckpointSingletonKey,
        jsonEncode(checkpoint.toJson()),
        now,
      );

  static QrCheckpoint? _qrCheckpointOf(SingletonRow? row) => row == null
      ? null
      : QrCheckpoint.fromJson(
          (jsonDecode(row.valueJson) as Map).cast<String, Object?>(),
        );

  // ---------- Pro status (singleton) ----------

  Future<ProStatus> getProStatus() async {
    final row = await _readSingleton(AppDatabase.proStatusSingletonKey);
    if (row == null) return ProStatus.initial;
    return ProStatusMapper.fromJson(row.valueJson);
  }

  Stream<ProStatus> watchProStatus() {
    return _watchSingleton(AppDatabase.proStatusSingletonKey).map(
      (row) => row == null
          ? ProStatus.initial
          : ProStatusMapper.fromJson(row.valueJson),
    );
  }

  Future<void> saveProStatus(ProStatus status, {DateTime? now}) async {
    await _writeSingleton(
      AppDatabase.proStatusSingletonKey,
      ProStatusMapper.toJson(status),
      now,
    );
  }

  // ---------- Sleep nights (read-only cache of health-store data) ----------

  /// Cached nights, oldest first. Empty when the feature is off or the user
  /// has no wearable — both normal, neither an error.
  Future<List<SleepNight>> listSleepNights() async {
    final rows = await (_db.select(
      _db.sleepNights,
    )..orderBy([(t) => OrderingTerm(expression: t.night)])).get();
    return rows.map(SleepNightMapper.fromRow).toList();
  }

  /// Reactive stream of cached nights, oldest first.
  Stream<List<SleepNight>> watchSleepNights() {
    return (_db.select(_db.sleepNights)
          ..orderBy([(t) => OrderingTerm(expression: t.night)]))
        .watch()
        .map((rows) => rows.map(SleepNightMapper.fromRow).toList());
  }

  /// Insert-or-replace by night. One transaction, so History never observes a
  /// half-written sync.
  Future<void> upsertSleepNights(
    List<SleepNight> nights, {
    DateTime? now,
  }) async {
    if (nights.isEmpty) return;
    await _db.transaction(() async {
      for (final night in nights) {
        await _db
            .into(_db.sleepNights)
            .insertOnConflictUpdate(
              SleepNightMapper.toCompanion(night, now: now),
            );
      }
    });
  }

  /// Drop cached nights whose key is before [before], bounding cache growth.
  /// Also the mechanism that clears everything when the user opts out.
  Future<void> pruneSleepNightsBefore(DateTime before) async {
    await (_db.delete(
      _db.sleepNights,
    )..where((t) => t.night.isSmallerThanValue(before))).go();
  }

  // ---------- Sleep sync state (singleton) ----------

  Future<SleepSyncState> getSleepSyncState() async {
    final row = await _readSingleton(AppDatabase.sleepSyncSingletonKey);
    if (row == null) return SleepSyncState.initial;
    return SleepSyncStateMapper.fromJson(row.valueJson);
  }

  Stream<SleepSyncState> watchSleepSyncState() {
    return _watchSingleton(AppDatabase.sleepSyncSingletonKey).map(
      (row) => row == null
          ? SleepSyncState.initial
          : SleepSyncStateMapper.fromJson(row.valueJson),
    );
  }

  Future<void> saveSleepSyncState(SleepSyncState state, {DateTime? now}) async {
    await _writeSingleton(
      AppDatabase.sleepSyncSingletonKey,
      SleepSyncStateMapper.toJson(state),
      now,
    );
  }

  // ---------- Singleton helpers ----------

  Future<SingletonRow?> _readSingleton(String key) {
    return (_db.select(
      _db.singletons,
    )..where((t) => t.singletonKey.equals(key))).getSingleOrNull();
  }

  Stream<SingletonRow?> _watchSingleton(String key) {
    return (_db.select(
      _db.singletons,
    )..where((t) => t.singletonKey.equals(key))).watchSingleOrNull();
  }

  Future<void> _writeSingleton(
    String key,
    String valueJson,
    DateTime? now,
  ) async {
    await _db
        .into(_db.singletons)
        .insertOnConflictUpdate(
          SingletonsCompanion(
            singletonKey: Value(key),
            valueJson: Value(valueJson),
            updatedAt: Value((now ?? DateTime.now()).toUtc()),
          ),
        );
  }
}
