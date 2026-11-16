import 'package:capywake/app/router.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Sleeping mascot, wordmark and the Settings gear, on all three tabs.
/// [height] is the 59.9 pt band between the status bar and the hero art.
class CapyHeader extends StatelessWidget {
  const CapyHeader({super.key});

  static const height = 59.9;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: CapySpacing.lg,
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Image.asset(
                  CapyArt.byId('mascot.sleeping').path,
                  height: CapyIconSize.wordmark + CapySpacing.sm,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: CapySpacing.sm),
              Semantics(
                header: true,
                label: 'CapyWake',
                child: ExcludeSemantics(
                  child: Image.asset(
                    CapyArt.wordmark.path,
                    height: CapyIconSize.wordmark,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => context.push(Routes.settings),
                tooltip: l10n.navSettingsOpenLabel,
                icon: const Icon(
                  Icons.settings_rounded,
                  color: CapyColors.cocoa,
                  size: CapyIconSize.md,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
