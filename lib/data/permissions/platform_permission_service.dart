import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/data/permissions/permission_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as plugin;

/// `permission_handler` behind [PermissionService]. The mapping decisions are
/// in [PermissionMapper]; user-facing copy comes from `ReliabilityCopyService`.
class PlatformPermissionService implements PermissionService {
  PlatformPermissionService({TargetPlatform? platform})
    : _isAndroid =
          (platform ?? defaultTargetPlatform) == TargetPlatform.android;

  final bool _isAndroid;

  @override
  Future<PermissionState> read() async {
    final notification = await plugin.Permission.notification.status;
    final exactAlarm = _isAndroid
        ? await plugin.Permission.scheduleExactAlarm.status
        : null;
    return PermissionState(
      notification: PermissionMapper.grantOf(notification),
      exactAlarm: PermissionMapper.exactAlarmGrant(
        isAndroid: _isAndroid,
        androidStatus: exactAlarm,
      ),
    );
  }

  @override
  Future<PermissionGrant> requestNotification() async {
    final status = await plugin.Permission.notification.request();
    return PermissionMapper.grantOf(status);
  }

  @override
  Future<PermissionGrant> requestExactAlarm() async {
    if (!_isAndroid) return PermissionGrant.granted;
    final status = await plugin.Permission.scheduleExactAlarm.request();
    return PermissionMapper.grantOf(status);
  }

  @override
  Future<bool> openAppSettings() => plugin.openAppSettings();
}
