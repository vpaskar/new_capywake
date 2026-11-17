import 'package:capywake/core/history/history_service.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/stats/stats_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 17, 9, 41);

Alarm _alarm() {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: 'a1',
    label: 'Morning',
    enabled: true,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const {},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 15,
    soundId: 'gentle',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: DismissMethod.normalButton,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: t,
    updatedAt: t,
  );
}

AlarmOccurrence _occurrence(
  String id,
  DateTime at, {
  AlarmStatus status = AlarmStatus.dismissed,
}) => AlarmOccurrence(
  id: id,
  alarmId: 'a1',
  scheduledAt: at,
  softStartAt: null,
  status: status,
  triggeredAt: status == AlarmStatus.skipped ? null : at,
  dismissedAt: status == AlarmStatus.dismissed
      ? at.add(const Duration(minutes: 1))
      : null,
  snoozeCount: 0,
  note: '',
);

Future<ProviderContainer> _container({
  List<AlarmOccurrence> occurrences = const [],
  List<Alarm> alarms = const [],
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      statsClockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(container.dispose);

  final repository = container.read(capywakeRepositoryProvider);
  for (final alarm in alarms) {
    await repository.upsertAlarm(alarm);
  }
  for (final occurrence in occurrences) {
    await repository.upsertOccurrence(occurrence);
  }
  // Both streams must emit before the fold is read, or every case reads as
  // loading and the tests pass for the wrong reason.
  container.listen(statsAlarmsStateProvider, (_, _) {});
  await container.read(allOccurrencesStreamProvider.future);
  await container.read(alarmsStreamProvider.future);
  return container;
}

void main() {
  group('emptiness is a state, not a summary full of zeros', () {
    test('no occurrence at all is empty', () async {
      final container = await _container(alarms: [_alarm()]);
      expect(container.read(statsAlarmsStateProvider), isA<StatsAlarmsEmpty>());
    });

    test('an occurrence outside the window is empty', () async {
      final container = await _container(
        alarms: [_alarm()],
        occurrences: [
          _occurrence('o1', _now.subtract(const Duration(days: 60))),
        ],
      );
      expect(container.read(statsAlarmsStateProvider), isA<StatsAlarmsEmpty>());
    });

    test('only-skipped rows inside the window are a real summary', () async {
      final container = await _container(
        alarms: [_alarm()],
        occurrences: [
          _occurrence(
            'o1',
            _now.subtract(const Duration(days: 1)),
            status: AlarmStatus.skipped,
          ),
        ],
      );
      final state = container.read(statsAlarmsStateProvider);
      expect(
        state,
        isA<StatsAlarmsReady>(),
        reason: 'A list of only-skipped rows is data, not absence.',
      );
      expect((state as StatsAlarmsReady).summary.skippedCount, 1);
    });

    test('a dismissed occurrence inside the window summarises', () async {
      final container = await _container(
        alarms: [_alarm()],
        occurrences: [
          _occurrence('o1', _now.subtract(const Duration(days: 1))),
        ],
      );
      final state = container.read(statsAlarmsStateProvider);
      expect(state, isA<StatsAlarmsReady>());
      expect((state as StatsAlarmsReady).summary.occurrenceCount, 1);
    });
  });

  group('the window', () {
    test('defaults to the service default, not the mockup label', () async {
      final container = await _container();
      expect(
        container.read(statsWindowProvider),
        HistoryService.defaultWindowDays,
      );
    });

    test('offers the mockup 7 alongside 14 and 90', () {
      expect(statsWindowChoices, containsAll([7, 14, 90]));
    });

    test('a window change re-folds the summary', () async {
      final container = await _container(
        alarms: [_alarm()],
        occurrences: [
          _occurrence('o1', _now.subtract(const Duration(days: 30))),
        ],
      );
      expect(container.read(statsAlarmsStateProvider), isA<StatsAlarmsEmpty>());

      container.read(statsWindowProvider.notifier).select(90);
      expect(container.read(statsAlarmsStateProvider), isA<StatsAlarmsReady>());
    });

    test('an unlisted window is refused', () async {
      final container = await _container();
      container.read(statsWindowProvider.notifier).select(365);
      expect(
        container.read(statsWindowProvider),
        HistoryService.defaultWindowDays,
      );
    });
  });
}
