import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

enum StatsSegment { sleep, alarms, games }

/// The three-way pill from `05_STATS.png`. The mockup's track is 30.9 pt; the
/// row takes the 44 pt tap floor, which `CLAUDE.md` binds over the mockup.
class StatsSegmentSwitcher extends StatelessWidget {
  const StatsSegmentSwitcher({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final StatsSegment selected;
  final ValueChanged<StatsSegment> onSelected;

  static const trackHeight = 30.9;
  static const rowHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    final labels = <StatsSegment, String>{
      StatsSegment.sleep: l10n.statsSegmentSleep,
      StatsSegment.alarms: l10n.statsSegmentAlarms,
      StatsSegment.games: l10n.statsSegmentGames,
    };

    return SizedBox(
      height: rowHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? CapyColors.darkSurface : CapyColors.surface,
          borderRadius: BorderRadius.circular(CapyRadius.pill),
          border: Border.all(
            color: dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt,
          ),
        ),
        child: Row(
          children: [
            for (final segment in StatsSegment.values)
              Expanded(
                child: _Segment(
                  label: labels[segment]!,
                  isSelected: segment == selected,
                  onTap: () => onSelected(segment),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CapyRadius.pill),
          child: Center(
            child: SizedBox(
              height: StatsSegmentSwitcher.trackHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isSelected
                      ? CapyColors.accentDeep
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(CapyRadius.pill),
                ),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: CapyType.label.copyWith(
                      color: isSelected ? CapyColors.cream : inkSoft,
                    ),
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
