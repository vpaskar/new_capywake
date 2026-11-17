import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';

/// Resolve a catalogue entry's l10n key to its display name. Product names,
/// but ARB keys rather than Dart literals: no hardcoded user-facing string.
String gameName(AppLocalizations l10n, GameEntry entry) {
  return switch (entry.nameKey) {
    'gameStepQuest' => l10n.gameStepQuest,
    'gameQrTreasureHunt' => l10n.gameQrTreasureHunt,
    'gameShakeDj' => l10n.gameShakeDj,
    'gameCatchTheCapy' => l10n.gameCatchTheCapy,
    'gameFindTheImpostor' => l10n.gameFindTheImpostor,
    'gameMemoryHideout' => l10n.gameMemoryHideout,
    'gameTiltMaze' => l10n.gameTiltMaze,
    'gameMorningSort' => l10n.gameMorningSort,
    'gameRhythmRescue' => l10n.gameRhythmRescue,
    'gameCapyRocket' => l10n.gameCapyRocket,
    _ => throw ArgumentError('Unmapped game name key: ${entry.nameKey}'),
  };
}

/// The headline over a game's win; the shared line for an unknown game.
String gameWinHeadline(AppLocalizations l10n, String gameId) {
  return switch (gameId) {
    'catch_the_capy' => l10n.gameWinHeadlineCatchTheCapy,
    'memory_hideout' => l10n.gameWinHeadlineMemoryHideout,
    'rhythm_rescue' => l10n.gameWinHeadlineRhythmRescue,
    'capy_rocket' => l10n.gameWinHeadlineCapyRocket,
    'morning_sort' => l10n.gameWinHeadlineMorningSort,
    'find_the_impostor' => l10n.gameWinHeadlineFindTheImpostor,
    'shake_dj' => l10n.gameWinHeadlineShakeDj,
    'tilt_maze' => l10n.gameWinHeadlineTiltMaze,
    'step_quest' => l10n.gameWinHeadlineStepQuest,
    'qr_treasure_hunt' => l10n.gameWinHeadlineQrTreasureHunt,
    _ => l10n.gameWinHeadline,
  };
}
