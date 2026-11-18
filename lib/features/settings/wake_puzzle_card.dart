import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/settings/settings_group.dart';
import 'package:flutter/material.dart';

/// Settings' entry to the wake puzzle, against `01_SETTINGS_REFINED.png`:
/// glyph, title, summary, up to [maxTiles] of the games switched on.
class WakePuzzleCard extends StatelessWidget {
  const WakePuzzleCard({
    required this.title,
    required this.summary,
    required this.enabledGames,
    required this.onTap,
    super.key,
  });

  final String title;
  final String summary;
  final Set<String> enabledGames;
  final VoidCallback onTap;

  static const maxTiles = 3;
  static const tileSize = 32.0;
  static const glyphSize = 34.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final tiles = GameCatalogue.playable
        .where((g) => enabledGames.contains(g.id))
        .take(maxTiles)
        .toList();

    return Semantics(
      button: true,
      label: '$title, $summary',
      onTap: onTap,
      child: ExcludeSemantics(
        child: SettingsCardSurface(
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: CapyToggle.minTapTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CapySpacing.md,
                  vertical: CapySpacing.sm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.extension_rounded,
                      size: glyphSize,
                      color: CapyColors.accent,
                    ),
                    const SizedBox(width: CapySpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            summary,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final game in tiles)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: CapySpacing.xs,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(CapyRadius.sm),
                          child: Image.asset(
                            CapyArt.byId(game.tileAssetId).path,
                            width: tileSize,
                            height: tileSize,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(width: CapySpacing.xs),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: CapyIconSize.md,
                      color: inkSoft,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
