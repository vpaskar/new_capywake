import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/data/motion/platform_step_sensor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The native step channel on a real build. Run by hand with `-d`; a
/// simulator has no pedometer, so it must answer "unavailable", not fail.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the native step channel is registered and answers', (
    tester,
  ) async {
    final available = await PlatformStepSensor.methods.invokeMethod<bool>(
      'isAvailable',
    );
    expect(available, isA<bool>(), reason: 'a MissingPluginException fails');
    final sensor = PlatformStepSensor();
    final access = await sensor.access();
    if (available!) {
      expect(access, isNot(StepAccess.unavailable));
    } else {
      expect(access, StepAccess.unavailable);
    }
    await sensor.dispose();
  });
}
