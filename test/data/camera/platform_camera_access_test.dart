import 'dart:io';

import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/data/camera/platform_camera_access.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
const _camera = 1;
const _denied = 0;
const _granted = 1;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];

  setUp(calls.clear);
  tearDown(() {
    messenger
      ..setMockMethodCallHandler(PlatformCameraAccess.methods, null)
      ..setMockMethodCallHandler(_permissions, null);
  });

  void ios(String Function() authorization, {bool available = true}) {
    messenger.setMockMethodCallHandler(PlatformCameraAccess.methods, (
      call,
    ) async {
      calls.add(call.method);
      return switch (call.method) {
        'isAvailable' => available,
        _ => authorization(),
      };
    });
  }

  group('iOS', () {
    final camera = PlatformCameraAccess(platform: TargetPlatform.iOS);

    test('reads AVFoundation authorization', () async {
      ios(() => 'authorized');
      expect(await camera.access(), DeviceAccess.ready);
      ios(() => 'denied');
      expect(await camera.access(), DeviceAccess.permanentlyDenied);
      ios(() => 'restricted');
      expect(await camera.access(), DeviceAccess.unavailable);
    });

    test('no camera is unavailable', () async {
      ios(() => 'authorized', available: false);
      expect(await camera.access(), DeviceAccess.unavailable);
    });

    test('a request prompts, reads the answer, and announces it', () async {
      var auth = 'notDetermined';
      messenger.setMockMethodCallHandler(PlatformCameraAccess.methods, (
        call,
      ) async {
        calls.add(call.method);
        return switch (call.method) {
          'isAvailable' => true,
          'requestAuthorization' => auth = 'authorized',
          _ => auth,
        };
      });
      final changed = camera.accessChanges.first;
      expect(await camera.requestAccess(), DeviceAccess.ready);
      await changed;
      expect(calls, contains('requestAuthorization'));
    });

    test('never prompts when there is nothing to ask', () async {
      ios(() => 'denied');
      expect(await camera.requestAccess(), DeviceAccess.permanentlyDenied);
      expect(calls, isNot(contains('requestAuthorization')));
    });
  });

  group('Android', () {
    final camera = PlatformCameraAccess(platform: TargetPlatform.android);

    test('asks for CAMERA through permission_handler', () async {
      var next = _denied;
      messenger.setMockMethodCallHandler(_permissions, (call) async {
        calls.add(call.method);
        switch (call.method) {
          case 'checkPermissionStatus':
            expect(call.arguments, _camera);
            return next;
          case 'requestPermissions':
            next = _granted;
            return {_camera: _granted};
          case 'openAppSettings':
            return true;
        }
        return null;
      });
      expect(await camera.access(), DeviceAccess.needsPermission);
      expect(await camera.requestAccess(), DeviceAccess.ready);
      expect(await camera.openSettings(), isTrue);
    });
  });

  test('a channel that fails is unavailable, never a throw', () async {
    final camera = PlatformCameraAccess(platform: TargetPlatform.iOS);
    expect(await camera.access(), DeviceAccess.unavailable);
    expect(await camera.requestAccess(), DeviceAccess.unavailable);
    expect(await camera.openSettings(), isFalse);
    messenger.setMockMethodCallHandler(
      _permissions,
      (_) async => throw PlatformException(code: 'boom'),
    );
    expect(await camera.openSettings(), isFalse);
    await camera.dispose();
  });

  test('only the platform scanner imports mobile_scanner (M4)', () {
    final importers = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('package:mobile_scanner/'))
        .map((f) => f.path)
        .toList();
    expect(importers, ['lib/data/camera/platform_code_scanner.dart']);
  });

  test('the camera prompt reads in every app language (M6)', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      RegExp(
        r'<key>NSCameraUsageDescription</key>\s*<string>[^<]{40,}</string>',
      ).hasMatch(plist),
      isTrue,
    );
    for (final locale in AppLocalizations.supportedLocales) {
      final code = locale.languageCode;
      final strings = File(
        'ios/Runner/$code.lproj/InfoPlist.strings',
      ).readAsStringSync();
      expect(
        RegExp(
          r'^NSCameraUsageDescription = "[^"]{40,}";$',
          multiLine: true,
        ).hasMatch(strings),
        isTrue,
        reason: code,
      );
    }
  });

  test('the native channel uses the names the Dart side calls', () {
    final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(swift, contains('"${PlatformCameraAccess.methods.name}"'));
    for (final method in [
      'isAvailable',
      'authorization',
      'requestAuthorization',
    ]) {
      expect(swift, contains('"$method"'));
    }
  });
}
