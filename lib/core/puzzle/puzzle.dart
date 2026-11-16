import 'package:capywake/core/puzzle/puzzle_content.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_equality.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:meta/meta.dart';

/// The correct answer to a puzzle, in the same locale-neutral vocabulary as
/// the content.
///
/// Sealed: every answer shape has exactly one matching response shape, and the
/// validator switches over both exhaustively.
@immutable
sealed class PuzzleAnswer {
  const PuzzleAnswer();
}

/// A single number the user types.
final class NumericAnswer extends PuzzleAnswer {
  const NumericAnswer(this.value);

  final int value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NumericAnswer && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'NumericAnswer($value)';
}

/// The index of the correct option in the content's option list.
final class OptionAnswer extends PuzzleAnswer {
  const OptionAnswer(this.index);

  final int index;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OptionAnswer && other.index == index;
  }

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() => 'OptionAnswer($index)';
}

/// An ordered run of digits the user types.
final class DigitsAnswer extends PuzzleAnswer {
  const DigitsAnswer(this.digits);

  final List<int> digits;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DigitsAnswer && puzzleListEquals(other.digits, digits);
  }

  @override
  int get hashCode => puzzleListHash(digits);

  @override
  String toString() => 'DigitsAnswer($digits)';
}

/// The set of cells the user must tap. Order does not matter when validating.
final class CellsAnswer extends PuzzleAnswer {
  const CellsAnswer(this.cells);

  final List<GridCell> cells;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CellsAnswer && puzzleListEquals(other.cells, cells);
  }

  @override
  int get hashCode => puzzleListHash(cells);

  @override
  String toString() => 'CellsAnswer($cells)';
}

/// Option indices in the order the user must arrange them.
final class OrderingAnswer extends PuzzleAnswer {
  const OrderingAnswer(this.indices);

  final List<int> indices;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderingAnswer && puzzleListEquals(other.indices, indices);
  }

  @override
  int get hashCode => puzzleListHash(indices);

  @override
  String toString() => 'OrderingAnswer($indices)';
}

/// One generated puzzle: what to show, and what answers it.
///
/// Carries its [seed] so a puzzle can be regenerated identically — useful for
/// reproducing a report and for the debug gallery. Nothing here is a
/// display string; the surface renders [content] and the ARB layer supplies
/// only the instruction and the accessibility labels.
@immutable
class Puzzle {
  const Puzzle({
    required this.type,
    required this.difficulty,
    required this.seed,
    required this.content,
    required this.answer,
  });

  final PuzzleType type;
  final PuzzleDifficulty difficulty;

  /// The seed `PuzzleGenerator.generate` was called with.
  final int seed;

  final PuzzleContent content;
  final PuzzleAnswer answer;

  /// How many options the user picks between, or `0` when the puzzle is
  /// answered by typing or tapping.
  int get optionCount => content.optionCount;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Puzzle &&
        other.type == type &&
        other.difficulty == difficulty &&
        other.seed == seed &&
        other.content == content &&
        other.answer == answer;
  }

  @override
  int get hashCode => Object.hash(type, difficulty, seed, content, answer);

  @override
  String toString() =>
      'Puzzle(${type.name}, ${difficulty.name}, seed: $seed, '
      'content: $content, answer: $answer)';
}
