import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/core/reliability/reliability_checklist_service.dart';
import 'package:capywake/core/reliability/reliability_copy_service.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/settings/settings_controller.dart';
import 'package:capywake/features/settings/settings_group.dart';
import 'package:capywake/features/settings/settings_header.dart';
import 'package:capywake/features/settings/settings_rows.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What affects whether alarms ring here. Every sentence comes from the
/// reliability layer; nothing here invents a claim or promises a ring.
class ReliabilityChecklistScreen extends ConsumerWidget {
  const ReliabilityChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SceneHeader(
        scene: SceneCrop.settings,
        bandHeight: _heroBandHeight,
        header: SettingsHeader(title: l10n.reliabilityTitle),
        child: const _Body(),
      ),
    );
  }

  /// **Not a measurement** — this screen has no mockup. Chosen shorter than
  /// Settings' 109.0 and recorded as a choice in `docs/visual/settings/`.
  static const _heroBandHeight = 84.0;
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final platform = ref.watch(reliabilityPlatformProvider);
    // `initial` is all-unknown, so no row claims to be fine before the
    // first read returns.
    final permissions =
        ref.watch(permissionStateProvider).value ?? PermissionState.initial;
    final settings =
        ref.watch(userSettingsStreamProvider).value ?? UserSettings.initial;
    final controller = ref.read(settingsControllerProvider);
    final notifier = ref.read(permissionStateProvider.notifier);

    final copy = ReliabilityCopyService(l10n: l10n, platform: platform);
    final entries = ReliabilityChecklistService.build(
      l10n: l10n,
      platform: platform,
      permissions: permissions,
      acknowledged: settings.reliabilityChecklistState,
    );
    final open = entries
        .where((e) => e.state != ChecklistEntryState.ok)
        .toList(growable: false);
    final summary = copy.attentionSummary(
      needsAttentionCount: open.length,
      firstAttentionBody: open.isEmpty ? null : open.first.body,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              CapySpacing.gutterNarrow,
              CapySpacing.lg,
              CapySpacing.gutterNarrow,
              CapySpacing.lg,
            ),
            children: [
              _AttentionCard(summary: summary, platformSummary: copy.summary()),
              const SizedBox(height: SettingsGroup.gap),
              SettingsGroup(
                icon: Icons.checklist_rounded,
                title: l10n.reliabilityChecklistHeading,
                rows: [
                  for (final entry in entries)
                    _ChecklistRow(
                      entry: entry,
                      onRequestNotification: notifier.requestNotification,
                      onRequestExactAlarm: notifier.requestExactAlarm,
                      onOpenSettings: notifier.openSettings,
                      onAcknowledge: () => controller.acknowledgeChecklistItem(
                        entry.item,
                        acknowledged: entry.state != ChecklistEntryState.ok,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: SettingsGroup.gap),
              for (final caution in copy.cautions())
                Padding(
                  padding: const EdgeInsets.only(bottom: CapySpacing.sm),
                  child: _CautionLine(text: caution.text),
                ),
            ],
          ),
        ),
        const MeadowFooter(height: 52.2),
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.summary,
    required this.platformSummary,
  });

  final ReliabilityAttentionSummary summary;
  final String platformSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    // Soft cocoa on the clay warning fill is 3.9:1, under the body-text bar.
    final inkSoft = dark
        ? CapyColors.darkInkSoft
        : (summary.needsAttention ? CapyColors.cocoa : CapyColors.cocoaSoft);

    return DecoratedBox(
      decoration: BoxDecoration(
        // Warm clay carries every warning in this product, never red.
        color: switch ((summary.needsAttention, dark)) {
          (true, false) => CapyColors.surfaceAlt,
          (true, true) => CapyColors.darkSurfaceAlt,
          (false, false) => CapyColors.surface,
          (false, true) => CapyColors.darkSurface,
        },
        borderRadius: BorderRadius.circular(SettingsGroup.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CapySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                summary.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: CapySpacing.xs),
            Text(
              summary.body,
              style: theme.textTheme.bodyMedium?.copyWith(color: ink),
            ),
            const SizedBox(height: CapySpacing.sm),
            Text(
              platformSummary,
              style: theme.textTheme.bodySmall?.copyWith(color: inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.entry,
    required this.onRequestNotification,
    required this.onRequestExactAlarm,
    required this.onOpenSettings,
    required this.onAcknowledge,
  });

  final ReliabilityChecklistEntry entry;
  final VoidCallback onRequestNotification;
  final VoidCallback onRequestExactAlarm;
  final VoidCallback onOpenSettings;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final action = entry.action;
    final ok = entry.state == ChecklistEntryState.ok;

    if (action == null) {
      return SettingsStatusRow(
        icon: _icon,
        title: entry.title,
        statusLabel: entry.body,
        satisfied: ok,
        actionLabel: '',
        onAction: () {},
      );
    }

    return SettingsStatusRow(
      icon: _icon,
      title: entry.title,
      statusLabel: entry.body,
      satisfied: ok,
      actionLabel: action.label,
      onAction: _handlerFor(action.kind),
    );
  }

  VoidCallback _handlerFor(ReliabilityChecklistActionKind kind) {
    switch (kind) {
      case ReliabilityChecklistActionKind.requestNotification:
        return onRequestNotification;
      case ReliabilityChecklistActionKind.requestExactAlarm:
        return onRequestExactAlarm;
      case ReliabilityChecklistActionKind.openSettings:
        return onOpenSettings;
      case ReliabilityChecklistActionKind.acknowledge:
        return onAcknowledge;
    }
  }

  IconData get _icon {
    switch (entry.item) {
      case ReliabilityChecklistItem.notificationPermission:
        return Icons.notifications_active_outlined;
      case ReliabilityChecklistItem.exactAlarmPermission:
        return Icons.alarm_on_rounded;
      case ReliabilityChecklistItem.batteryOptimization:
        return Icons.battery_saver_rounded;
      case ReliabilityChecklistItem.alarmVolume:
        return Icons.volume_up_rounded;
      case ReliabilityChecklistItem.doNotDisturbPosture:
        return Icons.do_not_disturb_on_outlined;
    }
  }
}

class _CautionLine extends StatelessWidget {
  const _CautionLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inkSoft = theme.brightness == Brightness.dark
        ? CapyColors.darkInkSoft
        : CapyColors.cocoaSoft;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.info_outline_rounded,
            size: CapyIconSize.sm,
            color: inkSoft,
          ),
        ),
        const SizedBox(width: CapySpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: inkSoft),
          ),
        ),
      ],
    );
  }
}
