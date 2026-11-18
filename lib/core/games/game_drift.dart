import 'dart:math' as math;

import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:meta/meta.dart';

/// Which two cards of a drifting grid swap next. Seeded, so a replay and a
/// capture drift the same way.
@immutable
class GameDrift {
  const GameDrift(this._seed);

  final int _seed;

  /// Two distinct entries of [movable] to swap, and the drift that follows;
  /// `null` when fewer than two cards may move.
  (int, int, GameDrift)? next(List<int> movable) {
    if (movable.length < 2) return null;
    final random = math.Random(_seed);
    final a = random.nextInt(movable.length);
    final b = (a + 1 + random.nextInt(movable.length - 1)) % movable.length;
    return (movable[a], movable[b], GameDrift(PuzzleRound.advanceSeed(_seed)));
  }
}
