import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PuzzleSettings — defaults', () {
    test(
      'the default set rotates through three accessible reasoning tasks',
      () {
        final settings = PuzzleSettings.defaults();
        expect(settings.enabledTypes, {
          PuzzleType.arithmetic,
          PuzzleType.sequenceNext,
          PuzzleType.missingOperator,
        });
        expect(
          settings.enabledTypes.every((t) => t.isScreenReaderSolvable),
          isTrue,
        );
        expect(settings.isVisualOnly, isFalse);
      },
    );

    test('the defaults are calm rather than demanding', () {
      final settings = PuzzleSettings.defaults();
      expect(settings.taskCount, 1);
      expect(settings.difficulty, PuzzleDifficulty.medium);
      expect(settings.toleratedWrongAnswers, 3);
      expect(settings.escapeStrictness, PuzzleEscapeStrictness.confirm);
    });

    test('the default set rotates widely enough to vary', () {
      expect(PuzzleSettings.defaults().enabledTypes.length, greaterThan(2));
    });
  });

  group('PuzzleSettings — the enabled set can never be empty', () {
    test('constructing with no types throws', () {
      expect(
        () => PuzzleSettings(enabledTypes: const <PuzzleType>{}),
        throwsArgumentError,
      );
    });

    test('copying to no types throws', () {
      expect(
        () => PuzzleSettings.defaults().copyWith(
          enabledTypes: const <PuzzleType>{},
        ),
        throwsArgumentError,
      );
    });

    test('a single type is allowed', () {
      final settings = PuzzleSettings(
        enabledTypes: const {PuzzleType.arithmetic},
      );
      expect(settings.enabledTypes, {PuzzleType.arithmetic});
    });

    test('the stored set cannot be mutated after construction', () {
      final source = {PuzzleType.arithmetic, PuzzleType.sequenceNext};
      final settings = PuzzleSettings(enabledTypes: source);
      expect(
        () => settings.enabledTypes.add(PuzzleType.shapeRotation),
        throwsUnsupportedError,
      );
      // Mutating the caller's set afterwards must not reach into the settings.
      source.add(PuzzleType.shapeRotation);
      expect(settings.enabledTypes.length, 2);
    });
  });

  group('PuzzleSettings — bounded numbers', () {
    test('taskCount is clamped to the documented range', () {
      expect(PuzzleSettings.minTaskCount, 1);
      expect(PuzzleSettings.maxTaskCount, 5);
      for (var count = 1; count <= 5; count++) {
        expect(
          PuzzleSettings(
            enabledTypes: const {PuzzleType.arithmetic},
            taskCount: count,
          ).taskCount,
          count,
        );
      }
      expect(
        () => PuzzleSettings(
          enabledTypes: const {PuzzleType.arithmetic},
          taskCount: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => PuzzleSettings(
          enabledTypes: const {PuzzleType.arithmetic},
          taskCount: 6,
        ),
        throwsArgumentError,
      );
    });

    test('toleratedWrongAnswers is clamped to the documented range', () {
      expect(PuzzleSettings.minToleratedWrongAnswers, 0);
      expect(PuzzleSettings.maxToleratedWrongAnswers, 10);
      expect(
        PuzzleSettings(
          enabledTypes: const {PuzzleType.arithmetic},
          toleratedWrongAnswers: 0,
        ).toleratedWrongAnswers,
        0,
      );
      expect(
        PuzzleSettings(
          enabledTypes: const {PuzzleType.arithmetic},
          toleratedWrongAnswers: 10,
        ).toleratedWrongAnswers,
        10,
      );
      expect(
        () => PuzzleSettings(
          enabledTypes: const {PuzzleType.arithmetic},
          toleratedWrongAnswers: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => PuzzleSettings(
          enabledTypes: const {PuzzleType.arithmetic},
          toleratedWrongAnswers: 11,
        ),
        throwsArgumentError,
      );
    });
  });

  group('PuzzleSettings — the escape cannot be configured away', () {
    test('every strictness level still requires a confirmation', () {
      expect(PuzzleEscapeStrictness.values, [
        PuzzleEscapeStrictness.confirm,
        PuzzleEscapeStrictness.confirmAndHold,
      ]);
      // There is deliberately no "off", "disabled" or "never" level: the
      // emergency escape is a safety rule, not a preference.
      expect(
        PuzzleEscapeStrictness.values.map((s) => s.name),
        everyElement(startsWith('confirm')),
      );
    });

    test('strictness round-trips through copyWith', () {
      final settings = PuzzleSettings.defaults().copyWith(
        escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
      );
      expect(
        settings.escapeStrictness,
        PuzzleEscapeStrictness.confirmAndHold,
      );
    });
  });

  group('PuzzleSettings — escape prominence', () {
    PuzzleEasingState afterWrong(int count) {
      var state = PuzzleEasingState.start(PuzzleDifficulty.medium);
      for (var i = 0; i < count; i++) {
        state = state.recordWrong();
      }
      return state;
    }

    test('the escape is available from the very first moment', () {
      // Neither outcome hides it. `available` is still a labelled, reachable
      // control — the threshold only decides how loudly it is offered.
      expect(
        PuzzleSettings.defaults().escapeVisibilityFor(afterWrong(0)),
        PuzzleEscapeVisibility.available,
      );
    });

    test('it becomes prominent once past the tolerated count', () {
      final settings = PuzzleSettings.defaults(); // tolerates 3
      expect(
        settings.escapeVisibilityFor(afterWrong(3)),
        PuzzleEscapeVisibility.available,
      );
      expect(
        settings.escapeVisibilityFor(afterWrong(4)),
        PuzzleEscapeVisibility.prominent,
      );
    });

    test('a tolerance of zero surfaces it on the first wrong answer', () {
      final settings = PuzzleSettings.defaults().copyWith(
        toleratedWrongAnswers: 0,
      );
      expect(
        settings.escapeVisibilityFor(afterWrong(0)),
        PuzzleEscapeVisibility.available,
      );
      expect(
        settings.escapeVisibilityFor(afterWrong(1)),
        PuzzleEscapeVisibility.prominent,
      );
    });

    test('it measures the whole round, not a consecutive run', () {
      // The user alternating wrong and right must still reach the threshold.
      var state = PuzzleEasingState.start(PuzzleDifficulty.medium);
      for (var i = 0; i < 4; i++) {
        state = state.recordWrong().recordCorrect();
      }
      expect(state.consecutiveWrong, 0);
      expect(
        PuzzleSettings.defaults().escapeVisibilityFor(state),
        PuzzleEscapeVisibility.prominent,
      );
    });

    test('once prominent it stays prominent for the rest of the round', () {
      final settings = PuzzleSettings.defaults();
      var state = afterWrong(4);
      expect(
        settings.escapeVisibilityFor(state),
        PuzzleEscapeVisibility.prominent,
      );
      for (var i = 0; i < 5; i++) {
        state = state.recordCorrect(wasQuick: true);
        expect(
          settings.escapeVisibilityFor(state),
          PuzzleEscapeVisibility.prominent,
          reason: 'a correct answer must not withdraw the way out',
        );
      }
    });
  });

  group('PuzzleSettings — visual-only detection', () {
    test('an all-visual set is flagged', () {
      final settings = PuzzleSettings(
        enabledTypes: const {
          PuzzleType.gridPatternRecall,
          PuzzleType.spotTheChange,
        },
      );
      expect(settings.isVisualOnly, isTrue);
    });

    test('one accessible type is enough to clear the flag', () {
      final settings = PuzzleSettings(
        enabledTypes: const {
          PuzzleType.gridPatternRecall,
          PuzzleType.arithmetic,
        },
      );
      expect(settings.isVisualOnly, isFalse);
    });
  });

  group('PuzzleSettings — value semantics', () {
    test('copyWith changes only what it is given', () {
      final base = PuzzleSettings.defaults();
      final copy = base.copyWith(taskCount: 3);
      expect(copy.taskCount, 3);
      expect(copy.enabledTypes, base.enabledTypes);
      expect(copy.difficulty, base.difficulty);
      expect(copy.toleratedWrongAnswers, base.toleratedWrongAnswers);
      expect(copy.escapeStrictness, base.escapeStrictness);
      expect(base.copyWith(), base);
    });

    test('equal settings compare and hash equal regardless of set order', () {
      final a = PuzzleSettings(
        enabledTypes: const {PuzzleType.arithmetic, PuzzleType.shapeRotation},
      );
      final b = PuzzleSettings(
        enabledTypes: const {PuzzleType.shapeRotation, PuzzleType.arithmetic},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, a);
    });

    test('each field participates in equality', () {
      final base = PuzzleSettings.defaults();
      expect(base, isNot(base.copyWith(taskCount: 2)));
      expect(base, isNot(base.copyWith(difficulty: PuzzleDifficulty.easy)));
      expect(base, isNot(base.copyWith(toleratedWrongAnswers: 1)));
      expect(
        base,
        isNot(
          base.copyWith(
            escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
          ),
        ),
      );
      expect(
        base,
        isNot(base.copyWith(enabledTypes: {PuzzleType.arithmetic})),
      );
      expect(base, isNot(<String>['not settings']));
    });

    test('toString summarises without dumping the whole set', () {
      final settings = PuzzleSettings(
        enabledTypes: const {PuzzleType.arithmetic, PuzzleType.digitRecall},
        taskCount: 2,
      );
      expect(
        settings.toString(),
        'PuzzleSettings(types: 2, tasks: 2, difficulty: medium, '
        'tolerated: 3, escape: confirm, games: 0, puzzles: true)',
      );
    });
  });
}
