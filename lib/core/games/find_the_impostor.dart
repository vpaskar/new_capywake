import 'dart:math' as math;

import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:meta/meta.dart';

/// Poses that read alike from afar; the hard level pairs within a group.
enum CapyPoseGroup { rest, busy, joy, calm }

/// Find the Impostor's authored bank (content-bank ban lifted for this game,
/// owner, 2026-11-15): bundled poses with clearly different silhouettes.
enum CapyPose {
  asleepNightcap(CapyPoseGroup.rest),
  curledAsleep(CapyPoseGroup.rest),
  underBlanket(CapyPoseGroup.rest),
  onCushion(CapyPoseGroup.rest),
  hiking(CapyPoseGroup.busy),
  jogging(CapyPoseGroup.busy),
  liftingWeights(CapyPoseGroup.busy),
  holdingClock(CapyPoseGroup.busy),
  cheering(CapyPoseGroup.joy),
  partying(CapyPoseGroup.joy),
  superhero(CapyPoseGroup.joy),
  blushing(CapyPoseGroup.joy),
  holdingMug(CapyPoseGroup.calm),
  reading(CapyPoseGroup.calm),
  listening(CapyPoseGroup.calm),
  detective(CapyPoseGroup.calm);

  const CapyPose(this.group);

  final CapyPoseGroup group;
}

enum FindTheImpostorOutcome { found, missed }

/// Find the Impostor: one Capy does something different; tap it. A wrong tap
/// keeps the same set — it eases, it never gets harder.
@immutable
class FindTheImpostorRound {
  const FindTheImpostorRound._(
    this._seed,
    this._difficulty, {
    required this.cellCount,
    required this.common,
    required this.odd,
    required this.oddAt,
    required this.target,
    required this.found,
    required this.wrongTaps,
    required this.lastOutcome,
  });

  factory FindTheImpostorRound.start({
    required PuzzleDifficulty difficulty,
    required int seed,
  }) {
    final cells = cellsFor(difficulty);
    final (common, odd, oddAt) = _deal(difficulty, seed, cells, null);
    return FindTheImpostorRound._(
      PuzzleRound.advanceSeed(seed),
      difficulty,
      cellCount: cells,
      common: common,
      odd: odd,
      oddAt: oddAt,
      target: targetFor(difficulty),
      found: 0,
      wrongTaps: 0,
      lastOutcome: null,
    );
  }

  static int cellsFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => 4,
    PuzzleDifficulty.medium => 6,
    PuzzleDifficulty.hard => 8,
  };

  static int targetFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => 2,
    PuzzleDifficulty.medium => 3,
    PuzzleDifficulty.hard => 4,
  };

  /// How long the cards rest between two carousel steps; every card moves.
  static Duration swapEveryFor(PuzzleDifficulty difficulty) =>
      switch (difficulty) {
        PuzzleDifficulty.easy => const Duration(milliseconds: 3200),
        PuzzleDifficulty.medium => const Duration(milliseconds: 2600),
        PuzzleDifficulty.hard => const Duration(milliseconds: 2000),
      };

  /// Same-group pairs too alike at card size: only a party hat differs.
  static const excludedPairs = <(CapyPose, CapyPose)>{
    (CapyPose.cheering, CapyPose.partying),
  };

  static bool isExcluded(CapyPose a, CapyPose b) =>
      excludedPairs.contains((a, b)) || excludedPairs.contains((b, a));

  /// Every (common, odd) pair the round can deal at [difficulty].
  static List<(CapyPose, CapyPose)> pairsFor(PuzzleDifficulty difficulty) {
    final sameGroup = difficulty == PuzzleDifficulty.hard;
    return [
      for (final common in CapyPose.values)
        for (final odd in CapyPose.values)
          if (common != odd &&
              (common.group == odd.group) == sameGroup &&
              !isExcluded(common, odd))
            (common, odd),
    ];
  }

  static (CapyPose, CapyPose, int) _deal(
    PuzzleDifficulty difficulty,
    int seed,
    int cells,
    CapyPose? previousCommon,
  ) {
    final random = math.Random(seed);
    final pairs = [
      for (final pair in pairsFor(difficulty))
        if (pair.$1 != previousCommon) pair,
    ];
    final (common, odd) = pairs[random.nextInt(pairs.length)];
    return (common, odd, random.nextInt(cells));
  }

  final int _seed;
  final PuzzleDifficulty _difficulty;
  final int cellCount;

  /// The pose every cell shows but one.
  final CapyPose common;

  /// The different pose, at [oddAt].
  final CapyPose odd;
  final int oddAt;
  final int target;
  final int found;
  final int wrongTaps;

  /// The result of the last tap, `null` before the first.
  final FindTheImpostorOutcome? lastOutcome;

  bool get isComplete => found >= target;

  CapyPose poseAt(int cell) => cell == oddAt ? odd : common;

  GameChallenge get challenge => GameChallenge.touch(
    target: target,
    completed: found,
    struggleCount: wrongTaps,
  );

  /// A no-op once complete, so a late tap counts for nothing.
  FindTheImpostorRound tap(int cell) {
    RangeError.checkValueInInterval(cell, 0, cellCount - 1, 'cell');
    if (isComplete) return this;
    if (cell != oddAt) {
      return FindTheImpostorRound._(
        _seed,
        _difficulty,
        cellCount: cellCount,
        common: common,
        odd: odd,
        oddAt: oddAt,
        target: target,
        found: found,
        wrongTaps: wrongTaps + 1,
        lastOutcome: FindTheImpostorOutcome.missed,
      );
    }
    if (found + 1 >= target) {
      return FindTheImpostorRound._(
        _seed,
        _difficulty,
        cellCount: cellCount,
        common: common,
        odd: odd,
        oddAt: oddAt,
        target: target,
        found: found + 1,
        wrongTaps: wrongTaps,
        lastOutcome: FindTheImpostorOutcome.found,
      );
    }
    final (nextCommon, nextOdd, nextAt) = _deal(
      _difficulty,
      _seed,
      cellCount,
      common,
    );
    return FindTheImpostorRound._(
      PuzzleRound.advanceSeed(_seed),
      _difficulty,
      cellCount: cellCount,
      common: nextCommon,
      odd: nextOdd,
      oddAt: nextAt,
      target: target,
      found: found + 1,
      wrongTaps: wrongTaps,
      lastOutcome: FindTheImpostorOutcome.found,
    );
  }
}
