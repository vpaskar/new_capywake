import 'package:capywake/core/alarm_format.dart';
import 'package:capywake/core/alarm_repeat.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// One alarm in the list, against `02_ALARMS.png`. A disabled row is dimmed
/// *and* its knob moves: F1 forbids colour as the only state channel.
class AlarmListTile extends StatelessWidget {
  const AlarmListTile({
    required this.alarm,
    required this.index,
    required this.timeFormat,
    required this.onToggle,
    required this.onTap,
    super.key,
  });

  final Alarm alarm;
  final int index;
  final TimeFormatPreference timeFormat;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  static const height = 89.6;
  static const artWidth = 124.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    final parts = AlarmFormat.timeParts(
      minutes: alarm.targetTimeMinutes,
      localeName: l10n.localeName,
      format: timeFormat,
    );
    final repeat = AlarmRepeatSummary.format(
      weekdays: alarm.repeatWeekdays,
      l10n: l10n,
    );

    return Semantics(
      button: true,
      label: _semanticLabel(l10n, parts, repeat),
      child: ExcludeSemantics(
        excluding: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(CapyRadius.lg),
            child: Opacity(
              opacity: alarm.enabled ? 1 : _disabledOpacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: dark ? CapyColors.darkSurface : CapyColors.surface,
                  borderRadius: BorderRadius.circular(CapyRadius.lg),
                  border: Border.all(
                    color: dark
                        ? CapyColors.darkSurfaceAlt
                        : CapyColors.surfaceAlt,
                  ),
                ),
                // A minimum, not a cap: the row grows at large text.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: height),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _art(context, dark),
                        Expanded(child: _details(parts, repeat, ink, inkSoft)),
                        _toggle(l10n),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: CapyIconSize.md,
                          color: inkSoft,
                        ),
                        const SizedBox(width: CapySpacing.sm),
                      ],
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

  Widget _art(BuildContext context, bool dark) {
    return ExcludeSemantics(
      child: ClipRRect(
        // Resolved against the ambient direction: hardcoding ltr put the
        // rounded corners on the wrong edge in Arabic.
        borderRadius: const BorderRadiusDirectional.horizontal(
          start: Radius.circular(CapyRadius.lg),
        ).resolve(Directionality.of(context)),
        child: SizedBox(
          width: artWidth,
          height: height,
          child: ColorFiltered(
            colorFilter: dark
                ? const ColorFilter.mode(CapyColors.artScrim, BlendMode.srcOver)
                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: Image.asset(
              CapyArt.thumbnailForIndex(index).path,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(
    ClockTimeParts parts,
    String repeat,
    Color ink,
    Color inkSoft,
  ) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: CapySpacing.md,
        top: CapySpacing.xs,
        bottom: CapySpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  parts.time,
                  maxLines: 1,
                  style: CapyType.title.copyWith(
                    color: ink,
                    fontSize: _timeSize,
                  ),
                ),
              ),
              if (parts.period != null) ...[
                const SizedBox(width: CapySpacing.xs),
                Text(
                  parts.period!,
                  maxLines: 1,
                  style: CapyType.label.copyWith(color: ink),
                ),
              ],
            ],
          ),
          Text(
            repeat,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CapyType.body.copyWith(color: ink),
          ),
          if (alarm.label.isNotEmpty)
            Text(
              alarm.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CapyType.label.copyWith(color: inkSoft),
            ),
        ],
      ),
    );
  }

  Widget _toggle(AppLocalizations l10n) {
    return CapyToggle(
      value: alarm.enabled,
      onChanged: onToggle,
      semanticLabel: l10n.alarmEnabledLabel,
      trackSize: CapyToggle.alarmsTrack,
    );
  }

  String _semanticLabel(
    AppLocalizations l10n,
    ClockTimeParts parts,
    String repeat,
  ) {
    final time = parts.period == null
        ? parts.time
        : '${parts.time} ${parts.period}';
    return alarm.label.isEmpty
        ? '$time, $repeat'
        : '$time, $repeat, ${alarm.label}';
  }

  static const _timeSize = 30.0;
  static const _disabledOpacity = 0.55;
}
