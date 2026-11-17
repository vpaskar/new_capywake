import 'dart:math' as math;

import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:meta/meta.dart';

/// Catch the Capy: tap the capybara as it wanders the meadow. A tap on the
/// meadow is a miss — the game's struggle.
@immutable
class CatchTheCapyRound {
  const CatchTheCapyRound._(
    this._seed, {
    required this.target,
    required this.caught,
    required this.misses,
    required this.spot,
  });

  factory CatchTheCapyRound.start({
    required PuzzleDifficulty difficulty,
    required int seed,
  }) => CatchTheCapyRound._(
    PuzzleRound.advanceSeed(seed),
    target: targetFor(difficulty),
    caught: 0,
    misses: 0,
    spot: math.Random(seed).nextInt(spotCount),
  );

  static const columns = 3;
  static const rows = 3;
  static const int spotCount = columns * rows;

  static int targetFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => 3,
    PuzzleDifficulty.medium => 5,
    PuzzleDifficulty.hard => 7,
  };

  /// How long one run takes: the difficulty is how fast the capybara is.
  static Duration runFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => const Duration(milliseconds: 1300),
    PuzzleDifficulty.medium => const Duration(milliseconds: 1000),
    PuzzleDifficulty.hard => const Duration(milliseconds: 750),
  };

  final int _seed;
  final int target;
  final int caught;
  final int misses;

  /// Index into the [columns] × [rows] grid, row-major.
  final int spot;

  int get column => spot % columns;
  int get row => spot ~/ columns;

  bool get isComplete => caught >= target;

  GameChallenge get challenge => GameChallenge.touch(
    target: target,
    completed: caught,
    struggleCount: misses,
  );

  /// The capybara is caught and moves to a different spot. A no-op once the
  /// goal is reached, so a double tap cannot count twice.
  CatchTheCapyRound catchCapy() {
    if (isComplete) return this;
    final draw = math.Random(_seed).nextInt(spotCount - 1);
    return CatchTheCapyRound._(
      PuzzleRound.advanceSeed(_seed),
      target: target,
      caught: caught + 1,
      misses: misses,
      spot: draw >= spot ? draw + 1 : draw,
    );
  }

  /// The capybara runs to a different spot on its own; nothing is counted.
  CatchTheCapyRound wander() {
    if (isComplete) return this;
    final draw = math.Random(_seed).nextInt(spotCount - 1);
    return CatchTheCapyRound._(
      PuzzleRound.advanceSeed(_seed),
      target: target,
      caught: caught,
      misses: misses,
      spot: draw >= spot ? draw + 1 : draw,
    );
  }

  /// The capybara bolts from a tap at ([column], [row]) to one of the spots
  /// farthest from it; ties are broken by the seed.
  CatchTheCapyRound fleeFrom({required int column, required int row}) {
    if (isComplete) return this;
    int distance(int s) {
      final dc = s % columns - column;
      final dr = s ~/ columns - row;
      return dc * dc + dr * dr;
    }

    final candidates = [
      for (var s = 0; s < spotCount; s++)
        if (s != spot) s,
    ];
    final farthest = candidates.map(distance).reduce(math.max);
    final best = [
      for (final s in candidates)
        if (distance(s) == farthest) s,
    ];
    return CatchTheCapyRound._(
      PuzzleRound.advanceSeed(_seed),
      target: target,
      caught: caught,
      misses: misses,
      spot: best[math.Random(_seed).nextInt(best.length)],
    );
  }

  CatchTheCapyRound miss() {
    if (isComplete) return this;
    return CatchTheCapyRound._(
      _seed,
      target: target,
      caught: caught,
      misses: misses + 1,
      spot: spot,
    );
  }
}
