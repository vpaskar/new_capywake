import 'package:capywake/core/games/step_quest.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

StepQuestRound _start([PuzzleDifficulty d = PuzzleDifficulty.easy]) =>
    StepQuestRound.start(difficulty: d);

void main() {
  test("the walk lengthens with difficulty; easy is the poster's 20", () {
    expect(
      [
        for (final d in PuzzleDifficulty.values) _start(d).target,
      ],
      [20, 30, 40],
    );
    expect(_start(PuzzleDifficulty.hard).milestones, 8);
  });

  test('starts at the trailhead', () {
    final round = _start();
    expect([round.steps, round.stalls, round.milestonesDone], [0, 0, 0]);
    expect(round.level, 0);
    expect(round.lastOutcome, isNull);
    expect(round.isComplete, isFalse);
  });

  test('a batch of steps lands at once and clears a stall line', () {
    final round = _start().stall().walk(4);
    expect(round.steps, 4);
    expect(round.milestonesDone, 0);
    expect(round.lastOutcome, isNull);
    expect(round.stalls, 1);
    expect(round.walk(1).milestonesDone, 1);
  });

  test('a stall is a struggle and loses no step', () {
    final round = _start().walk(3).stall().stall();
    expect(round.steps, 3);
    expect(round.stalls, 2);
    expect(round.lastOutcome, StepQuestOutcome.stalled);
    expect(round.challenge.struggleCount, 2);
  });

  test('a batch past the goal stops at the goal', () {
    final round = _start().walk(19).walk(4);
    expect(round.steps, 20);
    expect(round.isComplete, isTrue);
    expect(round.level, 1);
  });

  test('nothing changes a finished walk, and empty batches add nothing', () {
    final done = _start().walk(20);
    expect(identical(done.walk(1), done), isTrue);
    expect(identical(done.stall(), done), isTrue);
    final fresh = _start();
    expect(identical(fresh.walk(0), fresh), isTrue);
  });

  test('a motion challenge whose fallback needs no motion', () {
    final challenge = _start().walk(7).challenge;
    expect(challenge.requiresMotion, isTrue);
    expect(challenge.motionFallback!.requiresMotion, isFalse);
    expect(challenge.completed, 7);
    expect(challenge.target, 20);
  });

  test('pauses fifteen seconds before stalling', () {
    expect(StepQuestRound.stallAfter, const Duration(seconds: 15));
  });
}
