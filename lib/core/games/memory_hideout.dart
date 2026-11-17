import 'dart:math' as math;

import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:meta/meta.dart';

enum MemoryHideoutPhase {
  /// Capy is shown behind one bush until the user says they are ready.
  revealing,

  /// Capy is hidden and the bushes swap places while the user watches.
  shuffling,

  /// Capy is hidden; the user picks a bush.
  guessing,
}

enum MemoryHideoutOutcome { found, missed }

/// Memory Hideout: remember which bush Capy hid behind. A wrong pick shows the
/// same bush again — the game eases, it never gets harder for struggling.
@immutable
class MemoryHideoutRound {
  const MemoryHideoutRound._(
    this._seed,
    this._difficulty, {
    required this.bushCount,
    required this.target,
    required this.found,
    required this.wrongPicks,
    required this.hiddenAt,
    required this.phase,
    required this.lastOutcome,
    this.swaps = const [],
  });

  factory MemoryHideoutRound.start({
    required PuzzleDifficulty difficulty,
    required int seed,
  }) {
    final bushes = bushCountFor(difficulty);
    return MemoryHideoutRound._(
      PuzzleRound.advanceSeed(seed),
      difficulty,
      bushCount: bushes,
      target: targetFor(difficulty),
      found: 0,
      wrongPicks: 0,
      hiddenAt: math.Random(seed).nextInt(bushes),
      phase: MemoryHideoutPhase.revealing,
      lastOutcome: null,
    );
  }

  static int bushCountFor(PuzzleDifficulty difficulty) =>
      difficulty == PuzzleDifficulty.hard ? 4 : 3;

  static int swapCountFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => 1,
    PuzzleDifficulty.medium => 2,
    PuzzleDifficulty.hard => 3,
  };

  static int targetFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => 2,
    PuzzleDifficulty.medium => 3,
    PuzzleDifficulty.hard => 4,
  };

  final int bushCount;
  final int target;
  final int found;
  final int wrongPicks;
  final int hiddenAt;
  final MemoryHideoutPhase phase;

  /// The result of the previous pick, `null` before the first.
  final MemoryHideoutOutcome? lastOutcome;

  /// The position swaps to show while shuffling, in order; [hiddenAt] is
  /// already where Capy ends up after them.
  final List<(int, int)> swaps;
  final int _seed;
  final PuzzleDifficulty _difficulty;

  bool get isComplete => found >= target;

  GameChallenge get challenge => GameChallenge.touch(
    target: target,
    completed: found,
    struggleCount: wrongPicks,
  );

  /// Hide Capy. With [shuffle], the bushes swap places first; without it
  /// (reduce-motion, screen reader) the user guesses straight away.
  MemoryHideoutRound ready({bool shuffle = false}) {
    if (isComplete || phase != MemoryHideoutPhase.revealing) return this;
    if (!shuffle) return _copy(phase: MemoryHideoutPhase.guessing);

    final random = math.Random(_seed);
    var hidden = hiddenAt;
    final swaps = <(int, int)>[];
    for (var i = 0; i < swapCountFor(_difficulty); i++) {
      final a = random.nextInt(bushCount);
      final b = (a + 1 + random.nextInt(bushCount - 1)) % bushCount;
      swaps.add((a, b));
      if (hidden == a) {
        hidden = b;
      } else if (hidden == b) {
        hidden = a;
      }
    }
    return _copy(
      phase: MemoryHideoutPhase.shuffling,
      hiddenAt: hidden,
      swaps: swaps,
      seed: PuzzleRound.advanceSeed(_seed),
    );
  }

  /// The swaps have been shown; the user may pick.
  MemoryHideoutRound finishShuffle() {
    if (phase != MemoryHideoutPhase.shuffling) return this;
    return _copy(phase: MemoryHideoutPhase.guessing);
  }

  /// A no-op unless guessing and unfinished, so a double tap counts once.
  MemoryHideoutRound pick(int bush) {
    RangeError.checkValueInInterval(bush, 0, bushCount - 1, 'bush');
    if (isComplete || phase != MemoryHideoutPhase.guessing) return this;
    if (bush != hiddenAt) {
      return _copy(
        wrongPicks: wrongPicks + 1,
        phase: MemoryHideoutPhase.revealing,
        lastOutcome: MemoryHideoutOutcome.missed,
      );
    }
    return _copy(
      found: found + 1,
      hiddenAt: math.Random(_seed).nextInt(bushCount),
      phase: MemoryHideoutPhase.revealing,
      lastOutcome: MemoryHideoutOutcome.found,
      seed: PuzzleRound.advanceSeed(_seed),
    );
  }

  MemoryHideoutRound _copy({
    required MemoryHideoutPhase phase,
    int? found,
    int? wrongPicks,
    int? hiddenAt,
    MemoryHideoutOutcome? lastOutcome,
    List<(int, int)> swaps = const [],
    int? seed,
  }) => MemoryHideoutRound._(
    seed ?? _seed,
    _difficulty,
    swaps: swaps,
    bushCount: bushCount,
    target: target,
    found: found ?? this.found,
    wrongPicks: wrongPicks ?? this.wrongPicks,
    hiddenAt: hiddenAt ?? this.hiddenAt,
    phase: phase,
    lastOutcome: lastOutcome ?? this.lastOutcome,
  );
}
