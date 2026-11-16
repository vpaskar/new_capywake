import 'package:capywake/core/puzzle/puzzle.dart';
import 'package:capywake/core/puzzle/puzzle_content.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_equality.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every content and answer type asserted the same way: equal to itself, equal
/// to an identical copy (with a matching hash), different when any one field
/// differs, and carrying a `toString` that names its own data.
///
/// This looks mechanical, and it is — but these are the value types the surface
/// and the tests compare puzzles by. An `==` that short-circuits before its
/// last field silently makes two different puzzles look identical.
void _assertValueSemantics<T extends Object>(
  T subject,
  T identicalCopy,
  List<T> variants, {
  required String toStringContains,
}) {
  expect(subject, subject);
  expect(subject, identicalCopy);
  expect(subject.hashCode, identicalCopy.hashCode);
  for (final variant in variants) {
    expect(
      subject,
      isNot(variant),
      reason: '$subject compared equal to $variant',
    );
  }
  expect(subject, isNot(<String>['not the right type']));
  expect(subject.toString(), contains(toStringContains));
}

void main() {
  group('puzzle equality helpers', () {
    test('puzzleListEquals compares element-wise', () {
      const list = [1, 2, 3];
      expect(puzzleListEquals(list, list), isTrue);
      expect(puzzleListEquals(list, const [1, 2, 3]), isTrue);
      expect(puzzleListEquals(list, const [1, 2]), isFalse);
      expect(puzzleListEquals(list, const [1, 3, 2]), isFalse);
      expect(puzzleListEquals(const <int>[], const <int>[]), isTrue);
    });

    test('puzzleUnorderedEquals ignores order but not multiplicity', () {
      const list = [1, 2, 3];
      expect(puzzleUnorderedEquals(list, list), isTrue);
      expect(puzzleUnorderedEquals(list, const [3, 1, 2]), isTrue);
      expect(puzzleUnorderedEquals(list, const [1, 2]), isFalse);
      expect(puzzleUnorderedEquals(const [1, 1, 2], const [1, 2, 2]), isFalse);
      expect(puzzleUnorderedEquals(const [1, 1, 2], const [1, 2, 1]), isTrue);
      expect(puzzleUnorderedEquals(const <int>[], const <int>[]), isTrue);
    });

    test('puzzleListHash agrees with puzzleListEquals', () {
      expect(puzzleListHash(const [1, 2]), puzzleListHash(const [1, 2]));
    });
  });

  group('GridCell', () {
    test('value semantics', () {
      _assertValueSemantics(
        const GridCell(1, 2),
        const GridCell(1, 2),
        const [GridCell(2, 2), GridCell(1, 1)],
        toStringContains: 'GridCell(1, 2)',
      );
    });
  });

  group('PuzzleContent value semantics', () {
    test('ArithmeticContent', () {
      _assertValueSemantics(
        const ArithmeticContent(
          left: 7,
          right: 3,
          operation: ArithmeticOperator.add,
        ),
        const ArithmeticContent(
          left: 7,
          right: 3,
          operation: ArithmeticOperator.add,
        ),
        const [
          ArithmeticContent(
            left: 8,
            right: 3,
            operation: ArithmeticOperator.add,
          ),
          ArithmeticContent(
            left: 7,
            right: 4,
            operation: ArithmeticOperator.add,
          ),
          ArithmeticContent(
            left: 7,
            right: 3,
            operation: ArithmeticOperator.multiply,
          ),
        ],
        toStringContains: 'ArithmeticContent(7, add, 3)',
      );
      expect(
        const ArithmeticContent(
          left: 7,
          right: 3,
          operation: ArithmeticOperator.add,
        ).optionCount,
        0,
      );
    });

    test('SequenceNextContent', () {
      _assertValueSemantics(
        const SequenceNextContent(shown: [2, 4, 8]),
        const SequenceNextContent(shown: [2, 4, 8]),
        const [
          SequenceNextContent(shown: [2, 4, 9]),
          SequenceNextContent(shown: [2, 4]),
        ],
        toStringContains: '[2, 4, 8]',
      );
    });

    test('MissingOperatorContent', () {
      _assertValueSemantics(
        const MissingOperatorContent(
          left: 8,
          right: 4,
          result: 32,
          options: [ArithmeticOperator.add, ArithmeticOperator.multiply],
        ),
        const MissingOperatorContent(
          left: 8,
          right: 4,
          result: 32,
          options: [ArithmeticOperator.add, ArithmeticOperator.multiply],
        ),
        const [
          MissingOperatorContent(
            left: 9,
            right: 4,
            result: 32,
            options: [ArithmeticOperator.add, ArithmeticOperator.multiply],
          ),
          MissingOperatorContent(
            left: 8,
            right: 5,
            result: 32,
            options: [ArithmeticOperator.add, ArithmeticOperator.multiply],
          ),
          MissingOperatorContent(
            left: 8,
            right: 4,
            result: 33,
            options: [ArithmeticOperator.add, ArithmeticOperator.multiply],
          ),
          MissingOperatorContent(
            left: 8,
            right: 4,
            result: 32,
            options: [ArithmeticOperator.multiply, ArithmeticOperator.add],
          ),
        ],
        toStringContains: '8 ? 4 = 32',
      );
      expect(
        const MissingOperatorContent(
          left: 8,
          right: 4,
          result: 32,
          options: [ArithmeticOperator.add, ArithmeticOperator.multiply],
        ).optionCount,
        2,
      );
    });

    test('CompareValuesContent', () {
      _assertValueSemantics(
        const CompareValuesContent(
          values: [42, 17, 63],
          task: CompareTask.largest,
        ),
        const CompareValuesContent(
          values: [42, 17, 63],
          task: CompareTask.largest,
        ),
        const [
          CompareValuesContent(
            values: [42, 17, 64],
            task: CompareTask.largest,
          ),
          CompareValuesContent(
            values: [42, 17, 63],
            task: CompareTask.smallest,
          ),
        ],
        toStringContains: 'largest',
      );
      expect(
        const CompareValuesContent(
          values: [42, 17, 63],
          task: CompareTask.ascending,
        ).optionCount,
        3,
      );
    });

    test('OddOneOutNumericContent', () {
      _assertValueSemantics(
        const OddOneOutNumericContent(values: [8, 16, 26], divisor: 4),
        const OddOneOutNumericContent(values: [8, 16, 26], divisor: 4),
        const [
          OddOneOutNumericContent(values: [8, 16, 28], divisor: 4),
          OddOneOutNumericContent(values: [8, 16, 26], divisor: 8),
        ],
        toStringContains: 'divisor: 4',
      );
      expect(
        const OddOneOutNumericContent(
          values: [8, 16, 26],
          divisor: 4,
        ).optionCount,
        3,
      );
    });

    test('DigitRecallContent', () {
      _assertValueSemantics(
        const DigitRecallContent(digits: [7, 2, 9], reversed: false),
        const DigitRecallContent(digits: [7, 2, 9], reversed: false),
        const [
          DigitRecallContent(digits: [7, 2, 8], reversed: false),
          DigitRecallContent(digits: [7, 2, 9], reversed: true),
        ],
        toStringContains: 'reversed: false',
      );
    });

    test('GridPatternContent', () {
      _assertValueSemantics(
        const GridPatternContent(
          rows: 3,
          columns: 3,
          cells: [GridCell(0, 0), GridCell(1, 1)],
        ),
        const GridPatternContent(
          rows: 3,
          columns: 3,
          cells: [GridCell(0, 0), GridCell(1, 1)],
        ),
        const [
          GridPatternContent(
            rows: 4,
            columns: 3,
            cells: [GridCell(0, 0), GridCell(1, 1)],
          ),
          GridPatternContent(
            rows: 3,
            columns: 4,
            cells: [GridCell(0, 0), GridCell(1, 1)],
          ),
          GridPatternContent(
            rows: 3,
            columns: 3,
            cells: [GridCell(0, 0), GridCell(2, 1)],
          ),
        ],
        toStringContains: '3x3',
      );
      expect(
        const GridPatternContent(
          rows: 3,
          columns: 3,
          cells: [GridCell(0, 0)],
        ).optionCount,
        0,
      );
    });

    test('SpotTheChangeContent', () {
      _assertValueSemantics(
        const SpotTheChangeContent(
          before: [PuzzleShape.arrow, PuzzleShape.flag],
          after: [PuzzleShape.arrow, PuzzleShape.hook],
        ),
        const SpotTheChangeContent(
          before: [PuzzleShape.arrow, PuzzleShape.flag],
          after: [PuzzleShape.arrow, PuzzleShape.hook],
        ),
        const [
          SpotTheChangeContent(
            before: [PuzzleShape.wedge, PuzzleShape.flag],
            after: [PuzzleShape.arrow, PuzzleShape.hook],
          ),
          SpotTheChangeContent(
            before: [PuzzleShape.arrow, PuzzleShape.flag],
            after: [PuzzleShape.arrow, PuzzleShape.wedge],
          ),
        ],
        toStringContains: '->',
      );
      expect(
        const SpotTheChangeContent(
          before: [PuzzleShape.arrow, PuzzleShape.flag],
          after: [PuzzleShape.arrow, PuzzleShape.hook],
        ).optionCount,
        2,
      );
    });

    test('ShapeRotationContent', () {
      _assertValueSemantics(
        const ShapeRotationContent(
          shape: PuzzleShape.arrow,
          referenceRotation: 90,
          optionRotations: [0, 180, 270],
        ),
        const ShapeRotationContent(
          shape: PuzzleShape.arrow,
          referenceRotation: 90,
          optionRotations: [0, 180, 270],
        ),
        const [
          ShapeRotationContent(
            shape: PuzzleShape.flag,
            referenceRotation: 90,
            optionRotations: [0, 180, 270],
          ),
          ShapeRotationContent(
            shape: PuzzleShape.arrow,
            referenceRotation: 180,
            optionRotations: [0, 180, 270],
          ),
          ShapeRotationContent(
            shape: PuzzleShape.arrow,
            referenceRotation: 90,
            optionRotations: [0, 90, 270],
          ),
        ],
        toStringContains: 'arrow @90',
      );
    });

    test('targetRotation is a quarter turn clockwise and wraps', () {
      for (final (reference, target) in const <(int, int)>[
        (0, 90),
        (90, 180),
        (180, 270),
        (270, 0),
      ]) {
        expect(
          ShapeRotationContent(
            shape: PuzzleShape.arrow,
            referenceRotation: reference,
            optionRotations: const [0, 90, 180, 270],
          ).targetRotation,
          target,
        );
      }
    });
  });

  group('PuzzleAnswer value semantics', () {
    test('NumericAnswer', () {
      _assertValueSemantics(
        const NumericAnswer(42),
        const NumericAnswer(42),
        const [NumericAnswer(43)],
        toStringContains: 'NumericAnswer(42)',
      );
    });

    test('OptionAnswer', () {
      _assertValueSemantics(
        const OptionAnswer(2),
        const OptionAnswer(2),
        const [OptionAnswer(3)],
        toStringContains: 'OptionAnswer(2)',
      );
    });

    test('DigitsAnswer', () {
      _assertValueSemantics(
        const DigitsAnswer([1, 2, 3]),
        const DigitsAnswer([1, 2, 3]),
        const [
          DigitsAnswer([3, 2, 1]),
          DigitsAnswer([1, 2]),
        ],
        toStringContains: 'DigitsAnswer([1, 2, 3])',
      );
    });

    test('CellsAnswer', () {
      _assertValueSemantics(
        const CellsAnswer([GridCell(0, 0), GridCell(1, 1)]),
        const CellsAnswer([GridCell(0, 0), GridCell(1, 1)]),
        const [
          CellsAnswer([GridCell(0, 0)]),
          CellsAnswer([GridCell(0, 1), GridCell(1, 1)]),
        ],
        toStringContains: 'CellsAnswer(',
      );
    });

    test('OrderingAnswer', () {
      _assertValueSemantics(
        const OrderingAnswer([1, 0, 2]),
        const OrderingAnswer([1, 0, 2]),
        const [
          OrderingAnswer([0, 1, 2]),
          OrderingAnswer([1, 0]),
        ],
        toStringContains: 'OrderingAnswer([1, 0, 2])',
      );
    });
  });

  group('Puzzle', () {
    const content = ArithmeticContent(
      left: 7,
      right: 3,
      operation: ArithmeticOperator.add,
    );

    Puzzle build({
      PuzzleType type = PuzzleType.arithmetic,
      PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
      int seed = 1,
      PuzzleContent puzzleContent = content,
      PuzzleAnswer answer = const NumericAnswer(10),
    }) => Puzzle(
      type: type,
      difficulty: difficulty,
      seed: seed,
      content: puzzleContent,
      answer: answer,
    );

    test('value semantics', () {
      _assertValueSemantics(
        build(),
        build(),
        [
          build(type: PuzzleType.sequenceNext),
          build(difficulty: PuzzleDifficulty.hard),
          build(seed: 2),
          build(
            puzzleContent: const ArithmeticContent(
              left: 8,
              right: 3,
              operation: ArithmeticOperator.add,
            ),
          ),
          build(answer: const NumericAnswer(11)),
        ],
        toStringContains: 'Puzzle(arithmetic, easy, seed: 1',
      );
    });

    test('optionCount is delegated to the content', () {
      expect(build().optionCount, 0);
      expect(
        build(
          type: PuzzleType.oddOneOutNumeric,
          puzzleContent: const OddOneOutNumericContent(
            values: [8, 16, 26],
            divisor: 4,
          ),
          answer: const OptionAnswer(2),
        ).optionCount,
        3,
      );
    });
  });
}
