import 'package:capywake/core/puzzle/puzzle_content.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_exposure.dart';
import 'package:capywake/core/puzzle/puzzle_generator.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PuzzleExposure.forPuzzle', () {
    test('the three show-then-hide types get an exposure', () {
      for (final type in const [
        PuzzleType.digitRecall,
        PuzzleType.digitRecallReversed,
        PuzzleType.gridPatternRecall,
        PuzzleType.spotTheChange,
      ]) {
        final puzzle = PuzzleGenerator.generate(
          type: type,
          difficulty: PuzzleDifficulty.medium,
          seed: 7,
        );
        expect(
          PuzzleExposure.forPuzzle(puzzle),
          isNotNull,
          reason: '${type.name} hides its stimulus and must have an exposure',
        );
      }
    });

    test('every other type gets null', () {
      for (final type in const [
        PuzzleType.arithmetic,
        PuzzleType.sequenceNext,
        PuzzleType.missingOperator,
        PuzzleType.compareValues,
        PuzzleType.oddOneOutNumeric,
        PuzzleType.shapeRotation,
      ]) {
        // Sweep seeds: compareValues has three tasks and shapeRotation four
        // reference angles, so one seed does not cover the type.
        for (var seed = 0; seed < 12; seed++) {
          final puzzle = PuzzleGenerator.generate(
            type: type,
            difficulty: PuzzleDifficulty.hard,
            seed: seed,
          );
          expect(
            PuzzleExposure.forPuzzle(puzzle),
            isNull,
            reason: '${type.name} hides nothing',
          );
        }
      }
    });

    test('reads the actual content length, not a fixed guess', () {
      final short = PuzzleExposure.forDigits(
        digitCount: 3,
        difficulty: PuzzleDifficulty.medium,
      );
      final long = PuzzleExposure.forDigits(
        digitCount: 6,
        difficulty: PuzzleDifficulty.medium,
      );
      expect(long, greaterThan(short));
    });
  });

  group('difficulty scaling', () {
    test('easy shows longer than medium, hard shows shorter', () {
      Duration at(PuzzleDifficulty d) =>
          PuzzleExposure.forDigits(digitCount: 5, difficulty: d);
      expect(
        at(PuzzleDifficulty.easy),
        greaterThan(at(PuzzleDifficulty.medium)),
      );
      expect(at(PuzzleDifficulty.hard), lessThan(at(PuzzleDifficulty.medium)));
    });

    test('grid and shape-row exposures scale the same way', () {
      Duration grid(PuzzleDifficulty d) =>
          PuzzleExposure.forGrid(cellCount: 4, difficulty: d);
      Duration row(PuzzleDifficulty d) =>
          PuzzleExposure.forShapeRow(shapeCount: 5, difficulty: d);
      expect(
        grid(PuzzleDifficulty.easy),
        greaterThan(grid(PuzzleDifficulty.hard)),
      );
      expect(
        row(PuzzleDifficulty.easy),
        greaterThan(row(PuzzleDifficulty.hard)),
      );
    });

    test('never drops below the floor, however hard or short', () {
      expect(
        PuzzleExposure.forDigits(
          digitCount: 0,
          difficulty: PuzzleDifficulty.hard,
        ),
        greaterThanOrEqualTo(PuzzleExposure.minimum),
      );
      expect(
        PuzzleExposure.forGrid(cellCount: 0, difficulty: PuzzleDifficulty.hard),
        greaterThanOrEqualTo(PuzzleExposure.minimum),
      );
      expect(
        PuzzleExposure.forShapeRow(
          shapeCount: 0,
          difficulty: PuzzleDifficulty.hard,
        ),
        greaterThanOrEqualTo(PuzzleExposure.minimum),
      );
    });

    test('never exceeds the ceiling, however long the content', () {
      expect(
        PuzzleExposure.forDigits(
          digitCount: 200,
          difficulty: PuzzleDifficulty.easy,
        ),
        PuzzleExposure.maximum,
      );
      expect(
        PuzzleExposure.forGrid(
          cellCount: 200,
          difficulty: PuzzleDifficulty.easy,
        ),
        PuzzleExposure.maximum,
      );
      expect(
        PuzzleExposure.forShapeRow(
          shapeCount: 200,
          difficulty: PuzzleDifficulty.easy,
        ),
        PuzzleExposure.maximum,
      );
    });

    test('every generated recall puzzle lands inside the bounds', () {
      for (final type in const [
        PuzzleType.digitRecall,
        PuzzleType.gridPatternRecall,
        PuzzleType.spotTheChange,
      ]) {
        for (final difficulty in PuzzleDifficulty.values) {
          for (var seed = 0; seed < 20; seed++) {
            final exposure = PuzzleExposure.forPuzzle(
              PuzzleGenerator.generate(
                type: type,
                difficulty: difficulty,
                seed: seed,
              ),
            )!;
            expect(exposure, greaterThanOrEqualTo(PuzzleExposure.minimum));
            expect(exposure, lessThanOrEqualTo(PuzzleExposure.maximum));
          }
        }
      }
    });
  });

  test('the grid shows every lit cell at once', () {
    // A sequential flash would turn recall into tracking — continuous
    // attention under time pressure, which the calm rules ban — and would
    // contradict the validator's order-insensitive answer.
    expect(PuzzleExposure.gridCellsAppearTogether, isTrue);
  });

  test('a digit-recall exposure covers the digits it actually shows', () {
    final puzzle = PuzzleGenerator.generate(
      type: PuzzleType.digitRecall,
      difficulty: PuzzleDifficulty.medium,
      seed: 42,
    );
    final content = puzzle.content as DigitRecallContent;
    expect(
      PuzzleExposure.forPuzzle(puzzle),
      PuzzleExposure.forDigits(
        digitCount: content.digits.length,
        difficulty: PuzzleDifficulty.medium,
      ),
    );
  });
}
