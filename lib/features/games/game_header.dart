import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// A game's name pill, its instruction, and progress as `3 / 5` plus pips.
class GameHeader extends StatelessWidget {
  const GameHeader({
    required this.title,
    required this.instruction,
    required this.done,
    required this.total,
    super.key,
  });

  final String title;
  final String instruction;
  final int done;
  final int total;

  static const pipSize = 14.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final pill = dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: pill,
            borderRadius: BorderRadius.circular(CapyRadius.pill),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: CapySpacing.lg,
              vertical: CapySpacing.xs,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: CapyType.section.copyWith(color: ink),
            ),
          ),
        ),
        const SizedBox(height: CapySpacing.sm),
        Text(
          instruction,
          textAlign: TextAlign.center,
          style: CapyType.body.copyWith(color: ink),
        ),
        const SizedBox(height: CapySpacing.sm),
        Semantics(
          label: l10n.gameProgressSemantics(done, total),
          excludeSemantics: true,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: CapySpacing.xs,
            children: [
              Text(
                l10n.gameProgressValue(done, total),
                style: CapyType.label.copyWith(color: ink),
              ),
              const SizedBox(width: CapySpacing.xs),
              for (var i = 0; i < total; i++)
                Container(
                  width: pipSize,
                  height: pipSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < done ? CapyColors.accentDeep : pill,
                    border: Border.all(color: inkSoft),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
