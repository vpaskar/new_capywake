import 'dart:async';

import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/sleep/sleep.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads every provider in the graph against a real in-memory database.
/// Five were counted as covered with no test reading them — see Phase 03.
ProviderContainer _container() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return container;
}

/// Subscribes, takes the first value, drops the subscription. `read(p.future)`
/// never completes here: with no listener the stream is never subscribed.
Future<T> _firstValue<T>(
  ProviderContainer container,
  StreamProvider<T> provider,
) async {
  final completer = Completer<T>();
  final sub = container.listen<AsyncValue<T>>(provider, (_, next) {
    if (!completer.isCompleted && next.hasValue) {
      completer.complete(next.value as T);
    }
  }, fireImmediately: true);
  addTearDown(sub.close);
  return completer.future;
}

void main() {
  group('provider graph', () {
    test('repository is built from the database', () {
      final container = _container();
      expect(container.read(capywakeRepositoryProvider), isNotNull);
    });

    test('alarms stream starts empty', () async {
      final container = _container();
      expect(await _firstValue(container, alarmsStreamProvider), isEmpty);
    });

    test('settings stream yields the initial settings', () async {
      final container = _container();
      expect(
        await _firstValue(container, userSettingsStreamProvider),
        isA<UserSettings>(),
      );
    });

    test('pro status stream yields a value', () async {
      final container = _container();
      expect(
        await _firstValue(container, proStatusStreamProvider),
        isA<ProStatus>(),
      );
    });

    test('puzzle settings stream yields a value', () async {
      final container = _container();
      expect(
        await _firstValue(container, puzzleSettingsStreamProvider),
        isA<PuzzleSettings>(),
      );
    });

    test('finished occurrences stream starts empty', () async {
      final container = _container();
      expect(
        await _firstValue(container, finishedOccurrencesStreamProvider),
        isEmpty,
      );
    });

    test('snoozed occurrences stream starts empty', () async {
      final container = _container();
      expect(
        await _firstValue(container, snoozedOccurrencesStreamProvider),
        isEmpty,
      );
    });

    test('all occurrences stream starts empty', () async {
      final container = _container();
      expect(
        await _firstValue(container, allOccurrencesStreamProvider),
        isEmpty,
      );
    });

    test('sleep night store is backed by the repository', () {
      final container = _container();
      expect(container.read(sleepNightStoreProvider), isA<SleepNightStore>());
    });

    test('sleep sync state stream yields a value', () async {
      final container = _container();
      expect(
        await _firstValue(container, sleepSyncStateStreamProvider),
        isA<SleepSyncState>(),
      );
    });

    test('sleep nights stream starts empty', () async {
      final container = _container();
      expect(await _firstValue(container, sleepNightsStreamProvider), isEmpty);
    });

    // The unoverridden `appDatabaseProvider` is NOT tested: `AppDatabase()`
    // resolves a path via `path_provider`, which hangs in a widget test.
  });
}
