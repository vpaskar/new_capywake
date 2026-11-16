import 'package:capywake/app/app.dart';
import 'package:capywake/app/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Writes a PNG per screen through `flutter drive`.
///
/// **Never run this with `flutter test`.** `takeScreenshot` hands its bytes to
/// a driver; under `flutter test` there is no driver, so the bytes are dropped,
/// the run reports "All tests passed!" and nothing reaches disk. That failure
/// is silent and green, which is how the previous project captured zero
/// screenshots across 40 phases. `tool/capture.sh` verifies the artifact.
Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const screens = <String, String>{
    'shell': Routes.home,
    'alarms': Routes.alarms,
    'stats': Routes.stats,
  };

  var surfaceConverted = false;

  for (final entry in screens.entries) {
    testWidgets('capture ${entry.key}', (tester) async {
      await tester.pumpWidget(
        CapyWakeApp(
          router: createRouter(initialLocation: entry.value),
          showDebugBanner: false,
        ),
      );
      await tester.pumpAndSettle();

      // Required on iOS, and exactly once per session.
      if (!surfaceConverted) {
        await binding.convertFlutterSurfaceToImage();
        surfaceConverted = true;
      }
      await tester.pumpAndSettle();

      final inset = tester.view.padding.top / tester.view.devicePixelRatio;
      await binding.takeScreenshot(entry.key);
      binding.reportData = <String, dynamic>{
        ...?binding.reportData,
        entry.key: inset,
      };
    });
  }
}
