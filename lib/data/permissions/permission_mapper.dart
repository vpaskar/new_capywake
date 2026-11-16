import 'package:capywake/core/permissions/permission_service.dart';
import 'package:permission_handler/permission_handler.dart' as plugin;

/// Every decision in the permission adapter, kept out of the plugin shell.
abstract final class PermissionMapper {
  /// The plugin's status as a grant. `limited` and `provisional` still
  /// deliver; `restricted` never prompts again, so it is permanently denied.
  static PermissionGrant grantOf(plugin.PermissionStatus status) {
    return switch (status) {
      plugin.PermissionStatus.granted ||
      plugin.PermissionStatus.limited ||
      plugin.PermissionStatus.provisional => PermissionGrant.granted,
      plugin.PermissionStatus.denied => PermissionGrant.denied,
      plugin.PermissionStatus.permanentlyDenied ||
      plugin.PermissionStatus.restricted => PermissionGrant.permanentlyDenied,
    };
  }

  /// The exact-alarm grant. Always granted on iOS, which has no such
  /// permission — `unknown` would show an Android row on an iPhone.
  static PermissionGrant exactAlarmGrant({
    required bool isAndroid,
    required plugin.PermissionStatus? androidStatus,
  }) {
    if (!isAndroid) return PermissionGrant.granted;
    if (androidStatus == null) return PermissionGrant.unknown;
    return grantOf(androidStatus);
  }

  /// Whether the OS will still show a prompt, or only Settings remains.
  static bool canAskAgain(PermissionGrant grant) =>
      grant == PermissionGrant.unknown || grant == PermissionGrant.denied;

  /// Whether an enabled alarm can actually ring; false means the UI must not
  /// present it as set. iOS is judged on its notification grant alone.
  static bool canRing(PermissionState state, {required bool isAndroid}) {
    if (state.notification != PermissionGrant.granted) return false;
    if (!isAndroid) return true;
    return state.exactAlarm == PermissionGrant.granted;
  }
}
