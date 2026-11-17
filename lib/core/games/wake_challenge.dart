import 'dart:math' as math;

import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:meta/meta.dart';

/// What one ring asks of the user: the generated puzzles, or one game.
@immutable
sealed class WakeChallenge {
  const WakeChallenge();
}

/// The generated puzzle rotation, as before games existed.
final class PuzzleWakeChallenge extends WakeChallenge {
  const PuzzleWakeChallenge();

  @override
  bool operator ==(Object other) => other is PuzzleWakeChallenge;

  @override
  int get hashCode => (PuzzleWakeChallenge).hashCode;
}

/// One game from the catalogue, by id.
final class GameWakeChallenge extends WakeChallenge {
  const GameWakeChallenge(this.gameId);

  final String gameId;

  @override
  bool operator ==(Object other) =>
      other is GameWakeChallenge && other.gameId == gameId;

  @override
  int get hashCode => gameId.hashCode;
}

/// Picks one ring's challenge from the wake pool, uniformly and seeded.
abstract final class WakeChallengeSelector {
  /// Puzzles first when included, then games in catalogue order.
  static List<WakeChallenge> poolFor(
    PuzzleSettings settings, {
    required bool Function(String gameId) isLaunchable,
  }) => [
    if (settings.includePuzzles) const PuzzleWakeChallenge(),
    for (final id in GameCatalogue.ids)
      if (settings.enabledGames.contains(id) && isLaunchable(id))
        GameWakeChallenge(id),
  ];

  /// An empty pool falls back to puzzles: a ringing alarm always has
  /// something to solve, and `enabledTypes` is never empty.
  static WakeChallenge pick({
    required PuzzleSettings settings,
    required int seed,
    required bool Function(String gameId) isLaunchable,
  }) {
    final pool = poolFor(settings, isLaunchable: isLaunchable);
    if (pool.isEmpty) return const PuzzleWakeChallenge();
    return pool[math.Random(seed).nextInt(pool.length)];
  }
}
