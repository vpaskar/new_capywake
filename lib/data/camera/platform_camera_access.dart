import 'dart:async';

import 'package:capywake/core/camera/camera_access.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/data/permissions/device_access_mapper.dart';
import 'package:capywake/data/permissions/permission_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as plugin;

/// Camera access: iOS over CapyWake's own channel (`AppDelegate.swift`),
/// Android through `permission_handler`.
class PlatformCameraAccess implements CameraAccess {
  PlatformCameraAccess({TargetPlatform? platform})
    : _isAndroid =
          (platform ?? defaultTargetPlatform) == TargetPlatform.android;

  static const methods = MethodChannel('capywake/camera');

  final bool _isAndroid;
  final _accessChanges = StreamController<void>.broadcast();

  @override
  Future<DeviceAccess> access() => _orUnavailable(() async {
    if (_isAndroid) {
      final status = await plugin.Permission.camera.status;
      return DeviceAccessMapper.android(
        available: true,
        grant: PermissionMapper.grantOf(status),
      );
    }
    return DeviceAccessMapper.ios(
      available: await methods.invokeMethod<bool>('isAvailable') ?? false,
      authorization: await methods.invokeMethod<String>('authorization'),
    );
  });

  @override
  Future<DeviceAccess> requestAccess() => _orUnavailable(() async {
    if (await access() != DeviceAccess.needsPermission) return access();
    if (_isAndroid) {
      await plugin.Permission.camera.request();
    } else {
      await methods.invokeMethod<String>('requestAuthorization');
    }
    _accessChanges.add(null);
    return access();
  });

  @override
  Future<bool> openSettings() async {
    try {
      return await plugin.openAppSettings();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Stream<void> get accessChanges => _accessChanges.stream;

  Future<void> dispose() => _accessChanges.close();

  static Future<DeviceAccess> _orUnavailable(
    Future<DeviceAccess> Function() body,
  ) async {
    try {
      return await body();
    } on PlatformException {
      return DeviceAccess.unavailable;
    } on MissingPluginException {
      return DeviceAccess.unavailable;
    }
  }
}
