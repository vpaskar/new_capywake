import 'package:capywake/data/camera/platform_camera_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The native camera-permission channel on a real build. Run by hand with
/// `-d`; a simulator has no camera, so it must answer "unavailable".
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the native camera channel is registered and answers', (
    tester,
  ) async {
    final available = await PlatformCameraAccess.methods.invokeMethod<bool>(
      'isAvailable',
    );
    final authorization = await PlatformCameraAccess.methods
        .invokeMethod<String>('authorization');
    expect(available, isA<bool>(), reason: 'a MissingPluginException fails');
    expect(
      authorization,
      isIn(['authorized', 'notDetermined', 'denied', 'restricted']),
    );
  });
}
