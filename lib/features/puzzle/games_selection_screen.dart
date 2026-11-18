import 'dart:async';

import 'package:capywake/app/router.dart';
import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/game_names.dart';
import 'package:capywake/features/games/game_setup_offer.dart';
import 'package:capywake/features/puzzle/pool_switch_row.dart';
import 'package:capywake/features/puzzle/puzzle_settings_controller.dart';
import 'package:capywake/features/puzzle/puzzle_subpage.dart';
import 'package:capywake/features/settings/settings_group.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Every playable game in catalogue order, one switch each, against
/// `03_GAMES_SELECTION.png`.
class GamesSelectionScreen extends ConsumerWidget {
  const GamesSelectionScreen({super.key});

  static const tileSize = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = watchPuzzleSettings(ref);
    final controller = ref.read(puzzleSettingsControllerProvider);
    final games = GameCatalogue.playable.toList();
    final playableOn = games.where((g) => settings.enabledGames.contains(g.id));
    final lastGameStanding = !settings.includePuzzles && playableOn.length == 1;

    return PuzzleSubpage(
      title: l10n.challengeGamesTitle,
      glyph: const PuzzleHeaderGlyph(Icons.sports_esports_outlined),
      children: [
        PuzzleHelpText(l10n.challengeGamesHelp),
        const SizedBox(height: CapySpacing.md),
        CapyCard(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: CapySpacing.sm,
            vertical: CapySpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < games.length; i++) ...[
                if (i > 0) const SettingsDivider(),
                PoolSwitchRow(
                  key: ValueKey('pool-${games[i].id}'),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(CapyRadius.sm),
                    child: Image.asset(
                      CapyArt.byId(games[i].tileAssetId).path,
                      width: tileSize,
                      height: tileSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: gameName(l10n, games[i]),
                  value: settings.enabledGames.contains(games[i].id),
                  locked:
                      lastGameStanding &&
                      settings.enabledGames.contains(games[i].id),
                  onChanged: (on) {
                    final id = games[i].id;
                    unawaited(controller.setGameEnabled(id, enabled: on));
                    unawaited(
                      offerGameSetup(context, ref, gameId: id, enabled: on),
                    );
                  },
                  onTry: () => context.push(Routes.gamePractice(games[i].id)),
                  unlockLabel: l10n.puzzleSettingsTypesLabel,
                  onUnlock: () => context.push(Routes.settingsPuzzleTypes),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
