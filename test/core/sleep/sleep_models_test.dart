import 'package:capywake/core/sleep/sleep.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SleepStage', () {
    test('only real sleep stages count as asleep', () {
      expect(SleepStage.asleep.isAsleep, isTrue);
      expect(SleepStage.deep.isAsleep, isTrue);
      expect(SleepStage.light.isAsleep, isTrue);
      expect(SleepStage.rem.isAsleep, isTrue);
      expect(SleepStage.awake.isAsleep, isFalse);
      expect(SleepStage.inBed.isAsleep, isFalse);
      expect(SleepStage.unknown.isAsleep, isFalse);
    });

    test('only deep, light and REM are phases worth breaking down', () {
      expect(SleepStage.deep.isPhase, isTrue);
      expect(SleepStage.light.isPhase, isTrue);
      expect(SleepStage.rem.isPhase, isTrue);
      // Undifferentiated asleep is not a phase: a device reporting only this
      // has no breakdown to show.
      expect(SleepStage.asleep.isPhase, isFalse);
      expect(SleepStage.awake.isPhase, isFalse);
      expect(SleepStage.inBed.isPhase, isFalse);
      expect(SleepStage.unknown.isPhase, isFalse);
    });
  });

  group('SleepSegment', () {
    test('duration is whole minutes', () {
      final segment = SleepSegment(
        start: DateTime.utc(2026, 3, 10, 1),
        end: DateTime.utc(2026, 3, 10, 2, 30),
        stage: SleepStage.asleep,
        sourceName: 'Watch',
      );
      expect(segment.durationMinutes, 90);
    });

    test('a sub-minute span truncates to zero', () {
      final segment = SleepSegment(
        start: DateTime.utc(2026, 3, 10, 1),
        end: DateTime.utc(2026, 3, 10, 1, 0, 30),
        stage: SleepStage.asleep,
        sourceName: 'Watch',
      );
      expect(segment.durationMinutes, 0);
    });

    test('an end before the start is rejected', () {
      expect(
        () => SleepSegment(
          start: DateTime.utc(2026, 3, 10, 2),
          end: DateTime.utc(2026, 3, 10, 1),
          stage: SleepStage.asleep,
          sourceName: 'Watch',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('value equality', () {
      SleepSegment make() => SleepSegment(
        start: DateTime.utc(2026, 3, 10, 1),
        end: DateTime.utc(2026, 3, 10, 2),
        stage: SleepStage.deep,
        sourceName: 'Watch',
      );
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
    });

    test('toString leaks no times or durations', () {
      final segment = SleepSegment(
        start: DateTime.utc(2026, 3, 10, 1),
        end: DateTime.utc(2026, 3, 10, 2),
        stage: SleepStage.deep,
        sourceName: 'Watch',
      );
      final text = segment.toString();
      expect(text, contains('deep'));
      expect(text, isNot(contains('2026')));
      expect(text, isNot(contains('Watch')));
    });
  });

  group('SleepNight', () {
    SleepNight make({Map<SleepStage, int> stages = const {}}) => SleepNight(
      night: DateTime(2026, 3, 10),
      asleepAt: DateTime.utc(2026, 3, 9, 23),
      wokeAt: DateTime.utc(2026, 3, 10, 7),
      totalAsleepMinutes: 480,
      timeInBedMinutes: 500,
      sourceName: 'Watch',
      stageMinutes: stages,
    );

    test('a night with no phases reports no breakdown', () {
      expect(make().hasPhaseBreakdown, isFalse);
      expect(
        make(stages: {SleepStage.asleep: 480}).hasPhaseBreakdown,
        isFalse,
      );
    });

    test('a night with a phase reports a breakdown', () {
      expect(make(stages: {SleepStage.deep: 90}).hasPhaseBreakdown, isTrue);
    });

    test('a zero-minute phase does not count as a breakdown', () {
      expect(make(stages: {SleepStage.deep: 0}).hasPhaseBreakdown, isFalse);
    });

    test('minutesFor returns zero for an unreported stage', () {
      expect(make().minutesFor(SleepStage.rem), 0);
      expect(make(stages: {SleepStage.rem: 70}).minutesFor(SleepStage.rem), 70);
    });

    test('stageMinutes is unmodifiable', () {
      final night = make(stages: {SleepStage.deep: 90});
      expect(
        () => night.stageMinutes[SleepStage.rem] = 10,
        throwsUnsupportedError,
      );
    });

    test('a UTC night key is rejected — the key is a local date', () {
      expect(
        () => SleepNight(
          night: DateTime.utc(2026, 3, 10),
          asleepAt: DateTime.utc(2026, 3, 9, 23),
          wokeAt: DateTime.utc(2026, 3, 10, 7),
          totalAsleepMinutes: 480,
          timeInBedMinutes: 480,
          sourceName: 'Watch',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a negative total is rejected', () {
      expect(
        () => SleepNight(
          night: DateTime(2026, 3, 10),
          asleepAt: DateTime.utc(2026, 3, 9, 23),
          wokeAt: DateTime.utc(2026, 3, 10, 7),
          totalAsleepMinutes: -1,
          timeInBedMinutes: 0,
          sourceName: 'Watch',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('value equality includes the stage map', () {
      expect(
        make(stages: {SleepStage.deep: 90}),
        make(stages: {SleepStage.deep: 90}),
      );
      expect(
        make(stages: {SleepStage.deep: 90}).hashCode,
        make(stages: {SleepStage.deep: 90}).hashCode,
      );
      expect(
        make(stages: {SleepStage.deep: 90}),
        isNot(make(stages: {SleepStage.deep: 91})),
      );
      expect(
        make(stages: {SleepStage.deep: 90}),
        isNot(make(stages: {SleepStage.deep: 90, SleepStage.rem: 10})),
      );
      expect(make(), isNot(Object()));
    });

    test('toString leaks no durations', () {
      expect(make().toString(), isNot(contains('480')));
    });
  });

  group('SleepSyncState', () {
    test('starts off, with nothing read and no error', () {
      const state = SleepSyncState.initial;
      expect(state.enabled, isFalse);
      expect(state.lastSyncedAt, isNull);
      expect(state.lastError, isNull);
    });

    test('copyWith can clear the error and the last-synced stamp', () {
      final state = SleepSyncState(
        enabled: true,
        lastSyncedAt: DateTime.utc(2026, 3, 10),
        lastError: SleepSyncError.timeout,
      );

      expect(state.copyWith(clearError: true).lastError, isNull);
      expect(state.copyWith(clearLastSynced: true).lastSyncedAt, isNull);
      expect(state.copyWith(enabled: false).enabled, isFalse);
      // An unspecified field is carried over.
      expect(state.copyWith(enabled: false).lastError, SleepSyncError.timeout);
    });

    test('value equality compares every field', () {
      final synced = DateTime.utc(2026, 3, 10);
      final base = SleepSyncState(
        enabled: true,
        lastSyncedAt: synced,
        lastError: SleepSyncError.timeout,
      );

      expect(
        base,
        SleepSyncState(
          enabled: true,
          lastSyncedAt: synced,
          lastError: SleepSyncError.timeout,
        ),
      );
      expect(base.hashCode, isNot(SleepSyncState.initial.hashCode));
      // One differing field at a time, so each comparison is exercised.
      expect(base, isNot(base.copyWith(enabled: false)));
      expect(
        base,
        isNot(base.copyWith(lastSyncedAt: DateTime.utc(2026, 3, 11))),
      );
      expect(base, isNot(base.copyWith(clearError: true)));
      expect(base, isNot(Object()));
      expect(base == base, isTrue);
    });

    test('toString carries the flag and error name only', () {
      const state = SleepSyncState(
        enabled: true,
        lastError: SleepSyncError.timeout,
      );
      expect(state.toString(), contains('true'));
      expect(state.toString(), contains('timeout'));
    });
  });

  group('SleepSyncException', () {
    test('carries only a category', () {
      const e = SleepSyncException(SleepSyncError.permissionDenied);
      expect(e.error, SleepSyncError.permissionDenied);
      expect(e.toString(), contains('permissionDenied'));
    });
  });

  group('SleepFormat.split', () {
    test('under an hour uses the minutes-only shape', () {
      final parts = SleepFormat.split(45);
      expect(parts.shape, SleepDurationShape.minutesOnly);
      expect(parts.hours, 0);
      expect(parts.minutes, 45);
    });

    test('exactly an hour uses the hours-and-minutes shape', () {
      final parts = SleepFormat.split(60);
      expect(parts.shape, SleepDurationShape.hoursAndMinutes);
      expect(parts.hours, 1);
      expect(parts.minutes, 0);
    });

    test('splits hours and remaining minutes', () {
      final parts = SleepFormat.split(455);
      expect(parts.hours, 7);
      expect(parts.minutes, 35);
    });

    test('zero is the minutes-only shape', () {
      final parts = SleepFormat.split(0);
      expect(parts.shape, SleepDurationShape.minutesOnly);
      expect(parts.minutes, 0);
    });

    test('a negative input clamps to zero rather than throwing', () {
      // History must not fall over because of one bad cache row.
      final parts = SleepFormat.split(-30);
      expect(parts.shape, SleepDurationShape.minutesOnly);
      expect(parts.minutes, 0);
    });
  });

  group('FakeSleepGateway', () {
    test('reports segments inside the window only', () async {
      final gateway = FakeSleepGateway(
        segments: [
          SleepSegment(
            start: DateTime.utc(2026, 3, 1, 23),
            end: DateTime.utc(2026, 3, 2, 7),
            stage: SleepStage.asleep,
            sourceName: 'Watch',
          ),
          SleepSegment(
            start: DateTime.utc(2026, 3, 10, 23),
            end: DateTime.utc(2026, 3, 11, 7),
            stage: SleepStage.asleep,
            sourceName: 'Watch',
          ),
        ],
      );

      final read = await gateway.readSegments(
        start: DateTime.utc(2026, 3, 5),
        end: DateTime.utc(2026, 3, 15),
      );

      expect(read, hasLength(1));
      expect(read.single.start, DateTime.utc(2026, 3, 10, 23));
      expect(gateway.readCallCount, 1);
    });

    test('failNextRead throws once, then clears', () async {
      final gateway = FakeSleepGateway()..failNextRead = SleepSyncError.timeout;

      await expectLater(
        gateway.readSegments(
          start: DateTime.utc(2026, 3, 2),
          end: DateTime.utc(2026, 3, 3),
        ),
        throwsA(isA<SleepSyncException>()),
      );
      // Second call succeeds — the failure was one-shot.
      expect(
        await gateway.readSegments(
          start: DateTime.utc(2026, 3, 2),
          end: DateTime.utc(2026, 3, 3),
        ),
        isEmpty,
      );
    });

    test('a granted request flips the permission', () async {
      final gateway = FakeSleepGateway(permission: false);
      expect(await gateway.hasPermission(), isFalse);
      expect(await gateway.requestPermission(), isTrue);
      expect(await gateway.hasPermission(), isTrue);
    });

    test('a declined request leaves the permission alone', () async {
      final gateway = FakeSleepGateway(
        permission: false,
        permissionRequestResult: false,
      );
      expect(await gateway.requestPermission(), isFalse);
      expect(await gateway.hasPermission(), isFalse);
    });

    test('counts every call that would reach the platform', () async {
      final gateway = FakeSleepGateway();
      expect(gateway.totalPlatformCalls, 0);
      await gateway.availability();
      await gateway.requestPermission();
      await gateway.readSegments(
        start: DateTime.utc(2026, 3, 2),
        end: DateTime.utc(2026, 3, 3),
      );
      expect(gateway.totalPlatformCalls, 3);
    });

    test('openPermissionSettings follows its flag', () async {
      expect(await FakeSleepGateway().openPermissionSettings(), isTrue);
      expect(
        await FakeSleepGateway(canOpenSettings: false).openPermissionSettings(),
        isFalse,
      );
    });
  });
}
