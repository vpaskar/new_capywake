import 'dart:async';

import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/data/motion/step_access_mapper.dart';
import 'package:capywake/data/permissions/permission_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as plugin;

/// The phone's step sensor over CapyWake's own channel (`MainActivity.kt`,
/// `AppDelegate.swift`). Android's grant goes through `permission_handler`.
class PlatformStepSensor implements StepSensor {
  PlatformStepSensor({TargetPlatform? platform})
    : _isAndroid =
          (platform ?? defaultTargetPlatform) == TargetPlatform.android;

  static const methods = MethodChannel('capywake/steps');
  static const events = EventChannel('capywake/steps/events');

  final bool _isAndroid;
  final _accessChanges = StreamController<void>.broadcast();

  @override
  Future<StepAccess> access() => _orUnavailable(() async {
    final available = await methods.invokeMethod<bool>('isAvailable') ?? false;
    if (!available) return StepAccess.unavailable;
    if (_isAndroid) {
      final status = await plugin.Permission.activityRecognition.status;
      return StepAccessMapper.android(
        available: true,
        grant: PermissionMapper.grantOf(status),
      );
    }
    return StepAccessMapper.ios(
      available: true,
      authorization: await methods.invokeMethod<String>('authorization'),
    );
  });

  @override
  Future<StepAccess> requestAccess() => _orUnavailable(() async {
    if (await access() != StepAccess.needsPermission) return access();
    if (_isAndroid) {
      await plugin.Permission.activityRecognition.request();
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

  /// One stream for every listener: the channel keeps a single handler, so a
  /// second `receiveBroadcastStream` would cut off the first.
  @override
  late final Stream<int> steps = events
      .receiveBroadcastStream()
      .map((event) => (event! as num).toInt())
      .where((count) => count > 0);

  @override
  Stream<void> get accessChanges => _accessChanges.stream;

  Future<void> dispose() => _accessChanges.close();

  static Future<StepAccess> _orUnavailable(
    Future<StepAccess> Function() body,
  ) async {
    try {
      return await body();
    } on PlatformException {
      return StepAccess.unavailable;
    } on MissingPluginException {
      return StepAccess.unavailable;
    }
  }
}
