import 'package:capywake/app/router.dart';
import 'package:capywake/core/alarm_sound.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/settings/about_sheet.dart';
import 'package:capywake/features/settings/settings_controller.dart';
import 'package:capywake/features/settings/settings_group.dart';
import 'package:capywake/features/settings/settings_header.dart';
import 'package:capywake/features/settings/settings_rows.dart';
import 'package:capywake/features/settings/snooze_picker_sheet.dart';
import 'package:capywake/features/settings/sound_picker_sheet.dart';
import 'package:capywake/features/settings/theme_tile_row.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Settings, against `04_SETTINGS.png`. App Icon, Daily Reminder, Backup &
/// Sync and Restore Purchases are absent; `docs/visual/settings/` says why.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// 212.9 - 103.9 on the mockup. Home 188.4, Alarms 148.6, Add/Edit 112.1.
  static const heroBandHeight = 109.0;

  /// 853 - 770.3: the meadow runs to the bottom of the mockup.
  static const meadowHeight = 82.7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // A pushed route carries its own Scaffold: the shell's belongs to the
    // tabs this route covers.
    return Scaffold(
      body: SceneHeader(
        scene: SceneCrop.settings,
        bandHeight: heroBandHeight,
        header: SettingsHeader(title: l10n.settingsTitle),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(userSettingsStreamProvider).value ?? UserSettings.initial;
    final permissions = ref.watch(permissionStateProvider).value;
    final controller = ref.read(settingsControllerProvider);

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
              SettingsGroup(
                icon: Icons.alarm_rounded,
                title: l10n.settingsAlarmsHeading,
                rows: [
                  SettingsChevronRow(
                    icon: Icons.notifications_active_outlined,
                    title: l10n.settingsDefaultSoundLabel,
                    value: AlarmSoundCatalog.resolve(
                      settings.defaultSoundId,
                    ).label(l10n),
                    onTap: () => showSoundPickerSheet(context, ref),
                  ),
                  SettingsChevronRow(
                    icon: Icons.snooze_rounded,
                    title: l10n.settingsDefaultSnoozeLabel,
                    value: l10n.alarmSnoozeDurationValue(
                      settings.defaultSnoozeMinutes,
                    ),
                    onTap: () => showSnoozePickerSheet(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: SettingsGroup.gap),
              SettingsGroup(
                icon: Icons.palette_outlined,
                title: l10n.settingsAppearanceHeading,
                rows: [
                  ThemeTileRow(
                    value: settings.themeMode,
                    onChanged: controller.setThemeMode,
                  ),
                  SettingsChevronRow(
                    icon: Icons.schedule_rounded,
                    title: l10n.settingsTimeFormatLabel,
                    value: _timeFormatLabel(l10n, settings.timeFormat),
                    onTap: () => _cycleTimeFormat(controller, settings),
                  ),
                ],
              ),
              const SizedBox(height: SettingsGroup.gap),
              SettingsGroup(
                icon: Icons.notifications_outlined,
                title: l10n.settingsNotificationsHeading,
                rows: [
                  _NotificationStatusRow(permissions: permissions),
                ],
              ),
              const SizedBox(height: SettingsGroup.gap),
              SettingsGroup(
                icon: Icons.verified_outlined,
                title: l10n.settingsSupportHeading,
                rows: [
                  SettingsChevronRow(
                    icon: Icons.checklist_rounded,
                    title: l10n.settingsReliabilityEntryLabel,
                    subtitle: l10n.settingsReliabilityEntryDescription,
                    onTap: () => context.push(Routes.settingsReliability),
                  ),
                  SettingsChevronRow(
                    icon: Icons.map_outlined,
                    title: l10n.settingsOnboardingEntryLabel,
                    subtitle: l10n.settingsOnboardingEntryDescription,
                    onTap: () => context.push(Routes.settingsWalkthrough),
                  ),
                  SettingsToggleRow(
                    icon: Icons.directions_walk_rounded,
                    title: l10n.settingsMotionCheckLabel,
                    subtitle: l10n.settingsMotionCheckDescription,
                    value: settings.motionConfirmationEnabled,
                    onChanged: (enabled) => controller
                        .setMotionConfirmationEnabled(enabled: enabled),
                  ),
                ],
              ),
              const SizedBox(height: SettingsGroup.gap),
              SettingsGroup(
                icon: Icons.info_outline_rounded,
                title: l10n.settingsAboutHeading,
                rows: [
                  SettingsChevronRow(
                    icon: Icons.favorite_outline_rounded,
                    title: l10n.settingsAboutHeading,
                    value: aboutVersionLabel(l10n),
                    onTap: () => showAboutCapyWakeSheet(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        const MeadowFooter(height: SettingsScreen.meadowHeight),
      ],
    );
  }

  static String _timeFormatLabel(
    AppLocalizations l10n,
    TimeFormatPreference format,
  ) {
    switch (format) {
      case TimeFormatPreference.system:
        return l10n.settingsTimeFormatSystem;
      case TimeFormatPreference.h12:
        return l10n.settingsTimeFormatH12;
      case TimeFormatPreference.h24:
        return l10n.settingsTimeFormatH24;
    }
  }

  static Future<void> _cycleTimeFormat(
    SettingsController controller,
    UserSettings settings,
  ) {
    const order = TimeFormatPreference.values;
    final next = order[(order.indexOf(settings.timeFormat) + 1) % order.length];
    return controller.setTimeFormat(next);
  }
}

/// Reports whether the OS lets alarms notify, and only ever grants: the
/// mockup's switch would stop every alarm with nothing on screen saying so.
class _NotificationStatusRow extends ConsumerWidget {
  const _NotificationStatusRow({required this.permissions});

  final PermissionState? permissions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final grant = permissions?.notification ?? PermissionGrant.unknown;
    final granted = grant == PermissionGrant.granted;
    final notifier = ref.read(permissionStateProvider.notifier);

    return SettingsStatusRow(
      icon: Icons.notifications_active_outlined,
      title: l10n.settingsNotificationRowTitle,
      statusLabel: granted
          ? l10n.settingsNotificationAllowed
          : l10n.settingsNotificationNotAllowed,
      subtitle: granted ? l10n.settingsNotificationManageHint : null,
      satisfied: granted,
      actionLabel: grant == PermissionGrant.permanentlyDenied
          ? l10n.reliabilityOpenSettingsAction
          : l10n.settingsNotificationAllowAction,
      onAction: grant == PermissionGrant.permanentlyDenied
          ? notifier.openSettings
          : notifier.requestNotification,
    );
  }
}
