import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/permission_service.dart';

/// Decides when to ask for an alarm's permissions — a decision, so it is pure
/// and tested, even though only a device can answer the question itself.
abstract final class AlarmPermissionGate {
  /// Whether enabling an alarm should prompt: on the first transition that
  /// leaves one enabled, never on app start, never once only Settings remains.
  static bool shouldRequestNotification({
    required List<Alarm> alarms,
    required PermissionGrant grant,
  }) {
    if (!hasEnabledAlarm(alarms)) return false;
    return grant == PermissionGrant.unknown || grant == PermissionGrant.denied;
  }

  /// Whether to ask for Android's exact-alarm permission. Never on iOS.
  static bool shouldRequestExactAlarm({
    required List<Alarm> alarms,
    required PermissionGrant grant,
    required bool isAndroid,
  }) {
    if (!isAndroid) return false;
    if (!hasEnabledAlarm(alarms)) return false;
    return grant == PermissionGrant.unknown || grant == PermissionGrant.denied;
  }

  /// Whether the user should be sent to the Settings app instead of prompted.
  static bool shouldOpenSettings(PermissionGrant grant) =>
      grant == PermissionGrant.permanentlyDenied;

  /// Whether any alarm is enabled.
  static bool hasEnabledAlarm(List<Alarm> alarms) =>
      alarms.any((alarm) => alarm.enabled);

  /// The edge from nothing enabled to something enabled. An edge rather than
  /// a level, so a second alarm does not re-prompt someone who answered.
  static bool isFirstEnableTransition({
    required List<Alarm> before,
    required List<Alarm> after,
  }) => !hasEnabledAlarm(before) && hasEnabledAlarm(after);
}
