import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzleEasingState _easingWithWrongs(int wrongs) {
  var state = PuzzleEasingState.start(PuzzleDifficulty.medium);
  for (var i = 0; i < wrongs; i++) {
    state = state.recordWrong();
  }
  return state;
}

void main() {
  group('GameChallenge goal', () {
    test('is complete only at the target', () {
      const below = GameChallenge.touch(target: 5, completed: 4);
      const at = GameChallenge.touch(target: 5, completed: 5);

      expect(below.isComplete, isFalse);
      expect(at.isComplete, isTrue);
    });

    test('is complete when completed exceeds the target', () {
      const over = GameChallenge.touch(target: 3, completed: 4);
      expect(over.isComplete, isTrue);
    });

    test('a single-step game completes at one', () {
      const one = GameChallenge.touch(target: 1, completed: 1);
      expect(one.isComplete, isTrue);
    });
  });

  group('GameChallenge escape visibility', () {
    test('is available while struggle is within tolerance', () {
      const within = GameChallenge.touch(
        target: 5,
        completed: 1,
        struggleCount: 3,
      );
      expect(
        within.escapeVisibilityFor(toleratedStruggles: 3),
        PuzzleEscapeVisibility.available,
      );
    });

    test('is prominent once struggle passes tolerance', () {
      const beyond = GameChallenge.touch(
        target: 5,
        completed: 1,
        struggleCount: 4,
      );
      expect(
        beyond.escapeVisibilityFor(toleratedStruggles: 3),
        PuzzleEscapeVisibility.prominent,
      );
    });

    test('is never hidden — available is the floor', () {
      const fresh = GameChallenge.touch(target: 5, completed: 0);
      expect(
        fresh.escapeVisibilityFor(toleratedStruggles: 3),
        PuzzleEscapeVisibility.available,
      );
    });

    test('uses the same escape policy a puzzle does', () {
      final settings = PuzzleSettings.defaults();
      for (var count = 0; count <= 6; count++) {
        final game = GameChallenge.touch(
          target: 5,
          completed: 0,
          struggleCount: count,
        );
        expect(
          game.escapeVisibilityFor(
            toleratedStruggles: settings.toleratedWrongAnswers,
          ),
          settings.escapeVisibilityFor(_easingWithWrongs(count)),
          reason:
              'a game and a puzzle must offer the escape the same way against '
              'the user tolerance; only what they count differs',
        );
      }
    });
  });

  group('GameChallenge motion', () {
    test('a touch game requires no motion and offers no fallback', () {
      const touch = GameChallenge.touch(target: 5, completed: 0);
      expect(touch.requiresMotion, isFalse);
      expect(touch.motionFallback, isNull);
    });

    test('a motion game requires motion and always carries a fallback', () {
      final motion = GameChallenge.motion(
        target: 5,
        completed: 0,
        fallback: const GameChallenge.touch(target: 5, completed: 0),
      );
      expect(motion.requiresMotion, isTrue);
      expect(motion.motionFallback, isNotNull);
      expect(motion.motionFallback!.requiresMotion, isFalse);
    });

    test('a motion game cannot use another motion game as its fallback', () {
      final motionFallback = GameChallenge.motion(
        target: 3,
        completed: 0,
        fallback: const GameChallenge.touch(target: 3, completed: 0),
      );
      expect(
        () => GameChallenge.motion(
          target: 5,
          completed: 0,
          fallback: motionFallback,
        ),
        throwsA(isA<AssertionError>()),
        reason: 'a fallback that also needs motion is no fallback at all',
      );
    });
  });

  group('GameChallenge goal bounds', () {
    test('rejects a non-positive target', () {
      expect(
        () => GameChallenge.touch(target: 0, completed: 0),
        throwsA(isA<AssertionError>()),
        reason: 'a game with no goal would dismiss the alarm with no play',
      );
    });

    test('rejects negative progress or struggle', () {
      expect(
        () => GameChallenge.touch(target: 5, completed: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GameChallenge.touch(target: 5, completed: 0, struggleCount: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('GameChallenge has no gamification surface', () {
    test('carries only goal, struggle, and motion state', () {
      const challenge = GameChallenge.touch(
        target: 5,
        completed: 2,
        struggleCount: 1,
      );

      expect(challenge.target, 5);
      expect(challenge.completed, 2);
      expect(challenge.struggleCount, 1);
      expect(challenge.isComplete, isFalse);
      expect(challenge.requiresMotion, isFalse);
    });
  });
}
