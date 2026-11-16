import 'package:capywake/core/puzzle/puzzle_equality.dart';
import 'package:meta/meta.dart';

/// The four arithmetic operations a puzzle can reference.
///
/// Deliberately carries **no symbol string**. `+`, `−`, `×`, `÷` are rendered
/// at the UI boundary (Phase 18); the model stays free of display strings so
/// nothing in `lib/core/puzzle/` can ever become locale-dependent.
enum ArithmeticOperator { add, subtract, multiply, divide }

/// What a [CompareValuesContent] asks for.
enum CompareTask {
  /// Pick the largest value.
  largest,

  /// Pick the smallest value.
  smallest,

  /// Put every value in ascending order.
  ascending,
}

/// The shape vocabulary used by the visual puzzle types.
///
/// Every shape here is **rotationally asymmetric** — no shape maps onto itself
/// under a 90°, 180° or 270° turn. That is what makes [ShapeRotationContent]
/// answerable at all: a square or a circle would leave several options
/// indistinguishable. Shapes are referenced by this enum and never by a word,
/// so nothing needs translating.
enum PuzzleShape {
  arrow,
  chevron,
  flag,
  teardrop,
  hook,
  wedge,
  halfMoon,
  pennant,
}

/// A cell in a [GridPatternContent] grid. Zero-based, row-major.
@immutable
class GridCell {
  const GridCell(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridCell && other.row == row && other.column == column;
  }

  @override
  int get hashCode => Object.hash(row, column);

  @override
  String toString() => 'GridCell($row, $column)';
}

/// The generated, locale-neutral content of a puzzle.
///
/// Numbers, operators, digits, grid coordinates, shape enums and rotations —
/// never a display string. Sealed so the render dispatch in Phase 18 is
/// exhaustive and adding an eleventh type cannot silently miss a surface.
@immutable
sealed class PuzzleContent {
  const PuzzleContent();

  /// How many options the user chooses between, or `0` for the types that are
  /// answered by typing or tapping rather than by picking from a list.
  int get optionCount => 0;
}

/// `left <operation> right` — the user types the result.
final class ArithmeticContent extends PuzzleContent {
  const ArithmeticContent({
    required this.left,
    required this.right,
    required this.operation,
  });

  final int left;
  final int right;
  final ArithmeticOperator operation;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArithmeticContent &&
        other.left == left &&
        other.right == right &&
        other.operation == operation;
  }

  @override
  int get hashCode => Object.hash(left, right, operation);

  @override
  String toString() => 'ArithmeticContent($left, ${operation.name}, $right)';
}

/// The visible terms of a sequence — the user types the next one.
final class SequenceNextContent extends PuzzleContent {
  const SequenceNextContent({required this.shown});

  /// The terms shown, in order. The answer continues this list.
  final List<int> shown;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SequenceNextContent && puzzleListEquals(other.shown, shown);
  }

  @override
  int get hashCode => puzzleListHash(shown);

  @override
  String toString() => 'SequenceNextContent($shown)';
}

/// `left ? right = result` — the user picks the operator from [options].
final class MissingOperatorContent extends PuzzleContent {
  const MissingOperatorContent({
    required this.left,
    required this.right,
    required this.result,
    required this.options,
  });

  final int left;
  final int right;
  final int result;

  /// The operators offered, in presentation order. Exactly one of them makes
  /// the equation true — the generator proves this by construction.
  final List<ArithmeticOperator> options;

  @override
  int get optionCount => options.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MissingOperatorContent &&
        other.left == left &&
        other.right == right &&
        other.result == result &&
        puzzleListEquals(other.options, options);
  }

  @override
  int get hashCode => Object.hash(left, right, result, puzzleListHash(options));

  @override
  String toString() =>
      'MissingOperatorContent($left ? $right = $result, options: $options)';
}

/// A set of distinct values plus what to do with them.
final class CompareValuesContent extends PuzzleContent {
  const CompareValuesContent({required this.values, required this.task});

  /// Distinct values in presentation order. Distinctness is what makes
  /// "largest" / "smallest" a single unambiguous answer.
  final List<int> values;
  final CompareTask task;

  @override
  int get optionCount => values.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompareValuesContent &&
        puzzleListEquals(other.values, values) &&
        other.task == task;
  }

  @override
  int get hashCode => Object.hash(puzzleListHash(values), task);

  @override
  String toString() => 'CompareValuesContent($values, ${task.name})';
}

/// Values that all share a rule, except one.
final class OddOneOutNumericContent extends PuzzleContent {
  const OddOneOutNumericContent({
    required this.values,
    required this.divisor,
  });

  /// Values in presentation order. Exactly one is not a multiple of [divisor].
  final List<int> values;

  /// The rule every value but one obeys.
  ///
  /// **The surface is required to state this rule up front** — "Which is not a
  /// multiple of 4?" — and it is not optional. An odd-one-out over integers
  /// whose rule must be *guessed* has no single defensible answer: any finite
  /// set of numbers is also singled out by digit length, being the only
  /// square, the only multiple of 7, and endlessly more. Measurement of an
  /// earlier hidden-rule version found a competing reading pointing at a
  /// different value in roughly a third of puzzles. Stating the rule is what
  /// makes this type correct, so this field is part of the puzzle, not a
  /// debugging aid.
  final int divisor;

  @override
  int get optionCount => values.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OddOneOutNumericContent &&
        puzzleListEquals(other.values, values) &&
        other.divisor == divisor;
  }

  @override
  int get hashCode => Object.hash(puzzleListHash(values), divisor);

  @override
  String toString() => 'OddOneOutNumericContent($values, divisor: $divisor)';
}

/// Digits shown briefly, then re-entered — forwards or backwards.
final class DigitRecallContent extends PuzzleContent {
  const DigitRecallContent({required this.digits, required this.reversed});

  /// The digits as shown, in order. Always distinct, which keeps the display
  /// unambiguous for a half-asleep reader.
  final List<int> digits;

  /// Whether the user must enter [digits] back to front.
  final bool reversed;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DigitRecallContent &&
        puzzleListEquals(other.digits, digits) &&
        other.reversed == reversed;
  }

  @override
  int get hashCode => Object.hash(puzzleListHash(digits), reversed);

  @override
  String toString() => 'DigitRecallContent($digits, reversed: $reversed)';
}

/// Cells flashed in a grid, to be reproduced.
final class GridPatternContent extends PuzzleContent {
  const GridPatternContent({
    required this.rows,
    required this.columns,
    required this.cells,
  });

  final int rows;
  final int columns;

  /// The distinct cells that light up. Order is presentation order only — the
  /// answer is order-insensitive.
  final List<GridCell> cells;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridPatternContent &&
        other.rows == rows &&
        other.columns == columns &&
        puzzleListEquals(other.cells, cells);
  }

  @override
  int get hashCode => Object.hash(rows, columns, puzzleListHash(cells));

  @override
  String toString() => 'GridPatternContent(${rows}x$columns, $cells)';
}

/// One row of shapes, shown and then shown again with a single shape swapped.
///
/// [before] and [after] are presented **one after the other, in the same
/// place** — this is a change-detection task, not a side-by-side comparison.
/// (An earlier version of this doc said "two rows", which contradicted
/// `PuzzleType.spotTheChange` and describes a materially easier puzzle.)
final class SpotTheChangeContent extends PuzzleContent {
  const SpotTheChangeContent({required this.before, required this.after});

  /// The row as first shown. Shapes are distinct, so a change is unambiguous.
  final List<PuzzleShape> before;

  /// The row as shown second. Identical to [before] except at the changed
  /// position, and the replacement is a shape that was not already on the row.
  final List<PuzzleShape> after;

  @override
  int get optionCount => after.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpotTheChangeContent &&
        puzzleListEquals(other.before, before) &&
        puzzleListEquals(other.after, after);
  }

  @override
  int get hashCode =>
      Object.hash(puzzleListHash(before), puzzleListHash(after));

  @override
  String toString() => 'SpotTheChangeContent($before -> $after)';
}

/// One shape shown at a reference angle, and the same shape at several angles.
final class ShapeRotationContent extends PuzzleContent {
  const ShapeRotationContent({
    required this.shape,
    required this.referenceRotation,
    required this.optionRotations,
  });

  /// The shape used for the reference and every option. Always a rotationally
  /// asymmetric [PuzzleShape], so distinct angles look distinct.
  final PuzzleShape shape;

  /// The reference angle in degrees clockwise: one of 0, 90, 180, 270.
  final int referenceRotation;

  /// The candidate angles, in presentation order. Distinct, so exactly one is
  /// a quarter turn clockwise from [referenceRotation].
  final List<int> optionRotations;

  /// The angle that answers the puzzle: a quarter turn clockwise.
  int get targetRotation => (referenceRotation + 90) % 360;

  @override
  int get optionCount => optionRotations.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShapeRotationContent &&
        other.shape == shape &&
        other.referenceRotation == referenceRotation &&
        puzzleListEquals(other.optionRotations, optionRotations);
  }

  @override
  int get hashCode =>
      Object.hash(shape, referenceRotation, puzzleListHash(optionRotations));

  @override
  String toString() =>
      'ShapeRotationContent(${shape.name} @$referenceRotation, '
      'options: $optionRotations)';
}
