import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/core/reliability/reliability_copy_service.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/permissions/alarm_permission_gate.dart';
import 'package:capywake/features/settings/settings_controller.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks for an alarm's permissions on the edge from "nothing enabled" to
/// "something enabled" — never on app start, never twice for one answer.
class AlarmPermissionPrompt {
  const AlarmPermissionPrompt(this._ref);

  final WidgetRef _ref;

  /// Run the gate for a change that takes [before] to [after]. Returns
  /// whether anything was asked: the OS dialog is not ours to observe.
  Future<bool> maybeRequest({
    required BuildContext context,
    required List<Alarm> before,
    required List<Alarm> after,
  }) async {
    if (!AlarmPermissionGate.isFirstEnableTransition(
      before: before,
      after: after,
    )) {
      return false;
    }

    final permissions = await _ref.read(permissionServiceProvider).read();
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    // `shouldRequestNotification` is false when permanently denied, so the
    // settings route sits beside the request rather than behind it.
    final sendToSettings =
        AlarmPermissionGate.hasEnabledAlarm(after) &&
        AlarmPermissionGate.shouldOpenSettings(permissions.notification);
    final needsNotification = AlarmPermissionGate.shouldRequestNotification(
      alarms: after,
      grant: permissions.notification,
    );
    final needsExactAlarm = AlarmPermissionGate.shouldRequestExactAlarm(
      alarms: after,
      grant: permissions.exactAlarm,
      isAndroid: isAndroid,
    );
    if (!needsNotification && !needsExactAlarm && !sendToSettings) {
      return false;
    }

    if (!context.mounted) return false;
    final proceed = await _showReason(
      context,
      permissions,
      toSettings: sendToSettings,
    );
    if (proceed != true) return false;

    final notifier = _ref.read(permissionStateProvider.notifier);
    if (sendToSettings) {
      await notifier.openSettings();
    } else if (needsNotification) {
      await notifier.requestNotification();
    }
    if (needsExactAlarm) {
      await notifier.requestExactAlarm();
    }
    return true;
  }

  /// The reason, in the reliability layer's words: a permission prompt is
  /// reliability copy and may not be hand-rolled here.
  Future<bool?> _showReason(
    BuildContext context,
    PermissionState permissions, {
    required bool toSettings,
  }) {
    final l10n = AppLocalizations.of(context);
    final copy = ReliabilityCopyService(
      l10n: l10n,
      platform: _ref.read(reliabilityPlatformProvider),
    );
    final reason = copy.permissionDeniedCopy(permissions) ?? copy.summary();

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsNotificationRowTitle),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              toSettings
                  ? l10n.reliabilityOpenSettingsAction
                  : l10n.settingsNotificationAllowAction,
            ),
          ),
        ],
      ),
    );
  }
}
