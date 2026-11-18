import 'package:capywake/core/motion/fake_step_sensor.dart';
import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/motion/motion_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/games/catch_the_capy_view.dart';
import 'package:capywake/features/games/game_practice_screen.dart';
import 'package:capywake/features/games/game_win_celebration.dart';
import 'package:capywake/features/games/memory_hideout_view.dart';
import 'package:capywake/features/games/step_access_prompt.dart';
import 'package:capywake/features/games/step_quest_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester,
  String gameId, {
  StepSensor? steps,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  var seed = 0;
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      practiceSeedProvider.overrideWithValue(() => seed++),
      if (steps != null) stepSensorProvider.overrideWithValue(steps),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GamePracticeScreen(gameId: gameId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _catchAll(WidgetTester tester) async {
  final target = find.byKey(const ValueKey('catch-the-capy-target'));
  while (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('plays Catch the Capy with the practice note', (tester) async {
    await _pump(tester, 'catch_the_capy');
    expect(find.text('Catch the Capy'), findsWidgets);
    expect(
      find.text('Practice here. Nothing you do changes an alarm.'),
      findsOneWidget,
    );
    expect(find.byType(CatchTheCapyView), findsOneWidget);
  });

  testWidgets('finishing shows Practice done and Play again restarts', (
    tester,
  ) async {
    await _pump(tester, 'catch_the_capy');
    await _catchAll(tester);

    expect(find.text('Practice done'), findsOneWidget);
    expect(find.byType(GameWinCelebration), findsOneWidget);
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 5'), findsOneWidget);
  });

  testWidgets('uses the user difficulty and writes nothing', (tester) async {
    final container = await _pump(tester, 'catch_the_capy');
    final repo = container.read(capywakeRepositoryProvider);
    final before = await repo.getPuzzleSettings();

    await _catchAll(tester);

    expect(await repo.getPuzzleSettings(), before);
    expect(before, PuzzleSettings.defaults());
  });

  testWidgets('Memory Hideout is practisable too', (tester) async {
    await _pump(tester, 'memory_hideout');
    expect(find.byType(MemoryHideoutView), findsOneWidget);
  });

  testWidgets('an unbuilt game shows the not-built copy (L2)', (tester) async {
    await _pump(tester, 'qr_treasure_hunt');
    expect(
      find.textContaining('QR Treasure Hunt is on the way'),
      findsOneWidget,
    );
    expect(find.byType(CatchTheCapyView), findsNothing);
  });

  testWidgets('an unknown id never crashes (L2)', (tester) async {
    await _pump(tester, 'not_a_game');
    expect(tester.takeException(), isNull);
    expect(find.text('Not built yet'), findsOneWidget);
  });

  testWidgets('practice waits for the saved difficulty before starting', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        practiceSeedProvider.overrideWithValue(() => 1),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await container
        .read(capywakeRepositoryProvider)
        .savePuzzleSettings(
          PuzzleSettings.defaults().copyWith(difficulty: PuzzleDifficulty.hard),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamePracticeScreen(gameId: 'catch_the_capy'),
        ),
      ),
    );
    expect(find.text('0 / 5'), findsNothing, reason: 'no medium fallback');
    await tester.pumpAndSettle();
    expect(find.text('0 / 7'), findsOneWidget);
  });

  group('Step Quest practice offers the step sensor', () {
    final card = find.byKey(const ValueKey('step-access-card'));

    testWidgets('asks first, then counts with the sensor', (tester) async {
      final steps = FakeStepSensor(
        current: StepAccess.needsPermission,
        afterRequest: StepAccess.ready,
      );
      await _pump(tester, 'step_quest', steps: steps);
      expect(card, findsOneWidget);
      expect(find.byType(StepQuestView), findsOneWidget);
      expect(steps.requestCount, 0, reason: 'the reason is shown first');
      expect(steps.listenCount, 0);

      await tester.tap(find.text('Allow step counting'));
      await tester.pumpAndSettle();
      expect(steps.requestCount, 1);
      expect(card, findsNothing);
      expect(steps.hasListener, isTrue);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('step-quest-source')))
            .data,
        'Counted by your step sensor',
      );
    });

    testWidgets('Not now hides it and asks nothing', (tester) async {
      final steps = FakeStepSensor(current: StepAccess.needsPermission);
      await _pump(tester, 'step_quest', steps: steps);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(card, findsNothing);
      expect(steps.requestCount, 0);
    });

    testWidgets('a refusal points to Settings, and a return re-reads', (
      tester,
    ) async {
      final steps = FakeStepSensor(current: StepAccess.permanentlyDenied);
      await _pump(tester, 'step_quest', steps: steps);
      expect(
        find.textContaining('Step counting is off for CapyWake'),
        findsOneWidget,
      );
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(steps.settingsCount, 1);
      expect(steps.requestCount, 0, reason: 'iOS never asks twice');
      expect(card, findsOneWidget, reason: 'nothing changed yet');

      steps.current = StepAccess.ready;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(card, findsNothing);
      expect(steps.hasListener, isTrue);
    });

    for (final access in [StepAccess.ready, StepAccess.unavailable]) {
      testWidgets('shows nothing when access is ${access.name}', (
        tester,
      ) async {
        await _pump(
          tester,
          'step_quest',
          steps: FakeStepSensor(current: access),
        );
        expect(card, findsNothing);
      });
    }

    testWidgets('other games never offer it', (tester) async {
      final steps = FakeStepSensor(current: StepAccess.needsPermission);
      await _pump(tester, 'shake_dj', steps: steps);
      expect(card, findsNothing);
      expect(find.byType(StepAccessPrompt), findsNothing);
    });
  });
}
