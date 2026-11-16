import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PuzzleType', () {
    test('exactly the ten decided types ship', () {
      expect(PuzzleType.values, [
        PuzzleType.arithmetic,
        PuzzleType.sequenceNext,
        PuzzleType.missingOperator,
        PuzzleType.compareValues,
        PuzzleType.oddOneOutNumeric,
        PuzzleType.digitRecall,
        PuzzleType.digitRecallReversed,
        PuzzleType.gridPatternRecall,
        PuzzleType.spotTheChange,
        PuzzleType.shapeRotation,
      ]);
    });

    test('every type declares an accessibility profile', () {
      for (final type in PuzzleType.values) {
        expect(
          type.accessibility,
          isIn(PuzzleAccessibility.values),
          reason: '${type.name} has no accessibility profile',
        );
      }
    });

    test('the numeric types are solvable without sight', () {
      const expected = <PuzzleType>[
        PuzzleType.arithmetic,
        PuzzleType.sequenceNext,
        PuzzleType.missingOperator,
        PuzzleType.compareValues,
        PuzzleType.oddOneOutNumeric,
        PuzzleType.digitRecall,
        PuzzleType.digitRecallReversed,
      ];
      for (final type in expected) {
        expect(
          type.accessibility,
          PuzzleAccessibility.screenReaderSolvable,
          reason: '${type.name} should be screen-reader solvable',
        );
        expect(type.isScreenReaderSolvable, isTrue);
      }
    });

    test('the spatial types are honestly marked visual-only', () {
      const expected = <PuzzleType>[
        PuzzleType.gridPatternRecall,
        PuzzleType.spotTheChange,
        PuzzleType.shapeRotation,
      ];
      for (final type in expected) {
        expect(
          type.accessibility,
          PuzzleAccessibility.visualOnly,
          reason: '${type.name} should be marked visual-only',
        );
        expect(type.isScreenReaderSolvable, isFalse);
      }
    });

    test('at least one type is solvable with a screen reader', () {
      // The project guarantee: a user who cannot see the screen must still be
      // able to run the puzzle. `arithmetic` is that type, and it is the one
      // Free ships with.
      expect(PuzzleType.screenReaderSolvableTypes, isNotEmpty);
      expect(
        PuzzleType.screenReaderSolvableTypes,
        contains(PuzzleType.arithmetic),
      );
    });

    test('screenReaderSolvableTypes matches the per-type profiles', () {
      expect(
        PuzzleType.screenReaderSolvableTypes,
        PuzzleType.values.where((t) => t.isScreenReaderSolvable).toSet(),
      );
      expect(
        PuzzleType.screenReaderSolvableTypes.length,
        PuzzleType.values.length - 3,
      );
    });
  });
}
