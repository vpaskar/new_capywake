import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// The rounded surface card from `01_HOME.png`. Its hairline strokes inside
/// the box, so the detected edge sits ~1 pt inboard of the gutter.
class CapyCard extends StatelessWidget {
  const CapyCard({
    required this.child,
    this.padding = const EdgeInsetsDirectional.symmetric(
      horizontal: CapySpacing.lg,
      vertical: CapySpacing.md,
    ),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? CapyColors.darkSurface : CapyColors.surface,
        borderRadius: BorderRadius.circular(CapyRadius.lg),
        border: Border.all(
          color: dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CapyRadius.lg),
        child: decorated,
      ),
    );
  }
}
