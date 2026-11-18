import 'package:capywake/app/router.dart';
import 'package:capywake/core/camera/fake_camera_access.dart';
import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/data/camera/camera_providers.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/motion/motion_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/features/puzzle/games_selection_screen.dart';
import 'package:capywake/features/puzzle/puzzle_types_screen.dart';
import 'package:capywake/features/puzzle/wake_puzzle_advanced_screen.dart';
import 'package:capywake/features/puzzle/wake_puzzle_overview_screen.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The four puzzle screens on the real route shape, practice stubbed.
Future<ProviderContainer> pumpPuzzleRoute(
  WidgetTester tester,
  String location, {
  PuzzleSettings? seed,
  AppDatabase? database,
  StepSensor? steps,
  FakeCameraAccess? camera,
  bool checkpoint = false,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final db = database ?? AppDatabase.forTesting(NativeDatabase.memory());
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      if (steps != null) stepSensorProvider.overrideWithValue(steps),
      if (camera != null) cameraAccessProvider.overrideWithValue(camera),
    ],
  );
  addTearDown(() async {
    container.dispose();
    if (database == null) await db.close();
  });
  final repository = container.read(capywakeRepositoryProvider);
  if (checkpoint) {
    await repository.saveQrCheckpoint(
      QrCheckpoint.of('MIRROR', savedAt: DateTime(2026)),
    );
  }
  if (seed != null) await repository.savePuzzleSettings(seed);

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: Routes.settingsPuzzle,
        builder: (_, _) => const WakePuzzleOverviewScreen(),
        routes: [
          GoRoute(
            path: 'games',
            builder: (_, _) => const GamesSelectionScreen(),
          ),
          GoRoute(
            path: 'types',
            builder: (_, _) => const PuzzleTypesScreen(),
          ),
          GoRoute(
            path: 'advanced',
            builder: (_, _) => const WakePuzzleAdvancedScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '${Routes.games}/:id',
        builder: (_, state) =>
            Scaffold(body: Text('practice:${state.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<PuzzleSettings> savedPuzzleSettings(ProviderContainer c) =>
    c.read(capywakeRepositoryProvider).getPuzzleSettings();

AppLocalizations puzzleL10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).last));

Finder toggleLabelled(String label) =>
    find.byWidgetPredicate((w) => w is CapyToggle && w.semanticLabel == label);

Future<void> showAndTap(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}
