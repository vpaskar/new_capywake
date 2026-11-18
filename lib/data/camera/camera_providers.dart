import 'package:capywake/core/camera/camera_access.dart';
import 'package:capywake/core/camera/fake_camera_access.dart';
import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/data/camera/code_scanner.dart';
import 'package:capywake/data/camera/platform_camera_access.dart';
import 'package:capywake/data/camera/platform_code_scanner.dart';
import 'package:capywake/data/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Camera access. Defaults to an unavailable fake so no test prompts.
final cameraAccessProvider = Provider<CameraAccess>((ref) {
  final camera = FakeCameraAccess();
  ref.onDispose(camera.close);
  return camera;
}, dependencies: const []);

/// The camera view. Defaults to a fake so no test opens a camera.
final codeScannerProvider = Provider<CodeScanner>(
  (ref) => FakeCodeScanner(),
  dependencies: const [],
);

final qrCheckpointProvider = StreamProvider<QrCheckpoint?>(
  (ref) => ref.watch(capywakeRepositoryProvider).watchQrCheckpoint(),
);

/// Whether QR Treasure Hunt can be finished now: a checkpoint is saved and the
/// camera is allowed. Loading or failing counts as not ready.
final qrHuntReadyProvider = FutureProvider<bool>((ref) async {
  final camera = ref.watch(cameraAccessProvider);
  final changes = camera.accessChanges.listen((_) => ref.invalidateSelf());
  final returns = _OnResume(ref.invalidateSelf);
  ref
    ..onDispose(changes.cancel)
    ..onDispose(returns.dispose);
  final checkpoint = await ref.watch(qrCheckpointProvider.future);
  if (checkpoint == null) return false;
  return await camera.access() == DeviceAccess.ready;
}, dependencies: [cameraAccessProvider]);

List<Override> platformCameraOverrides() => [
  cameraAccessProvider.overrideWith((ref) {
    final camera = PlatformCameraAccess();
    ref.onDispose(camera.dispose);
    return camera;
  }),
  codeScannerProvider.overrideWith((ref) => PlatformCodeScanner()),
];

class _OnResume with WidgetsBindingObserver {
  _OnResume(this.onResume) {
    WidgetsBinding.instance.addObserver(this);
  }

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }

  void dispose() => WidgetsBinding.instance.removeObserver(this);
}
