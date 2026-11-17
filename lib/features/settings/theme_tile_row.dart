import 'package:capywake/core/models/theme_mode_preference.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/settings/settings_rows.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The three-tile theme selector, x 180.6-366.2, y 384.7-429.5. The mockup's
/// sunset tile is System, there being no sunset theme (G12).
class ThemeTileRow extends StatelessWidget {
  const ThemeTileRow({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ThemeModePreference value;
  final ValueChanged<ThemeModePreference> onChanged;

  static const tileWidth = 57.0;
  static const tileHeight = 44.8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: SettingsRowMetrics.minHeight,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: SettingsRowMetrics.horizontalPadding,
          vertical: SettingsRowMetrics.verticalPadding,
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.wb_sunny_outlined,
                size: CapyIconSize.md,
                color: inkSoft,
              ),
            ),
            const SizedBox(width: CapySpacing.md),
            Expanded(
              child: Text(
                l10n.settingsThemeLabel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: CapySpacing.sm),
            for (final mode in ThemeModePreference.values) ...[
              if (mode != ThemeModePreference.values.first)
                const SizedBox(width: CapySpacing.xs),
              _ThemeTile(
                mode: mode,
                label: _label(l10n, mode),
                selected: value == mode,
                onTap: () => onChanged(mode),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _label(AppLocalizations l10n, ThemeModePreference mode) {
    switch (mode) {
      case ThemeModePreference.system:
        return l10n.settingsThemeSystem;
      case ThemeModePreference.light:
        return l10n.settingsThemeLight;
      case ThemeModePreference.dark:
        return l10n.settingsThemeDark;
    }
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeModePreference mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: ThemeTileRow.tileWidth,
            height: SettingsRowMetrics.minHeight,
            child: Center(
              child: Container(
                width: ThemeTileRow.tileWidth,
                height: ThemeTileRow.tileHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(CapyRadius.sm),
                  border: Border.all(
                    color: selected
                        ? CapyColors.accentDeep
                        : CapyColors.cocoaSoft.withValues(alpha: 0.35),
                    width: selected ? 2.4 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(CapyRadius.sm - 1),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _Swatch(mode: mode),
                      // Border, check and semantics carry selection, not
                      // colour alone.
                      if (selected)
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: CapyIconSize.sm,
                              color: CapyColors.accentDeep,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.mode});

  final ThemeModePreference mode;

  @override
  Widget build(BuildContext context) {
    final art = switch (mode) {
      ThemeModePreference.system => CapyArt.themeSystem,
      ThemeModePreference.light => CapyArt.themeLight,
      ThemeModePreference.dark => CapyArt.themeDark,
    };
    return Image.asset(art.path, fit: BoxFit.cover);
  }
}
