import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PuzzleDifficulty', () {
    test('the scale is ordered easy -> medium -> hard', () {
      expect(PuzzleDifficulty.values, [
        PuzzleDifficulty.easy,
        PuzzleDifficulty.medium,
        PuzzleDifficulty.hard,
      ]);
      expect(PuzzleDifficulty.easiest, PuzzleDifficulty.easy);
      expect(PuzzleDifficulty.hardest, PuzzleDifficulty.hard);
    });

    test('easier steps down and clamps at the floor', () {
      expect(PuzzleDifficulty.hard.easier, PuzzleDifficulty.medium);
      expect(PuzzleDifficulty.medium.easier, PuzzleDifficulty.easy);
      expect(PuzzleDifficulty.easy.easier, PuzzleDifficulty.easy);
    });

    test('harder steps up and clamps at the ceiling', () {
      expect(PuzzleDifficulty.easy.harder, PuzzleDifficulty.medium);
      expect(PuzzleDifficulty.medium.harder, PuzzleDifficulty.hard);
      expect(PuzzleDifficulty.hard.harder, PuzzleDifficulty.hard);
    });

    test('atMost returns the easier of the pair', () {
      expect(
        PuzzleDifficulty.hard.atMost(PuzzleDifficulty.easy),
        PuzzleDifficulty.easy,
      );
      expect(
        PuzzleDifficulty.easy.atMost(PuzzleDifficulty.hard),
        PuzzleDifficulty.easy,
      );
      expect(
        PuzzleDifficulty.medium.atMost(PuzzleDifficulty.medium),
        PuzzleDifficulty.medium,
      );
    });
  });

  group('PuzzleEasingState — a wrong answer can never trap the user', () {
    test('starts at the user ceiling with a clean slate', () {
      final state = PuzzleEasingState.start(PuzzleDifficulty.hard);
      expect(state.ceiling, PuzzleDifficulty.hard);
      expect(state.difficulty, PuzzleDifficulty.hard);
      expect(state.consecutiveCorrect, 0);
      expect(state.consecutiveWrong, 0);
      expect(state.isAtFloor, isFalse);
    });

    test('repeated wrong answers descend monotonically and floor', () {
      var state = PuzzleEasingState.start(PuzzleDifficulty.hard);
      final seen = <PuzzleDifficulty>[state.difficulty];
      for (var i = 0; i < 20; i++) {
        final previous = state.difficulty;
        state = state.recordWrong();
        expect(
          state.difficulty.index,
          lessThanOrEqualTo(previous.index),
          reason: 'difficulty went up after a wrong answer',
        );
        seen.add(state.difficulty);
      }
      expect(seen.take(3), [
        PuzzleDifficulty.hard,
        PuzzleDifficulty.medium,
        PuzzleDifficulty.easy,
      ]);
      expect(state.difficulty, PuzzleDifficulty.easy);
      expect(state.isAtFloor, isTrue);
      expect(state.consecutiveWrong, 20);
    });

    test('a wrong answer at the floor stays at the floor', () {
      final state = PuzzleEasingState.start(
        PuzzleDifficulty.easy,
      ).recordWrong().recordWrong();
      expect(state.difficulty, PuzzleDifficulty.easy);
      expect(state.isAtFloor, isTrue);
    });

    test('a wrong answer clears the step-up streak', () {
      final state = PuzzleEasingState.start(PuzzleDifficulty.hard)
          .recordWrong()
          .recordCorrect(wasQuick: true)
          .recordCorrect(wasQuick: true)
          .recordWrong();
      expect(state.consecutiveCorrect, 0);
      expect(state.consecutiveWrong, 1);
      // Two quick answers were not enough to climb back, then the wrong answer
      // eased again.
      expect(state.difficulty, PuzzleDifficulty.easy);
    });
  });

  group('PuzzleEasingState — climbing back', () {
    test('a slow correct answer holds the level and resets the streak', () {
      final state = PuzzleEasingState.start(
        PuzzleDifficulty.hard,
      ).recordWrong().recordCorrect(wasQuick: true).recordCorrect();
      expect(state.difficulty, PuzzleDifficulty.medium);
      expect(state.consecutiveCorrect, 0);
      expect(state.consecutiveWrong, 0);
    });

    test('three quick correct answers step back up one level', () {
      var state = PuzzleEasingState.start(PuzzleDifficulty.hard).recordWrong();
      expect(state.difficulty, PuzzleDifficulty.medium);
      state = state.recordCorrect(wasQuick: true);
      expect(state.consecutiveCorrect, 1);
      expect(state.difficulty, PuzzleDifficulty.medium);
      state = state.recordCorrect(wasQuick: true);
      expect(state.consecutiveCorrect, 2);
      expect(state.difficulty, PuzzleDifficulty.medium);
      state = state.recordCorrect(wasQuick: true);
      expect(state.difficulty, PuzzleDifficulty.hard);
      expect(state.consecutiveCorrect, 0);
    });

    test('difficulty never climbs above the user ceiling', () {
      var state = PuzzleEasingState.start(PuzzleDifficulty.easy);
      for (var i = 0; i < 30; i++) {
        state = state.recordCorrect(wasQuick: true);
        expect(state.difficulty, PuzzleDifficulty.easy);
      }
      expect(state.ceiling, PuzzleDifficulty.easy);
    });

    test('a ceiling of medium is reached but not exceeded', () {
      var state = PuzzleEasingState.start(
        PuzzleDifficulty.medium,
      ).recordWrong().recordWrong();
      expect(state.difficulty, PuzzleDifficulty.easy);
      for (var i = 0; i < 12; i++) {
        state = state.recordCorrect(wasQuick: true);
      }
      expect(state.difficulty, PuzzleDifficulty.medium);
    });

    test('the step-up streak is the documented constant', () {
      expect(PuzzleEasingState.stepUpStreak, 3);
    });
  });

  group('PuzzleEasingState — the round remembers a hard morning', () {
    test('a correct answer does not erase earlier wrong answers', () {
      // `consecutiveWrong` is reset by any correct answer, which is faithful
      // to its name but wrong for escape prominence: with taskCount up to 5, a
      // user who gets three wrong on task 1 and then solves it would start
      // task 2 with the escape receded, as if the morning had gone fine.
      final state = PuzzleEasingState.start(
        PuzzleDifficulty.hard,
      ).recordWrong().recordWrong().recordWrong().recordCorrect();
      expect(state.consecutiveWrong, 0);
      expect(state.wrongThisRound, 3);
    });

    test('alternating wrong and right still accumulates', () {
      // The person alternating wrong/right/wrong/right is struggling just as
      // much as the one failing repeatedly, and a consecutive counter is the
      // one thing that never fires for them.
      var state = PuzzleEasingState.start(PuzzleDifficulty.medium);
      for (var i = 0; i < 4; i++) {
        state = state.recordWrong().recordCorrect(wasQuick: true);
      }
      expect(state.consecutiveWrong, 0);
      expect(state.wrongThisRound, 4);
    });

    test('wrongThisRound never decreases within a round', () {
      var state = PuzzleEasingState.start(PuzzleDifficulty.hard);
      var previous = 0;
      for (var i = 0; i < 30; i++) {
        state = i.isEven
            ? state.recordWrong()
            : state.recordCorrect(wasQuick: i.isOdd);
        expect(state.wrongThisRound, greaterThanOrEqualTo(previous));
        previous = state.wrongThisRound;
      }
    });

    test('a fresh round starts clean', () {
      expect(PuzzleEasingState.start(PuzzleDifficulty.easy).wrongThisRound, 0);
    });
  });

  group('PuzzleEasingState — value semantics', () {
    test('equal states compare and hash equal', () {
      final a = PuzzleEasingState.start(PuzzleDifficulty.medium).recordWrong();
      final b = PuzzleEasingState.start(PuzzleDifficulty.medium).recordWrong();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, a);
    });

    test('each field participates in equality', () {
      final base = PuzzleEasingState.start(PuzzleDifficulty.medium);
      expect(base, isNot(PuzzleEasingState.start(PuzzleDifficulty.hard)));
      expect(base, isNot(base.recordWrong()));
      expect(base, isNot(base.recordCorrect(wasQuick: true)));
      expect(
        base.recordCorrect(wasQuick: true),
        isNot(base.recordCorrect()),
      );
      // wrongThisRound participates too: two states can agree on every other
      // field and still describe very different mornings.
      expect(
        base.recordWrong().recordCorrect(),
        isNot(base.recordCorrect()),
      );
      expect(base, isNot(<String>['not an easing state']));
    });

    test('toString names the levels and counters', () {
      final state = PuzzleEasingState.start(
        PuzzleDifficulty.hard,
      ).recordWrong();
      expect(
        state.toString(),
        'PuzzleEasingState(ceiling: hard, difficulty: medium, '
        'consecutiveCorrect: 0, consecutiveWrong: 1, wrongThisRound: 1)',
      );
    });
  });
}
