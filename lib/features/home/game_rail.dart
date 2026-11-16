import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/home/game_unavailable_sheet.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The four tiles from `01_HOME.png`, from [GameCatalogue]. No tile is a
/// dead tap: an unavailable one opens a sheet saying so.
class GameRail extends StatelessWidget {
  const GameRail({super.key});

  /// Crop of `01_HOME.png`: tiles end 559.7pt, labels run 568.5 - 593.9.
  static const tileSize = 74.0;

  /// Two lines at the label scale, plus slack for a descender.
  static const labelHeight = 36.0;
  static const double totalHeight = tileSize + CapySpacing.sm + labelHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: totalHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: CapySpacing.gutter,
        ),
        itemCount: GameCatalogue.entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: CapySpacing.md),
        itemBuilder: (context, i) => _Tile(entry: GameCatalogue.entries[i]),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.entry});

  final GameEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = gameName(l10n, entry);
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? CapyColors.darkInk
        : CapyColors.cocoa;

    final label = entry.isPlayable
        ? name
        : '$name, ${l10n.homeGameUnavailableBadge}';

    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: () => showGameUnavailableSheet(context, entry),
          borderRadius: BorderRadius.circular(CapyRadius.lg),
          child: SizedBox(
            width: GameRail.tileSize,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TileArt(entry: entry),
                const SizedBox(height: CapySpacing.sm),
                SizedBox(
                  height: GameRail.labelHeight,
                  child: Text(
                    name,
                    style: CapyType.label.copyWith(color: ink),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TileArt extends StatelessWidget {
  const _TileArt({required this.entry});

  final GameEntry entry;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CapyRadius.lg);

    // foregroundDecoration, not a Border: a Border insets the child and
    // would render the featured tile 4pt smaller.
    return Container(
      width: GameRail.tileSize,
      height: GameRail.tileSize,
      foregroundDecoration: entry.id == featuredGameId
          ? BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: CapyColors.cocoa, width: 2),
            )
          : null,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              CapyArt.byId(entry.tileAssetId).path,
              fit: BoxFit.cover,
            ),
            if (!entry.isPlayable) const _SoonBadge(),
          ],
        ),
      ),
    );
  }
}

/// Marks an unavailable tile for a sighted user. `CLAUDE.md` requires a
/// `comingSoon` card be visibly marked, not only announced to a screen reader.
class _SoonBadge extends StatelessWidget {
  const _SoonBadge();

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      bottom: CapySpacing.xs,
      start: CapySpacing.xs,
      end: CapySpacing.xs,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: CapyColors.cocoa.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(CapyRadius.sm),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 2),
            child: Text(
              AppLocalizations.of(context).homeGameUnavailableBadge,
              textAlign: TextAlign.center,
              style: CapyType.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The tile `01_HOME.png` rings. Drawn in `cocoa`, not its green: `success`
/// is 2.68:1 on cream and F1 forbids a lone boundary channel.
const featuredGameId = 'step_quest';

/// Resolve a catalogue entry's l10n key to its display name. Product names,
/// but ARB keys rather than Dart literals: no hardcoded user-facing string.
String gameName(AppLocalizations l10n, GameEntry entry) {
  return switch (entry.nameKey) {
    'gameStepQuest' => l10n.gameStepQuest,
    'gameShakeDj' => l10n.gameShakeDj,
    'gameCatchTheCapy' => l10n.gameCatchTheCapy,
    'gameFindTheImpostor' => l10n.gameFindTheImpostor,
    _ => throw ArgumentError('Unmapped game name key: ${entry.nameKey}'),
  };
}
