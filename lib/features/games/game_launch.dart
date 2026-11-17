import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:flutter/foundation.dart';

/// Everything a host hands a game view: the ring's seed, the resolved
/// difficulty, and the contract's callbacks.
@immutable
class GameLaunch {
  const GameLaunch({
    required this.seed,
    required this.difficulty,
    required this.onProgress,
    required this.onCompleted,
    required this.reduceMotion,
  });

  final int seed;
  final PuzzleDifficulty difficulty;
  final ValueChanged<GameChallenge> onProgress;
  final VoidCallback onCompleted;
  final bool reduceMotion;
}
