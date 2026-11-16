import 'package:capywake/core/puzzle/puzzle.dart';
import 'package:capywake/core/puzzle/puzzle_content.dart';
import 'package:capywake/core/puzzle/puzzle_equality.dart';
import 'package:meta/meta.dart';

/// What the user did, in the shape the puzzle expects.
///
/// Sealed and matched against the puzzle's [PuzzleAnswer]: a text response
/// answers a numeric or digits puzzle, an option response answers a
/// pick-one puzzle, and so on. Handing the validator the wrong shape is a
/// programming error, not a wrong answer, and throws.
@immutable
sealed class PuzzleResponse {
  const PuzzleResponse();
}

/// Raw typed text — for the numeric and digit-entry types.
final class PuzzleTextResponse extends PuzzleResponse {
  const PuzzleTextResponse(this.text);

  final String text;
}

/// The index of the option the user picked.
final class PuzzleOptionResponse extends PuzzleResponse {
  const PuzzleOptionResponse(this.index);

  final int index;
}

/// The cells the user tapped, in tap order (which does not matter).
final class PuzzleCellsResponse extends PuzzleResponse {
  const PuzzleCellsResponse(this.cells);

  final List<GridCell> cells;
}

/// Option indices in the order the user arranged them.
final class PuzzleOrderingResponse extends PuzzleResponse {
  const PuzzleOrderingResponse(this.indices);

  final List<int> indices;
}

/// The result of checking a response.
///
/// [empty] and [unparseable] exist so the surface can offer a calmer, more
/// useful hint ("enter the digits") instead of the flat "not quite" it shows
/// for a genuine wrong answer. None of them is framed as failure, and none of
/// them ever locks the alarm — the emergency escape stays reachable throughout.
enum PuzzleAnswerOutcome {
  /// The response answers the puzzle.
  correct,

  /// A real attempt, but not the answer. The next puzzle eases.
  incorrect,

  /// Nothing was entered.
  empty,

  /// The input is not in the shape the puzzle expects — letters where digits
  /// belong, the wrong number of positions in an ordering, an option index
  /// outside the offered range.
  unparseable,
}

/// Checks a [PuzzleResponse] against a [Puzzle].
///
/// Pure and total. Numeric and digit entry are deliberately tolerant of
/// incidental input noise — surrounding whitespace, leading zeros, a leading
/// `+`, the Unicode minus some keyboards emit, and the spaces or dashes people
/// naturally type between digits. None of that is a wrong answer.
abstract final class PuzzleValidator {
  /// Validate [response] against [puzzle].
  ///
  /// Throws [ArgumentError] when the response shape does not match the
  /// puzzle's answer shape.
  static PuzzleAnswerOutcome validate({
    required Puzzle puzzle,
    required PuzzleResponse response,
  }) {
    final answer = puzzle.answer;
    switch (answer) {
      case NumericAnswer():
        return _validateNumeric(answer, _expectText(puzzle, response));
      case DigitsAnswer():
        return _validateDigits(answer, _expectText(puzzle, response));
      case OptionAnswer():
        return _validateOption(
          answer,
          _expect<PuzzleOptionResponse>(puzzle, response),
          puzzle.optionCount,
        );
      case CellsAnswer():
        return _validateCells(
          answer,
          _expect<PuzzleCellsResponse>(puzzle, response),
          puzzle.content,
        );
      case OrderingAnswer():
        return _validateOrdering(
          answer,
          _expect<PuzzleOrderingResponse>(puzzle, response),
        );
    }
  }

  /// Convenience for callers that only need a yes/no.
  static bool isCorrect({
    required Puzzle puzzle,
    required PuzzleResponse response,
  }) =>
      validate(puzzle: puzzle, response: response) ==
      PuzzleAnswerOutcome.correct;

  // ---------------- per-shape validation ----------------

  static PuzzleAnswerOutcome _validateNumeric(
    NumericAnswer answer,
    String text,
  ) {
    final trimmed = _normaliseDigits(text).trim();
    if (trimmed.isEmpty) return PuzzleAnswerOutcome.empty;
    final normalised = _stripGrouping(_normaliseSigns(trimmed));
    // `int.tryParse` alone is too generous: with no radix it honours an `0x`
    // prefix, so `0x40` would validate against an answer of 64. Require a
    // plain optionally-signed run of digits and nothing else.
    if (!RegExp(r'^[+-]?[0-9]+$').hasMatch(normalised)) {
      return PuzzleAnswerOutcome.unparseable;
    }
    final parsed = int.tryParse(normalised);
    if (parsed == null) return PuzzleAnswerOutcome.unparseable;
    return parsed == answer.value
        ? PuzzleAnswerOutcome.correct
        : PuzzleAnswerOutcome.incorrect;
  }

  static PuzzleAnswerOutcome _validateDigits(
    DigitsAnswer answer,
    String text,
  ) {
    // People type "7 2 9 4" or "7-2-9-4" as readily as "7294" — but only
    // *between* digits. A leading or trailing separator is malformed input,
    // not a style, and saying so is more useful than silently accepting it.
    final normalised = _normaliseDigits(text).trim();
    if (normalised.isEmpty) return PuzzleAnswerOutcome.empty;
    if (!RegExp(r'^[0-9]+([\s\-−][0-9]+)*$').hasMatch(normalised)) {
      return RegExp('[0-9]').hasMatch(normalised)
          ? PuzzleAnswerOutcome.unparseable
          : PuzzleAnswerOutcome.empty;
    }
    final digits = <int>[
      for (final unit
          in normalised.replaceAll(RegExp(r'[\s\-−]'), '').codeUnits)
        unit - 0x30, // '0'
    ];
    return puzzleListEquals(digits, answer.digits)
        ? PuzzleAnswerOutcome.correct
        : PuzzleAnswerOutcome.incorrect;
  }

  static PuzzleAnswerOutcome _validateOption(
    OptionAnswer answer,
    PuzzleOptionResponse response,
    int optionCount,
  ) {
    if (response.index < 0 || response.index >= optionCount) {
      return PuzzleAnswerOutcome.unparseable;
    }
    return response.index == answer.index
        ? PuzzleAnswerOutcome.correct
        : PuzzleAnswerOutcome.incorrect;
  }

  static PuzzleAnswerOutcome _validateCells(
    CellsAnswer answer,
    PuzzleCellsResponse response,
    PuzzleContent content,
  ) {
    if (response.cells.isEmpty) return PuzzleAnswerOutcome.empty;
    // A cell outside the grid, or the same cell twice, is an input artefact
    // rather than a real attempt — the same judgement `_validateOption` makes
    // for an out-of-range index and `_validateOrdering` for a duplicate. It
    // matters more here than it looks: `incorrect` feeds `recordWrong()`, so
    // classifying a double-tap as a wrong answer would ease the next puzzle
    // and count against the user's escape threshold for something they did
    // not get wrong.
    if (content is GridPatternContent) {
      final outOfGrid = response.cells.any(
        (c) =>
            c.row < 0 ||
            c.row >= content.rows ||
            c.column < 0 ||
            c.column >= content.columns,
      );
      if (outOfGrid) return PuzzleAnswerOutcome.unparseable;
    }
    if (response.cells.toSet().length != response.cells.length) {
      return PuzzleAnswerOutcome.unparseable;
    }
    // Order-insensitive on purpose: the puzzle is which cells lit up, not the
    // order they are tapped in.
    return puzzleUnorderedEquals(response.cells, answer.cells)
        ? PuzzleAnswerOutcome.correct
        : PuzzleAnswerOutcome.incorrect;
  }

  static PuzzleAnswerOutcome _validateOrdering(
    OrderingAnswer answer,
    PuzzleOrderingResponse response,
  ) {
    if (response.indices.isEmpty) return PuzzleAnswerOutcome.empty;
    // A duplicate index needs no separate check: `answer.indices` is always a
    // duplicate-free permutation, so a same-length response containing one is
    // necessarily missing another and fails the multiset comparison anyway.
    if (response.indices.length != answer.indices.length ||
        !puzzleUnorderedEquals(response.indices, answer.indices)) {
      // Not a permutation of the offered positions — the surface produced
      // something the puzzle never offered.
      return PuzzleAnswerOutcome.unparseable;
    }
    return puzzleListEquals(response.indices, answer.indices)
        ? PuzzleAnswerOutcome.correct
        : PuzzleAnswerOutcome.incorrect;
  }

  // ---------------- helpers ----------------

  static String _expectText(Puzzle puzzle, PuzzleResponse response) =>
      _expect<PuzzleTextResponse>(puzzle, response).text;

  static T _expect<T extends PuzzleResponse>(
    Puzzle puzzle,
    PuzzleResponse response,
  ) {
    if (response is T) return response;
    throw ArgumentError.value(
      response,
      'response',
      'A ${puzzle.type.name} puzzle expects a $T',
    );
  }

  /// Some keyboards emit U+2212 MINUS SIGN, and people sometimes type a
  /// leading `+`. Neither is a wrong answer.
  static String _normaliseSigns(String value) {
    final normalised = value.replaceAll('−', '-');
    return normalised.startsWith('+') ? normalised.substring(1) : normalised;
  }

  /// Fold non-ASCII decimal digits onto `0`-`9`.
  ///
  /// Arabic (U+0660-0669) and Extended Arabic-Indic / Persian (U+06F0-06F9)
  /// digits are what an Arabic keyboard produces, and `ar` is a shipped RTL
  /// locale. Without this a user on that keyboard cannot answer a numeric or
  /// digit-recall puzzle at all and has to take the emergency escape every
  /// single morning.
  static String _normaliseDigits(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Remove thousands separators from a fully-grouped number.
  ///
  /// `CLAUDE.md` requires every number to be displayed through `intl`, and
  /// hard answers reach four digits — so the puzzle a user reads is `1,998`
  /// in `en`/`ja`/`ar`, `1.998` in `de`/`es`/`it`/`pt`/`tr`, `1 998` in `fr`
  /// (U+202F) and `1 998` in `ru` (U+00A0). Typing back what you were shown
  /// must not be an error, and before this it was: `int.tryParse` returns
  /// null for all ten forms.
  ///
  /// Only a *fully* grouped number is stripped — every separator must be
  /// followed by exactly three digits. That is what keeps a decimal like
  /// `1.5` unparseable, which it must stay: puzzle answers are whole numbers,
  /// and quietly reading `1.5` as `15` would accept an answer the user did
  /// not give.
  static String _stripGrouping(String value) {
    if (!RegExp(
      '^[+-]?[0-9]{1,3}($_groupSeparators[0-9]{3})+\$',
    ).hasMatch(value)) {
      return value;
    }
    return value.replaceAll(RegExp(_groupSeparators), '');
  }

  /// The thousands separators the ten shipped locales actually emit: comma
  /// (`en`/`ja`/`ar`), full stop (`de`/`es`/`it`/`pt`/`tr`), no-break space
  /// (`ru`), narrow no-break space (`fr`), plus thin and plain spaces.
  ///
  /// Written as escapes rather than literals so the invisible ones cannot be
  /// lost to a careless edit or a copy-paste through a normalising editor.
  static const String _groupSeparators = '[,.    ]';
}
