import 'package:capywake/app/app.dart';
import 'package:capywake/app/bootstrap.dart';
import 'package:capywake/app/router.dart';
import 'package:capywake/core/engine/fake_alarm_engine.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Alarm _seedAlarm({
  required String id,
  required String label,
  required int minutes,
  required Set<int> repeat,
  required bool enabled,
}) {
  final stamp = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: id,
    label: label,
    enabled: enabled,
    targetTimeMinutes: minutes,
    repeatWeekdays: repeat,
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
    createdAt: stamp,
    updatedAt: stamp,
  );
}

/// The alarms the captures are taken against, so the screens are comparable
/// to the mockups. Demo data lives here, never in `lib/`;
/// `docs/visual/<screen>/` records that the capture was seeded and with what.
///
/// `02_ALARMS.png`'s four rows, two of them off, so the capture carries both
/// toggle states. `capture-weekday` keeps its id and position because Home's
/// recorded comparison was taken against it.
final captureSeed = <Alarm>[
  _seedAlarm(
    id: 'capture-weekday',
    label: 'Wake Up',
    minutes: 7 * 60,
    repeat: const {1, 2, 3, 4, 5},
    enabled: true,
  ),
  _seedAlarm(
    id: 'capture-workout',
    label: 'Workout',
    minutes: 7 * 60 + 30,
    repeat: const {1, 3, 5},
    enabled: true,
  ),
  _seedAlarm(
    id: 'capture-walk',
    label: 'Morning Walk',
    minutes: 8 * 60,
    repeat: const {6, 7},
    enabled: false,
  ),
  _seedAlarm(
    id: 'capture-winddown',
    label: 'Wind Down',
    minutes: 21 * 60 + 30,
    repeat: const {1, 2, 3, 4, 5, 6, 7},
    enabled: false,
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
    'add_edit_alarm': Routes.alarmNew,
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

  // The ringing surface has no route: it is opened by the engine. Captured by
  // firing a ring into the live provider graph, which is also the only way a
  // user ever sees it.
  testWidgets('capture ringing', (tester) async {
    await bootstrap();

    final clock = DateTime.utc(2026, 5, 21, 5);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final engine = FakeAlarmEngine(now: () => clock);
    addTearDown(engine.dispose);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        alarmEngineProvider.overrideWithValue(engine),
        engineNowProvider.overrideWithValue(() => clock),
      ],
    );
    addTearDown(container.dispose);
    for (final alarm in captureSeed) {
      await container.read(capywakeRepositoryProvider).upsertAlarm(alarm);
    }

    await tester.pumpWidget(
      CapyWakeApp(
        router: createRouter(),
        showDebugBanner: false,
        scopeBuilder: (child) =>
            UncontrolledProviderScope(container: container, child: child),
      ),
    );
    await tester.pumpAndSettle();

    if (!surfaceConverted) {
      await binding.convertFlutterSurfaceToImage();
      surfaceConverted = true;
    }

    // Puzzle-backed, because that is the configuration the board draws and
    // the one where the emergency escape must be visible.
    await container
        .read(capywakeRepositoryProvider)
        .upsertAlarm(
          captureSeed.first.copyWith(dismissMethod: DismissMethod.puzzle),
        );
    await tester.pumpAndSettle();

    engine.fire('capture-weekday', firedAt: clock);
    await tester.pumpAndSettle();

    final inset = tester.view.padding.top / tester.view.devicePixelRatio;
    await binding.takeScreenshot('ringing');
    binding.reportData = <String, dynamic>{
      ...?binding.reportData,
      'ringing': inset,
    };
  });
}
