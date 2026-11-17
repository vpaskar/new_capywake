import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A pushed route's header: back control, brand lockup, centred title.
/// Lockup y 27.7-57.7, title y 59.6-97.4, chevron x 23.1-35.1.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({required this.title, super.key});

  final String title;

  /// 103.9 - 44.0 on the mockup: status bar to hero art.
  static const height = 59.9;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Inset past the back control on both sides, so a long title in
            // any of the ten locales stays centred and never overlaps it.
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: CapyToggle.minTapTarget + CapySpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Image.asset(
                      CapyArt.byId('mascot.sleeping').path,
                      height: CapyIconSize.wordmark,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: CapySpacing.sm),
                  Flexible(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              start: CapySpacing.sm,
              top: 0,
              bottom: 0,
              child: Center(child: _BackControl(ink: ink)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackControl extends StatelessWidget {
  const _BackControl({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    final label = MaterialLocalizations.of(context).backButtonTooltip;
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: IconButton(
          onPressed: () => context.pop(),
          tooltip: label,
          iconSize: CapyIconSize.md,
          color: ink,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
    );
  }
}
