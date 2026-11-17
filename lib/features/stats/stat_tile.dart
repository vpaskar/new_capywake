import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// A heading with one measured value, or the absence of one. A null [value]
/// renders the em dash: a tile cannot be handed a number that does not exist.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? value;

  static const double iconSize = CapyIconSize.md;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final shown = value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: iconSize, color: CapyColors.accentDeep),
            const SizedBox(width: CapySpacing.sm),
            Flexible(
              child: Text(
                label,
                style: CapyType.section.copyWith(color: ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: CapySpacing.xs),
        // An em dash read aloud is punctuation, not an answer.
        Semantics(
          label: shown == null ? l10n.statsNoValueSemanticLabel : null,
          excludeSemantics: shown == null,
          child: Text(
            shown ?? l10n.statsNoValue,
            style: CapyType.title.copyWith(
              color: shown == null ? inkSoft : ink,
            ),
          ),
        ),
      ],
    );
  }
}
