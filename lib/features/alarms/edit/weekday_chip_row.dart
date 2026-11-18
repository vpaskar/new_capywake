import 'package:capywake/core/alarm_format.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The seven repeat-day chips from `03_ADD_EDIT_ALARM.png`. They read
/// "Mon", not "M". Selected is filled *and* bolder, so F1 holds.
class WeekdayChipRow extends StatelessWidget {
  const WeekdayChipRow({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  static const chipHeight = 31.8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      for (var weekday = 1; weekday <= 7; weekday++)
        (
          weekday,
          AlarmFormat.shortWeekday(
            weekday: weekday,
            localeName: l10n.localeName,
          ),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final chipWidth =
            (constraints.maxWidth - CapySpacing.xs * 6) / labels.length;
        final fits = chipWidth >= _minChipWidth;

        // One row of seven at normal text size, as the mockup draws it. At
        // accessibility sizes the row reflows instead of clipping the names.
        return Wrap(
          spacing: CapySpacing.xs,
          runSpacing: CapySpacing.xs,
          children: [
            for (final (weekday, label) in labels)
              SizedBox(
                width: fits ? chipWidth : null,
                child: _Chip(
                  label: label,
                  selected: selected.contains(weekday),
                  onTap: () => onToggle(weekday),
                ),
              ),
          ],
        );
      },
    );
  }

  static const _minChipWidth = 40.0;
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        // Paint stays at the mockup's 31.8 pt; only the hit area grows.
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CapyRadius.pill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CapyToggle.minTapTarget,
            ),
            child: Center(
              heightFactor: 1,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: WeekdayChipRow.chipHeight,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: CapySpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? CapyColors.accent
                      : (dark ? CapyColors.darkSurface : CapyColors.surface),
                  borderRadius: BorderRadius.circular(CapyRadius.pill),
                  border: Border.all(
                    color: selected
                        ? CapyColors.accentDeep
                        : (dark
                              ? CapyColors.darkSurfaceAlt
                              : CapyColors.surfaceAlt),
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: CapyType.label.copyWith(
                    color: selected
                        ? CapyColors.cocoa
                        : (dark
                              ? CapyColors.darkInkSoft
                              : CapyColors.cocoaSoft),
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    height: 1,
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
