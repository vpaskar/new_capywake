import 'package:capywake/app/app.dart';
import 'package:capywake/app/router.dart';
import 'package:capywake/core/engine/fake_alarm_engine.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/features/ringing/ringing_screen.dart';
import 'package:capywake/features/settings/settings_screen.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata;

Alarm _puzzleAlarm() {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: 'a1',
    label: 'Morning',
    enabled: true,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const {},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 0,
    soundId: 'gentle',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: DismissMethod.puzzle,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting();
  });

  final clock = DateTime.utc(2026, 5, 21, 5);

  Future<({FakeAlarmEngine engine, CapyWakeRepository repository})> pumpApp(
    WidgetTester tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final engine = FakeAlarmEngine(now: () => clock);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        alarmEngineProvider.overrideWithValue(engine),
        engineNowProvider.overrideWithValue(() => clock),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await engine.dispose();
      await db.close();
    });

    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      CapyWakeApp(
        router: createRouter(),
        showDebugBanner: false,
        scopeBuilder: (child) =>
            UncontrolledProviderScope(container: container, child: child),
      ),
    );
    await tester.pumpAndSettle();
    return (engine: engine, repository: CapyWakeRepository(db));
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  }

  // `RingingHost` sits above the router, so both halves are asserted: the
  // surface appears over a pushed Settings, AND the escape opens on it.
  testWidgets('a ring covers a pushed Settings route', (tester) async {
    final app = await pumpApp(tester);
    await app.repository.upsertAlarm(_puzzleAlarm());
    await tester.pumpAndSettle();

    await openSettings(tester);

    app.engine.fire('a1', firedAt: clock);
    await tester.pumpAndSettle();

    expect(find.byType(RingingScreen), findsOneWidget);
  });

  testWidgets('the emergency escape still opens over Settings', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await app.repository.upsertAlarm(_puzzleAlarm());
    await app.repository.savePuzzleSettings(
      PuzzleSettings.defaults().copyWith(
        escapeStrictness: PuzzleEscapeStrictness.confirm,
      ),
    );
    await tester.pumpAndSettle();

    await openSettings(tester);
    app.engine.fire('a1', firedAt: clock);
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RingingScreen)),
    );
    await tester.tap(find.text(l10n.puzzleEscapeAction));
    await tester.pumpAndSettle();

    // Phase 06 shipped a version where this threw instead of opening,
    // because the host has no root Navigator in its context.
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.puzzleEscapeConfirmTitle), findsOneWidget);
  });

  testWidgets('stopping the alarm returns to Settings, still pushed', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await app.repository.upsertAlarm(_puzzleAlarm());
    await tester.pumpAndSettle();

    await openSettings(tester);
    app.engine.fire('a1', firedAt: clock);
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RingingScreen)),
    );
    await tester.tap(find.text(l10n.puzzleEscapeAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.puzzleEscapeConfirmAction));
    await tester.pumpAndSettle();

    expect(find.byType(RingingScreen), findsNothing);
    expect(
      find.byType(SettingsScreen),
      findsOneWidget,
      reason: 'the ring covered Settings, it did not replace it',
    );
  });
}
