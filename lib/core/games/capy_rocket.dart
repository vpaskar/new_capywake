import 'dart:math' as math;

import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:meta/meta.dart';

/// A logical side, so a right-to-left layout mirrors the cue with it.
enum RocketSide { start, end }

enum CapyRocketOutcome { boosted, wobbled }

/// Capy Rocket: swipe the way the arrow points to fly Capy up. A swipe the
/// other way wobbles the rocket and counts as a struggle; no climb is lost.
@immutable
class CapyRocketRound {
  const CapyRocketRound._(
    this._seed, {
    required this.target,
    required this.boosts,
    required this.wobbles,
    required this.cue,
    required this.lastOutcome,
  });

  factory CapyRocketRound.start({
    required PuzzleDifficulty difficulty,
    required int seed,
  }) => CapyRocketRound._(
    PuzzleRound.advanceSeed(seed),
    target: targetFor(difficulty),
    boosts: 0,
    wobbles: 0,
    cue: _sideFrom(seed),
    lastOutcome: null,
  );

  static int targetFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => 6,
    PuzzleDifficulty.medium => 8,
    PuzzleDifficulty.hard => 10,
  };

  /// How long one boost's climb takes: the difficulty is how fast it flies.
  static Duration climbFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => const Duration(milliseconds: 700),
    PuzzleDifficulty.medium => const Duration(milliseconds: 550),
    PuzzleDifficulty.hard => const Duration(milliseconds: 420),
  };

  static RocketSide _sideFrom(int seed) =>
      math.Random(seed).nextBool() ? RocketSide.end : RocketSide.start;

  final int _seed;
  final int target;
  final int boosts;
  final int wobbles;

  /// The side the arrow points to: the swipe that boosts.
  final RocketSide cue;

  /// The result of the last swipe, `null` before the first.
  final CapyRocketOutcome? lastOutcome;

  bool get isComplete => boosts >= target;

  /// Share of the climb done, `0` at the start and `1` once complete.
  double get altitude => boosts / target;

  GameChallenge get challenge => GameChallenge.touch(
    target: target,
    completed: boosts,
    struggleCount: wobbles,
  );

  /// A no-op once complete, so a late swipe counts for nothing.
  CapyRocketRound boost(RocketSide side) {
    if (isComplete) return this;
    if (side != cue) {
      return CapyRocketRound._(
        _seed,
        target: target,
        boosts: boosts,
        wobbles: wobbles + 1,
        cue: cue,
        lastOutcome: CapyRocketOutcome.wobbled,
      );
    }
    return CapyRocketRound._(
      PuzzleRound.advanceSeed(_seed),
      target: target,
      boosts: boosts + 1,
      wobbles: wobbles,
      cue: _sideFrom(_seed),
      lastOutcome: CapyRocketOutcome.boosted,
    );
  }
}
