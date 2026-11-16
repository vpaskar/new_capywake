import 'dart:async';

import 'package:capywake/core/sleep/sleep_aggregator.dart';
import 'package:capywake/core/sleep/sleep_gateway.dart';
import 'package:capywake/core/sleep/sleep_night.dart';
import 'package:capywake/core/sleep/sleep_sync_state.dart';
import 'package:meta/meta.dart';

/// Where aggregated nights and sync state are cached.
///
/// Declared here, implemented in `lib/data/`, so `lib/core/` stays Drift-free
/// and the service is unit-testable without a database.
abstract class SleepNightStore {
  Future<void> upsertNights(List<SleepNight> nights);

  Future<SleepSyncState> readSyncState();

  Future<void> writeSyncState(SleepSyncState state);

  /// Removes cached nights older than [before] (local-midnight key), so the
  /// cache cannot grow without bound.
  Future<void> pruneNightsBefore(DateTime before);
}

/// Outcome of one sync run. Carries counts and a category, never health
/// content, so it is safe to surface and persist.
@immutable
class SleepSyncOutcome {
  const SleepSyncOutcome({
    this.nightsWritten = 0,
    this.error,
    this.skipped = false,
  });

  /// The feature was off, or permission was absent, so nothing was read.
  const SleepSyncOutcome.skipped() : this(skipped: true);

  final int nightsWritten;

  final SleepSyncError? error;

  /// True when no platform call was made at all.
  final bool skipped;

  bool get succeeded => error == null && !skipped;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SleepSyncOutcome &&
        other.nightsWritten == nightsWritten &&
        other.error == error &&
        other.skipped == skipped;
  }

  @override
  int get hashCode => Object.hash(nightsWritten, error, skipped);

  @override
  String toString() =>
      'SleepSyncOutcome(nights: $nightsWritten, error: ${error?.name}, '
      'skipped: $skipped)';
}

/// Reads sleep from the platform store, aggregates it, and caches the result.
///
/// **Nothing happens while the feature is off.** [sync] returns
/// [SleepSyncOutcome.skipped] before touching the gateway, which is what makes
/// the off-by-default promise verifiable rather than aspirational.
///
/// Single-flight: a second [sync] during an in-flight run joins the first
/// rather than issuing a parallel health read.
class SleepSyncService {
  // Dart cannot pass a private named initializing formal (`this._gateway`), so
  // the fields are assigned in the initializer list instead.
  // ignore_for_file: prefer_initializing_formals
  SleepSyncService({
    required SleepGateway gateway,
    required SleepNightStore store,
    this.lookBackDays = defaultLookBackDays,
  }) : _gateway = gateway,
       _store = store,
       assert(lookBackDays > 0, 'lookBackDays must be > 0.');

  /// Matches `HistoryService.extendedWindowDays`, so History never shows a
  /// morning whose night was pruned from the cache.
  static const int defaultLookBackDays = 90;

  final SleepGateway _gateway;
  final SleepNightStore _store;

  /// How far back a read reaches.
  final int lookBackDays;

  Future<SleepSyncOutcome>? _inFlight;

  bool get isSyncing => _inFlight != null;

  /// Read, aggregate and cache. [now] is injected so tests are deterministic.
  Future<SleepSyncOutcome> sync({required DateTime now}) {
    final existing = _inFlight;
    if (existing != null) return existing;

    final run = _run(now: now);
    _inFlight = run;
    return run.whenComplete(() {
      _inFlight = null;
    });
  }

  Future<SleepSyncOutcome> _run({required DateTime now}) async {
    final state = await _store.readSyncState();
    if (!state.enabled) return const SleepSyncOutcome.skipped();

    // iOS returns null (undisclosed). Treat that as "try the read" — the read
    // itself returns empty when access was declined, and a null is not a no.
    final permitted = await _gateway.hasPermission();
    if (permitted == false) {
      await _store.writeSyncState(
        state.copyWith(lastError: SleepSyncError.permissionDenied),
      );
      return const SleepSyncOutcome(error: SleepSyncError.permissionDenied);
    }

    final nowUtc = now.toUtc();
    final start = nowUtc.subtract(Duration(days: lookBackDays));

    try {
      final segments = await _gateway.readSegments(start: start, end: nowUtc);
      final nights = SleepAggregator.aggregate(segments);

      await _store.upsertNights(nights);

      final local = now.toLocal();
      final pruneBefore = DateTime(
        local.year,
        local.month,
        local.day,
      ).subtract(Duration(days: lookBackDays));
      await _store.pruneNightsBefore(pruneBefore);

      await _store.writeSyncState(
        state.copyWith(lastSyncedAt: nowUtc, clearError: true),
      );
      return SleepSyncOutcome(nightsWritten: nights.length);
    } on SleepSyncException catch (e) {
      await _store.writeSyncState(state.copyWith(lastError: e.error));
      return SleepSyncOutcome(error: e.error);
    } on Object {
      await _store.writeSyncState(
        state.copyWith(lastError: SleepSyncError.unknown),
      );
      return const SleepSyncOutcome(error: SleepSyncError.unknown);
    }
  }

  /// Turn the feature on: asks for permission first and only enables when it
  /// is granted, so an enabled state always means a usable one.
  Future<bool> enable() async {
    final availability = await _gateway.availability();
    if (availability != SleepStoreAvailability.available) {
      final state = await _store.readSyncState();
      await _store.writeSyncState(
        state.copyWith(
          lastError: availability == SleepStoreAvailability.needsProvider
              ? SleepSyncError.providerUnavailable
              : SleepSyncError.unsupportedPlatform,
        ),
      );
      return false;
    }

    final granted = await _gateway.requestPermission();
    final state = await _store.readSyncState();
    if (!granted) {
      await _store.writeSyncState(
        state.copyWith(lastError: SleepSyncError.permissionDenied),
      );
      return false;
    }
    await _store.writeSyncState(
      state.copyWith(enabled: true, clearError: true),
    );
    return true;
  }

  /// Turn the feature off and forget every cached night.
  ///
  /// The data is dropped rather than kept dormant: a user who switches this
  /// off is withdrawing consent, and leaving their sleep in our database would
  /// not honour that.
  Future<void> disable() async {
    final state = await _store.readSyncState();
    await _store.writeSyncState(
      state.copyWith(
        enabled: false,
        clearError: true,
        clearLastSynced: true,
      ),
    );
    await _store.pruneNightsBefore(
      DateTime.now().toUtc().add(const Duration(days: 365 * 100)),
    );
  }
}
