import 'package:capywake/app/app.dart';
import 'package:capywake/app/bootstrap.dart';
import 'package:capywake/app/router.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The alarm the captures are taken against, so the screens are comparable to
/// the mockups. Demo data lives here, never in `lib/`; `docs/visual/<screen>/`
/// records that the capture was seeded and with what.
final captureSeed = <Alarm>[
  Alarm(
    id: 'capture-weekday',
    label: 'Workdays',
    enabled: true,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const {1, 2, 3, 4, 5},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 15,
    soundId: 'gentle',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: DismissMethod.normalButton,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: DateTime.utc(2026, 5, 21, 8),
    updatedAt: DateTime.utc(2026, 5, 21, 8),
  ),
];

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
    'home': Routes.home,
    'alarms': Routes.alarms,
    'stats': Routes.stats,
  };

  var surfaceConverted = false;

  for (final entry in screens.entries) {
    testWidgets('capture ${entry.key}', (tester) async {
      await bootstrap();

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      for (final alarm in captureSeed) {
        await container.read(capywakeRepositoryProvider).upsertAlarm(alarm);
      }

      await tester.pumpWidget(
        CapyWakeApp(
          router: createRouter(initialLocation: entry.value),
          showDebugBanner: false,
          scopeBuilder: (child) => UncontrolledProviderScope(
            container: container,
            child: child,
          ),
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
