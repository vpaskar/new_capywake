import 'dart:io';

import 'package:capywake/core/camera/fake_camera_access.dart';
import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/data/camera/camera_providers.dart';
import 'package:capywake/data/camera/code_scanner.dart';
import 'package:capywake/data/camera/platform_camera_access.dart';
import 'package:capywake/data/camera/platform_code_scanner.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  ProviderContainer container(FakeCameraAccess camera) {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        cameraAccessProvider.overrideWithValue(camera),
      ],
    );
    addTearDown(c.dispose);
    final listening = c.listen(qrHuntReadyProvider, (_, _) {});
    addTearDown(listening.close);
    return c;
  }

  Future<void> saveCheckpoint(ProviderContainer c) => c
      .read(capywakeRepositoryProvider)
      .saveQrCheckpoint(QrCheckpoint.of('MIRROR', savedAt: DateTime(2026)));

  test('not ready without a checkpoint, even with the camera', () async {
    final c = container(FakeCameraAccess(current: DeviceAccess.ready));
    expect(await c.read(qrHuntReadyProvider.future), isFalse);
  });

  test('not ready without the camera, even with a checkpoint', () async {
    final c = container(
      FakeCameraAccess(current: DeviceAccess.needsPermission),
    );
    await saveCheckpoint(c);
    expect(await c.read(qrHuntReadyProvider.future), isFalse);
  });

  test('ready with both, and follows a camera grant', () async {
    final camera = FakeCameraAccess(
      current: DeviceAccess.needsPermission,
      afterRequest: DeviceAccess.ready,
    );
    final c = container(camera);
    await saveCheckpoint(c);
    await pumpEventQueue();
    expect(await c.read(qrHuntReadyProvider.future), isFalse);
    await camera.requestAccess();
    await pumpEventQueue();
    expect(await c.read(qrHuntReadyProvider.future), isTrue);
  });

  test('a grant made in Settings is read on return', () async {
    final camera = FakeCameraAccess(current: DeviceAccess.permanentlyDenied);
    final c = container(camera);
    await saveCheckpoint(c);
    expect(await c.read(qrHuntReadyProvider.future), isFalse);
    camera.current = DeviceAccess.ready;
    TestWidgetsFlutterBinding.instance
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(await c.read(qrHuntReadyProvider.future), isTrue);
  });

  test('defaults are fakes; production swaps in the platform', () {
    final defaults = ProviderContainer();
    addTearDown(defaults.dispose);
    expect(defaults.read(cameraAccessProvider), isA<FakeCameraAccess>());
    expect(defaults.read(codeScannerProvider), isA<FakeCodeScanner>());

    final production = ProviderContainer(overrides: platformCameraOverrides());
    addTearDown(production.dispose);
    expect(production.read(cameraAccessProvider), isA<PlatformCameraAccess>());
    expect(production.read(codeScannerProvider), isA<PlatformCodeScanner>());
    expect(
      File('lib/data/engine/platform_engine_overrides.dart').readAsStringSync(),
      contains('...platformCameraOverrides()'),
    );
  });
}
