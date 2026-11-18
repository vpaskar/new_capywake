import 'package:capywake/core/games/win_art.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/game_win_celebration.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shown for a moment after a game stopped the alarm. The alarm is already
/// silent when this appears; it only closes.
class RingingWinOverlay extends StatelessWidget {
  const RingingWinOverlay({
    required this.gameId,
    required this.onClose,
    this.art = WinArt.pose,
    super.key,
  });

  final String gameId;
  final WinArt art;
  final VoidCallback onClose;

  static const visibleFor = Duration(milliseconds: 2600);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CapySpacing.gutterWide),
          child: Column(
            children: [
              const Spacer(),
              GameWinPanel(
                gameId: gameId,
                art: art,
                subline: l10n.ringingGameWonTitle,
              ),
              const Spacer(),
              CapyButton(label: l10n.gameWinCloseAction, onPressed: onClose),
            ],
          ),
        ),
      ),
    );
  }
}
