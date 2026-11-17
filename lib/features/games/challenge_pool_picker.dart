import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/game_names.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The wake pool: the puzzles plus every playable game, one switch each. The
/// last member left on cannot be switched off — the pool is never empty.
class ChallengePoolPicker extends StatelessWidget {
  const ChallengePoolPicker({
    required this.includePuzzles,
    required this.enabledGames,
    required this.onPuzzlesChanged,
    required this.onGameChanged,
    this.onTryGame,
    super.key,
  });

  final bool includePuzzles;
  final Set<String> enabledGames;
  final ValueChanged<bool> onPuzzlesChanged;
  final void Function(String gameId, {required bool enabled}) onGameChanged;

  /// Opens practice; `null` hides the action.
  final ValueChanged<String>? onTryGame;

  static const artSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final games = GameCatalogue.playable.toList();
    final enabledCount =
        (includePuzzles ? 1 : 0) +
        games.where((g) => enabledGames.contains(g.id)).length;
    final lastOn = enabledCount <= 1;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PoolRow(
          leading: Icon(
            Icons.extension_rounded,
            size: artSize,
            color: dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft,
          ),
          title: l10n.challengePuzzlesLabel,
          value: includePuzzles,
          onChanged: lastOn && includePuzzles ? null : onPuzzlesChanged,
        ),
        for (final game in games)
          _PoolRow(
            key: ValueKey('pool-${game.id}'),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(CapyRadius.sm),
              child: Image.asset(
                CapyArt.byId(game.tileAssetId).path,
                width: artSize,
                height: artSize,
                fit: BoxFit.cover,
              ),
            ),
            title: gameName(l10n, game),
            value: enabledGames.contains(game.id),
            onChanged: lastOn && enabledGames.contains(game.id)
                ? null
                : (on) => onGameChanged(game.id, enabled: on),
            onTry: onTryGame == null ? null : () => onTryGame!(game.id),
          ),
      ],
    );
  }
}

class _PoolRow extends StatelessWidget {
  const _PoolRow({
    required this.leading,
    required this.title,
    required this.value,
    required this.onChanged,
    this.onTry,
    super.key,
  });

  final Widget leading;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CapySpacing.xs),
      child: Row(
        children: [
          ExcludeSemantics(child: leading),
          const SizedBox(width: CapySpacing.md),
          Expanded(
            child: Text(title, style: CapyType.body.copyWith(color: ink)),
          ),
          if (onTry != null)
            TextButton(
              onPressed: onTry,
              style: TextButton.styleFrom(foregroundColor: ink),
              child: Text(
                l10n.gameTryAction,
                semanticsLabel: '${l10n.gameTryAction}, $title',
              ),
            ),
          CapyToggle(
            value: value,
            onChanged: onChanged,
            semanticLabel: title,
            trackSize: CapyToggle.alarmEditTrack,
          ),
        ],
      ),
    );
  }
}
