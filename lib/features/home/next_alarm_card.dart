import 'package:capywake/core/alarm_format.dart';
import 'package:capywake/core/alarm_repeat.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/next_alarm.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The card at the top of Home. The empty state is the default — a fresh
/// install has no alarm — and every value comes from the model.
class NextAlarmCard extends StatelessWidget {
  const NextAlarmCard({
    required this.next,
    required this.settings,
    required this.onToggle,
    super.key,
  });

  /// `null` when no enabled alarm has a next occurrence — the default state.
  final NextAlarmInfo? next;

  final UserSettings settings;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final info = next;
    return CapyCard(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: CapySpacing.lg,
        vertical: CapySpacing.sm,
      ),
      child: info == null
          ? const _Empty()
          : _Populated(
              info: info,
              settings: settings,
              onToggle: onToggle,
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? CapyColors.darkInk
        : CapyColors.cocoa;
    final inkSoft = theme.brightness == Brightness.dark
        ? CapyColors.darkInkSoft
        : CapyColors.cocoaSoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.todayNoAlarmTitle,
          style: CapyType.title.copyWith(color: ink),
        ),
        const SizedBox(height: CapySpacing.xs),
        Text(
          l10n.todayNoAlarmBody,
          style: CapyType.body.copyWith(color: inkSoft),
        ),
      ],
    );
  }
}

class _Populated extends StatelessWidget {
  const _Populated({
    required this.info,
    required this.settings,
    required this.onToggle,
  });

  final NextAlarmInfo info;
  final UserSettings settings;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? CapyColors.darkInk
        : CapyColors.cocoa;
    final inkSoft = theme.brightness == Brightness.dark
        ? CapyColors.darkInkSoft
        : CapyColors.cocoaSoft;

    final time = AlarmFormat.time(
      minutes: info.alarm.targetTimeMinutes,
      localeName: locale,
      format: settings.timeFormat,
    );
    final repeat = AlarmRepeatSummary.format(
      weekdays: info.alarm.repeatWeekdays,
      l10n: l10n,
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // `01_HOME.png`: 22pt cap height (~32pt, not display's 44) in
              // a 65.1pt card, so both lines are set tight.
              Text(
                time,
                style: CapyType.display.copyWith(
                  color: ink,
                  fontSize: 32,
                  height: 1,
                ),
              ),
              Text(
                repeat,
                style: CapyType.body.copyWith(color: inkSoft, height: 1.1),
              ),
            ],
          ),
        ),
        const SizedBox(width: CapySpacing.md),
        CapyToggle(
          value: info.alarm.enabled,
          onChanged: onToggle,
          semanticLabel: '$time $repeat',
          trackSize: CapyToggle.homeTrack,
        ),
      ],
    );
  }
}
