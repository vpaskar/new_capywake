import 'package:capywake/core/camera/fake_camera_access.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('answers, changes on request, announces, and opens Settings', () async {
    final camera = FakeCameraAccess(
      current: DeviceAccess.needsPermission,
      afterRequest: DeviceAccess.ready,
    );
    expect(await camera.access(), DeviceAccess.needsPermission);
    final changed = camera.accessChanges.first;
    expect(await camera.requestAccess(), DeviceAccess.ready);
    await changed;
    expect(await camera.openSettings(), isTrue);
    expect(
      [camera.accessCount, camera.requestCount, camera.settingsCount],
      [1, 1, 1],
    );
    await camera.close();
  });

  test('a request with no outcome leaves the access as it was', () async {
    final camera = FakeCameraAccess();
    expect(await camera.requestAccess(), DeviceAccess.unavailable);
  });
}
