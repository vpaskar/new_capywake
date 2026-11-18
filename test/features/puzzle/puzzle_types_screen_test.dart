import 'package:capywake/app/router.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/puzzle/puzzle_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'puzzle_harness.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  PuzzleSettings? seed,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) => pumpPuzzleRoute(
  tester,
  Routes.settingsPuzzleTypes,
  seed: seed,
  locale: locale,
  textScaler: textScaler,
);

void main() {
  testWidgets('renders all ten puzzle types under the two groups', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = puzzleL10n(tester);
    expect(find.text(l10n.puzzleSettingsGroupSpoken), findsOneWidget);
    for (final type in PuzzleType.values) {
      final label = find.text(puzzleTypeLabel(type, l10n));
      await tester.scrollUntilVisible(
        label,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(label, findsOneWidget, reason: 'missing ${type.name}');
    }
    expect(find.text(l10n.puzzleSettingsGroupVisual), findsOneWidget);
  });

  testWidgets('enabling a type persists it', (tester) async {
    final c = await _pump(
      tester,
      seed: PuzzleSettings(enabledTypes: const {PuzzleType.arithmetic}),
    );
    await showAndTap(
      tester,
      find.text(puzzleTypeLabel(PuzzleType.shapeRotation, puzzleL10n(tester))),
    );
    expect(
      (await savedPuzzleSettings(c)).enabledTypes,
      contains(PuzzleType.shapeRotation),
    );
  });

  testWidgets('the last enabled type cannot be turned off', (tester) async {
    final handle = tester.ensureSemantics();
    final c = await _pump(
      tester,
      seed: PuzzleSettings(enabledTypes: const {PuzzleType.arithmetic}),
    );
    final l10n = puzzleL10n(tester);
    final locked = tester
        .getSemantics(
          find.bySemanticsLabel(
            RegExp(
              '^${RegExp.escape(puzzleTypeLabel(PuzzleType.arithmetic, l10n))}'
              '.*${RegExp.escape(l10n.puzzleSettingsTypesFloorNote)}',
            ),
          ),
        )
        .getSemanticsData();
    expect(locked.hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
    await showAndTap(
      tester,
      find.text(puzzleTypeLabel(PuzzleType.arithmetic, puzzleL10n(tester))),
    );
    expect((await savedPuzzleSettings(c)).enabledTypes, {
      PuzzleType.arithmetic,
    });
  });

  testWidgets('the Puzzles switch takes puzzles out of the pool', (
    tester,
  ) async {
    final c = await _pump(
      tester,
      seed: PuzzleSettings(
        enabledTypes: const {PuzzleType.arithmetic},
        enabledGames: const {'memory_hideout'},
      ),
    );
    await tester.tap(toggleLabelled('Puzzles'));
    await tester.pumpAndSettle();
    final saved = await savedPuzzleSettings(c);
    expect(saved.includePuzzles, isFalse);
    expect(saved.enabledTypes, {PuzzleType.arithmetic});
  });

  testWidgets('the locked Puzzles switch links to Games', (tester) async {
    await _pump(tester);
    await showAndTap(tester, find.text(puzzleL10n(tester).challengeGamesTitle));
    expect(find.text(puzzleL10n(tester).challengeGamesHelp), findsOneWidget);
  });

  testWidgets('type names wrap, never truncate, at 2x German', (
    tester,
  ) async {
    await _pump(
      tester,
      locale: const Locale('de'),
      textScaler: const TextScaler.linear(2),
    );
    final l10n = puzzleL10n(tester);
    for (final type in PuzzleType.values) {
      final label = find.text(puzzleTypeLabel(type, l10n));
      await tester.scrollUntilVisible(
        label,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final card = find.ancestor(of: label, matching: find.byType(InkWell));
      final text = tester.getRect(label);
      final box = tester.getRect(card.first);
      expect(
        box.top <= text.top && text.bottom <= box.bottom,
        isTrue,
        reason: type.name,
      );
      expect(tester.widget<Text>(label).maxLines, isNull);
    }
  });

  testWidgets('with no game on, Puzzles is locked and says why (H1)', (
    tester,
  ) async {
    final c = await _pump(tester);
    final reason = puzzleL10n(tester).challengePoolFloorReason;
    final locked = toggleLabelled('Puzzles. $reason');
    expect(tester.widget<CapyToggle>(locked).onChanged, isNull);
    expect(find.text(reason), findsOneWidget);
    await tester.tap(locked);
    await tester.pumpAndSettle();
    expect((await savedPuzzleSettings(c)).includePuzzles, isTrue);
  });

  testWidgets('warns when every enabled type needs sight', (tester) async {
    await _pump(
      tester,
      seed: PuzzleSettings(
        enabledTypes: const {PuzzleType.gridPatternRecall},
      ),
    );
    expect(
      find.text(puzzleL10n(tester).puzzleSettingsVisualOnlyTitle),
      findsOneWidget,
    );
  });

  testWidgets('does not warn when a spoken type is enabled', (tester) async {
    await _pump(
      tester,
      seed: PuzzleSettings(enabledTypes: const {PuzzleType.arithmetic}),
    );
    expect(
      find.text(puzzleL10n(tester).puzzleSettingsVisualOnlyTitle),
      findsNothing,
    );
  });

  testWidgets('the grid ignores the status-bar inset (capture finding)', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 59.1 * 3);
    addTearDown(tester.view.resetPadding);
    await _pump(tester);
    final l10n = puzzleL10n(tester);
    final heading = tester.getRect(find.text(l10n.puzzleSettingsGroupSpoken));
    final card = tester.getRect(
      find
          .ancestor(
            of: find.text(puzzleTypeLabel(PuzzleType.arithmetic, l10n)),
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(card.top - heading.bottom, lessThan(CapySpacing.xl));
  });

  testWidgets('a type card carries a tap action for a screen reader', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    final label = puzzleTypeLabel(PuzzleType.compareValues, puzzleL10n(tester));
    final card = find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}'));
    expect(
      tester
          .getSemantics(card)
          .getSemanticsData()
          .hasAction(
            SemanticsAction.tap,
          ),
      isTrue,
    );
    handle.dispose();
  });
}
