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
