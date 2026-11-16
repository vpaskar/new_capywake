/// Accessibility profile of a puzzle type.
///
/// Declared per type so the settings layer (Phase 19) and the wake surface
/// (Phase 18) can reason about who a type actually works for, rather than
/// discovering it at 03:00.
enum PuzzleAccessibility {
  /// The puzzle can be read out and answered without sight — the content is
  /// numbers and operators, and the answer is typed or picked from a labelled
  /// list.
  screenReaderSolvable,

  /// The puzzle depends on seeing spatial content (a grid, a row of shapes, a
  /// rotation). A screen reader can announce that a puzzle is present, but it
  /// cannot convey the content. Never the only enabled type for a user who
  /// relies on a screen reader.
  visualOnly,
}

/// The ten shipped wake-puzzle types.
///
/// Every type's *content* is numbers, shapes, positions or patterns — nothing
/// that translates. Only the instruction and the accessibility labels live in
/// ARB (Phase 18). The rejected alternatives, and why, are recorded in
/// `ai-orchestration/phases/phase-17-puzzle-engine.md`.
enum PuzzleType {
  /// `17 + 28`, `63 − 19`, `8 × 7` — type the result.
  arithmetic,

  /// `2, 4, 8, 16, ?` — type the next term.
  sequenceNext,

  /// `8 ? 4 = 32` — pick the operator that makes it true.
  missingOperator,

  /// Pick the largest / smallest of a set, or put a set in ascending order.
  compareValues,

  /// `12, 18, 24, 31, 36` — pick the one that breaks the rule.
  oddOneOutNumeric,

  /// Show `7-2-9-4`, then enter it.
  digitRecall,

  /// Show `3-8-1-6`, enter `6-1-8-3`.
  digitRecallReversed,

  /// Flash cells in a grid, reproduce them.
  gridPatternRecall,

  /// A row of shapes, shown again with one replaced — pick the position that
  /// changed. Shown in sequence, not side by side.
  spotTheChange,

  /// Pick the shape rotated a quarter turn from the reference.
  shapeRotation;

  /// Whether this type can be solved without sight.
  PuzzleAccessibility get accessibility => switch (this) {
    PuzzleType.arithmetic ||
    PuzzleType.sequenceNext ||
    PuzzleType.missingOperator ||
    PuzzleType.compareValues ||
    PuzzleType.oddOneOutNumeric ||
    PuzzleType.digitRecall ||
    PuzzleType.digitRecallReversed => PuzzleAccessibility.screenReaderSolvable,
    PuzzleType.gridPatternRecall ||
    PuzzleType.spotTheChange ||
    PuzzleType.shapeRotation => PuzzleAccessibility.visualOnly,
  };

  /// Convenience for [PuzzleAccessibility.screenReaderSolvable].
  bool get isScreenReaderSolvable =>
      accessibility == PuzzleAccessibility.screenReaderSolvable;

  /// Every type that is solvable without sight.
  ///
  /// This is deliberately the default enabled set (see `PuzzleSettings`): the
  /// out-of-the-box experience has to work for everyone, and these seven still
  /// rotate widely enough that no two consecutive mornings look alike.
  static Set<PuzzleType> get screenReaderSolvableTypes =>
      values.where((t) => t.isScreenReaderSolvable).toSet();

  /// Every shipped type, as a set.
  static Set<PuzzleType> get allTypes => values.toSet();
}
