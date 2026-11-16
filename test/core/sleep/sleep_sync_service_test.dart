import 'package:capywake/core/sleep/sleep.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [SleepNightStore], so the service is tested without Drift.
class _FakeStore implements SleepNightStore {
  // Dart cannot pass a private named initializing formal (`this._state`).
  // ignore_for_file: prefer_initializing_formals
  _FakeStore({SleepSyncState state = SleepSyncState.initial}) : _state = state;

  SleepSyncState _state;
  final List<SleepNight> nights = [];
  final List<DateTime> pruneCalls = [];
  int writeStateCount = 0;

  @override
  Future<SleepSyncState> readSyncState() async => _state;

  @override
  Future<void> writeSyncState(SleepSyncState state) async {
    writeStateCount++;
    _state = state;
  }

  SleepSyncState get state => _state;

  @override
  Future<void> upsertNights(List<SleepNight> incoming) async {
    nights
      ..clear()
      ..addAll(incoming);
  }

  @override
  Future<void> pruneNightsBefore(DateTime before) async {
    pruneCalls.add(before);
  }
}

/// Throws a plain [StateError], not a [SleepSyncException], to exercise the
/// service's catch-all.
class _ThrowingGateway implements SleepGateway {
  @override
  Future<SleepStoreAvailability> availability() async =>
      SleepStoreAvailability.available;

  @override
  Future<bool?> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<List<SleepSegment>> readSegments({
    required DateTime start,
    required DateTime end,
  }) async => throw StateError('platform blew up');

  @override
  Future<bool> openPermissionSettings() async => false;
}

SleepSegment _night(int day, {String source = 'Watch'}) => SleepSegment(
  start: DateTime(2026, 3, day, 23).toUtc(),
  end: DateTime(2026, 3, day + 1, 7).toUtc(),
  stage: SleepStage.asleep,
  sourceName: source,
);

void main() {
  final now = DateTime(2026, 3, 15, 9);

  group('SleepSyncService.sync', () {
    test('does nothing at all while the feature is off', () async {
      final gateway = FakeSleepGateway(segments: [_night(9)]);
      final store = _FakeStore();
      final service = SleepSyncService(gateway: gateway, store: store);

      final outcome = await service.sync(now: now);

      expect(outcome.skipped, isTrue);
      expect(outcome.succeeded, isFalse);
      // The acceptance criterion: an opted-out user reaches no health API.
      expect(gateway.totalPlatformCalls, 0);
      expect(store.nights, isEmpty);
      expect(store.writeStateCount, 0);
    });

    test('reads, aggregates and caches when enabled', () async {
      final gateway = FakeSleepGateway(
        segments: [_night(9), _night(10)],
      );
      final store = _FakeStore(
        state: const SleepSyncState(enabled: true),
      );
      final service = SleepSyncService(gateway: gateway, store: store);

      final outcome = await service.sync(now: now);

      expect(outcome.succeeded, isTrue);
      expect(outcome.nightsWritten, 2);
      expect(store.nights, hasLength(2));
      expect(store.state.lastSyncedAt, now.toUtc());
      expect(store.state.lastError, isNull);
    });

    test('records a denied permission without reading', () async {
      final gateway = FakeSleepGateway(permission: false)
        ..setSegments([_night(9)]);
      final store = _FakeStore(state: const SleepSyncState(enabled: true));
      final service = SleepSyncService(gateway: gateway, store: store);

      final outcome = await service.sync(now: now);

      expect(outcome.error, SleepSyncError.permissionDenied);
      expect(gateway.readCallCount, 0);
      expect(store.state.lastError, SleepSyncError.permissionDenied);
    });

    test('an undisclosed (null) permission still attempts the read', () async {
      // iOS never says whether READ was granted. Treating null as "no" would
      // make the feature permanently dead there.
      final gateway = FakeSleepGateway(
        permission: null,
        segments: [_night(9)],
      );
      final store = _FakeStore(state: const SleepSyncState(enabled: true));
      final service = SleepSyncService(gateway: gateway, store: store);

      final outcome = await service.sync(now: now);

      expect(gateway.readCallCount, 1);
      expect(outcome.succeeded, isTrue);
    });

    test('an empty read is a success, not a failure', () async {
      final gateway = FakeSleepGateway();
      final store = _FakeStore(state: const SleepSyncState(enabled: true));
      final service = SleepSyncService(gateway: gateway, store: store);

      final outcome = await service.sync(now: now);

      expect(outcome.succeeded, isTrue);
      expect(outcome.nightsWritten, 0);
      expect(store.state.lastError, isNull);
    });

    test('an unexpected error is recorded as unknown, not rethrown', () async {
      // A gateway that throws something other than SleepSyncException must
      // not take History down with it.
      final store = _FakeStore(state: const SleepSyncState(enabled: true));
      final service = SleepSyncService(
        gateway: _ThrowingGateway(),
        store: store,
      );

      final outcome = await service.sync(now: now);

      expect(outcome.error, SleepSyncError.unknown);
      expect(store.state.lastError, SleepSyncError.unknown);
    });

    test('a gateway failure is recorded as its category', () async {
      final gateway = FakeSleepGateway()..failNextRead = SleepSyncError.timeout;
      final store = _FakeStore(state: const SleepSyncState(enabled: true));
      final service = SleepSyncService(gateway: gateway, store: store);

      final outcome = await service.sync(now: now);

      expect(outcome.error, SleepSyncError.timeout);
      expect(store.state.lastError, SleepSyncError.timeout);
    });

    test('a later success clears the stored error', () async {
      final gateway = FakeSleepGateway(segments: [_night(9)])
        ..failNextRead = SleepSyncError.storeUnavailable;
      final store = _FakeStore(state: const SleepSyncState(enabled: true));
      final service = SleepSyncService(gateway: gateway, store: store);

      await service.sync(now: now);
      expect(store.state.lastError, SleepSyncError.storeUnavailable);

      final second = await service.sync(now: now);

      expect(second.succeeded, isTrue);
      expect(store.state.lastError, isNull);
    });

    test('prunes the cache to the look-back window', () async {
      final gateway = FakeSleepGateway(segments: [_night(9)]);
      final store = _FakeStore(state: const SleepSyncState(enabled: true));
      final service = SleepSyncService(
        gateway: gateway,
        store: store,
        lookBackDays: 30,
      );

      await service.sync(now: now);

      expect(store.pruneCalls, hasLength(1));
      expect(
        store.pruneCalls.single,
        DateTime(2026, 3, 15).subtract(const Duration(days: 30)),
      );
    });

    test('a concurrent sync joins the in-flight run', () async {
      final gateway = FakeSleepGateway(segments: [_night(9)]);
      final store = _FakeStore(state: const SleepSyncState(enabled: true));
      final service = SleepSyncService(gateway: gateway, store: store);

      final results = await Future.wait([
        service.sync(now: now),
        service.sync(now: now),
      ]);

      expect(gateway.readCallCount, 1);
      expect(results.first, results.last);
      expect(service.isSyncing, isFalse);
    });
  });

  group('SleepSyncService.enable', () {
    test('enables and reads once permission is granted', () async {
      final gateway = FakeSleepGateway(
        permission: false,
        segments: [_night(9)],
      );
      final store = _FakeStore();
      final service = SleepSyncService(gateway: gateway, store: store);

      final enabled = await service.enable();

      expect(enabled, isTrue);
      expect(store.state.enabled, isTrue);
      expect(gateway.permissionRequestCount, 1);
    });

    test('stays off when permission is declined', () async {
      final gateway = FakeSleepGateway(permissionRequestResult: false);
      final store = _FakeStore();
      final service = SleepSyncService(gateway: gateway, store: store);

      final enabled = await service.enable();

      expect(enabled, isFalse);
      expect(store.state.enabled, isFalse);
      expect(store.state.lastError, SleepSyncError.permissionDenied);
    });

    test('reports a missing Health Connect provider', () async {
      final gateway = FakeSleepGateway(
        storeAvailability: SleepStoreAvailability.needsProvider,
      );
      final store = _FakeStore();
      final service = SleepSyncService(gateway: gateway, store: store);

      expect(await service.enable(), isFalse);
      expect(store.state.lastError, SleepSyncError.providerUnavailable);
      expect(gateway.permissionRequestCount, 0);
    });

    test('reports an unsupported platform', () async {
      final gateway = FakeSleepGateway(
        storeAvailability: SleepStoreAvailability.unsupported,
      );
      final store = _FakeStore();
      final service = SleepSyncService(gateway: gateway, store: store);

      expect(await service.enable(), isFalse);
      expect(store.state.lastError, SleepSyncError.unsupportedPlatform);
    });
  });

  group('SleepSyncService.disable', () {
    test('turns the feature off and drops every cached night', () async {
      final gateway = FakeSleepGateway(segments: [_night(9)]);
      final store = _FakeStore(state: const SleepSyncState(enabled: true));
      final service = SleepSyncService(gateway: gateway, store: store);
      await service.sync(now: now);
      expect(store.nights, isNotEmpty);

      await service.disable();

      expect(store.state.enabled, isFalse);
      expect(store.state.lastSyncedAt, isNull);
      expect(store.state.lastError, isNull);
      // Opting out withdraws consent, so the cache is cleared with a prune
      // boundary far in the future rather than left dormant.
      expect(store.pruneCalls.last.isAfter(DateTime.now()), isTrue);
    });

    test('a sync after disabling reads nothing', () async {
      final gateway = FakeSleepGateway(segments: [_night(9)]);
      final store = _FakeStore(state: const SleepSyncState(enabled: true));
      final service = SleepSyncService(gateway: gateway, store: store);
      await service.sync(now: now);
      final readsBefore = gateway.readCallCount;

      await service.disable();
      final outcome = await service.sync(now: now);

      expect(outcome.skipped, isTrue);
      expect(gateway.readCallCount, readsBefore);
    });
  });

  group('SleepSyncOutcome', () {
    test('value equality compares every field', () {
      const base = SleepSyncOutcome(
        nightsWritten: 2,
        error: SleepSyncError.timeout,
      );

      expect(
        base,
        const SleepSyncOutcome(
          nightsWritten: 2,
          error: SleepSyncError.timeout,
        ),
      );
      expect(
        base.hashCode,
        const SleepSyncOutcome(
          nightsWritten: 2,
          error: SleepSyncError.timeout,
        ).hashCode,
      );
      // One differing field at a time.
      expect(
        base,
        isNot(
          const SleepSyncOutcome(
            nightsWritten: 1,
            error: SleepSyncError.timeout,
          ),
        ),
      );
      expect(base, isNot(const SleepSyncOutcome(nightsWritten: 2)));
      expect(
        base,
        isNot(
          const SleepSyncOutcome(
            nightsWritten: 2,
            error: SleepSyncError.timeout,
            skipped: true,
          ),
        ),
      );
      expect(base, isNot(Object()));
      expect(base == base, isTrue);
      expect(const SleepSyncOutcome.skipped().skipped, isTrue);
    });

    test('toString carries counts but no health content', () {
      const outcome = SleepSyncOutcome(nightsWritten: 3);
      expect(outcome.toString(), contains('3'));
    });
  });
}
