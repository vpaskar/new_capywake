import 'package:capywake/design/art.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// What a fresh install shows. The default state of the list, not a fallback
/// for a failed read — `CLAUDE.md`, content integrity.
class AlarmsEmptyState extends StatelessWidget {
  const AlarmsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CapySpacing.xl,
        vertical: CapySpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              CapyArt.byId('thumb.sleeping').path,
              height: _artHeight,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: CapySpacing.lg),
          Text(
            l10n.alarmsEmptyTitle,
            textAlign: TextAlign.center,
            style: CapyType.section.copyWith(color: ink),
          ),
          const SizedBox(height: CapySpacing.sm),
          Text(
            l10n.alarmsEmptyBody,
            textAlign: TextAlign.center,
            style: CapyType.body.copyWith(color: inkSoft),
          ),
        ],
      ),
    );
  }

  static const _artHeight = 96.0;
}
