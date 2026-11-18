import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/core/permissions/permission_service.dart';

/// Every decision in the device-permission adapters, out of the shells.
abstract final class DeviceAccessMapper {
  /// An Android runtime permission may be asked again until the OS reports
  /// it permanently denied.
  static DeviceAccess android({
    required bool available,
    required PermissionGrant grant,
  }) {
    if (!available) return DeviceAccess.unavailable;
    return switch (grant) {
      PermissionGrant.granted => DeviceAccess.ready,
      PermissionGrant.permanentlyDenied => DeviceAccess.permanentlyDenied,
      PermissionGrant.unknown ||
      PermissionGrant.denied => DeviceAccess.needsPermission,
    };
  }

  /// iOS's Motion & Fitness answer. iOS never asks twice, so a refusal is
  /// permanent; `restricted` (parental controls) cannot be fixed in Settings.
  static DeviceAccess ios({
    required bool available,
    required String? authorization,
  }) {
    if (!available) return DeviceAccess.unavailable;
    return switch (authorization) {
      'authorized' => DeviceAccess.ready,
      'notDetermined' => DeviceAccess.needsPermission,
      'denied' => DeviceAccess.permanentlyDenied,
      _ => DeviceAccess.unavailable,
    };
  }
}
