import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/sleep/sleep.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/data/sleep/repository_sleep_night_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod 3 (no codegen) provider graph for the data layer.
///
/// Tests override [appDatabaseProvider] with an `AppDatabase.forTesting(
/// NativeDatabase.memory())` so the suite stays headless and fast — no real
/// file I/O, no `path_provider` plugin call.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// The single repository the rest of the app reads/writes through.
final capywakeRepositoryProvider = Provider<CapyWakeRepository>((ref) {
  return CapyWakeRepository(ref.watch(appDatabaseProvider));
});

/// Streams ----

final alarmsStreamProvider = StreamProvider<List<Alarm>>((ref) {
  return ref.watch(capywakeRepositoryProvider).watchAlarms();
});

final userSettingsStreamProvider = StreamProvider<UserSettings>((ref) {
  return ref.watch(capywakeRepositoryProvider).watchSettings();
});

final proStatusStreamProvider = StreamProvider<ProStatus>((ref) {
  return ref.watch(capywakeRepositoryProvider).watchProStatus();
});

/// The persisted app-wide wake-puzzle settings.
///
/// `puzzleSettingsProvider` (the notifier the ringing surface and the debug
/// gallery read) folds this stream in, so a change made in Settings reaches
/// the next alarm without anything having to remember to republish it.
final puzzleSettingsStreamProvider = StreamProvider<PuzzleSettings>((ref) {
  return ref.watch(capywakeRepositoryProvider).watchPuzzleSettings();
});

/// Stream of every finished (terminal) `AlarmOccurrence` across alarms,
/// oldest first.
///
/// Read by the Today card and by `AlarmScheduleCoordinator`, which both hand
/// it to the schedule engine so a ring that is already over — skipped, or
/// dismissed / escaped / missed — is not offered as the next one. See
/// `CapyWakeRepository.watchFinishedOccurrences`.
final finishedOccurrencesStreamProvider = StreamProvider<List<AlarmOccurrence>>(
  (ref) {
    return ref.watch(capywakeRepositoryProvider).watchFinishedOccurrences();
  },
);

/// Stream of every `snoozed` `AlarmOccurrence` across alarms, oldest first.
///
/// Feeds `AlarmScheduleCoordinator.sync`, which arms the snooze ring in place
/// of the alarm's next scheduled occurrence. See
/// `CapyWakeRepository.watchSnoozedOccurrences`.
final snoozedOccurrencesStreamProvider = StreamProvider<List<AlarmOccurrence>>((
  ref,
) {
  return ref.watch(capywakeRepositoryProvider).watchSnoozedOccurrences();
});

/// Stream of every `AlarmOccurrence` across alarms, oldest first by
/// scheduled time. Used by the History screen to compute calm summaries.
final allOccurrencesStreamProvider = StreamProvider<List<AlarmOccurrence>>((
  ref,
) {
  return ref.watch(capywakeRepositoryProvider).watchAllOccurrences();
});

/// Sleep ----
///
/// The platform read path is not wired yet: `sleepGatewayProvider` and
/// `sleepSyncServiceProvider` arrive with `LiveSleepGateway` in the phase that
/// adds `package:health`. What exists here reads only the local cache, so
/// nothing touches the health store.

final sleepNightStoreProvider = Provider<SleepNightStore>((ref) {
  return RepositorySleepNightStore(ref.watch(capywakeRepositoryProvider));
});

/// Persisted opt-in state for sleep reading.
final sleepSyncStateStreamProvider = StreamProvider<SleepSyncState>((ref) {
  return ref.watch(capywakeRepositoryProvider).watchSleepSyncState();
});

/// Cached nights, oldest first. Empty while the feature is off.
final sleepNightsStreamProvider = StreamProvider<List<SleepNight>>((ref) {
  return ref.watch(capywakeRepositoryProvider).watchSleepNights();
});
