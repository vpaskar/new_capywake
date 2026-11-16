import 'package:capywake/app/router.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/features/alarms/edit/alarm_edit_screen.dart';
import 'package:capywake/features/alarms/edit/time_stepper_field.dart';
import 'package:capywake/features/alarms/edit/weekday_chip_row.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../alarms_screen_test.dart' show alarmFixture;

final _fixedNow = DateTime.utc(2026, 5, 21, 8);

/// Scroll a control into view before tapping: the form is taller than the
/// viewport on a device too.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

/// The app's database and repository, so tests assert through the mapper
/// rather than raw Drift columns.
typedef EditHarness = ({AppDatabase db, CapyWakeRepository repository});

Future<EditHarness> pumpEdit(
  WidgetTester tester, {
  List<Alarm> seed = const [],
  String? alarmId,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      alarmEditClockProvider.overrideWithValue(() => _fixedNow),
      alarmIdFactoryProvider.overrideWithValue(() => 'generated-id'),
    ],
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
        routerConfig: createRouter(
          initialLocation: alarmId == null
              ? Routes.alarmNew
              : Routes.alarmEdit(alarmId),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (db: db, repository: container.read(capywakeRepositoryProvider));
}

void main() {
  setUpAll(initializeDateFormatting);

  group('the Add state, which is what the mockup shows', () {
    testWidgets('titles itself Add Alarm and offers no delete', (
      tester,
    ) async {
      await pumpEdit(tester);

      expect(find.text('Add Alarm'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsNothing);
    });

    testWidgets('shows the five cards the mockup draws', (tester) async {
      await pumpEdit(tester);

      expect(find.byType(TimeStepperField), findsOneWidget);
      expect(find.byType(WeekdayChipRow), findsOneWidget);
      expect(find.text('Label'), findsOneWidget);
      expect(find.text('Sound'), findsOneWidget);
      expect(find.text('Snooze'), findsOneWidget);
      expect(find.byType(CapyButton), findsOneWidget);
    });

    testWidgets('opens at 07:00, the default a new draft carries', (
      tester,
    ) async {
      await pumpEdit(tester);

      expect(find.text('7'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
    });

    testWidgets('saving writes a new alarm and pops back', (tester) async {
      final harness = await pumpEdit(tester);

      await tapSave(tester);

      final stored = await harness.repository.listAlarms();
      expect(stored, hasLength(1));
      expect(stored.single.id, 'generated-id');
      expect(stored.single.targetTimeMinutes, 7 * 60);
    });
  });

  group('the Edit state', () {
    testWidgets('titles itself Edit Alarm and offers delete', (tester) async {
      await pumpEdit(
        tester,
        seed: [alarmFixture(id: 'a1', minutes: 7 * 60)],
        alarmId: 'a1',
      );

      expect(find.text('Edit Alarm'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
    });

    testWidgets('hydrates from the stored alarm', (tester) async {
      await pumpEdit(
        tester,
        seed: [
          alarmFixture(
            id: 'a1',
            minutes: 8 * 60 + 30,
            label: 'Yoga',
            repeat: const {1, 3, 5},
          ),
        ],
        alarmId: 'a1',
      );

      expect(find.text('8'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('Yoga'), findsOneWidget);
    });

    testWidgets('editing the label and saving updates the row', (
      tester,
    ) async {
      final harness = await pumpEdit(
        tester,
        seed: [alarmFixture(id: 'a1', minutes: 7 * 60, label: 'Old')],
        alarmId: 'a1',
      );

      await tester.enterText(find.byType(TextField), 'New');
      await tester.pumpAndSettle();
      await tapSave(tester);

      final stored = (await harness.repository.listAlarms()).single;
      expect(stored.label, 'New');
      expect(stored.id, 'a1');
    });

    testWidgets('delete asks first and removes on confirmation', (
      tester,
    ) async {
      final harness = await pumpEdit(
        tester,
        seed: [alarmFixture(id: 'a1', minutes: 7 * 60)],
        alarmId: 'a1',
      );

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this alarm?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(await harness.repository.listAlarms(), isEmpty);
    });

    testWidgets('dismissing the delete dialog keeps the alarm', (
      tester,
    ) async {
      final harness = await pumpEdit(
        tester,
        seed: [alarmFixture(id: 'a1', minutes: 7 * 60)],
        alarmId: 'a1',
      );

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Back'));
      await tester.pumpAndSettle();

      expect(await harness.repository.listAlarms(), hasLength(1));
    });

    testWidgets('an unknown id does not crash', (tester) async {
      await pumpEdit(tester, alarmId: 'does-not-exist');
      expect(tester.takeException(), isNull);
    });
  });

  group('editing fields', () {
    testWidgets('a weekday chip toggles into the saved set', (tester) async {
      final harness = await pumpEdit(tester);

      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();
      await tapSave(tester);

      final stored = await harness.repository.listAlarms();
      expect(stored.single.repeatWeekdays, contains(1));
    });

    testWidgets('the snooze toggle writes through', (tester) async {
      final harness = await pumpEdit(tester);

      await tapVisible(tester, find.byType(CapyToggle));
      await tapSave(tester);

      final stored = (await harness.repository.listAlarms()).single;
      expect(stored.snoozeEnabled, isFalse);
    });

    testWidgets('the sound row says the picker is not built yet', (
      tester,
    ) async {
      await pumpEdit(tester);

      await tapVisible(tester, find.text('Sound'));

      expect(find.text('Preview unavailable'), findsOneWidget);
    });

    testWidgets('the repeat summary follows the chips', (tester) async {
      await pumpEdit(tester);

      expect(find.text('Once, then it stays off'), findsOneWidget);

      for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']) {
        await tester.tap(find.text(day));
        await tester.pumpAndSettle();
      }

      expect(find.text('Weekdays'), findsOneWidget);
    });
  });

  group('self-review #2 probes', () {
    testWidgets('deleting does not flash the missing-alarm screen', (
      tester,
    ) async {
      await pumpEdit(
        tester,
        seed: [alarmFixture(id: 'a1', minutes: 7 * 60)],
        alarmId: 'a1',
      );

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pump();

      // The form keeps showing the alarm it loaded while the route pops;
      // the one empty-state title on screen is the list's own, behind it.
      expect(find.text('No alarms yet'), findsOneWidget);
      expect(find.byType(AlarmEditScreen), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(AlarmEditScreen), findsNothing);
    });

    testWidgets('a second Save tap does not write twice', (tester) async {
      final harness = await pumpEdit(tester);

      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'), warnIfMissed: false);
      await tester.tap(find.text('Save'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final stored = await harness.repository.listAlarms();
      expect(stored, hasLength(1));
    });
  });

  group('localization and scaling', () {
    testWidgets('German shows no AM/PM control', (tester) async {
      await pumpEdit(tester, locale: const Locale('de'));

      expect(find.text('AM'), findsNothing);
      expect(find.text('PM'), findsNothing);
      expect(find.text('07'), findsOneWidget);
    });

    testWidgets('English shows the AM/PM pills', (tester) async {
      await pumpEdit(tester);

      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('survives 2x text without overflowing', (tester) async {
      await pumpEdit(tester, textScaler: const TextScaler.linear(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic lays out right-to-left without throwing', (
      tester,
    ) async {
      await pumpEdit(tester, locale: const Locale('ar'));
      expect(tester.takeException(), isNull);
    });
  });
}
