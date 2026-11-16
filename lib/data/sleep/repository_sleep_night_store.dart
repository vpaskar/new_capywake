import 'package:capywake/core/sleep/sleep.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';

/// Adapts [CapyWakeRepository] to the core-declared [SleepNightStore].
///
/// Exists so `SleepSyncService` can be unit-tested against an in-memory store
/// while production goes through Drift, and so `lib/core/` keeps no knowledge
/// of the repository.
class RepositorySleepNightStore implements SleepNightStore {
  const RepositorySleepNightStore(this._repository);

  final CapyWakeRepository _repository;

  @override
  Future<void> upsertNights(List<SleepNight> nights) {
    return _repository.upsertSleepNights(nights);
  }

  @override
  Future<SleepSyncState> readSyncState() => _repository.getSleepSyncState();

  @override
  Future<void> writeSyncState(SleepSyncState state) {
    return _repository.saveSleepSyncState(state);
  }

  @override
  Future<void> pruneNightsBefore(DateTime before) {
    return _repository.pruneSleepNightsBefore(before);
  }
}
