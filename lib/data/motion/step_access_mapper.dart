import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/core/permissions/permission_service.dart';

/// Every decision in the step-sensor adapter, kept out of the channel shell.
abstract final class StepAccessMapper {
  /// Android asks for `ACTIVITY_RECOGNITION`, which may be asked again until
  /// the OS reports it permanently denied.
  static StepAccess android({
    required bool available,
    required PermissionGrant grant,
  }) {
    if (!available) return StepAccess.unavailable;
    return switch (grant) {
      PermissionGrant.granted => StepAccess.ready,
      PermissionGrant.permanentlyDenied => StepAccess.permanentlyDenied,
      PermissionGrant.unknown ||
      PermissionGrant.denied => StepAccess.needsPermission,
    };
  }

  /// iOS's Motion & Fitness answer. iOS never asks twice, so a refusal is
  /// permanent; `restricted` (parental controls) cannot be fixed in Settings.
  static StepAccess ios({
    required bool available,
    required String? authorization,
  }) {
    if (!available) return StepAccess.unavailable;
    return switch (authorization) {
      'authorized' => StepAccess.ready,
      'notDetermined' => StepAccess.needsPermission,
      'denied' => StepAccess.permanentlyDenied,
      _ => StepAccess.unavailable,
    };
  }
}
