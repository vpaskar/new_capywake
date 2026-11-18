import 'package:capywake/app/router.dart';
import 'package:capywake/core/motion/fake_step_sensor.dart';
import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/motion/motion_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/features/puzzle/puzzle_chooser_screen.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  PuzzleSettings? seed,
  StepSensor? steps,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      if (steps != null) stepSensorProvider.overrideWithValue(steps),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  if (seed != null) {
    await container.read(capywakeRepositoryProvider).savePuzzleSettings(seed);
  }
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const PuzzleChooserScreen()),
      GoRoute(
        path: '${Routes.games}/:id',
        builder: (_, state) =>
            Scaffold(body: Text('practice:${state.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<PuzzleSettings> _saved(ProviderContainer c) =>
    c.read(capywakeRepositoryProvider).getPuzzleSettings();

Finder _toggle(String label) =>
    find.byWidgetPredicate((w) => w is CapyToggle && w.semanticLabel == label);

Future<void> _flip(WidgetTester tester, String label) async {
  await tester.ensureVisible(_toggle(label));
  await tester.pumpAndSettle();
  await tester.tap(_toggle(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the Games section sits in the chooser', (tester) async {
    await _pump(tester);
    expect(find.text('Wake challenges'), findsOneWidget);
    expect(find.text('Catch the Capy'), findsOneWidget);
    expect(find.text('Memory Hideout'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Applies to puzzles only.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Applies to puzzles only.'), findsOneWidget);
  });

  testWidgets('enabling a game persists it', (tester) async {
    final c = await _pump(tester);
    await _flip(tester, 'Catch the Capy');
    expect((await _saved(c)).enabledGames, {'catch_the_capy'});
  });

  testWidgets('the Puzzles switch has a writer (M2)', (tester) async {
    final c = await _pump(
      tester,
      seed: PuzzleSettings(
        enabledTypes: const {PuzzleType.arithmetic},
        enabledGames: const {'memory_hideout'},
      ),
    );
    await _flip(tester, 'Puzzles');
    final saved = await _saved(c);
    expect(saved.includePuzzles, isFalse);
    expect(saved.enabledGames, {'memory_hideout'});
  });

  testWidgets('the pool cannot be emptied from the chooser', (tester) async {
    final c = await _pump(
      tester,
      seed: PuzzleSettings(
        enabledTypes: const {PuzzleType.arithmetic},
        enabledGames: const {'memory_hideout'},
        includePuzzles: false,
      ),
    );
    await _flip(tester, 'Memory Hideout');
    expect((await _saved(c)).enabledGames, {'memory_hideout'});
  });

  testWidgets('Try it opens practice for that game', (tester) async {
    await _pump(tester);
    final tryIt = find.text('Try it').at(1);
    await tester.ensureVisible(tryIt);
    await tester.pumpAndSettle();
    await tester.tap(tryIt);
    await tester.pumpAndSettle();
    expect(find.text('practice:shake_dj'), findsOneWidget);
  });

  group('switching Step Quest on offers the step sensor', () {
    final sheet = find.byKey(const ValueKey('step-access-sheet'));

    testWidgets('after the switch is saved, never instead of it (M4)', (
      tester,
    ) async {
      final steps = FakeStepSensor(current: StepAccess.needsPermission);
      final c = await _pump(tester, steps: steps);
      await _flip(tester, 'Step Quest');
      expect(sheet, findsOneWidget);
      expect((await _saved(c)).enabledGames, contains('step_quest'));
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(steps.requestCount, 0);
      expect((await _saved(c)).enabledGames, contains('step_quest'));
    });

    testWidgets('Allow shows the OS prompt and closes', (tester) async {
      final steps = FakeStepSensor(
        current: StepAccess.needsPermission,
        afterRequest: StepAccess.ready,
      );
      await _pump(tester, steps: steps);
      await _flip(tester, 'Step Quest');
      await tester.tap(find.text('Allow step counting'));
      await tester.pumpAndSettle();
      expect(steps.requestCount, 1);
      expect(sheet, findsNothing);
    });

    testWidgets('Open Settings closes the sheet', (tester) async {
      final steps = FakeStepSensor(current: StepAccess.permanentlyDenied);
      await _pump(tester, steps: steps);
      await _flip(tester, 'Step Quest');
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(steps.settingsCount, 1);
      expect(sheet, findsNothing);
    });

    testWidgets('nothing is offered when there is nothing to ask', (
      tester,
    ) async {
      for (final access in [StepAccess.ready, StepAccess.unavailable]) {
        await _pump(tester, steps: FakeStepSensor(current: access));
        await _flip(tester, 'Step Quest');
        expect(sheet, findsNothing, reason: access.name);
      }
    });

    testWidgets('switching it off, or another game on, offers nothing', (
      tester,
    ) async {
      final steps = FakeStepSensor(current: StepAccess.needsPermission);
      await _pump(
        tester,
        steps: steps,
        seed: PuzzleSettings(
          enabledTypes: const {PuzzleType.arithmetic},
          enabledGames: const {'step_quest'},
        ),
      );
      await _flip(tester, 'Step Quest');
      expect(sheet, findsNothing);
      await _flip(tester, 'Shake DJ');
      expect(sheet, findsNothing);
    });
  });
}
