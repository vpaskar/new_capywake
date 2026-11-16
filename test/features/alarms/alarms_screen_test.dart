import 'package:capywake/app/router.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/features/alarms/alarm_list_tile.dart';
import 'package:capywake/features/alarms/alarms_empty_state.dart';
import 'package:capywake/features/alarms/alarms_screen.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Alarm alarmFixture({
  required String id,
  required int minutes,
  bool enabled = true,
  String label = '',
  Set<int> repeat = const {},
  DateTime? createdAt,
}) {
  final t = createdAt ?? DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: id,
    label: label,
    enabled: enabled,
    targetTimeMinutes: minutes,
    repeatWeekdays: repeat,
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

Future<AppDatabase> pumpAlarms(
  WidgetTester tester, {
  List<Alarm> seed = const [],
  Size size = const Size(393, 852),
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(container.dispose);

  for (final alarm in seed) {
    await container.read(capywakeRepositoryProvider).upsertAlarm(alarm);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: createRouter(initialLocation: Routes.alarms),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

void main() {
  setUpAll(initializeDateFormatting);

  // The empty state is the DEFAULT, not a fallback — a fresh install has no
  // alarms — so it is asserted before any populated case.
  group('Alarms with no alarms — the state the app ships in', () {
    testWidgets('renders the empty state, not an empty list', (tester) async {
      await pumpAlarms(tester);

      expect(find.byType(AlarmsEmptyState), findsOneWidget);
      expect(find.byType(AlarmListTile), findsNothing);
      expect(find.text('No alarms yet'), findsOneWidget);
    });

    testWidgets('still shows the title, the Add pill and the meadow', (
      tester,
    ) async {
      await pumpAlarms(tester);

      // "Alarms" is also the nav-bar label, so the title is found by its
      // header semantics rather than by text alone.
      expect(
        find.ancestor(
          of: find.text('Alarms'),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && (w.properties.header ?? false),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Add Alarm'), findsOneWidget);
      expect(find.byType(MeadowFooter), findsOneWidget);
    });

    testWidgets('shows no toggle, because there is nothing to toggle', (
      tester,
    ) async {
      await pumpAlarms(tester);
      expect(find.byType(CapyToggle), findsNothing);
    });
  });

  group('Alarms with alarms', () {
    testWidgets('renders one tile per alarm', (tester) async {
      await pumpAlarms(
        tester,
        seed: [
          alarmFixture(id: 'a', minutes: 7 * 60),
          alarmFixture(id: 'b', minutes: 8 * 60),
        ],
      );

      expect(find.byType(AlarmListTile), findsNWidgets(2));
      expect(find.byType(AlarmsEmptyState), findsNothing);
    });

    testWidgets('orders by time of day, not creation order', (tester) async {
      await pumpAlarms(
        tester,
        seed: [
          alarmFixture(
            id: 'late',
            minutes: 21 * 60 + 30,
            createdAt: DateTime.utc(2026),
          ),
          alarmFixture(
            id: 'early',
            minutes: 6 * 60,
            createdAt: DateTime.utc(2026, 6),
          ),
        ],
      );

      final tiles = tester
          .widgetList<AlarmListTile>(find.byType(AlarmListTile))
          .toList();
      expect(tiles.first.alarm.id, 'early');
      expect(tiles.last.alarm.id, 'late');
    });

    testWidgets('toggling a tile writes the new state through', (
      tester,
    ) async {
      final db = await pumpAlarms(
        tester,
        seed: [alarmFixture(id: 'a', minutes: 7 * 60)],
      );

      await tester.tap(find.byType(CapyToggle));
      await tester.pumpAndSettle();

      final stored = await db.select(db.alarms).getSingle();
      expect(stored.enabled, isFalse);
    });

    testWidgets('a disabled alarm still renders its time and repeat', (
      tester,
    ) async {
      await pumpAlarms(
        tester,
        seed: [
          alarmFixture(
            id: 'a',
            minutes: 8 * 60,
            enabled: false,
            repeat: const {6, 7},
          ),
        ],
      );

      expect(find.text('8:00'), findsOneWidget);
      expect(find.text('Weekends'), findsOneWidget);
    });

    testWidgets('tapping a tile pushes the edit route', (tester) async {
      await pumpAlarms(
        tester,
        seed: [alarmFixture(id: 'a1b2', minutes: 7 * 60)],
      );

      await tester.tap(find.byType(AlarmListTile));
      await tester.pumpAndSettle();

      expect(find.text('Edit Alarm'), findsOneWidget);
    });

    testWidgets('the Add pill pushes the create route', (tester) async {
      await pumpAlarms(tester);

      await tester.tap(find.text('Add Alarm'));
      await tester.pumpAndSettle();

      expect(find.text('Add Alarm'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('sortAlarmsForDisplay', () {
    test('sorts by time, breaking ties on createdAt', () {
      final sorted = sortAlarmsForDisplay([
        alarmFixture(
          id: 'second-at-seven',
          minutes: 7 * 60,
          createdAt: DateTime.utc(2026, 6),
        ),
        alarmFixture(id: 'six', minutes: 6 * 60),
        alarmFixture(
          id: 'first-at-seven',
          minutes: 7 * 60,
          createdAt: DateTime.utc(2026),
        ),
      ]);

      expect(
        sorted.map((a) => a.id),
        ['six', 'first-at-seven', 'second-at-seven'],
      );
    });

    test('does not mutate the list it is given', () {
      final original = [
        alarmFixture(id: 'late', minutes: 20 * 60),
        alarmFixture(id: 'early', minutes: 5 * 60),
      ];
      sortAlarmsForDisplay(original);
      expect(original.first.id, 'late');
    });
  });

  group('localization and scaling', () {
    testWidgets('German renders a 24-hour time with no period', (
      tester,
    ) async {
      await pumpAlarms(
        tester,
        locale: const Locale('de'),
        seed: [alarmFixture(id: 'a', minutes: 21 * 60 + 30)],
      );

      expect(find.text('21:30'), findsOneWidget);
      expect(find.text('PM'), findsNothing);
    });

    testWidgets('survives 2x text without overflowing', (tester) async {
      await pumpAlarms(
        tester,
        textScaler: const TextScaler.linear(2),
        seed: [
          alarmFixture(
            id: 'a',
            minutes: 7 * 60,
            label: 'Workdays',
            repeat: const {1, 2, 3, 4, 5},
          ),
        ],
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic lays out right-to-left without throwing', (
      tester,
    ) async {
      await pumpAlarms(
        tester,
        locale: const Locale('ar'),
        seed: [alarmFixture(id: 'a', minutes: 7 * 60)],
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AlarmListTile), findsOneWidget);
    });
  });
}
