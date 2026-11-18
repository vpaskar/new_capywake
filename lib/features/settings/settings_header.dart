import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A pushed route's header: back control, brand lockup, centred title.
/// Lockup y 27.7-57.7, title y 59.6-97.4, chevron x 23.1-35.1.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    required this.title,
    this.height = defaultHeight,
    this.glyph,
    super.key,
  });

  final String title;
  final double height;

  /// Replaces the sleeping-capy lockup, e.g. the gamepad on Games.
  final Widget? glyph;

  /// 103.9 - 44.0 on `04_SETTINGS.png`: status bar to hero art.
  static const defaultHeight = 59.9;

  /// The tap floor. `01_SETTINGS_REFINED.png` draws 34.4, which cannot hold
  /// a 44 pt back control.
  static const compactHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;

    return SafeArea(
      bottom: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Centred on the back control's line, inset past it on both sides
            // so a long title in any locale never overlaps it.
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: CapyToggle.minTapTarget + CapySpacing.sm,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child:
                          glyph ??
                          Image.asset(
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
      onTap: () => context.pop(),
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
