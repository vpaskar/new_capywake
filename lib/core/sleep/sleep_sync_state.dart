import 'package:capywake/core/sleep/sleep_gateway.dart';
import 'package:meta/meta.dart';

/// Persisted state of the sleep-reading feature.
///
/// **[enabled] defaults to false.** CapyWake reads nothing until the user turns
/// this on and grants permission, which is what keeps the offline-first promise
/// honest: an owner who never opens this setting has an app that behaves
/// exactly as it did before the feature existed.
@immutable
class SleepSyncState {
  const SleepSyncState({
    this.enabled = false,
    this.lastSyncedAt,
    this.lastError,
  });

  /// The off-by-default initial state.
  static const SleepSyncState initial = SleepSyncState();

  /// Whether the user has opted in to reading sleep from the health store.
  final bool enabled;

  /// When a read last succeeded, UTC. Null before the first one.
  final DateTime? lastSyncedAt;

  /// Category of the last failure, or null when the last attempt succeeded.
  /// Carries no health content.
  final SleepSyncError? lastError;

  SleepSyncState copyWith({
    bool? enabled,
    DateTime? lastSyncedAt,
    SleepSyncError? lastError,
    bool clearError = false,
    bool clearLastSynced = false,
  }) {
    return SleepSyncState(
      enabled: enabled ?? this.enabled,
      lastSyncedAt: clearLastSynced
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SleepSyncState &&
        other.enabled == enabled &&
        other.lastSyncedAt == lastSyncedAt &&
        other.lastError == lastError;
  }

  @override
  int get hashCode => Object.hash(enabled, lastSyncedAt, lastError);

  @override
  String toString() =>
      'SleepSyncState(enabled: $enabled, error: ${lastError?.name})';
}
