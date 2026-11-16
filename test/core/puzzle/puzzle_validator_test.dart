import 'package:capywake/core/puzzle/puzzle.dart';
import 'package:capywake/core/puzzle/puzzle_content.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/core/puzzle/puzzle_validator.dart';
import 'package:flutter_test/flutter_test.dart';

Puzzle _numeric(int value) => Puzzle(
  type: PuzzleType.arithmetic,
  difficulty: PuzzleDifficulty.easy,
  seed: 1,
  content: const ArithmeticContent(
    left: 7,
    right: 3,
    operation: ArithmeticOperator.add,
  ),
  answer: NumericAnswer(value),
);

Puzzle _digits(List<int> digits, {bool reversed = false}) => Puzzle(
  type: reversed ? PuzzleType.digitRecallReversed : PuzzleType.digitRecall,
  difficulty: PuzzleDifficulty.easy,
  seed: 1,
  content: DigitRecallContent(digits: digits, reversed: reversed),
  answer: DigitsAnswer(reversed ? digits.reversed.toList() : digits),
);

Puzzle _option(int index) => Puzzle(
  type: PuzzleType.oddOneOutNumeric,
  difficulty: PuzzleDifficulty.easy,
  seed: 1,
  content: const OddOneOutNumericContent(
    values: [8, 16, 26, 32],
    divisor: 4,
  ),
  answer: OptionAnswer(index),
);

Puzzle _cells(List<GridCell> cells) => Puzzle(
  type: PuzzleType.gridPatternRecall,
  difficulty: PuzzleDifficulty.easy,
  seed: 1,
  content: GridPatternContent(rows: 3, columns: 3, cells: cells),
  answer: CellsAnswer(cells),
);

Puzzle _ordering(List<int> indices) => Puzzle(
  type: PuzzleType.compareValues,
  difficulty: PuzzleDifficulty.easy,
  seed: 1,
  content: const CompareValuesContent(
    values: [42, 17, 63],
    task: CompareTask.ascending,
  ),
  answer: OrderingAnswer(indices),
);

void main() {
  group('PuzzleValidator — numeric entry', () {
    final puzzle = _numeric(10);

    test('accepts the exact answer', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleTextResponse('10'),
        ),
        PuzzleAnswerOutcome.correct,
      );
      expect(
        PuzzleValidator.isCorrect(
          puzzle: puzzle,
          response: const PuzzleTextResponse('10'),
        ),
        isTrue,
      );
    });

    test('tolerates whitespace, leading zeros and a leading plus', () {
      for (final input in <String>['  10 ', '010', '0010', '+10', ' +010 ']) {
        expect(
          PuzzleValidator.validate(
            puzzle: puzzle,
            response: PuzzleTextResponse(input),
          ),
          PuzzleAnswerOutcome.correct,
          reason: '"$input" should be accepted',
        );
      }
    });

    test('tolerates the Unicode minus some keyboards emit', () {
      expect(
        PuzzleValidator.validate(
          puzzle: _numeric(-4),
          response: const PuzzleTextResponse('−4'),
        ),
        PuzzleAnswerOutcome.correct,
      );
    });

    test('a near miss is incorrect, not unparseable', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleTextResponse('11'),
        ),
        PuzzleAnswerOutcome.incorrect,
      );
    });

    test('nothing entered reads as empty', () {
      for (final input in <String>['', '   ', '\n']) {
        expect(
          PuzzleValidator.validate(
            puzzle: puzzle,
            response: PuzzleTextResponse(input),
          ),
          PuzzleAnswerOutcome.empty,
        );
      }
    });

    test('letters read as unparseable', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleTextResponse('ten'),
        ),
        PuzzleAnswerOutcome.unparseable,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleTextResponse('1.5'),
        ),
        PuzzleAnswerOutcome.unparseable,
      );
    });
  });

  group('PuzzleValidator — numbers as the ten locales display them', () {
    test('a grouped number can be typed back in every shipped locale', () {
      // CLAUDE.md requires numbers to be rendered through `intl`, and hard
      // answers reach four digits — so this is the form the user is actually
      // looking at. `int.tryParse` returns null for every one of them, which
      // meant a German user reading "1.998" and typing it back was told their
      // input was unparseable.
      final puzzle = _numeric(1998);
      for (final input in <String>[
        '1,998', // en, ja, ar
        '1.998', // de, es, it, pt, tr
        '1\u202F998', // fr — narrow no-break space
        '1\u00A0998', // ru — no-break space
        '1\u2009998', // thin space
        '1 998', // plain space
        '1998',
      ]) {
        expect(
          PuzzleValidator.validate(
            puzzle: puzzle,
            response: PuzzleTextResponse(input),
          ),
          PuzzleAnswerOutcome.correct,
          reason: 'grouped form ${input.codeUnits} should be accepted',
        );
      }
    });

    test('only a fully-grouped number is stripped, so decimals stay '
        'unparseable', () {
      // Reading "1.5" as 15 would accept an answer the user did not give.
      // Every separator must be followed by exactly three digits.
      for (final input in <String>['1.5', '1,5', '19.98', '1.9980', '1..998']) {
        expect(
          PuzzleValidator.validate(
            puzzle: _numeric(1998),
            response: PuzzleTextResponse(input),
          ),
          PuzzleAnswerOutcome.unparseable,
          reason: '"$input" is not a grouped whole number',
        );
      }
    });

    test('hexadecimal is not silently accepted', () {
      // `int.tryParse` with no radix honours an 0x prefix, so 0x40 used to
      // validate against an answer of 64.
      for (final input in <String>['0x40', '0X40', ' 0x40 ']) {
        expect(
          PuzzleValidator.validate(
            puzzle: _numeric(64),
            response: PuzzleTextResponse(input),
          ),
          PuzzleAnswerOutcome.unparseable,
        );
      }
      expect(
        PuzzleValidator.validate(
          puzzle: _numeric(64),
          response: const PuzzleTextResponse('64'),
        ),
        PuzzleAnswerOutcome.correct,
      );
    });

    test('Arabic and Persian digits are accepted', () {
      // `ar` is a shipped RTL locale and its keyboard emits U+0660-0669.
      // Without this a user on that keyboard cannot answer at all and has to
      // take the emergency escape every morning.
      expect(
        PuzzleValidator.validate(
          puzzle: _numeric(1998),
          response: const PuzzleTextResponse('\u0661\u0669\u0669\u0668'),
        ),
        PuzzleAnswerOutcome.correct,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: _numeric(42),
          response: const PuzzleTextResponse('\u06F4\u06F2'),
        ),
        PuzzleAnswerOutcome.correct,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: _digits(const [7, 2, 9, 4]),
          response: const PuzzleTextResponse('\u0667\u0662\u0669\u0664'),
        ),
        PuzzleAnswerOutcome.correct,
      );
    });
  });

  group('PuzzleValidator — digit entry', () {
    final puzzle = _digits(const [7, 2, 9, 4]);

    test('accepts the digits typed plainly', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleTextResponse('7294'),
        ),
        PuzzleAnswerOutcome.correct,
      );
    });

    test('accepts separators people naturally type', () {
      for (final input in <String>[
        '7 2 9 4',
        '7-2-9-4',
        ' 7294 ',
        '7−2−9−4',
      ]) {
        expect(
          PuzzleValidator.validate(
            puzzle: puzzle,
            response: PuzzleTextResponse(input),
          ),
          PuzzleAnswerOutcome.correct,
          reason: '"$input" should be accepted',
        );
      }
    });

    test('a leading zero in the answer survives the round trip', () {
      expect(
        PuzzleValidator.validate(
          puzzle: _digits(const [0, 5, 3]),
          response: const PuzzleTextResponse('053'),
        ),
        PuzzleAnswerOutcome.correct,
      );
    });

    test('the reversed variant expects the digits back to front', () {
      final reversed = _digits(const [3, 8, 1, 6], reversed: true);
      expect(
        PuzzleValidator.validate(
          puzzle: reversed,
          response: const PuzzleTextResponse('6183'),
        ),
        PuzzleAnswerOutcome.correct,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: reversed,
          response: const PuzzleTextResponse('3816'),
        ),
        PuzzleAnswerOutcome.incorrect,
      );
    });

    test('wrong digits, wrong length and letters are distinguished', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleTextResponse('7295'),
        ),
        PuzzleAnswerOutcome.incorrect,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleTextResponse('729'),
        ),
        PuzzleAnswerOutcome.incorrect,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleTextResponse('72x4'),
        ),
        PuzzleAnswerOutcome.unparseable,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleTextResponse('  -  '),
        ),
        PuzzleAnswerOutcome.empty,
      );
    });
  });

  group('PuzzleValidator — digit separators belong between digits', () {
    test('a leading or trailing separator is malformed, not a style', () {
      for (final input in <String>[
        '-7294',
        '7294-',
        '\u22127\u22122\u22129\u22124',
      ]) {
        expect(
          PuzzleValidator.validate(
            puzzle: _digits(const [7, 2, 9, 4]),
            response: PuzzleTextResponse(input),
          ),
          PuzzleAnswerOutcome.unparseable,
          reason: '"$input" has a separator outside the digits',
        );
      }
      expect(
        PuzzleValidator.validate(
          puzzle: _digits(const [7, 2, 9, 4]),
          response: const PuzzleTextResponse('7-2-9-4'),
        ),
        PuzzleAnswerOutcome.correct,
      );
    });
  });

  group('PuzzleValidator — option choice', () {
    final puzzle = _option(2);

    test('the answered slot is correct and any other is incorrect', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleOptionResponse(2),
        ),
        PuzzleAnswerOutcome.correct,
      );
      for (final index in <int>[0, 1, 3]) {
        expect(
          PuzzleValidator.validate(
            puzzle: puzzle,
            response: PuzzleOptionResponse(index),
          ),
          PuzzleAnswerOutcome.incorrect,
        );
      }
    });

    test('an index outside the offered range is unparseable', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleOptionResponse(-1),
        ),
        PuzzleAnswerOutcome.unparseable,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleOptionResponse(4),
        ),
        PuzzleAnswerOutcome.unparseable,
      );
    });
  });

  group('PuzzleValidator — grid cells', () {
    const cells = [GridCell(0, 0), GridCell(1, 2), GridCell(2, 1)];
    final puzzle = _cells(cells);

    test('tap order does not matter', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: PuzzleCellsResponse(cells.reversed.toList()),
        ),
        PuzzleAnswerOutcome.correct,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleCellsResponse([
            GridCell(1, 2),
            GridCell(0, 0),
            GridCell(2, 1),
          ]),
        ),
        PuzzleAnswerOutcome.correct,
      );
    });

    test('a wrong cell, too few and too many all read as incorrect', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleCellsResponse([
            GridCell(0, 0),
            GridCell(1, 2),
            GridCell(2, 2),
          ]),
        ),
        PuzzleAnswerOutcome.incorrect,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleCellsResponse([GridCell(0, 0)]),
        ),
        PuzzleAnswerOutcome.incorrect,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleCellsResponse([
            GridCell(0, 0),
            GridCell(1, 2),
            GridCell(2, 1),
            GridCell(0, 1),
          ]),
        ),
        PuzzleAnswerOutcome.incorrect,
      );
    });

    test('a duplicated tap is an input artefact, not a wrong answer', () {
      // `incorrect` feeds `recordWrong()`, so classifying a double-tap as a
      // wrong answer would ease the next puzzle and count against the user's
      // escape threshold for something they did not get wrong. The ordering
      // path already made this call for duplicates; the cells path did not.
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleCellsResponse([
            GridCell(0, 0),
            GridCell(0, 0),
            GridCell(1, 2),
          ]),
        ),
        PuzzleAnswerOutcome.unparseable,
      );
    });

    test('a cell outside the grid is unparseable', () {
      for (final cell in const [
        GridCell(9, 9),
        GridCell(-1, 0),
        GridCell(0, 3),
      ]) {
        expect(
          PuzzleValidator.validate(
            puzzle: puzzle,
            response: PuzzleCellsResponse([cell, const GridCell(1, 2)]),
          ),
          PuzzleAnswerOutcome.unparseable,
          reason: '$cell is not on a 3x3 grid',
        );
      }
    });

    test('no taps reads as empty', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleCellsResponse([]),
        ),
        PuzzleAnswerOutcome.empty,
      );
    });
  });

  group('PuzzleValidator — ordering', () {
    final puzzle = _ordering(const [1, 0, 2]);

    test('the exact order is correct', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleOrderingResponse([1, 0, 2]),
        ),
        PuzzleAnswerOutcome.correct,
      );
    });

    test('a different permutation is incorrect', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleOrderingResponse([0, 1, 2]),
        ),
        PuzzleAnswerOutcome.incorrect,
      );
    });

    test('a non-permutation is unparseable', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleOrderingResponse([1, 0]),
        ),
        PuzzleAnswerOutcome.unparseable,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleOrderingResponse([1, 1, 2]),
        ),
        PuzzleAnswerOutcome.unparseable,
      );
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleOrderingResponse([1, 0, 5]),
        ),
        PuzzleAnswerOutcome.unparseable,
      );
    });

    test('no arrangement reads as empty', () {
      expect(
        PuzzleValidator.validate(
          puzzle: puzzle,
          response: const PuzzleOrderingResponse([]),
        ),
        PuzzleAnswerOutcome.empty,
      );
    });
  });

  group('PuzzleValidator — response shape mismatch is a caller bug', () {
    test('each answer shape rejects the wrong response shape', () {
      final mismatches = <Puzzle, PuzzleResponse>{
        _numeric(10): const PuzzleOptionResponse(0),
        _digits(const [1, 2, 3]): const PuzzleOptionResponse(0),
        _option(1): const PuzzleTextResponse('1'),
        _cells(const [GridCell(0, 0)]): const PuzzleTextResponse('0,0'),
        _ordering(const [0, 1, 2]): const PuzzleOptionResponse(0),
      };
      for (final entry in mismatches.entries) {
        expect(
          () => PuzzleValidator.validate(
            puzzle: entry.key,
            response: entry.value,
          ),
          throwsArgumentError,
          reason: '${entry.key.type.name} accepted the wrong response shape',
        );
      }
    });
  });
}
