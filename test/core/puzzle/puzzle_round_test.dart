import 'package:capywake/core/puzzle/puzzle.dart';
import 'package:capywake/core/puzzle/puzzle_content.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_exposure.dart';
import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/core/puzzle/puzzle_validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Settings pinned to the one type whose answer is trivially derivable, so a
/// test can answer *correctly* without re-implementing a generator.
PuzzleSettings _arithmeticOnly({
  int taskCount = 1,
  int toleratedWrongAnswers = 3,
  PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
  PuzzleEscapeStrictness escapeStrictness = PuzzleEscapeStrictness.confirm,
}) => PuzzleSettings(
  enabledTypes: const {PuzzleType.arithmetic},
  taskCount: taskCount,
  difficulty: difficulty,
  toleratedWrongAnswers: toleratedWrongAnswers,
  escapeStrictness: escapeStrictness,
);

/// The correct typed answer for the round's current puzzle.
String _correctText(PuzzleRound round) {
  final answer = round.puzzle.answer as NumericAnswer;
  return answer.value.toString();
}

/// A response that is definitely wrong for the round's current puzzle.
PuzzleResponse _wrong(PuzzleRound round) {
  final answer = round.puzzle.answer as NumericAnswer;
  return PuzzleTextResponse('${answer.value + 1}');
}

/// A definitely-wrong response in whatever shape [puzzle] expects.
///
/// Handing the validator a mismatched shape throws, so a test that walks
/// several puzzle types has to answer each in its own vocabulary.
PuzzleResponse _wrongForAnyType(Puzzle puzzle) {
  final answer = puzzle.answer;
  switch (answer) {
    case NumericAnswer(:final value):
      return PuzzleTextResponse('${value + 1}');
    case DigitsAnswer(:final digits):
      return PuzzleTextResponse(
        [(digits.first + 1) % 10, ...digits.skip(1)].join(),
      );
    case OptionAnswer(:final index):
      return PuzzleOptionResponse((index + 1) % puzzle.optionCount);
    case OrderingAnswer(:final indices):
      return PuzzleOrderingResponse([
        indices[1],
        indices[0],
        ...indices.skip(2),
      ]);
    case CellsAnswer(:final cells):
      final content = puzzle.content as GridPatternContent;
      for (var row = 0; row < content.rows; row++) {
        for (var column = 0; column < content.columns; column++) {
          final candidate = GridCell(row, column);
          if (!cells.contains(candidate)) {
            return PuzzleCellsResponse([candidate]);
          }
        }
      }
      throw StateError('every cell is lit — no wrong answer exists');
  }
}

void main() {
  group('PuzzleRound.start', () {
    test('opens on the first task at the configured ceiling', () {
      final round = PuzzleRound.start(
        settings: _arithmeticOnly(
          taskCount: 3,
          difficulty: PuzzleDifficulty.hard,
        ),
        seed: 1,
      );
      expect(round.solvedCount, 0);
      expect(round.taskNumber, 1);
      expect(round.taskCount, 3);
      expect(round.isSolved, isFalse);
      expect(round.lastOutcome, isNull);
      expect(round.easing.ceiling, PuzzleDifficulty.hard);
      expect(round.puzzle.difficulty, PuzzleDifficulty.hard);
    });

    test('is fully reproducible from its seed', () {
      final a = PuzzleRound.start(settings: _arithmeticOnly(), seed: 99);
      final b = PuzzleRound.start(settings: _arithmeticOnly(), seed: 99);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), b.toString());
    });

    test('different seeds generally give different puzzles', () {
      final puzzles = {
        for (var seed = 0; seed < 30; seed++)
          PuzzleRound.start(settings: _arithmeticOnly(), seed: seed).puzzle,
      };
      expect(puzzles.length, greaterThan(10));
    });

    test('trims an over-long recent window before consulting the selector', () {
      final round = PuzzleRound.start(
        settings: PuzzleSettings.defaults(),
        seed: 5,
        recentTypes: List.filled(20, PuzzleType.arithmetic),
      );
      expect(round.recentTypes.length, PuzzleRound.recentWindow);
    });

    test('the recent window is unmodifiable', () {
      final round = PuzzleRound.start(settings: _arithmeticOnly(), seed: 3);
      expect(
        () => round.recentTypes.add(PuzzleType.arithmetic),
        throwsUnsupportedError,
      );
    });

    test('progress is hidden for a one-task round and shown beyond it', () {
      expect(
        PuzzleRound.start(settings: _arithmeticOnly(), seed: 1).showsProgress,
        isFalse,
      );
      expect(
        PuzzleRound.start(
          settings: _arithmeticOnly(taskCount: 2),
          seed: 1,
        ).showsProgress,
        isTrue,
      );
    });

    test('exposes the exposure of its current puzzle', () {
      final round = PuzzleRound.start(settings: _arithmeticOnly(), seed: 1);
      expect(round.exposure, PuzzleExposure.forPuzzle(round.puzzle));
      expect(round.exposure, isNull, reason: 'arithmetic hides nothing');
    });
  });

  group('a correct answer', () {
    test('solves a one-task round and stops generating', () {
      final round = PuzzleRound.start(settings: _arithmeticOnly(), seed: 11);
      final solved = round.submit(PuzzleTextResponse(_correctText(round)));
      expect(solved.isSolved, isTrue);
      expect(solved.solvedCount, 1);
      expect(solved.lastOutcome, PuzzleAnswerOutcome.correct);
      // The puzzle is kept rather than replaced — the round is over.
      expect(solved.puzzle, round.puzzle);
    });

    test('advances to a new puzzle in a multi-task round', () {
      final round = PuzzleRound.start(
        settings: _arithmeticOnly(taskCount: 3),
        seed: 11,
      );
      final next = round.submit(PuzzleTextResponse(_correctText(round)));
      expect(next.isSolved, isFalse);
      expect(next.solvedCount, 1);
      expect(next.taskNumber, 2);
      expect(next.puzzle, isNot(round.puzzle));
    });

    test('a solved round ignores further answers', () {
      var round = PuzzleRound.start(settings: _arithmeticOnly(), seed: 11);
      round = round.submit(PuzzleTextResponse(_correctText(round)));
      final again = round.submit(const PuzzleTextResponse('0'));
      expect(identical(again, round), isTrue);
      expect(again.solvedCount, 1);
    });

    test(
      'a quick answer can climb back toward the ceiling, a slow one holds',
      () {
        var round = PuzzleRound.start(
          settings: _arithmeticOnly(
            taskCount: 5,
            difficulty: PuzzleDifficulty.hard,
          ),
          seed: 3,
        );
        // Drop to easy first so there is somewhere to climb back to.
        round = round.submit(_wrong(round));
        round = round.submit(_wrong(round));
        expect(round.easing.difficulty, PuzzleDifficulty.easy);

        var slow = round;
        for (var i = 0; i < PuzzleEasingState.stepUpStreak; i++) {
          slow = slow.submit(PuzzleTextResponse(_correctText(slow)));
        }
        expect(slow.easing.difficulty, PuzzleDifficulty.easy);

        var quick = round;
        for (var i = 0; i < PuzzleEasingState.stepUpStreak; i++) {
          quick = quick.submit(
            PuzzleTextResponse(_correctText(quick)),
            wasQuick: true,
          );
        }
        expect(quick.easing.difficulty, PuzzleDifficulty.medium);
      },
    );

    test('solving every task of a multi-task round finishes it', () {
      var round = PuzzleRound.start(
        settings: _arithmeticOnly(taskCount: 4),
        seed: 8,
      );
      for (var i = 0; i < 4; i++) {
        expect(round.isSolved, isFalse);
        round = round.submit(PuzzleTextResponse(_correctText(round)));
      }
      expect(round.isSolved, isTrue);
      expect(round.taskNumber, 4, reason: 'clamped once solved');
    });
  });

  group('a wrong answer', () {
    test('eases the next puzzle and serves a different one', () {
      final round = PuzzleRound.start(
        settings: _arithmeticOnly(difficulty: PuzzleDifficulty.hard),
        seed: 21,
      );
      final next = round.submit(_wrong(round));
      expect(next.lastOutcome, PuzzleAnswerOutcome.incorrect);
      expect(next.solvedCount, 0);
      expect(next.easing.difficulty, PuzzleDifficulty.medium);
      expect(next.puzzle.difficulty, PuzzleDifficulty.medium);
      expect(next.puzzle, isNot(round.puzzle));
    });

    test('walks down to easy and floors there — never unsolvable', () {
      var round = PuzzleRound.start(
        settings: _arithmeticOnly(difficulty: PuzzleDifficulty.hard),
        seed: 21,
      );
      for (var i = 0; i < 10; i++) {
        round = round.submit(_wrong(round));
      }
      expect(round.easing.difficulty, PuzzleDifficulty.easy);
      expect(round.easing.isAtFloor, isTrue);
      expect(round.isSolved, isFalse);
      // Still answerable: the correct answer still stops the alarm.
      final solved = round.submit(PuzzleTextResponse(_correctText(round)));
      expect(solved.isSolved, isTrue);
    });
  });

  group('an input artefact is not a wrong answer', () {
    test('an empty answer keeps the puzzle, the easing and the threshold', () {
      final round = PuzzleRound.start(settings: _arithmeticOnly(), seed: 4);
      final after = round.submit(const PuzzleTextResponse('  '));
      expect(after.lastOutcome, PuzzleAnswerOutcome.empty);
      expect(after.puzzle, round.puzzle);
      expect(after.easing, round.easing);
      expect(after.easing.wrongThisRound, 0);
      expect(after.seed, round.seed);
    });

    test('unparseable input likewise', () {
      final round = PuzzleRound.start(settings: _arithmeticOnly(), seed: 4);
      final after = round.submit(const PuzzleTextResponse('abc'));
      expect(after.lastOutcome, PuzzleAnswerOutcome.unparseable);
      expect(after.puzzle, round.puzzle);
      expect(after.easing, round.easing);
      expect(after.easing.wrongThisRound, 0);
    });

    test('neither ever pushes the escape to prominent', () {
      var round = PuzzleRound.start(
        settings: _arithmeticOnly(toleratedWrongAnswers: 0),
        seed: 4,
      );
      for (var i = 0; i < 10; i++) {
        round = round.submit(const PuzzleTextResponse(''));
      }
      expect(round.escapeVisibility, PuzzleEscapeVisibility.available);
    });

    test('a spent-reveal puzzle is replaced rather than left unanswerable', () {
      // By the time an answer can be submitted, a show-then-hide type has
      // already taken its stimulus away. Keeping it would leave someone who
      // submitted blank looking at digits they can no longer see.
      for (final type in const [
        PuzzleType.digitRecall,
        PuzzleType.digitRecallReversed,
      ]) {
        final round = PuzzleRound.start(
          settings: PuzzleSettings(enabledTypes: {type}),
          seed: 11,
        );
        expect(
          PuzzleExposure.hidesStimulus(round.puzzle),
          isTrue,
          reason:
              '$type must be a show-then-hide type for this test to mean '
              'anything',
        );
        final after = round.submit(const PuzzleTextResponse(''));
        expect(after.lastOutcome, PuzzleAnswerOutcome.empty);
        expect(
          after.puzzle,
          isNot(round.puzzle),
          reason: '$type: a fresh puzzle, with a fresh exposure',
        );
        expect(after.exposure, isNotNull);
      }
    });

    test('the grid replaces itself when nothing was tapped', () {
      final round = PuzzleRound.start(
        settings: PuzzleSettings(
          enabledTypes: const {PuzzleType.gridPatternRecall},
        ),
        seed: 21,
      );
      final after = round.submit(const PuzzleCellsResponse([]));
      expect(after.lastOutcome, PuzzleAnswerOutcome.empty);
      expect(after.puzzle, isNot(round.puzzle));
    });

    test(
      'replacing a spent-reveal puzzle is not charged as a wrong answer',
      () {
        // The user did not get anything wrong — they got nothing to work with.
        // So the difficulty must not ease and the escape must not creep toward
        // prominent, both of which `recordWrong()` would have done.
        var round = PuzzleRound.start(
          settings: PuzzleSettings(
            enabledTypes: const {PuzzleType.digitRecall},
            toleratedWrongAnswers: 0,
            difficulty: PuzzleDifficulty.hard,
          ),
          seed: 31,
        );
        final easing = round.easing;
        for (var i = 0; i < 10; i++) {
          round = round.submit(const PuzzleTextResponse(''));
        }
        expect(round.easing, easing);
        expect(round.easing.wrongThisRound, 0);
        expect(round.easing.difficulty, PuzzleDifficulty.hard);
        expect(round.escapeVisibility, PuzzleEscapeVisibility.available);
        expect(round.solvedCount, 0);
      },
    );

    test('a still-visible puzzle is kept, even for a visual type', () {
      // `shapeRotation` is visual but hides nothing, so the artefact rule that
      // keeps the same puzzle still applies — the discriminator is the spent
      // reveal, not whether the content is pictures.
      final round = PuzzleRound.start(
        settings: PuzzleSettings(
          enabledTypes: const {PuzzleType.shapeRotation},
        ),
        seed: 41,
      );
      expect(PuzzleExposure.hidesStimulus(round.puzzle), isFalse);
      final after = round.submit(const PuzzleOptionResponse(99));
      expect(after.lastOutcome, PuzzleAnswerOutcome.unparseable);
      expect(after.puzzle, round.puzzle);
      expect(after.seed, round.seed);
    });
  });

  group('the emergency escape', () {
    test('is available from the very first frame of a round', () {
      final round = PuzzleRound.start(settings: _arithmeticOnly(), seed: 1);
      expect(round.escapeVisibility, PuzzleEscapeVisibility.available);
    });

    test('turns prominent once wrong answers pass the tolerance', () {
      var round = PuzzleRound.start(
        settings: _arithmeticOnly(toleratedWrongAnswers: 2),
        seed: 12,
      );
      round = round.submit(_wrong(round));
      round = round.submit(_wrong(round));
      expect(round.escapeVisibility, PuzzleEscapeVisibility.available);
      round = round.submit(_wrong(round));
      expect(round.escapeVisibility, PuzzleEscapeVisibility.prominent);
    });

    test('stays prominent for someone alternating wrong and right', () {
      // The failure this guards: a *consecutive* counter would recede exactly
      // as this user needs the way out most.
      var round = PuzzleRound.start(
        settings: _arithmeticOnly(taskCount: 5, toleratedWrongAnswers: 1),
        seed: 12,
      );
      round = round.submit(_wrong(round));
      round = round.submit(_wrong(round));
      expect(round.escapeVisibility, PuzzleEscapeVisibility.prominent);
      round = round.submit(PuzzleTextResponse(_correctText(round)));
      expect(round.easing.consecutiveWrong, 0);
      expect(round.escapeVisibility, PuzzleEscapeVisibility.prominent);
    });
  });

  group('type rotation', () {
    test('never serves the same type twice in a row', () {
      var round = PuzzleRound.start(
        settings: PuzzleSettings(
          enabledTypes: PuzzleType.screenReaderSolvableTypes,
          taskCount: 5,
        ),
        seed: 77,
      );
      final served = <PuzzleType>[round.puzzle.type];
      for (var i = 0; i < 20; i++) {
        // A wrong answer keeps the round going without solving it.
        round = round.submit(_wrongForAnyType(round.puzzle));
        served.add(round.puzzle.type);
      }
      for (var i = 1; i < served.length; i++) {
        expect(served[i], isNot(served[i - 1]));
      }
      expect(served.toSet().length, greaterThan(1));
    });

    test('a single enabled type simply repeats — variety comes from seeds', () {
      var round = PuzzleRound.start(
        settings: _arithmeticOnly(taskCount: 4),
        seed: 5,
      );
      final puzzles = <Puzzle>[round.puzzle];
      for (var i = 0; i < 3; i++) {
        round = round.submit(PuzzleTextResponse(_correctText(round)));
        puzzles.add(round.puzzle);
      }
      expect(puzzles.every((p) => p.type == PuzzleType.arithmetic), isTrue);
      expect(puzzles.toSet().length, puzzles.length);
    });

    test('the recent window stays bounded across a long round', () {
      var round = PuzzleRound.start(
        settings: PuzzleSettings(
          enabledTypes: PuzzleType.screenReaderSolvableTypes,
          taskCount: 5,
        ),
        seed: 31,
      );
      for (var i = 0; i < 20; i++) {
        round = round.submit(_wrongForAnyType(round.puzzle));
        expect(
          round.recentTypes.length,
          lessThanOrEqualTo(PuzzleRound.recentWindow),
        );
      }
    });
  });

  group('seed advance', () {
    test('is deterministic and non-negative', () {
      expect(PuzzleRound.advanceSeed(0), PuzzleRound.advanceSeed(0));
      for (final seed in [0, 1, -1, 12345, 1 << 40]) {
        expect(PuzzleRound.advanceSeed(seed), greaterThanOrEqualTo(0));
      }
    });

    test('moves consecutive seeds apart', () {
      expect(PuzzleRound.advanceSeed(1), isNot(1));
      expect(PuzzleRound.advanceSeed(1), isNot(PuzzleRound.advanceSeed(2)));
    });
  });

  group('value semantics', () {
    test('rounds differing in any field are unequal', () {
      final base = PuzzleRound.start(settings: _arithmeticOnly(), seed: 1);
      expect(
        base,
        isNot(PuzzleRound.start(settings: _arithmeticOnly(), seed: 2)),
      );
      expect(
        base,
        isNot(
          PuzzleRound.start(
            settings: _arithmeticOnly(taskCount: 2),
            seed: 1,
          ),
        ),
      );
      expect(base, isNot(base.submit(const PuzzleTextResponse(''))));
      expect(base == Object(), isFalse);
      expect(base == base, isTrue);
    });

    test('rounds with different recent windows are unequal', () {
      final settings = PuzzleSettings.defaults();
      final a = PuzzleRound.start(settings: settings, seed: 4);
      final b = PuzzleRound.start(
        settings: settings,
        seed: 4,
        recentTypes: const [PuzzleType.arithmetic, PuzzleType.sequenceNext],
      );
      expect(a, isNot(b));
    });

    test('toString names the task, type and difficulty', () {
      final round = PuzzleRound.start(
        settings: _arithmeticOnly(taskCount: 2),
        seed: 1,
      );
      expect(round.toString(), contains('task 1 of 2'));
      expect(round.toString(), contains('arithmetic'));
      expect(round.toString(), contains('medium'));
    });
  });

  test('the quick-answer threshold is generous, not a hidden clock', () {
    expect(
      PuzzleRound.quickAnswer,
      greaterThanOrEqualTo(const Duration(seconds: 5)),
    );
  });
}
