import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// One grouped card on Settings: a tinted header band, then rows split by
/// hairline dividers. Card x 9.70-383.32, band 28.2, radius ~16, gap 13.9.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    required this.icon,
    required this.title,
    required this.rows,
    super.key,
  });

  final IconData icon;
  final String title;
  final List<Widget> rows;

  static const bandHeight = 28.2;
  static const radius = 16.0;
  static const gap = 13.9;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final band = dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt;
    final surface = dark ? CapyColors.darkSurface : CapyColors.surface;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: CapyColors.cocoa.withValues(alpha: dark ? 0.30 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // The sheet the rows are printed on; an InkWell row needs it.
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Container(
                color: band,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: CapySpacing.md,
                ),
                constraints: const BoxConstraints(minHeight: bandHeight),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(icon, size: CapyIconSize.md, color: ink),
                    ),
                    const SizedBox(width: CapySpacing.sm),
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SettingsDivider(),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// The hairline between two rows inside a group.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: CapySpacing.md),
      child: Divider(
        height: 1,
        thickness: 1,
        color: (dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft)
            .withValues(alpha: 0.22),
      ),
    );
  }
}
