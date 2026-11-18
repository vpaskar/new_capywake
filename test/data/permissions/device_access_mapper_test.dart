import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/data/permissions/device_access_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android: a grant is ready, a refusal may be asked again', () {
    DeviceAccess android(PermissionGrant grant) =>
        DeviceAccessMapper.android(available: true, grant: grant);
    expect(android(PermissionGrant.granted), DeviceAccess.ready);
    expect(android(PermissionGrant.denied), DeviceAccess.needsPermission);
    expect(android(PermissionGrant.unknown), DeviceAccess.needsPermission);
    expect(
      android(PermissionGrant.permanentlyDenied),
      DeviceAccess.permanentlyDenied,
    );
  });

  test('iOS: a refusal is permanent; restricted cannot be fixed', () {
    DeviceAccess ios(String? auth) =>
        DeviceAccessMapper.ios(available: true, authorization: auth);
    expect(ios('authorized'), DeviceAccess.ready);
    expect(ios('notDetermined'), DeviceAccess.needsPermission);
    expect(ios('denied'), DeviceAccess.permanentlyDenied);
    expect(ios('restricted'), DeviceAccess.unavailable);
    expect(ios(null), DeviceAccess.unavailable);
  });

  test('no sensor is unavailable whatever the grant', () {
    expect(
      DeviceAccessMapper.android(
        available: false,
        grant: PermissionGrant.granted,
      ),
      DeviceAccess.unavailable,
    );
    expect(
      DeviceAccessMapper.ios(available: false, authorization: 'authorized'),
      DeviceAccess.unavailable,
    );
  });
}
