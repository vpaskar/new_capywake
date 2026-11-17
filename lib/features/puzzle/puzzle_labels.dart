import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The localized name of one puzzle type.
String puzzleTypeLabel(PuzzleType type, AppLocalizations l10n) =>
    switch (type) {
      PuzzleType.arithmetic => l10n.puzzleTypeArithmetic,
      PuzzleType.sequenceNext => l10n.puzzleTypeSequenceNext,
      PuzzleType.missingOperator => l10n.puzzleTypeMissingOperator,
      PuzzleType.compareValues => l10n.puzzleTypeCompareValues,
      PuzzleType.oddOneOutNumeric => l10n.puzzleTypeOddOneOut,
      PuzzleType.digitRecall => l10n.puzzleTypeDigitRecall,
      PuzzleType.digitRecallReversed => l10n.puzzleTypeDigitRecallReversed,
      PuzzleType.gridPatternRecall => l10n.puzzleTypeGridPattern,
      PuzzleType.spotTheChange => l10n.puzzleTypeSpotTheChange,
      PuzzleType.shapeRotation => l10n.puzzleTypeShapeRotation,
    };

/// A glanceable icon per type — Material glyphs, not cutouts (`asset_gaps.md`
/// G21); decorative, excluded from semantics.
IconData puzzleTypeIcon(PuzzleType type) => switch (type) {
  PuzzleType.arithmetic => Icons.calculate_outlined,
  PuzzleType.sequenceNext => Icons.trending_up_rounded,
  PuzzleType.missingOperator => Icons.add_circle_outline_rounded,
  PuzzleType.compareValues => Icons.sort_rounded,
  PuzzleType.oddOneOutNumeric => Icons.filter_alt_outlined,
  PuzzleType.digitRecall => Icons.pin_outlined,
  PuzzleType.digitRecallReversed => Icons.swap_horiz_rounded,
  PuzzleType.gridPatternRecall => Icons.grid_view_rounded,
  PuzzleType.spotTheChange => Icons.difference_outlined,
  PuzzleType.shapeRotation => Icons.rotate_right_rounded,
};

/// The localized accessibility note shown on a type card.
String puzzleAccessibilityLabel(PuzzleType type, AppLocalizations l10n) =>
    type.isScreenReaderSolvable
    ? l10n.puzzleAccessibilitySpokenLabel
    : l10n.puzzleAccessibilityVisualLabel;

/// The localized name of a difficulty, shared with the alarm form's vocabulary.
String puzzleDifficultyLabel(PuzzleDifficulty d, AppLocalizations l10n) =>
    switch (d) {
      PuzzleDifficulty.easy => l10n.alarmDismissDifficultyEasy,
      PuzzleDifficulty.medium => l10n.alarmDismissDifficultyMedium,
      PuzzleDifficulty.hard => l10n.alarmDismissDifficultyHard,
    };

/// The localized name of an escape-strictness setting. Two values only — no
/// "off"; the mockup's "Never" is not rendered.
String puzzleEscapeLabel(PuzzleEscapeStrictness s, AppLocalizations l10n) =>
    switch (s) {
      PuzzleEscapeStrictness.confirm => l10n.puzzleSettingsEscapeConfirm,
      PuzzleEscapeStrictness.confirmAndHold => l10n.puzzleSettingsEscapeHold,
    };
