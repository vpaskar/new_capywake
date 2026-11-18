import 'package:capywake/app/router.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/design/capy_segmented.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'puzzle_harness.dart';

void main() {
  testWidgets('difficulty persists', (tester) async {
    final c = await pumpPuzzleRoute(tester, Routes.settingsPuzzleAdvanced);
    await showAndTap(
      tester,
      find.text(puzzleL10n(tester).alarmDismissDifficultyHard),
    );
    expect((await savedPuzzleSettings(c)).difficulty, PuzzleDifficulty.hard);
  });

  testWidgets('puzzles to solve persists, and says puzzles only', (
    tester,
  ) async {
    final c = await pumpPuzzleRoute(tester, Routes.settingsPuzzleAdvanced);
    final l10n = puzzleL10n(tester);
    await showAndTap(
      tester,
      find.bySemanticsLabel(l10n.puzzleSettingsTaskCountValue(4)),
    );
    expect((await savedPuzzleSettings(c)).taskCount, 4);
    expect(find.text(l10n.puzzleSettingsTaskCountPuzzlesOnly), findsOneWidget);
  });

  testWidgets('the escape control offers exactly two values (no "never")', (
    tester,
  ) async {
    await pumpPuzzleRoute(tester, Routes.settingsPuzzleAdvanced);
    final escape = tester
        .widgetList<CapySegmented<PuzzleEscapeStrictness>>(
          find.byType(CapySegmented<PuzzleEscapeStrictness>),
        )
        .single;
    expect(escape.segments.map((s) => s.value), PuzzleEscapeStrictness.values);
    expect(
      find.text(puzzleL10n(tester).puzzleSettingsEscapeExplanation),
      findsOneWidget,
    );
  });

  testWidgets('escape strictness persists', (tester) async {
    final c = await pumpPuzzleRoute(tester, Routes.settingsPuzzleAdvanced);
    await showAndTap(
      tester,
      find.text(puzzleL10n(tester).puzzleSettingsEscapeHold),
    );
    expect(
      (await savedPuzzleSettings(c)).escapeStrictness,
      PuzzleEscapeStrictness.confirmAndHold,
    );
  });

  testWidgets('the tolerance stepper shows tolerated + 1 and raises it', (
    tester,
  ) async {
    final c = await pumpPuzzleRoute(
      tester,
      Routes.settingsPuzzleAdvanced,
      seed: PuzzleSettings.defaults(),
    );
    final l10n = puzzleL10n(tester);
    final before = (await savedPuzzleSettings(c)).toleratedWrongAnswers;
    expect(
      find.text(l10n.puzzleSettingsToleranceValue(before + 1)),
      findsOneWidget,
    );
    await showAndTap(tester, find.byTooltip(l10n.puzzleSettingsToleranceLater));
    expect((await savedPuzzleSettings(c)).toleratedWrongAnswers, before + 1);
    expect(
      find.text(l10n.puzzleSettingsToleranceExplanation),
      findsOneWidget,
    );
  });

  testWidgets('the tolerance cannot go past its bounds', (tester) async {
    await pumpPuzzleRoute(
      tester,
      Routes.settingsPuzzleAdvanced,
      seed: PuzzleSettings(
        enabledTypes: PuzzleSettings.defaults().enabledTypes,
        toleratedWrongAnswers: PuzzleSettings.minToleratedWrongAnswers,
      ),
    );
    final sooner = find.ancestor(
      of: find.byTooltip(puzzleL10n(tester).puzzleSettingsToleranceSooner),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(sooner).onPressed, isNull);
  });
}
