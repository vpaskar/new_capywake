import 'dart:async';

import 'package:capywake/core/camera/camera_access.dart';
import 'package:capywake/core/permissions/device_access.dart';

/// Test double for [CameraAccess]: answers [current] and counts every ask.
class FakeCameraAccess implements CameraAccess {
  FakeCameraAccess({
    this.current = DeviceAccess.unavailable,
    this.afterRequest,
  });

  DeviceAccess current;

  /// What [requestAccess] turns [current] into; `null` leaves it unchanged.
  DeviceAccess? afterRequest;

  int accessCount = 0;
  int requestCount = 0;
  int settingsCount = 0;
  final _accessChanges = StreamController<void>.broadcast();

  @override
  Future<DeviceAccess> access() async {
    accessCount++;
    return current;
  }

  @override
  Future<DeviceAccess> requestAccess() async {
    requestCount++;
    current = afterRequest ?? current;
    _accessChanges.add(null);
    return current;
  }

  @override
  Future<bool> openSettings() async {
    settingsCount++;
    return true;
  }

  @override
  Stream<void> get accessChanges => _accessChanges.stream;

  Future<void> close() => _accessChanges.close();
}
