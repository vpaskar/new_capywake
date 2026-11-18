import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Writes the app-wide wake-puzzle singleton the ringing surface reads.
/// Each setter re-reads first, through the path the ringing controller watches.
class PuzzleSettingsController {
  const PuzzleSettingsController(this._ref);

  final Ref _ref;

  /// Turn one type on or off, refusing to empty the enabled set — the floor is
  /// held here too, so no UI path can crash the constructor.
  Future<void> setTypeEnabled(PuzzleType type, {required bool enabled}) {
    return _update((s) {
      final next = {...s.enabledTypes};
      if (enabled) {
        next.add(type);
      } else {
        next.remove(type);
      }
      if (next.isEmpty) return s;
      return s.copyWith(enabledTypes: next);
    });
  }

  /// Add or drop the puzzles from the wake pool; never empties it.
  Future<void> setPuzzlesIncluded({required bool included}) => _update(
    (s) => !included && !hasPlayableGame(s.enabledGames)
        ? s
        : s.copyWith(includePuzzles: included),
  );

  /// Add or drop one game from the wake pool; never empties it.
  Future<void> setGameEnabled(String gameId, {required bool enabled}) {
    return _update((s) {
      final next = {...s.enabledGames};
      if (enabled) {
        next.add(gameId);
      } else {
        next.remove(gameId);
      }
      if (!hasPlayableGame(next) && !s.includePuzzles) return s;
      return s.copyWith(enabledGames: next);
    });
  }

  Future<void> setTaskCount(int count) =>
      _update((s) => s.copyWith(taskCount: count));

  Future<void> setDifficulty(PuzzleDifficulty difficulty) =>
      _update((s) => s.copyWith(difficulty: difficulty));

  Future<void> setToleratedWrongAnswers(int tolerated) =>
      _update((s) => s.copyWith(toleratedWrongAnswers: tolerated));

  Future<void> setEscapeStrictness(PuzzleEscapeStrictness strictness) =>
      _update((s) => s.copyWith(escapeStrictness: strictness));

  Future<void> _update(PuzzleSettings Function(PuzzleSettings) change) async {
    final repository = _ref.read(capywakeRepositoryProvider);
    final current = await repository.getPuzzleSettings();
    await repository.savePuzzleSettings(change(current));
  }
}

final puzzleSettingsControllerProvider = Provider<PuzzleSettingsController>(
  PuzzleSettingsController.new,
);

/// Whether [gameIds] holds a game that can actually ring: a coming-soon id
/// must not be the pool's last member.
bool hasPlayableGame(Set<String> gameIds) =>
    gameIds.any((id) => GameCatalogue.byId(id)?.isPlayable ?? false);

/// The app-wide puzzle settings every puzzle screen renders from.
PuzzleSettings watchPuzzleSettings(WidgetRef ref) =>
    ref.watch(puzzleSettingsStreamProvider).value ?? PuzzleSettings.defaults();
