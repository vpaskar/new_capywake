import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:meta/meta.dart';

enum StepQuestOutcome { stalled }

/// Step Quest: walk with the phone, or tap the step button, to walk Capy
/// along. A long pause stalls (a struggle); no step is lost.
@immutable
class StepQuestRound {
  const StepQuestRound._({
    required this.target,
    required this.steps,
    required this.stalls,
    required this.lastOutcome,
  });

  factory StepQuestRound.start({required PuzzleDifficulty difficulty}) =>
      StepQuestRound._(
        target: targetFor(difficulty),
        steps: 0,
        stalls: 0,
        lastOutcome: null,
      );

  static int targetFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => 20,
    PuzzleDifficulty.medium => 30,
    PuzzleDifficulty.hard => 40,
  };

  /// Getting out of bed takes longer than a shake, so the pause is generous.
  static const stallAfter = Duration(seconds: 15);
  static const stepsPerMilestone = 5;

  final int target;
  final int steps;
  final int stalls;
  final StepQuestOutcome? lastOutcome;

  bool get isComplete => steps >= target;

  int get milestones => target ~/ stepsPerMilestone;
  int get milestonesDone => steps ~/ stepsPerMilestone;

  /// Share of the walk done, `0` at the start and `1` once complete.
  double get level => steps / target;

  GameChallenge get challenge => GameChallenge.motion(
    target: target,
    completed: steps,
    struggleCount: stalls,
    fallback: GameChallenge.touch(
      target: target,
      completed: steps,
      struggleCount: stalls,
    ),
  );

  /// [count] more steps, capped at the goal.
  StepQuestRound walk(int count) => isComplete || count <= 0
      ? this
      : StepQuestRound._(
          target: target,
          steps: (steps + count).clamp(0, target),
          stalls: stalls,
          lastOutcome: null,
        );

  StepQuestRound stall() => isComplete
      ? this
      : StepQuestRound._(
          target: target,
          steps: steps,
          stalls: stalls + 1,
          lastOutcome: StepQuestOutcome.stalled,
        );
}
