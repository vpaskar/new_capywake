import 'dart:math' as math;

import 'package:capywake/core/puzzle/puzzle.dart';
import 'package:capywake/core/puzzle/puzzle_content.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';

/// Pure, seeded generators — one per [PuzzleType].
///
/// Contract, relied on by every caller and asserted by the seed-sweep tests:
///
/// - **Deterministic.** The same `(type, difficulty, seed)` always yields the
///   same [Puzzle]. Nothing reads a clock or an unseeded `Random`.
/// - **Constructed, not banked.** There is no authored content list. Every
///   puzzle is built from the seed, so variety is a property of the code.
///   It is *not* infinite, and saying so would be the same overclaim this
///   project bans elsewhere: each generator's space is bounded by its
///   difficulty band, and the easy bands are deliberately the narrowest
///   because easy has to stay easy. The bands are sized so that even the
///   smallest — `arithmetic` and `sequenceNext` at easy, which are also where
///   `PuzzleEasingState` floors a struggling user — stay well clear of the
///   repeat-within-weeks failure mode that `CLAUDE.md` cites when it bans a
///   trivia bank. `puzzle_generator_test.dart` measures every band at every
///   difficulty and fails if one shrinks.
/// - **Locale-neutral.** Content is numbers, operators, digits, coordinates,
///   shape enums and angles. No strings.
/// - **Exactly one correct answer.** For every option-based type the correct
///   option is unique *by construction*, not by hoping — a puzzle with two
///   right answers reads to a half-asleep user as a broken app.
///
/// Where a naive draw could produce an ambiguous puzzle, the generator
/// enumerates or pre-filters the valid candidate space and picks from it,
/// rather than drawing and rejecting. No generator can fail, and none has a
/// give-up branch — which would be both a coverage hole and a 03:00 failure
/// mode. (`_distinctInts` does redraw on a collision, but it is drawing a
/// handful of values from a four-digit range, always terminates, and cannot
/// produce an invalid puzzle if it does.)
abstract final class PuzzleGenerator {
  /// Generate a puzzle of [type] at [difficulty], reproducibly from [seed].
  static Puzzle generate({
    required PuzzleType type,
    required PuzzleDifficulty difficulty,
    required int seed,
  }) {
    final random = math.Random(seed);
    final (content, answer) = switch (type) {
      PuzzleType.arithmetic => _arithmetic(random, difficulty),
      PuzzleType.sequenceNext => _sequenceNext(random, difficulty),
      PuzzleType.missingOperator => _missingOperator(random, difficulty),
      PuzzleType.compareValues => _compareValues(random, difficulty),
      PuzzleType.oddOneOutNumeric => _oddOneOutNumeric(random, difficulty),
      PuzzleType.digitRecall => _digitRecall(
        random,
        difficulty,
        reversed: false,
      ),
      PuzzleType.digitRecallReversed => _digitRecall(
        random,
        difficulty,
        reversed: true,
      ),
      PuzzleType.gridPatternRecall => _gridPattern(random, difficulty),
      PuzzleType.spotTheChange => _spotTheChange(random, difficulty),
      PuzzleType.shapeRotation => _shapeRotation(random, difficulty),
    };
    return Puzzle(
      type: type,
      difficulty: difficulty,
      seed: seed,
      content: content,
      answer: answer,
    );
  }

  // ------------------------------------------------------------------
  // 1. arithmetic
  // ------------------------------------------------------------------

  /// `a + b`, `a − b`, `a × b`. Subtraction is normalised so the result is
  /// never negative — a minus result is a needless stumble at 03:00, and the
  /// point is to wake someone, not to catch them out.
  static (PuzzleContent, PuzzleAnswer) _arithmetic(
    math.Random random,
    PuzzleDifficulty difficulty,
  ) {
    final int left;
    final int right;
    final ArithmeticOperator operation;
    switch (difficulty) {
      case PuzzleDifficulty.easy:
        operation = random.nextBool()
            ? ArithmeticOperator.add
            : ArithmeticOperator.subtract;
        // 2..12 rather than 2..9: sums stay inside the twenties, so this is
        // still an easy sum, but the reachable space is ~187 puzzles instead
        // of the 100 that single digits allow. Easy is where easing floors a
        // struggling user, so it is the band that most needs the room.
        left = _between(random, 2, 12);
        right = _between(random, 2, 12);
      case PuzzleDifficulty.medium:
        final pick = random.nextInt(3);
        operation = switch (pick) {
          0 => ArithmeticOperator.add,
          1 => ArithmeticOperator.subtract,
          _ => ArithmeticOperator.multiply,
        };
        if (operation == ArithmeticOperator.multiply) {
          left = _between(random, 3, 9);
          right = _between(random, 3, 9);
        } else if (operation == ArithmeticOperator.subtract) {
          right = _between(random, 10, 79);
          left = _between(random, right + 10, 99);
        } else {
          left = _between(random, 10, 99);
          right = _between(random, 10, 99);
        }
      case PuzzleDifficulty.hard:
        final pick = random.nextInt(3);
        operation = switch (pick) {
          0 => ArithmeticOperator.add,
          1 => ArithmeticOperator.subtract,
          _ => ArithmeticOperator.multiply,
        };
        if (operation == ArithmeticOperator.multiply) {
          left = _between(random, 11, 99);
          right = _between(random, 3, 9);
        } else if (operation == ArithmeticOperator.subtract) {
          // Draw the smaller operand first, then force a gap. Drawing both
          // operands freely lets a *hard* subtraction come out as
          // `413 - 411 = 2` — easier than a typical easy puzzle. Nothing
          // otherwise constrains the minimum difficulty of a hard puzzle.
          right = _between(random, 100, 799);
          left = _between(random, right + 100, 999);
        } else {
          left = _between(random, 100, 999);
          right = _between(random, 100, 999);
        }
    }

    // Order subtraction so the answer stays non-negative.
    final ordered = operation == ArithmeticOperator.subtract && right > left
        ? (left: right, right: left)
        : (left: left, right: right);
    // Division is never generated for this type: the answer would often not be
    // a whole number, and rounding rules are exactly the kind of ambiguity a
    // wake puzzle must not have. `divide` exists for `missingOperator`, which
    // only offers it where it divides evenly.
    //
    // The `!` below is safe *because* of that: `_applyOperator` returns null
    // only for a division that does not come out whole. Anything that adds
    // `divide` to the branches above must handle the null here first.
    final result = _applyOperator(ordered.left, ordered.right, operation)!;
    return (
      ArithmeticContent(
        left: ordered.left,
        right: ordered.right,
        operation: operation,
      ),
      NumericAnswer(result),
    );
  }

  // ------------------------------------------------------------------
  // 2. sequenceNext
  // ------------------------------------------------------------------

  /// An arithmetic, geometric or alternating-step progression. Terms stay
  /// non-negative and bounded so the row remains readable on a dim screen.
  static (PuzzleContent, PuzzleAnswer) _sequenceNext(
    math.Random random,
    PuzzleDifficulty difficulty,
  ) {
    final terms = <int>[];
    switch (difficulty) {
      case PuzzleDifficulty.easy:
        // start 1..20 x step 2..12 = 220 sequences, against the 72 that
        // 1..9 x 2..9 allowed. The final term still lands under 70, so the
        // row reads at a glance on a dim screen.
        final start = _between(random, 1, 20);
        final step = _between(random, 2, 12);
        for (var i = 0; i < 5; i++) {
          terms.add(start + step * i);
        }
      case PuzzleDifficulty.medium:
        if (random.nextBool()) {
          final start = _between(random, 5, 40);
          final step = _between(random, 3, 15);
          for (var i = 0; i < 5; i++) {
            terms.add(start + step * i);
          }
        } else {
          // The geometric branch is inherently narrow — only a handful of
          // (start, ratio) pairs keep the terms readable — so the arithmetic
          // branch above carries the variety for this difficulty.
          final start = _between(random, 1, 6);
          final ratio = _between(random, 2, 3);
          var value = start;
          for (var i = 0; i < 5; i++) {
            terms.add(value);
            value *= ratio;
          }
        }
      case PuzzleDifficulty.hard:
        if (random.nextBool()) {
          // Two steps alternating: +a, +b, +a, +b, ... Which of the two is the
          // larger is drawn as well, so "the second gap is always the bigger
          // one" never becomes a tell.
          final start = _between(random, 2, 20);
          final smaller = _between(random, 3, 11);
          final larger = smaller + _between(random, 3, 11);
          final largerFirst = random.nextBool();
          final first = largerFirst ? larger : smaller;
          final second = largerFirst ? smaller : larger;
          var value = start;
          for (var i = 0; i < 6; i++) {
            terms.add(value);
            value += i.isEven ? first : second;
          }
        } else {
          // Five terms rather than six: a sixth would push the answer past
          // 5000, which is tedious to compute and type at 03:00 rather than
          // hard. Hard should ask for thought, not for stamina.
          final start = _between(random, 2, 5);
          final ratio = _between(random, 3, 4);
          var value = start;
          for (var i = 0; i < 5; i++) {
            terms.add(value);
            value *= ratio;
          }
        }
    }
    // The last term generated is the answer; the rest are shown.
    final answer = terms.removeLast();
    return (SequenceNextContent(shown: _frozen(terms)), NumericAnswer(answer));
  }

  // ------------------------------------------------------------------
  // 3. missingOperator
  // ------------------------------------------------------------------

  /// `left ? right = result`, pick from `+ − × ÷`.
  ///
  /// Built by **enumerating** every `(left, right, operator)` in the band for
  /// which exactly one of the four operators reproduces the result, then
  /// picking one. `2 ? 2 = 4` (both `+` and `×`) can therefore never be
  /// generated, and there is no retry loop that could spin or fall back.
  static (PuzzleContent, PuzzleAnswer) _missingOperator(
    math.Random random,
    PuzzleDifficulty difficulty,
  ) {
    final band = switch (difficulty) {
      PuzzleDifficulty.easy => (
        minLeft: 2,
        maxLeft: 9,
        minRight: 2,
        maxRight: 9,
      ),
      PuzzleDifficulty.medium => (
        minLeft: 2,
        maxLeft: 14,
        minRight: 2,
        maxRight: 12,
      ),
      PuzzleDifficulty.hard => (
        minLeft: 3,
        maxLeft: 24,
        minRight: 2,
        maxRight: 12,
      ),
    };

    final candidates =
        <({int left, int right, ArithmeticOperator operation})>[];
    for (var left = band.minLeft; left <= band.maxLeft; left++) {
      for (var right = band.minRight; right <= band.maxRight; right++) {
        for (final operation in ArithmeticOperator.values) {
          final result = _applyOperator(left, right, operation);
          if (result == null || result < 0) continue;
          final matching = ArithmeticOperator.values
              .where((o) => _applyOperator(left, right, o) == result)
              .length;
          if (matching == 1) {
            candidates.add((left: left, right: right, operation: operation));
          }
        }
      }
    }

    final chosen = candidates[random.nextInt(candidates.length)];
    final result = _applyOperator(chosen.left, chosen.right, chosen.operation)!;
    final options = _shuffled(ArithmeticOperator.values.toList(), random);
    return (
      MissingOperatorContent(
        left: chosen.left,
        right: chosen.right,
        result: result,
        options: _frozen(options),
      ),
      OptionAnswer(options.indexOf(chosen.operation)),
    );
  }

  /// Apply [operation], or `null` when it has no whole-number meaning here.
  static int? _applyOperator(int a, int b, ArithmeticOperator operation) =>
      switch (operation) {
        ArithmeticOperator.add => a + b,
        ArithmeticOperator.subtract => a - b,
        ArithmeticOperator.multiply => a * b,
        ArithmeticOperator.divide => b != 0 && a % b == 0 ? a ~/ b : null,
      };

  // ------------------------------------------------------------------
  // 4. compareValues
  // ------------------------------------------------------------------

  /// Pick the largest, the smallest, or put everything in ascending order.
  /// Values are always distinct, which is what makes the answer unique.
  static (PuzzleContent, PuzzleAnswer) _compareValues(
    math.Random random,
    PuzzleDifficulty difficulty,
  ) {
    final (count, min, max) = switch (difficulty) {
      PuzzleDifficulty.easy => (3, 10, 99),
      PuzzleDifficulty.medium => (4, 100, 999),
      PuzzleDifficulty.hard => (4, 1000, 9999),
    };
    final values = _distinctInts(random, count: count, min: min, max: max);
    final task = switch (random.nextInt(3)) {
      0 => CompareTask.largest,
      1 => CompareTask.smallest,
      _ => CompareTask.ascending,
    };

    final content = CompareValuesContent(values: _frozen(values), task: task);
    switch (task) {
      case CompareTask.largest:
        var best = 0;
        for (var i = 1; i < values.length; i++) {
          if (values[i] > values[best]) best = i;
        }
        return (content, OptionAnswer(best));
      case CompareTask.smallest:
        var best = 0;
        for (var i = 1; i < values.length; i++) {
          if (values[i] < values[best]) best = i;
        }
        return (content, OptionAnswer(best));
      case CompareTask.ascending:
        final indices = List<int>.generate(values.length, (i) => i)
          ..sort((a, b) => values[a].compareTo(values[b]));
        return (content, OrderingAnswer(_frozen(indices)));
    }
  }

  // ------------------------------------------------------------------
  // 5. oddOneOutNumeric
  // ------------------------------------------------------------------

  /// All values are multiples of `divisor`, except one.
  ///
  /// **The rule is stated, not discovered — and the surface is required to
  /// state it.** `OddOneOutNumericContent.divisor` exists for exactly that, and
  /// the instruction reads "Which is not a multiple of 4?".
  ///
  /// This is not a presentation preference; it is what makes the puzzle
  /// correct. An earlier cut of this generator hid the rule and tried to defend
  /// the resulting ambiguity by filtering the pools — no value divisible by 3,
  /// 4 or 5, so those readings could not single anything out. Measurement
  /// killed that approach: a value *other than* the declared answer was still
  /// the only one of its digit length in ~28% of puzzles, the only perfect
  /// square in ~36%, and the only multiple of 7 in ~46%. For `divisor == 4`
  /// the failure was structural rather than incidental — `8` was the only
  /// single-digit value the generator could emit and was never the answer, so
  /// a user tapping the one obviously different-looking number was marked
  /// wrong and had the next puzzle eased, punished for the more defensible
  /// reading.
  ///
  /// No amount of filtering fixes that. Any finite set of integers admits
  /// endless post-hoc rules, so each filter is whack-a-mole *and* shrinks the
  /// pool, which is the opposite of what "a different puzzle every morning"
  /// needs. Stating the rule removes the ambiguity by construction and lets
  /// the pools be as wide as the band allows.
  static (PuzzleContent, PuzzleAnswer) _oddOneOutNumeric(
    math.Random random,
    PuzzleDifficulty difficulty,
  ) {
    final (count, maxMultiplier) = switch (difficulty) {
      PuzzleDifficulty.easy => (4, 16),
      PuzzleDifficulty.medium => (5, 30),
      PuzzleDifficulty.hard => (6, 60),
    };
    final divisor = const [3, 4, 6, 7, 8, 9][random.nextInt(6)];

    final multiples = <int>[
      for (var k = 2; k <= maxMultiplier; k++) divisor * k,
    ];
    // The intruder sits beside a multiple, drawn from the same k range, so it
    // is close enough in magnitude that the answer is arithmetic rather than
    // "the one that looks different". Every divisor above is >= 3 and every
    // offset is +-1 or +-2, so `divisor * k + offset` is never itself a
    // multiple of `divisor` — the intruder provably breaks the stated rule,
    // and provably cannot collide with one of the picked multiples.
    final offsets = <int>[
      for (var k = 2; k <= maxMultiplier; k++)
        for (final offset in const [1, 2, -1, -2]) divisor * k + offset,
    ];

    final picked = _pickDistinct(multiples, count - 1, random);
    final intruder = offsets[random.nextInt(offsets.length)];
    final values = _shuffled([...picked, intruder], random);
    return (
      OddOneOutNumericContent(values: _frozen(values), divisor: divisor),
      OptionAnswer(values.indexOf(intruder)),
    );
  }

  // ------------------------------------------------------------------
  // 6 & 7. digitRecall / digitRecallReversed
  // ------------------------------------------------------------------

  /// Distinct digits, shown then re-entered. Distinctness keeps the row easy
  /// to read at a glance and removes any "was that two sevens?" ambiguity.
  static (PuzzleContent, PuzzleAnswer) _digitRecall(
    math.Random random,
    PuzzleDifficulty difficulty, {
    required bool reversed,
  }) {
    final length = switch (difficulty) {
      PuzzleDifficulty.easy => reversed ? 3 : 4,
      PuzzleDifficulty.medium => reversed ? 4 : 5,
      PuzzleDifficulty.hard => reversed ? 5 : 6,
    };
    final digits = _pickDistinct(
      List<int>.generate(10, (i) => i),
      length,
      random,
    );
    final expected = reversed ? digits.reversed.toList() : [...digits];
    return (
      // Separate, unmodifiable lists on purpose. Handing the same instance to
      // both would let a surface that sorts or shuffles the displayed digits
      // silently rewrite the correct answer — and mutate an already-computed
      // hashCode on a value type declared @immutable.
      DigitRecallContent(digits: _frozen(digits), reversed: reversed),
      DigitsAnswer(_frozen(expected)),
    );
  }

  // ------------------------------------------------------------------
  // 8. gridPatternRecall
  // ------------------------------------------------------------------

  /// Distinct cells flashed in a grid. Answered as a set — requiring a tap
  /// order would be a trap, not a wake-up.
  static (PuzzleContent, PuzzleAnswer) _gridPattern(
    math.Random random,
    PuzzleDifficulty difficulty,
  ) {
    final (rows, columns, cellCount) = switch (difficulty) {
      PuzzleDifficulty.easy => (3, 3, 3),
      PuzzleDifficulty.medium => (3, 3, 4),
      PuzzleDifficulty.hard => (4, 4, 5),
    };
    final all = <GridCell>[
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < columns; c++) GridCell(r, c),
    ];
    final cells = _pickDistinct(all, cellCount, random);
    return (
      // Separate, unmodifiable lists — see `_digitRecall`. A grid layout that
      // sorts `content.cells` into row-major order is a natural thing for a
      // widget to do, and must not touch the answer.
      GridPatternContent(
        rows: rows,
        columns: columns,
        cells: _frozen(cells),
      ),
      CellsAnswer(_frozen([...cells])),
    );
  }

  // ------------------------------------------------------------------
  // 9. spotTheChange
  // ------------------------------------------------------------------

  /// Two rows of distinct shapes differing at exactly one position. The
  /// replacement is drawn from the shapes *not* already on the row, so the
  /// changed position is the only difference and no duplicate appears.
  static (PuzzleContent, PuzzleAnswer) _spotTheChange(
    math.Random random,
    PuzzleDifficulty difficulty,
  ) {
    final count = switch (difficulty) {
      PuzzleDifficulty.easy => 4,
      PuzzleDifficulty.medium => 5,
      PuzzleDifficulty.hard => 6,
    };
    final before = _pickDistinct(PuzzleShape.values.toList(), count, random);
    // `spare` holds the shapes not already on the row, so the replacement is
    // always one the user has not just seen. It has `PuzzleShape.values.length
    // - count` entries — 2 at the hardest setting today. Raising `count` to
    // the full shape count would empty it and make `nextInt(0)` throw at
    // 03:00, so the band above and this pool have to move together.
    final spare = PuzzleShape.values.where((s) => !before.contains(s)).toList();
    final changedIndex = random.nextInt(count);
    final after = [...before]
      ..[changedIndex] = spare[random.nextInt(spare.length)];
    return (
      SpotTheChangeContent(before: _frozen(before), after: _frozen(after)),
      OptionAnswer(changedIndex),
    );
  }

  // ------------------------------------------------------------------
  // 10. shapeRotation
  // ------------------------------------------------------------------

  /// One shape at a reference angle; pick the option a quarter turn clockwise.
  /// Option angles are distinct and every [PuzzleShape] is rotationally
  /// asymmetric, so exactly one option can be the answer.
  static (PuzzleContent, PuzzleAnswer) _shapeRotation(
    math.Random random,
    PuzzleDifficulty difficulty,
  ) {
    final optionCount = switch (difficulty) {
      PuzzleDifficulty.easy => 3,
      PuzzleDifficulty.medium => 4,
      PuzzleDifficulty.hard => 4,
    };
    final shape = PuzzleShape.values[random.nextInt(PuzzleShape.values.length)];
    // The reference is drawn at every difficulty, including easy.
    //
    // An earlier cut pinned easy to 0, reasoning that an upright reference is
    // easier to picture. The effect was the opposite of intended: with the
    // reference constant the target was *always* 90 degrees, so the reference
    // panel became decorative and the puzzle degenerated into recognising
    // eight memorised poses. That is the same learnable tell that was fixed
    // for the alternating sequence, and it landed on the level easing floors
    // to — where a struggling user spends the most time. Easy is made easy by
    // offering three options rather than four; hard additionally refuses an
    // upright reference, so it always requires a real mental rotation.
    final referenceRotation = difficulty == PuzzleDifficulty.hard
        ? const [90, 180, 270][random.nextInt(3)]
        : const [0, 90, 180, 270][random.nextInt(4)];
    final target = (referenceRotation + 90) % 360;
    final distractors = _pickDistinct(
      const [0, 90, 180, 270].where((r) => r != target).toList(),
      optionCount - 1,
      random,
    );
    final optionRotations = _shuffled([target, ...distractors], random);
    return (
      ShapeRotationContent(
        shape: shape,
        referenceRotation: referenceRotation,
        optionRotations: _frozen(optionRotations),
      ),
      OptionAnswer(optionRotations.indexOf(target)),
    );
  }

  // ------------------------------------------------------------------
  // Shared helpers
  // ------------------------------------------------------------------

  /// A uniform integer in `[min, max]`, both inclusive.
  static int _between(math.Random random, int min, int max) =>
      min + random.nextInt(max - min + 1);

  /// Freeze a generated list before it enters a `@immutable` value type.
  ///
  /// The content and answer classes take `List` fields and hash them with
  /// `Object.hashAll`, so a caller that mutates one in place would corrupt an
  /// already-computed `hashCode` and, where content and answer describe the
  /// same data, silently change the correct answer. Every generated list goes
  /// through here; the const literals used in tests are already immutable.
  static List<T> _frozen<T>(List<T> items) => List<T>.unmodifiable(items);

  /// [count] distinct values drawn uniformly from [pool], order randomised.
  ///
  /// Every call site keeps `count <= pool.length` by construction, and each
  /// pool is a function of the difficulty alone — never of the seed. The
  /// seed-sweep tests therefore exercise every pool the app can build, so
  /// shrinking a band below what its call site needs fails the suite rather
  /// than throwing at 03:00.
  static List<T> _pickDistinct<T>(List<T> pool, int count, math.Random random) {
    final remaining = [...pool];
    final picked = <T>[];
    for (var i = 0; i < count; i++) {
      picked.add(remaining.removeAt(random.nextInt(remaining.length)));
    }
    return picked;
  }

  /// [count] distinct integers in `[min, max]`, in random order.
  static List<int> _distinctInts(
    math.Random random, {
    required int count,
    required int min,
    required int max,
  }) {
    final seen = <int>{};
    while (seen.length < count) {
      seen.add(_between(random, min, max));
    }
    return seen.toList();
  }

  /// A Fisher-Yates shuffle on a copy, driven by the seeded [random] so option
  /// order — and therefore the correct answer's position — stays reproducible
  /// and unbiased.
  static List<T> _shuffled<T>(List<T> items, math.Random random) {
    final copy = [...items];
    for (var i = copy.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final swap = copy[i];
      copy[i] = copy[j];
      copy[j] = swap;
    }
    return copy;
  }
}
