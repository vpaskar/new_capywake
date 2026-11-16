import 'package:capywake/core/alarm_format.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/time_stepper.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Hour/minute wells with chevrons and AM/PM pills, against
/// `03_ADD_EDIT_ALARM.png`. No period column on a 24-hour clock.
class TimeStepperField extends StatelessWidget {
  const TimeStepperField({
    required this.minutes,
    required this.timeFormat,
    required this.onChanged,
    super.key,
  });

  final int minutes;
  final TimeFormatPreference timeFormat;
  final ValueChanged<int> onChanged;

  static const wellWidth = 91.0;
  static const wellHeight = 74.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parts = AlarmFormat.timeParts(
      minutes: minutes,
      localeName: l10n.localeName,
      format: timeFormat,
    );
    final digits = parts.time.split(_separator(parts.time));

    final wells = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _Column(
            value: digits.first,
            upLabel: l10n.alarmTimeStepperHourUp,
            downLabel: l10n.alarmTimeStepperHourDown,
            onUp: () => onChanged(TimeStepper.stepHours(minutes, delta: 1)),
            onDown: () => onChanged(TimeStepper.stepHours(minutes, delta: -1)),
          ),
        ),
        _Separator(separator: _separator(parts.time)),
        Flexible(
          child: _Column(
            value: digits.length > 1 ? digits[1] : '',
            upLabel: l10n.alarmTimeStepperMinuteUp,
            downLabel: l10n.alarmTimeStepperMinuteDown,
            onUp: () =>
                onChanged(TimeStepper.stepFiveMinutes(minutes, delta: 1)),
            onDown: () =>
                onChanged(TimeStepper.stepFiveMinutes(minutes, delta: -1)),
          ),
        ),
      ],
    );

    if (parts.period == null) return wells;

    // Beside the wells, dropping below only when the row will not fit.
    return LayoutBuilder(
      builder: (context, constraints) {
        const needed =
            wellWidth * 2 + _separatorWidth + CapySpacing.md + _pillColumnWidth;
        final pills = _PeriodPills(minutes: minutes, onChanged: onChanged);

        if (constraints.maxWidth >= needed) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: wells),
              const SizedBox(width: CapySpacing.md),
              pills,
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            wells,
            const SizedBox(height: CapySpacing.sm),
            pills,
          ],
        );
      },
    );
  }

  static const _separatorWidth = 25.4;
  static const _pillColumnWidth = 70.2;

  /// The locale's own hour/minute separator, taken from the formatted string
  /// rather than assumed to be a colon.
  static String _separator(String time) {
    final match = RegExp(r'[^\p{N}]', unicode: true).firstMatch(time);
    return match?.group(0) ?? ':';
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.value,
    required this.upLabel,
    required this.downLabel,
    required this.onUp,
    required this.onDown,
  });

  final String value;
  final String upLabel;
  final String downLabel;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Chevron(
          icon: Icons.keyboard_arrow_up_rounded,
          label: upLabel,
          onPressed: onUp,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: TimeStepperField.wellWidth,
            minHeight: TimeStepperField.wellHeight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt,
              borderRadius: BorderRadius.circular(CapyRadius.md),
            ),
            child: Center(
              child: Text(
                value,
                maxLines: 1,
                style: CapyType.display.copyWith(
                  color: dark ? CapyColors.darkInk : CapyColors.cocoa,
                ),
              ),
            ),
          ),
        ),
        _Chevron(
          icon: Icons.keyboard_arrow_down_rounded,
          label: downLabel,
          onPressed: onDown,
        ),
      ],
    );
  }
}

/// A stepper arrow: the mockup's 19.4 pt glyph inside a 44 pt tap region,
/// so Tier A and reachability both hold.
class _Chevron extends StatelessWidget {
  const _Chevron({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  static const paintedHeight = 19.4;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Tooltip(
          message: label,
          child: SizedBox(
            height: paintedHeight,
            width: TimeStepperField.wellWidth,
            child: OverflowBox(
              maxHeight: CapyToggle.minTapTarget,
              child: GestureDetector(
                onTap: onPressed,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: CapyToggle.minTapTarget,
                  width: TimeStepperField.wellWidth,
                  child: Center(
                    child: Icon(
                      icon,
                      size: CapyIconSize.md,
                      color: dark
                          ? CapyColors.darkInkSoft
                          : CapyColors.cocoaSoft,
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

class _Separator extends StatelessWidget {
  const _Separator({required this.separator});

  final String separator;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CapySpacing.xs),
        child: Text(
          separator,
          style: CapyType.display.copyWith(
            color: dark ? CapyColors.darkInk : CapyColors.cocoa,
          ),
        ),
      ),
    );
  }
}

/// AM over PM, as the mockup stacks them. Selected is filled *and* bolder.
class _PeriodPills extends StatelessWidget {
  const _PeriodPills({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMorning = minutes < _halfDay;
    final labels = AlarmFormat.periodLabels(localeName: l10n.localeName);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pill(context, labels.$1, selected: isMorning, toMorning: true),
        const SizedBox(height: CapySpacing.xs),
        _pill(context, labels.$2, selected: !isMorning, toMorning: false),
      ],
    );
  }

  Widget _pill(
    BuildContext context,
    String label, {
    required bool selected,
    required bool toMorning,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? CapyColors.accent
            : (dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt),
        borderRadius: BorderRadius.circular(CapyRadius.pill),
        child: InkWell(
          onTap: () => onChanged(_withPeriod(toMorning: toMorning)),
          borderRadius: BorderRadius.circular(CapyRadius.pill),
          child: SizedBox(
            width: _pillWidth,
            height: _pillHeight,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                style: CapyType.section.copyWith(
                  color: selected
                      ? CapyColors.cocoa
                      : (dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _withPeriod({required bool toMorning}) {
    final isMorning = minutes < _halfDay;
    if (isMorning == toMorning) return minutes;
    return toMorning ? minutes - _halfDay : minutes + _halfDay;
  }

  static const int _halfDay = 12 * 60;
  static const _pillWidth = 70.2;
  static const _pillHeight = 35.1;
}
