import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// Shared geometry for every Settings row. Rows size to content above the
/// tap floor: the mockup's ~37.5-39 pt is a division, not a measurement.
abstract final class SettingsRowMetrics {
  static const double minHeight = CapyToggle.minTapTarget;
  static const double horizontalPadding = CapySpacing.md;

  /// The mockup's row is ~41 pt, under the 44 pt tap floor, so any padding
  /// above the floor only pushes every group below it down.
  static const double verticalPadding = CapySpacing.xs;
}

/// A row's leading icon, title and optional second line.
class _RowBody extends StatelessWidget {
  const _RowBody({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Row(
      children: [
        ExcludeSemantics(
          child: Icon(icon, size: CapyIconSize.md, color: inkSoft),
        ),
        const SizedBox(width: CapySpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // A title is never truncated and never overflows: it wraps.
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: inkSoft),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A row that opens something: a value and a chevron. [onTap] is
/// non-nullable, so a chevron that opens nothing cannot be written.
class SettingsChevronRow extends StatelessWidget {
  const SettingsChevronRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? value;
  final String? subtitle;
  final VoidCallback onTap;

  /// The most of the row a value may take before it ellipsizes.
  static const maxValueFraction = 0.4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Semantics(
      button: true,
      label: [title, if (value != null) value!].join(', '),
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: SettingsRowMetrics.minHeight,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SettingsRowMetrics.horizontalPadding,
                vertical: SettingsRowMetrics.verticalPadding,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    Expanded(
                      child: _RowBody(
                        icon: icon,
                        title: title,
                        subtitle: subtitle,
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(width: CapySpacing.sm),
                      // Capped and laid out before the title, so the value
                      // yields (ellipsis) and can never be painted over.
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * maxValueFraction,
                        ),
                        child: Text(
                          value!,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: inkSoft,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: CapySpacing.xs),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: CapyIconSize.md,
                      color: inkSoft,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row carrying a switch the user may flip.
class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // One node, so a screen reader reads the row and its switch together
    // rather than announcing a loose label beside an unlabelled control.
    return MergeSemantics(
      child: ConstrainedBox(
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
              Expanded(
                child: ExcludeSemantics(
                  child: _RowBody(
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                  ),
                ),
              ),
              const SizedBox(width: CapySpacing.sm),
              CapyToggle(
                value: value,
                onChanged: onChanged,
                semanticLabel: subtitle == null ? title : '$title. $subtitle',
                trackSize: CapyToggle.settingsTrack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reports a state the app does not own. It grants and never revokes: a
/// switch here would stop every alarm from ringing, from inside Settings.
class SettingsStatusRow extends StatelessWidget {
  const SettingsStatusRow({
    required this.icon,
    required this.title,
    required this.statusLabel,
    required this.satisfied,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// The current state, read plainly. Never a promise that an alarm rings:
  /// that copy comes from `ReliabilityCopyService`.
  final String statusLabel;
  final bool satisfied;

  /// Shown only while [satisfied] is false — nothing to grant otherwise.
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Semantics(
      button: !satisfied,
      label: '$title, $statusLabel',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: satisfied ? null : onAction,
          child: ConstrainedBox(
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
                  Expanded(
                    child: _RowBody(
                      icon: icon,
                      title: title,
                      // The status always shows; a hint is extra, never a
                      // replacement for the state the row exists to report.
                      subtitle: subtitle == null
                          ? statusLabel
                          : '$statusLabel\n$subtitle',
                    ),
                  ),
                  const SizedBox(width: CapySpacing.sm),
                  // Icon and text carry state, not colour: `success` does
                  // not clear 3:1 on cream.
                  Icon(
                    satisfied
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    size: CapyIconSize.md,
                    color: inkSoft,
                  ),
                  if (!satisfied) ...[
                    const SizedBox(width: CapySpacing.xs),
                    Flexible(
                      child: Text(
                        actionLabel,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: CapyColors.accentDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
