import 'package:capywake/app/router.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_header.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/alarms/alarm_list_tile.dart';
import 'package:capywake/features/alarms/alarm_permission_prompt.dart';
import 'package:capywake/features/alarms/alarms_empty_state.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Reads "now" for the `updatedAt` stamp a toggle writes.
final alarmsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Orders the list the way `02_ALARMS.png` reads: by time of day, with
/// `createdAt` breaking ties so equal times keep a stable order.
List<Alarm> sortAlarmsForDisplay(List<Alarm> alarms) {
  return [...alarms]..sort((a, b) {
    final byTime = a.targetTimeMinutes.compareTo(b.targetTimeMinutes);
    return byTime != 0 ? byTime : a.createdAt.compareTo(b.createdAt);
  });
}

/// The alarm list, against `02_ALARMS.png`.
class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmsStreamProvider).value ?? const <Alarm>[];
    final settings = ref.watch(userSettingsStreamProvider).value;

    return SceneHeader(
      scene: SceneCrop.alarms,
      // 252.5 - 103.9 on `02_ALARMS.png`; Home's band is 188.4.
      bandHeight: _heroBandHeight,
      header: const CapyHeader(),
      child: _Body(
        alarms: sortAlarmsForDisplay(alarms),
        timeFormat: (settings ?? UserSettings.initial).timeFormat,
      ),
    );
  }

  static const _heroBandHeight = 148.6;
}

class _Body extends ConsumerWidget {
  const _Body({required this.alarms, required this.timeFormat});

  final List<Alarm> alarms;
  final TimeFormatPreference timeFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        const SizedBox(height: _titleTopGap),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: CapySpacing.gutter,
          ),
          child: _TitleRow(
            title: l10n.navAlarmsLabel,
            actionLabel: l10n.alarmAddAction,
            onAction: () => context.push(Routes.alarmNew),
          ),
        ),
        const SizedBox(height: _titleToListGap),
        Expanded(
          child: alarms.isEmpty
              ? const SingleChildScrollView(child: AlarmsEmptyState())
              : _list(ref),
        ),
        const MeadowFooter(height: _meadowHeight),
      ],
    );
  }

  Widget _list(WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsetsDirectional.only(
        start: CapySpacing.gutter,
        end: CapySpacing.gutter,
        bottom: CapySpacing.lg,
      ),
      itemCount: alarms.length,
      separatorBuilder: (_, _) => const SizedBox(height: _cardGap),
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return AlarmListTile(
          alarm: alarm,
          index: index,
          timeFormat: timeFormat,
          onToggle: (enabled) =>
              _setEnabled(context, ref, alarm, enabled: enabled),
          onTap: () => context.push(Routes.alarmEdit(alarm.id)),
        );
      },
    );
  }

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    Alarm alarm, {
    required bool enabled,
  }) async {
    final updated = alarm.copyWith(
      enabled: enabled,
      updatedAt: ref.read(alarmsClockProvider)().toUtc(),
    );
    await ref.read(capywakeRepositoryProvider).upsertAlarm(updated);

    if (!context.mounted) return;
    await AlarmPermissionPrompt(ref).maybeRequest(
      context: context,
      before: alarms,
      after: [
        for (final a in alarms) a.id == updated.id ? updated : a,
      ],
    );
  }

  /// 272.5 - 252.5 on `02_ALARMS.png`: hero lower edge to the Add pill's top.
  static const _titleTopGap = 16.3;

  /// 329.7 - 309.4: the pill's bottom to the first card's top border.
  static const _titleToListGap = 16.8;
  static const _cardGap = 12.5;

  /// 780.5 - 728.3 on `02_ALARMS.png`; Home's band is 65.2.
  static const _meadowHeight = 52.2;
}

/// The screen title with the Add Alarm pill beside it. Not `SectionHeader`:
/// the mockup has a filled pill, the fill-under-cocoa pattern F1 prefers.
class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: CapyType.title.copyWith(
                color: dark ? CapyColors.darkInk : CapyColors.cocoa,
                fontSize: _titleSize,
                // The glyphs measure 279.4-302.0 inside the mockup's 36.9pt
                // pill row; the default line box would make the row taller.
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: CapySpacing.sm),
        _AddPill(label: actionLabel, onPressed: onAction),
      ],
    );
  }

  static const _titleSize = 30.0;
}

class _AddPill extends StatelessWidget {
  const _AddPill({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  /// `02_ALARMS.png`'s orange pill; the tap target grows to 44 around it.
  static const paintedHeight = 36.9;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(CapyRadius.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: CapyToggle.minTapTarget,
          ),
          child: Center(
            heightFactor: 1,
            child: Material(
              color: CapyColors.accent,
              borderRadius: BorderRadius.circular(CapyRadius.pill),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: _AddPill.paintedHeight,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: CapySpacing.lg,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: CapyIconSize.sm,
                        color: CapyColors.cocoa,
                      ),
                      const SizedBox(width: CapySpacing.xs),
                      Flexible(
                        child: Text(
                          label,
                          style: CapyType.label.copyWith(
                            color: CapyColors.cocoa,
                            fontWeight: FontWeight.w700,
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
