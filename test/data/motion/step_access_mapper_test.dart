import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/data/motion/step_access_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android: a grant is ready, a refusal may be asked again', () {
    StepAccess android(PermissionGrant grant) =>
        StepAccessMapper.android(available: true, grant: grant);
    expect(android(PermissionGrant.granted), StepAccess.ready);
    expect(android(PermissionGrant.denied), StepAccess.needsPermission);
    expect(android(PermissionGrant.unknown), StepAccess.needsPermission);
    expect(
      android(PermissionGrant.permanentlyDenied),
      StepAccess.permanentlyDenied,
    );
  });

  test('iOS: a refusal is permanent; restricted cannot be fixed', () {
    StepAccess ios(String? auth) =>
        StepAccessMapper.ios(available: true, authorization: auth);
    expect(ios('authorized'), StepAccess.ready);
    expect(ios('notDetermined'), StepAccess.needsPermission);
    expect(ios('denied'), StepAccess.permanentlyDenied);
    expect(ios('restricted'), StepAccess.unavailable);
    expect(ios(null), StepAccess.unavailable);
  });

  test('no sensor is unavailable whatever the grant', () {
    expect(
      StepAccessMapper.android(
        available: false,
        grant: PermissionGrant.granted,
      ),
      StepAccess.unavailable,
    );
    expect(
      StepAccessMapper.ios(available: false, authorization: 'authorized'),
      StepAccess.unavailable,
    );
  });
}
