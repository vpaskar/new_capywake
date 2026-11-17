import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';

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

/// A glanceable painted icon per type; decorative, excluded from semantics.
ArtAsset puzzleTypeArt(PuzzleType type) => CapyArt.byId(
  'icon.puzzle.${switch (type) {
    PuzzleType.arithmetic => 'arithmetic',
    PuzzleType.sequenceNext => 'sequence_next',
    PuzzleType.missingOperator => 'missing_operator',
    PuzzleType.compareValues => 'compare_values',
    PuzzleType.oddOneOutNumeric => 'odd_one_out',
    PuzzleType.digitRecall => 'digit_recall',
    PuzzleType.digitRecallReversed => 'digit_recall_reversed',
    PuzzleType.gridPatternRecall => 'grid_pattern',
    PuzzleType.spotTheChange => 'spot_the_change',
    PuzzleType.shapeRotation => 'shape_rotation',
  }}',
);

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
