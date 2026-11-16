import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/home/game_rail.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Explain why a game cannot be opened yet. Every tile taps somewhere,
/// rather than doing nothing or routing into a screen that does not exist.
Future<void> showGameUnavailableSheet(
  BuildContext context,
  GameEntry entry,
) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => _Sheet(entry: entry),
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.entry});

  final GameEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? CapyColors.darkInk
        : CapyColors.cocoa;
    final inkSoft = theme.brightness == Brightness.dark
        ? CapyColors.darkInkSoft
        : CapyColors.cocoaSoft;

    final name = gameName(l10n, entry);
    final body = switch (entry.availability) {
      GameAvailability.blocked => l10n.homeGameBlockedBody(name),
      _ => l10n.homeGameComingSoonBody(name),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(CapySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeGameComingSoonTitle,
              style: CapyType.title.copyWith(color: ink),
            ),
            const SizedBox(height: CapySpacing.sm),
            Text(body, style: CapyType.body.copyWith(color: inkSoft)),
          ],
        ),
      ),
    );
  }
}
