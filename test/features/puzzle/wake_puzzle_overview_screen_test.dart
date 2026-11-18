import 'package:capywake/app/router.dart';
import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/features/puzzle/puzzle_controls.dart';
import 'package:capywake/features/puzzle/puzzle_labels.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'puzzle_harness.dart';

final _seed = PuzzleSettings(
  enabledTypes: const {PuzzleType.arithmetic, PuzzleType.spotTheChange},
  enabledGames: const {'catch_the_capy', 'memory_hideout', 'shake_dj'},
  difficulty: PuzzleDifficulty.hard,
  taskCount: 2,
  toleratedWrongAnswers: 4,
  escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
);

void main() {
  testWidgets('the cards count the real selection', (tester) async {
    await pumpPuzzleRoute(tester, Routes.settingsPuzzle, seed: _seed);
    final l10n = puzzleL10n(tester);
    final games = GameCatalogue.playable.length;
    expect(find.text(l10n.challengeSelectedCount(3, games)), findsOneWidget);
    expect(
      find.text(l10n.challengeSelectedCount(2, PuzzleType.values.length)),
      findsOneWidget,
    );
  });

  testWidgets('Puzzle types reads Off while puzzles are out of the pool', (
    tester,
  ) async {
    await pumpPuzzleRoute(
      tester,
      Routes.settingsPuzzle,
      seed: PuzzleSettings(
        enabledTypes: const {PuzzleType.arithmetic},
        enabledGames: const {'shake_dj', 'tilt_maze'},
        includePuzzles: false,
      ),
    );
    final l10n = puzzleL10n(tester);
    expect(find.text(l10n.puzzleOff), findsOneWidget);
    expect(
      find.text(l10n.challengeSelectedCount(1, PuzzleType.values.length)),
      findsNothing,
    );
  });

  testWidgets('the four value rows show the saved values', (tester) async {
    await pumpPuzzleRoute(tester, Routes.settingsPuzzle, seed: _seed);
    final l10n = puzzleL10n(tester);
    for (final value in [
      puzzleDifficultyLabel(PuzzleDifficulty.hard, l10n),
      l10n.puzzleSettingsTaskCountValue(2),
      puzzleEscapeLabel(PuzzleEscapeStrictness.confirmAndHold, l10n),
      toleranceValueLabel(4, l10n),
    ]) {
      await tester.scrollUntilVisible(
        find.text(value),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(value), findsOneWidget, reason: value);
    }
  });

  testWidgets('the overview and the stepper name the same wrong answer', (
    tester,
  ) async {
    await pumpPuzzleRoute(tester, Routes.settingsPuzzle, seed: _seed);
    final shown = puzzleL10n(tester).puzzleSettingsToleranceValue(5);
    await showAndTap(tester, find.text(shown));
    expect(find.byType(ToleranceStepper), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ToleranceStepper),
        matching: find.text(shown),
      ),
      findsOneWidget,
    );
  });

  testWidgets('warns on the overview when every type needs sight', (
    tester,
  ) async {
    await pumpPuzzleRoute(
      tester,
      Routes.settingsPuzzle,
      seed: PuzzleSettings(enabledTypes: const {PuzzleType.shapeRotation}),
    );
    expect(find.byType(VisualOnlyNotice), findsOneWidget);
  });

  testWidgets('each card opens its screen', (tester) async {
    await pumpPuzzleRoute(tester, Routes.settingsPuzzle, seed: _seed);
    final l10n = puzzleL10n(tester);
    await tester.tap(find.text(l10n.challengeGamesTitle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.challengeGamesHelp), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.puzzleSettingsTypesLabel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.puzzleTypesHelp), findsOneWidget);
  });

  testWidgets('a value row opens Advanced', (tester) async {
    await pumpPuzzleRoute(tester, Routes.settingsPuzzle, seed: _seed);
    final l10n = puzzleL10n(tester);
    await showAndTap(tester, find.text(l10n.puzzleSettingsTaskCountLabel));
    expect(find.text(l10n.puzzleSettingsTaskCountPuzzlesOnly), findsOneWidget);
  });

  testWidgets('a selection made on Games survives a restart', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await pumpPuzzleRoute(tester, Routes.settingsPuzzleGames, database: db);
    await tester.tap(toggleLabelled('Capy Rocket'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());

    await pumpPuzzleRoute(tester, Routes.settingsPuzzle, database: db);
    expect(
      find.text(
        puzzleL10n(
          tester,
        ).challengeSelectedCount(1, GameCatalogue.playable.length),
      ),
      findsOneWidget,
    );
  });
}
