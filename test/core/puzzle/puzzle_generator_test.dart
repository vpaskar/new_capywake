import 'package:capywake/core/puzzle/puzzle.dart';
import 'package:capywake/core/puzzle/puzzle_content.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_generator.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/core/puzzle/puzzle_validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// How many seeds each property is swept over.
///
/// The point of this suite is that the properties hold across the *space* the
/// generators can produce, not for a handful of hand-picked examples. A puzzle
/// with two right answers, or one whose correct option always lands in the same
/// slot, reads to a half-asleep user as a broken app — and neither defect shows
/// up in an example-based test.
const int _sweep = 400;

void main() {
  group('PuzzleGenerator — determinism', () {
    test('the same (type, difficulty, seed) always yields the same puzzle', () {
      for (final type in PuzzleType.values) {
        for (final difficulty in PuzzleDifficulty.values) {
          for (var seed = 0; seed < 60; seed++) {
            final first = PuzzleGenerator.generate(
              type: type,
              difficulty: difficulty,
              seed: seed,
            );
            final second = PuzzleGenerator.generate(
              type: type,
              difficulty: difficulty,
              seed: seed,
            );
            expect(
              first,
              second,
              reason: '${type.name}/${difficulty.name}/$seed is not stable',
            );
            expect(first.hashCode, second.hashCode);
          }
        }
      }
    });

    test('the puzzle records the seed and the requested type/difficulty', () {
      final puzzle = PuzzleGenerator.generate(
        type: PuzzleType.arithmetic,
        difficulty: PuzzleDifficulty.hard,
        seed: 99,
      );
      expect(puzzle.seed, 99);
      expect(puzzle.type, PuzzleType.arithmetic);
      expect(puzzle.difficulty, PuzzleDifficulty.hard);
    });

    test('every band at every difficulty has room to vary', () {
      // This test used to sweep `medium` only, which is precisely where the
      // problem was not. The narrow bands are at `easy` — which is also where
      // `PuzzleEasingState` floors a struggling user, and (from Phase 20) the
      // level a Free user on the single `arithmetic` type spends most time at.
      // A generator that has collapsed onto a small set is the "authored bank"
      // failure mode `CLAUDE.md` bans, reached from the other direction.
      const seeds = 4000;
      // Floors, not measurements: each is comfortably under what the band
      // reaches today, so ordinary tuning does not trip the test but a real
      // narrowing does.
      const minimum = <PuzzleDifficulty, int>{
        PuzzleDifficulty.easy: 140,
        PuzzleDifficulty.medium: 250,
        PuzzleDifficulty.hard: 400,
      };
      for (final type in PuzzleType.values) {
        for (final difficulty in PuzzleDifficulty.values) {
          final produced = <PuzzleContent>{};
          for (var seed = 0; seed < seeds; seed++) {
            produced.add(
              PuzzleGenerator.generate(
                type: type,
                difficulty: difficulty,
                seed: seed,
              ).content,
            );
          }
          expect(
            produced.length,
            greaterThanOrEqualTo(minimum[difficulty]!),
            reason:
                '${type.name}/${difficulty.name} reaches only '
                '${produced.length} distinct puzzles',
          );
        }
      }
    });
  });

  group('PuzzleGenerator — the declared answer satisfies the type rule', () {
    test('arithmetic: the answer is the operation applied, never negative', () {
      _sweepAll(PuzzleType.arithmetic, (puzzle) {
        final content = puzzle.content as ArithmeticContent;
        final answer = puzzle.answer as NumericAnswer;
        expect(
          content.operation,
          isNot(ArithmeticOperator.divide),
          reason: 'division would not always be a whole number',
        );
        final expected = switch (content.operation) {
          ArithmeticOperator.add => content.left + content.right,
          ArithmeticOperator.subtract => content.left - content.right,
          ArithmeticOperator.multiply => content.left * content.right,
          ArithmeticOperator.divide => content.left ~/ content.right,
        };
        expect(answer.value, expected);
        expect(answer.value, greaterThanOrEqualTo(0));
      });
    });

    test('sequenceNext: the answer continues a rule the shown terms obey', () {
      _sweepAll(PuzzleType.sequenceNext, (puzzle) {
        final content = puzzle.content as SequenceNextContent;
        final answer = puzzle.answer as NumericAnswer;
        expect(content.shown.length, greaterThanOrEqualTo(4));
        expect(content.shown.every((t) => t >= 0), isTrue);
        expect(
          _continuesRule(content.shown, answer.value),
          isTrue,
          reason: '${content.shown} -> ${answer.value} follows no rule',
        );
      });
    });

    test('typed answers stay within what a person can do at 03:00', () {
      // Hard should ask for thought, not for stamina. Nothing the user has to
      // compute in their head and type back is allowed past four digits.
      for (final type in <PuzzleType>[
        PuzzleType.arithmetic,
        PuzzleType.sequenceNext,
      ]) {
        _sweepAll(type, (puzzle) {
          expect(
            (puzzle.answer as NumericAnswer).value,
            lessThan(2000),
            reason:
                '${type.name}/${puzzle.difficulty.name} seed ${puzzle.seed} '
                'asks for ${(puzzle.answer as NumericAnswer).value}',
          );
        });
      }
    });

    test('a hard puzzle is never accidentally easier than an easy one', () {
      // Drawing both subtraction operands freely let a *hard* arithmetic
      // puzzle come out as `413 - 411 = 2`. Nothing constrained the minimum
      // difficulty of a hard puzzle, and mean-based monotonicity cannot see
      // per-instance inversions.
      for (var seed = 0; seed < _sweep; seed++) {
        final puzzle = PuzzleGenerator.generate(
          type: PuzzleType.arithmetic,
          difficulty: PuzzleDifficulty.hard,
          seed: seed,
        );
        final content = puzzle.content as ArithmeticContent;
        if (content.operation != ArithmeticOperator.subtract) continue;
        expect(
          (puzzle.answer as NumericAnswer).value,
          greaterThanOrEqualTo(100),
          reason:
              'hard subtraction ${content.left} - ${content.right} is a '
              'single- or double-digit answer',
        );
      }
      for (var seed = 0; seed < _sweep; seed++) {
        final puzzle = PuzzleGenerator.generate(
          type: PuzzleType.arithmetic,
          difficulty: PuzzleDifficulty.medium,
          seed: seed,
        );
        final content = puzzle.content as ArithmeticContent;
        if (content.operation != ArithmeticOperator.subtract) continue;
        expect(
          (puzzle.answer as NumericAnswer).value,
          greaterThanOrEqualTo(10),
        );
      }
    });

    test('missingOperator: exactly one offered operator makes it true', () {
      _sweepAll(PuzzleType.missingOperator, (puzzle) {
        final content = puzzle.content as MissingOperatorContent;
        final answer = puzzle.answer as OptionAnswer;
        expect(content.options.toSet().length, content.options.length);
        expect(content.options.length, ArithmeticOperator.values.length);
        final satisfying = <int>[];
        for (var i = 0; i < content.options.length; i++) {
          if (_apply(content.left, content.right, content.options[i]) ==
              content.result) {
            satisfying.add(i);
          }
        }
        expect(
          satisfying,
          [answer.index],
          reason:
              '${content.left} ? ${content.right} = ${content.result} '
              'has ${satisfying.length} answers',
        );
        expect(content.result, greaterThanOrEqualTo(0));
      });
    });

    test('compareValues: values are distinct and the task is answered', () {
      _sweepAll(PuzzleType.compareValues, (puzzle) {
        final content = puzzle.content as CompareValuesContent;
        expect(content.values.toSet().length, content.values.length);
        switch (content.task) {
          case CompareTask.largest:
            final answer = puzzle.answer as OptionAnswer;
            expect(
              content.values[answer.index],
              content.values.reduce((a, b) => a > b ? a : b),
            );
          case CompareTask.smallest:
            final answer = puzzle.answer as OptionAnswer;
            expect(
              content.values[answer.index],
              content.values.reduce((a, b) => a < b ? a : b),
            );
          case CompareTask.ascending:
            final answer = puzzle.answer as OrderingAnswer;
            expect(answer.indices.toSet().length, content.values.length);
            final ordered = [for (final i in answer.indices) content.values[i]];
            expect(ordered, orderedEquals([...ordered]..sort()));
        }
      });
    });

    test('oddOneOutNumeric: exactly one value breaks the declared rule', () {
      _sweepAll(PuzzleType.oddOneOutNumeric, (puzzle) {
        final content = puzzle.content as OddOneOutNumericContent;
        final answer = puzzle.answer as OptionAnswer;
        expect(content.values.toSet().length, content.values.length);
        final breaking = <int>[
          for (var i = 0; i < content.values.length; i++)
            if (content.values[i] % content.divisor != 0) i,
        ];
        expect(breaking, [answer.index]);
      });
    });

    test('oddOneOutNumeric: the stated rule is well-formed and decisive', () {
      // This replaces an earlier test that tried to prove no *competing* rule
      // singles out a different value. That test could never be complete: it
      // probed divisibility by {2,3,4,5,10} while the real ambiguity came from
      // digit length (~28% of puzzles), perfect squares (~36%) and multiples
      // of 7 (~46%) — and any finite set of integers admits endlessly more
      // such readings. The type now states its rule rather than hiding it, so
      // what must hold is that the stated rule is usable and decides the
      // answer on its own.
      _sweepAll(PuzzleType.oddOneOutNumeric, (puzzle) {
        final content = puzzle.content as OddOneOutNumericContent;
        final answer = puzzle.answer as OptionAnswer;
        expect(content.divisor, greaterThanOrEqualTo(3));
        expect(content.values.every((v) => v > 0), isTrue);
        // The rule decides exactly one value, and that value is the answer.
        final breaking = <int>[
          for (var i = 0; i < content.values.length; i++)
            if (content.values[i] % content.divisor != 0) i,
        ];
        expect(breaking, [answer.index]);
      });
    });

    test('oddOneOutNumeric: the answer is not findable by being extreme', () {
      // With the rule stated, an intruder that is always the largest or
      // smallest value would let the user shortcut the arithmetic entirely.
      for (final difficulty in PuzzleDifficulty.values) {
        var isMax = 0;
        var isMin = 0;
        var total = 0;
        for (var seed = 0; seed < 900; seed++) {
          final puzzle = PuzzleGenerator.generate(
            type: PuzzleType.oddOneOutNumeric,
            difficulty: difficulty,
            seed: seed,
          );
          final values = (puzzle.content as OddOneOutNumericContent).values;
          final intruder = values[(puzzle.answer as OptionAnswer).index];
          if (intruder == values.reduce((a, b) => a > b ? a : b)) isMax++;
          if (intruder == values.reduce((a, b) => a < b ? a : b)) isMin++;
          total++;
        }
        // A uniformly-placed intruder is the extreme value about 1-in-count of
        // the time; allow double that before calling it a tell.
        final bound = total * 2 / (difficulty == PuzzleDifficulty.easy ? 4 : 5);
        expect(
          isMax,
          lessThan(bound),
          reason:
              '${difficulty.name}: intruder '
              'is the largest value $isMax/$total times',
        );
        expect(
          isMin,
          lessThan(bound),
          reason:
              '${difficulty.name}: intruder '
              'is the smallest value $isMin/$total times',
        );
      }
    });

    test('digitRecall: distinct digits, entered forwards', () {
      _sweepAll(PuzzleType.digitRecall, (puzzle) {
        final content = puzzle.content as DigitRecallContent;
        final answer = puzzle.answer as DigitsAnswer;
        expect(content.reversed, isFalse);
        expect(content.digits.toSet().length, content.digits.length);
        expect(content.digits.every((d) => d >= 0 && d <= 9), isTrue);
        expect(answer.digits, content.digits);
      });
    });

    test('digitRecallReversed: the answer is the digits back to front', () {
      _sweepAll(PuzzleType.digitRecallReversed, (puzzle) {
        final content = puzzle.content as DigitRecallContent;
        final answer = puzzle.answer as DigitsAnswer;
        expect(content.reversed, isTrue);
        expect(content.digits.toSet().length, content.digits.length);
        expect(answer.digits, content.digits.reversed.toList());
      });
    });

    test('gridPatternRecall: distinct in-bounds cells, answered as a set', () {
      _sweepAll(PuzzleType.gridPatternRecall, (puzzle) {
        final content = puzzle.content as GridPatternContent;
        final answer = puzzle.answer as CellsAnswer;
        expect(content.cells.toSet().length, content.cells.length);
        expect(content.cells.length, lessThan(content.rows * content.columns));
        for (final cell in content.cells) {
          expect(cell.row, inInclusiveRange(0, content.rows - 1));
          expect(cell.column, inInclusiveRange(0, content.columns - 1));
        }
        expect(answer.cells, content.cells);
      });
    });

    test('spotTheChange: the rows differ at exactly the answered '
        'position', () {
      _sweepAll(PuzzleType.spotTheChange, (puzzle) {
        final content = puzzle.content as SpotTheChangeContent;
        final answer = puzzle.answer as OptionAnswer;
        expect(content.before.toSet().length, content.before.length);
        expect(content.after.toSet().length, content.after.length);
        expect(content.after.length, content.before.length);
        final differing = <int>[
          for (var i = 0; i < content.before.length; i++)
            if (content.before[i] != content.after[i]) i,
        ];
        expect(differing, [answer.index]);
      });
    });

    test('shapeRotation: exactly one option is a quarter turn clockwise', () {
      _sweepAll(PuzzleType.shapeRotation, (puzzle) {
        final content = puzzle.content as ShapeRotationContent;
        final answer = puzzle.answer as OptionAnswer;
        expect(
          content.optionRotations.toSet().length,
          content.optionRotations.length,
        );
        expect(
          content.optionRotations.every(const [0, 90, 180, 270].contains),
          isTrue,
        );
        expect(content.referenceRotation, isIn(const [0, 90, 180, 270]));
        final matching = <int>[
          for (var i = 0; i < content.optionRotations.length; i++)
            if (content.optionRotations[i] == content.targetRotation) i,
        ];
        expect(matching, [answer.index]);
      });
    });

    test('shapeRotation: the reference varies everywhere, and hard is never '
        'upright', () {
      // Easy used to pin the reference to 0, which made the target *always*
      // 90 degrees across every seed — the reference panel was decorative and
      // the puzzle degenerated into recognising eight memorised poses. Easy is
      // where easing floors a struggling user, so that is the worst place for
      // a learnable tell.
      final easyReferences = <int>{};
      final easyTargets = <int>{};
      for (var seed = 0; seed < _sweep; seed++) {
        final easy =
            PuzzleGenerator.generate(
                  type: PuzzleType.shapeRotation,
                  difficulty: PuzzleDifficulty.easy,
                  seed: seed,
                ).content
                as ShapeRotationContent;
        easyReferences.add(easy.referenceRotation);
        easyTargets.add(easy.targetRotation);
        expect(easy.optionRotations, hasLength(3));

        final hard =
            PuzzleGenerator.generate(
                  type: PuzzleType.shapeRotation,
                  difficulty: PuzzleDifficulty.hard,
                  seed: seed,
                ).content
                as ShapeRotationContent;
        expect(hard.referenceRotation, isNot(0));
        expect(hard.optionRotations, hasLength(4));
      }
      expect(easyReferences, {0, 90, 180, 270});
      expect(easyTargets, {0, 90, 180, 270});
    });

    test('shapeRotation: difficulty is a structural ladder', () {
      // Asserted directly rather than through the mean-complexity test below.
      // Medium and hard differ only by whether the reference may be upright,
      // which on any numeric metric is a fraction-of-a-percent difference —
      // a margin small enough that a passing test would prove nothing.
      for (final (difficulty, options) in const <(PuzzleDifficulty, int)>[
        (PuzzleDifficulty.easy, 3),
        (PuzzleDifficulty.medium, 4),
        (PuzzleDifficulty.hard, 4),
      ]) {
        for (var seed = 0; seed < 50; seed++) {
          expect(
            (PuzzleGenerator.generate(
                      type: PuzzleType.shapeRotation,
                      difficulty: difficulty,
                      seed: seed,
                    ).content
                    as ShapeRotationContent)
                .optionRotations,
            hasLength(options),
          );
        }
      }
    });
  });

  group('PuzzleGenerator — option position is not biased', () {
    test('every slot wins its fair share across seeds', () {
      const optionTypes = <PuzzleType>[
        PuzzleType.missingOperator,
        PuzzleType.compareValues,
        PuzzleType.oddOneOutNumeric,
        PuzzleType.spotTheChange,
        PuzzleType.shapeRotation,
      ];
      for (final type in optionTypes) {
        for (final difficulty in PuzzleDifficulty.values) {
          final counts = <int, int>{};
          var slots = 0;
          var total = 0;
          for (var seed = 0; seed < 900; seed++) {
            final puzzle = PuzzleGenerator.generate(
              type: type,
              difficulty: difficulty,
              seed: seed,
            );
            final answer = puzzle.answer;
            // compareValues sometimes asks for an ordering instead.
            if (answer is! OptionAnswer) continue;
            slots = puzzle.optionCount;
            counts[answer.index] = (counts[answer.index] ?? 0) + 1;
            total++;
          }
          expect(
            counts.keys.toSet(),
            {for (var i = 0; i < slots; i++) i},
            reason:
                '${type.name}/${difficulty.name} never answers in some '
                'slot',
          );
          // +-35% of a uniform share. The previous bounds were "between half
          // and double", i.e. 12.5%-50% for four slots, which a generator that
          // skipped shuffling 30% of the time would pass at a 48.6% share —
          // "the answer is usually the first button" is exactly the learnable
          // tell this test exists to prevent. At n=900 these bounds still sit
          // >4 sigma from expectation, so they cannot flake.
          final share = total / slots;
          for (final entry in counts.entries) {
            expect(
              entry.value,
              greaterThan(share * 0.65),
              reason:
                  '${type.name}/${difficulty.name} under-uses slot '
                  '${entry.key} (${entry.value} of $total)',
            );
            expect(
              entry.value,
              lessThan(share * 1.35),
              reason:
                  '${type.name}/${difficulty.name} over-uses slot '
                  '${entry.key} (${entry.value} of $total)',
            );
          }
        }
      }
    });
  });

  group('PuzzleGenerator — difficulty is monotonic', () {
    test('mean complexity rises with each step for every type', () {
      for (final type in PuzzleType.values) {
        // shapeRotation is asserted structurally instead: its medium/hard gap
        // is a fraction of a percent on any numeric metric, so a green mean
        // comparison would be noise rather than evidence.
        if (type == PuzzleType.shapeRotation) continue;
        final means = <PuzzleDifficulty, double>{};
        for (final difficulty in PuzzleDifficulty.values) {
          var sum = 0;
          for (var seed = 0; seed < _sweep; seed++) {
            sum += _complexity(
              PuzzleGenerator.generate(
                type: type,
                difficulty: difficulty,
                seed: seed,
              ),
            );
          }
          means[difficulty] = sum / _sweep;
        }
        expect(
          means[PuzzleDifficulty.easy],
          lessThan(means[PuzzleDifficulty.medium]!),
          reason: '${type.name}: medium is no harder than easy ($means)',
        );
        expect(
          means[PuzzleDifficulty.medium],
          lessThan(means[PuzzleDifficulty.hard]!),
          reason: '${type.name}: hard is no harder than medium ($means)',
        );
      }
    });
  });

  group('PuzzleGenerator — generated lists are frozen and unaliased', () {
    test('mutating a content list is rejected, not silently destructive', () {
      // Content and answer used to share one List instance, so a surface
      // sorting `content.cells` into row-major order for layout would rewrite
      // the correct answer — and mutate an already-computed hashCode on a
      // value type declared @immutable.
      for (var seed = 0; seed < 40; seed++) {
        final grid = PuzzleGenerator.generate(
          type: PuzzleType.gridPatternRecall,
          difficulty: PuzzleDifficulty.hard,
          seed: seed,
        );
        final content = grid.content as GridPatternContent;
        final answer = grid.answer as CellsAnswer;
        expect(identical(content.cells, answer.cells), isFalse);
        expect(content.cells.clear, throwsUnsupportedError);
        expect(
          () => content.cells.sort((a, b) => a.row.compareTo(b.row)),
          throwsUnsupportedError,
        );
        expect(answer.cells.clear, throwsUnsupportedError);

        final digits = PuzzleGenerator.generate(
          type: PuzzleType.digitRecall,
          difficulty: PuzzleDifficulty.hard,
          seed: seed,
        );
        final digitContent = digits.content as DigitRecallContent;
        final digitAnswer = digits.answer as DigitsAnswer;
        expect(identical(digitContent.digits, digitAnswer.digits), isFalse);
        expect(digitContent.digits.shuffle, throwsUnsupportedError);
        expect(digitAnswer.digits.shuffle, throwsUnsupportedError);
      }
    });

    test('every list-carrying content type is frozen', () {
      _sweepEveryType((puzzle) {
        final content = puzzle.content;
        switch (content) {
          case ArithmeticContent():
            break;
          case SequenceNextContent():
            expect(content.shown.clear, throwsUnsupportedError);
          case MissingOperatorContent():
            expect(content.options.clear, throwsUnsupportedError);
          case CompareValuesContent():
            expect(content.values.clear, throwsUnsupportedError);
          case OddOneOutNumericContent():
            expect(content.values.clear, throwsUnsupportedError);
          case DigitRecallContent():
            expect(content.digits.clear, throwsUnsupportedError);
          case GridPatternContent():
            expect(content.cells.clear, throwsUnsupportedError);
          case SpotTheChangeContent():
            expect(content.before.clear, throwsUnsupportedError);
            expect(content.after.clear, throwsUnsupportedError);
          case ShapeRotationContent():
            expect(
              content.optionRotations.clear,
              throwsUnsupportedError,
            );
        }
      });
    });
  });

  group('PuzzleGenerator — the generated answer validates', () {
    test('the correct response is accepted for every type and '
        'difficulty', () {
      _sweepEveryType((puzzle) {
        expect(
          PuzzleValidator.validate(
            puzzle: puzzle,
            response: _correctResponse(puzzle),
          ),
          PuzzleAnswerOutcome.correct,
          reason: '${puzzle.type.name} rejected its own answer',
        );
      });
    });

    test('a near-miss response is rejected for every type and '
        'difficulty', () {
      _sweepEveryType((puzzle) {
        final nearMiss = _nearMissResponse(puzzle);
        expect(
          PuzzleValidator.validate(puzzle: puzzle, response: nearMiss),
          PuzzleAnswerOutcome.incorrect,
          reason: '${puzzle.type.name} accepted a near miss',
        );
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Run [check] over every difficulty × [_sweep] seeds for one type.
void _sweepAll(PuzzleType type, void Function(Puzzle puzzle) check) {
  for (final difficulty in PuzzleDifficulty.values) {
    for (var seed = 0; seed < _sweep; seed++) {
      check(
        PuzzleGenerator.generate(
          type: type,
          difficulty: difficulty,
          seed: seed,
        ),
      );
    }
  }
}

/// Run [check] over every type × difficulty × a shorter seed sweep.
void _sweepEveryType(void Function(Puzzle puzzle) check) {
  for (final type in PuzzleType.values) {
    for (final difficulty in PuzzleDifficulty.values) {
      for (var seed = 0; seed < 80; seed++) {
        check(
          PuzzleGenerator.generate(
            type: type,
            difficulty: difficulty,
            seed: seed,
          ),
        );
      }
    }
  }
}

int? _apply(int a, int b, ArithmeticOperator operation) => switch (operation) {
  ArithmeticOperator.add => a + b,
  ArithmeticOperator.subtract => a - b,
  ArithmeticOperator.multiply => a * b,
  ArithmeticOperator.divide => b != 0 && a % b == 0 ? a ~/ b : null,
};

/// Whether `answer` continues a constant-difference, constant-ratio, or
/// alternating-difference rule that the shown terms already obey.
bool _continuesRule(List<int> shown, int answer) {
  final full = [...shown, answer];
  final diffs = <int>[
    for (var i = 1; i < full.length; i++) full[i] - full[i - 1],
  ];
  if (diffs.toSet().length == 1) return true;
  if (full.every((v) => v != 0)) {
    final ratios = <int>[
      for (var i = 1; i < full.length; i++)
        if (full[i] % full[i - 1] == 0) full[i] ~/ full[i - 1] else -1,
    ];
    if (ratios.toSet().length == 1 && ratios.first != -1) return true;
  }
  final even = <int>[for (var i = 0; i < diffs.length; i += 2) diffs[i]];
  final odd = <int>[for (var i = 1; i < diffs.length; i += 2) diffs[i]];
  return even.toSet().length == 1 && odd.toSet().length == 1;
}

/// A per-type structural measure of how much work a puzzle asks for. Only its
/// ordering matters; the units are arbitrary.
int _complexity(Puzzle puzzle) {
  final content = puzzle.content;
  switch (content) {
    case ArithmeticContent():
      return (puzzle.answer as NumericAnswer).value;
    case SequenceNextContent():
      return (puzzle.answer as NumericAnswer).value + content.shown.length;
    case MissingOperatorContent():
      return content.left > content.right ? content.left : content.right;
    case CompareValuesContent():
      return content.values.length * 10000 +
          content.values.reduce((a, b) => a > b ? a : b);
    case OddOneOutNumericContent():
      return content.values.length;
    case DigitRecallContent():
      return content.digits.length;
    case GridPatternContent():
      return content.cells.length + content.rows * content.columns;
    case SpotTheChangeContent():
      return content.before.length;
    case ShapeRotationContent():
      return content.optionRotations.length * 10 +
          (content.referenceRotation == 0 ? 0 : 1);
  }
}

PuzzleResponse _correctResponse(Puzzle puzzle) {
  final answer = puzzle.answer;
  return switch (answer) {
    NumericAnswer() => PuzzleTextResponse('${answer.value}'),
    DigitsAnswer() => PuzzleTextResponse(answer.digits.join()),
    OptionAnswer() => PuzzleOptionResponse(answer.index),
    CellsAnswer() => PuzzleCellsResponse(answer.cells.reversed.toList()),
    OrderingAnswer() => PuzzleOrderingResponse(answer.indices),
  };
}

PuzzleResponse _nearMissResponse(Puzzle puzzle) {
  final answer = puzzle.answer;
  switch (answer) {
    case NumericAnswer():
      return PuzzleTextResponse('${answer.value + 1}');
    case DigitsAnswer():
      // Swap the first two digits — they are distinct, so this is always wrong.
      final digits = [...answer.digits];
      final head = digits[0];
      digits[0] = digits[1];
      digits[1] = head;
      return PuzzleTextResponse(digits.join());
    case OptionAnswer():
      return PuzzleOptionResponse(
        (answer.index + 1) % puzzle.optionCount,
      );
    case CellsAnswer():
      // Replace one lit cell with a neighbouring column, wrapping in-grid.
      final content = puzzle.content as GridPatternContent;
      final cells = [...answer.cells];
      final free = <GridCell>[
        for (var r = 0; r < content.rows; r++)
          for (var c = 0; c < content.columns; c++)
            if (!cells.contains(GridCell(r, c))) GridCell(r, c),
      ];
      cells[0] = free.first;
      return PuzzleCellsResponse(cells);
    case OrderingAnswer():
      final indices = [...answer.indices];
      final head = indices[0];
      indices[0] = indices[1];
      indices[1] = head;
      return PuzzleOrderingResponse(indices);
  }
}
