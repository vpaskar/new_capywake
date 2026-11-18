import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/games/catch_the_capy_view.dart';
import 'package:capywake/features/games/game_practice_screen.dart';
import 'package:capywake/features/games/game_win_celebration.dart';
import 'package:capywake/features/games/memory_hideout_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(WidgetTester tester, String gameId) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  var seed = 0;
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      practiceSeedProvider.overrideWithValue(() => seed++),
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
    await _pump(tester, 'step_quest');
    expect(find.textContaining('Step Quest is on the way'), findsOneWidget);
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
}
