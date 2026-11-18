import 'package:capywake/app/app.dart';
import 'package:capywake/app/bootstrap.dart';
import 'package:capywake/app/router.dart';
import 'package:capywake/core/engine/fake_alarm_engine.dart';
import 'package:capywake/core/games/morning_sort.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/alarm_puzzle_override.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/features/games/game_win_celebration.dart';
import 'package:capywake/features/games/morning_sort_view.dart';
import 'package:capywake/features/ringing/ringing_win_overlay.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/features/games/_maze_by_ear.dart';

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
    'settings': Routes.settings,
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

  // A ring whose alarm draws only one game: the game on the real surface.
  for (final game in [
    'catch_the_capy',
    'memory_hideout',
    'rhythm_rescue',
    'capy_rocket',
    'morning_sort',
    'find_the_impostor',
    'shake_dj',
    'tilt_maze',
  ]) {
    testWidgets('capture ringing_$game', (tester) async {
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
      await container
          .read(capywakeRepositoryProvider)
          .upsertAlarm(
            captureSeed.first.copyWith(
              dismissMethod: DismissMethod.puzzle,
              puzzleOverride: AlarmPuzzleOverride(
                enabledGames: {game},
                includePuzzles: false,
              ),
            ),
          );

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

      engine.fire('capture-weekday', firedAt: clock);
      await tester.pumpAndSettle();
      // pumpAndSettle does not wait for image decoding; a screenshot taken
      // before it shows empty game cards.
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
      });
      await tester.pumpAndSettle();

      await binding.takeScreenshot('ringing_$game');
      binding.reportData = <String, dynamic>{
        ...?binding.reportData,
        'ringing_$game': tester.view.padding.top / tester.view.devicePixelRatio,
      };

      await _win(tester, game);
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
      });
      await tester.pump(GameWinCelebration.entrance);
      await binding.takeScreenshot('win_$game');
      binding.reportData = <String, dynamic>{
        ...?binding.reportData,
        'win_$game': tester.view.padding.top / tester.view.devicePixelRatio,
      };
      await tester.tap(find.byType(CapyButton).last);
      await tester.pumpAndSettle();
    });
  }
}

/// Finishes the ringing game the way a user would, by its own targets.
Future<void> _win(WidgetTester tester, String game) async {
  if (game == 'shake_dj') {
    for (var i = 0; i < 30; i++) {
      await tester.tap(find.byKey(const ValueKey('shake-dj-beat')));
      await tester.pump(const Duration(milliseconds: 60));
    }
    return;
  }
  if (game == 'tilt_maze') {
    final handle = tester.ensureSemantics();
    for (var maze = 0; maze < 3; maze++) {
      await solveMazeByEar(tester);
    }
    handle.dispose();
    return;
  }
  if (game == 'rhythm_rescue') {
    for (var attempt = 0; attempt < 10; attempt++) {
      if (find.byType(RingingWinOverlay).evaluate().isNotEmpty) return;
      await _watchRhythm(tester);
      await tester.tap(find.byKey(const ValueKey('rhythm-rescue-replay')));
      await tester.pump();
      for (final pad in await _watchRhythm(tester)) {
        await tester.tap(find.byKey(ValueKey('rhythm-rescue-pad-$pad')));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
    }
    return;
  }
  if (game == 'capy_rocket') {
    for (var i = 0; i < 8; i++) {
      final right = find.text('Swipe right').evaluate().isNotEmpty;
      await tester.tap(
        find.byKey(ValueKey('capy-rocket-${right ? 'end' : 'start'}')),
      );
      await tester.pump(const Duration(milliseconds: 600));
    }
    return;
  }
  if (game == 'find_the_impostor') {
    for (var i = 0; i < 3; i++) {
      await tester.tap(
        find.byKey(ValueKey('find-the-impostor-cell-${_oddCell(tester)}')),
      );
      await tester.pump(const Duration(milliseconds: 700));
    }
    return;
  }
  if (game == 'morning_sort') {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(MorningSortView)),
    );
    final useful = {
      for (final item in MorningItem.values)
        morningItemName(l10n, item): item.useful,
    };
    for (var i = 0; i < 9; i++) {
      await tester.tap(
        find.byKey(
          ValueKey('morning-sort-card-${_usefulCard(tester, useful)}'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
    }
    return;
  }
  if (game == 'catch_the_capy') {
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('catch-the-capy-target')));
      await tester.pump(const Duration(milliseconds: 400));
    }
    return;
  }
  for (var attempt = 0; attempt < 30; attempt++) {
    if (find.byType(RingingWinOverlay).evaluate().isNotEmpty) return;
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('memory-hideout-bush-${attempt % 3}')),
    );
    await tester.pumpAndSettle();
  }
}

/// Watches Rhythm Rescue's pads light until it is the user's turn.
Future<List<int>> _watchRhythm(WidgetTester tester) async {
  final seen = <int>[];
  int? last;
  for (var i = 0; i < 200; i++) {
    if (find.text('Your turn').evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 60));
    int? now;
    for (var p = 0; p < 4; p++) {
      if (find.byKey(ValueKey('rhythm-rescue-lit-$p')).evaluate().isNotEmpty) {
        now = p;
      }
    }
    if (now != null && now != last) seen.add(now);
    last = now;
  }
  return seen;
}

/// The Find the Impostor card whose picture appears only once.
int _oddCell(WidgetTester tester) {
  final keys = <String>[];
  for (var c = 0; ; c++) {
    final cell = find.byKey(ValueKey('find-the-impostor-cell-$c'));
    if (cell.evaluate().isEmpty) break;
    final art = tester.widget<Image>(
      find.descendant(of: cell, matching: find.byType(Image)),
    );
    keys.add((art.key! as ValueKey<String>).value);
  }
  return keys.indexWhere((k) => keys.where((o) => o == k).length == 1);
}

/// A Morning Sort card Capy needs and has not packed yet, read by its name.
int _usefulCard(WidgetTester tester, Map<String, bool> useful) {
  for (var i = 0; ; i++) {
    final card = find.byKey(ValueKey('morning-sort-card-$i'));
    final name = tester
        .widget<Text>(find.descendant(of: card, matching: find.byType(Text)))
        .data!;
    final done = find
        .descendant(of: card, matching: find.byType(Icon))
        .evaluate()
        .isNotEmpty;
    if ((useful[name] ?? false) && !done) return i;
  }
}
