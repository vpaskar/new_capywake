import 'dart:async';

import 'package:capywake/app/app.dart';
import 'package:capywake/app/router.dart';
import 'package:capywake/core/camera/fake_camera_access.dart';
import 'package:capywake/core/engine/fake_alarm_engine.dart';
import 'package:capywake/core/games/memory_hideout.dart';
import 'package:capywake/core/games/morning_sort.dart';
import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:capywake/core/games/shake_dj.dart';
import 'package:capywake/core/games/step_quest.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/motion/fake_motion_sensor.dart';
import 'package:capywake/core/motion/fake_step_sensor.dart';
import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/core/motion/tilt_reader.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/core/puzzle/alarm_puzzle_override.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/data/camera/camera_providers.dart';
import 'package:capywake/data/camera/code_scanner.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/motion/motion_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/features/games/capy_rocket_view.dart';
import 'package:capywake/features/games/catch_the_capy_view.dart';
import 'package:capywake/features/games/device_access_prompt.dart';
import 'package:capywake/features/games/find_the_impostor_view.dart';
import 'package:capywake/features/games/game_header.dart';
import 'package:capywake/features/games/game_win_celebration.dart';
import 'package:capywake/features/games/memory_hideout_view.dart';
import 'package:capywake/features/games/morning_sort_view.dart';
import 'package:capywake/features/games/qr_treasure_hunt_view.dart';
import 'package:capywake/features/games/rhythm_rescue_view.dart';
import 'package:capywake/features/games/shake_dj_view.dart';
import 'package:capywake/features/games/step_quest_view.dart';
import 'package:capywake/features/games/tilt_maze_view.dart';
import 'package:capywake/features/ringing/puzzle_view.dart';
import 'package:capywake/features/ringing/ringing_host.dart';
import 'package:capywake/features/ringing/ringing_providers.dart';
import 'package:capywake/features/ringing/ringing_screen.dart';
import 'package:capywake/features/ringing/ringing_win_overlay.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../games/_maze_by_ear.dart';

Alarm _alarm({
  DismissMethod dismissMethod = DismissMethod.normalButton,
  AlarmPuzzleOverride? puzzleOverride,
}) {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: 'a1',
    label: 'Morning',
    enabled: true,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const {},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 0,
    soundId: 'gentle',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: dismissMethod,
    puzzleOverride: puzzleOverride,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: t,
    updatedAt: t,
  );
}

FakeMotionSensor sensorOfMotion(ProviderContainer container) =>
    container.read(motionSensorProvider) as FakeMotionSensor;

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting();
  });

  final clock = DateTime.utc(2026, 5, 21, 5);

  /// Returns the engine so a test can fire a ring into the live graph.
  Future<
    ({
      FakeAlarmEngine engine,
      CapyWakeRepository repository,
      ProviderContainer container,
    })
  >
  pumpApp(WidgetTester tester, {List<Override> extra = const []}) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final engine = FakeAlarmEngine(now: () => clock);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        alarmEngineProvider.overrideWithValue(engine),
        engineNowProvider.overrideWithValue(() => clock),
        ...extra,
      ],
    );

    // Dispose the container before the database: a live Drift stream keeps a
    // timer alive, and the framework asserts none is pending at teardown.
    addTearDown(() async {
      container.dispose();
      await engine.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      CapyWakeApp(
        router: createRouter(),
        showDebugBanner: false,
        scopeBuilder: (child) =>
            UncontrolledProviderScope(container: container, child: child),
      ),
    );
    await tester.pumpAndSettle();
    return (
      engine: engine,
      repository: CapyWakeRepository(db),
      container: container,
    );
  }

  AlarmPuzzleOverride gamesOnly(String id, {int? tolerated}) =>
      AlarmPuzzleOverride(
        enabledGames: {id},
        includePuzzles: false,
        toleratedWrongAnswers: tolerated,
      );

  Future<
    ({
      FakeAlarmEngine engine,
      CapyWakeRepository repository,
      ProviderContainer container,
    })
  >
  ring(
    WidgetTester tester,
    AlarmPuzzleOverride override, {
    DeviceAccess? stepAccess,
    DeviceAccess? cameraAccess,
    String? checkpoint,
    List<Override> extra = const [],
  }) async {
    final app = await pumpApp(tester, extra: extra);
    if (stepAccess != null) {
      (app.container.read(stepSensorProvider) as FakeStepSensor).current =
          stepAccess;
    }
    if (cameraAccess != null) {
      (app.container.read(cameraAccessProvider) as FakeCameraAccess).current =
          cameraAccess;
      app.container.invalidate(qrHuntReadyProvider);
    }
    if (checkpoint != null) {
      await app.repository.saveQrCheckpoint(
        QrCheckpoint.of(checkpoint, savedAt: clock),
      );
    }
    await app.repository.upsertAlarm(
      _alarm(dismissMethod: DismissMethod.puzzle, puzzleOverride: override),
    );
    await tester.pumpAndSettle();
    app.engine.fire('a1', firedAt: clock);
    await tester.pumpAndSettle();
    return app;
  }

  Future<void> miss(WidgetTester tester) async {
    final field = tester.getRect(
      find.byKey(const ValueKey('catch-the-capy-meadow')),
    );
    final capy = tester.getRect(
      find.byKey(const ValueKey('catch-the-capy-target')),
    );
    await tester.tapAt(
      capy.center.dx > field.center.dx
          ? field.centerLeft + const Offset(10, 0)
          : field.centerRight - const Offset(10, 0),
    );
    await tester.pumpAndSettle();
  }

  Finder prominentEscape() => find.ancestor(
    of: find.text('Stop without solving'),
    matching: find.byType(CapyButton),
  );

  testWidgets('a games-only alarm launches its game, escape beside it', (
    tester,
  ) async {
    await ring(tester, gamesOnly('catch_the_capy'));

    expect(tester.takeException(), isNull, reason: 'H1: unbounded height');
    expect(find.byType(CatchTheCapyView), findsOneWidget);
    expect(find.byType(PuzzleView), findsNothing);
    expect(find.text('Stop without solving'), findsOneWidget);
    expect(find.text('Stop alarm'), findsNothing);
  });

  testWidgets('Memory Hideout launches the same way', (tester) async {
    await ring(tester, gamesOnly('memory_hideout'));

    expect(tester.takeException(), isNull);
    expect(find.byType(MemoryHideoutView), findsOneWidget);
  });

  testWidgets('finishing the game dismisses the alarm, once', (tester) async {
    final app = await ring(tester, gamesOnly('catch_the_capy'));

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('catch-the-capy-target')));
      await tester.pumpAndSettle();
    }

    expect(find.byType(RingingScreen), findsNothing);
    final rows = await app.repository.listOccurrencesForAlarm('a1');
    expect(rows.where((o) => o.status == AlarmStatus.dismissed), hasLength(1));
  });

  Future<void> win(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('catch-the-capy-target')));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump();
  }

  testWidgets('a win stops the alarm first, then celebrates briefly', (
    tester,
  ) async {
    final app = await ring(tester, gamesOnly('catch_the_capy'));
    await win(tester);

    final rows = await app.repository.listOccurrencesForAlarm('a1');
    expect(rows.where((o) => o.status == AlarmStatus.dismissed), hasLength(1));
    expect(find.byType(RingingScreen), findsNothing);
    expect(find.byType(RingingWinOverlay), findsOneWidget);
    expect(find.byType(GameWinCelebration), findsOneWidget);
    expect(find.text('Alarm stopped'), findsOneWidget);
    expect(find.text('Nice catch!'), findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.text('Alarm stopped'),
        matching: find.byType(RichText),
      ),
    );
    expect(
      paragraph.text.style?.decoration,
      isNot(TextDecoration.underline),
      reason: 'no Material above the overlay draws the yellow fallback text',
    );

    await tester.pump(RingingWinOverlay.visibleFor);
    await tester.pumpAndSettle();
    expect(find.byType(RingingWinOverlay), findsNothing);
  });

  testWidgets('Close ends the celebration early', (tester) async {
    await ring(tester, gamesOnly('catch_the_capy'));
    await win(tester);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(RingingWinOverlay), findsNothing);
  });

  testWidgets('a new ring replaces the celebration', (tester) async {
    final app = await ring(tester, gamesOnly('catch_the_capy'));
    await win(tester);
    expect(find.byType(RingingWinOverlay), findsOneWidget);

    await app.repository.upsertAlarm(
      _alarm().copyWith(id: 'a2', label: 'Second'),
    );
    await tester.pump();
    app.engine.fire('a2', firedAt: clock);
    await tester.pump();
    await tester.pump();

    expect(find.byType(RingingScreen), findsOneWidget);
    expect(find.byType(RingingWinOverlay), findsNothing);
    await tester.pump(RingingWinOverlay.visibleFor);
  });

  testWidgets('under reduce-motion the celebration is a still frame', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await ring(tester, gamesOnly('catch_the_capy'));
    await win(tester);

    expect(find.byType(GameWinCelebration), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(RingingWinOverlay.visibleFor);
  });

  testWidgets("the escape rises at the alarm's own tolerance (H6)", (
    tester,
  ) async {
    await ring(tester, gamesOnly('catch_the_capy', tolerated: 0));
    expect(prominentEscape(), findsNothing);

    await miss(tester);

    expect(
      prominentEscape(),
      findsOneWidget,
      reason: 'one miss is past an override tolerance of 0; default is 3',
    );
  });

  testWidgets('below the tolerance the escape stays available', (
    tester,
  ) async {
    final app = await ring(tester, gamesOnly('catch_the_capy', tolerated: 2));

    for (var i = 0; i < 2; i++) {
      await miss(tester);
    }

    expect(prominentEscape(), findsNothing);
    expect(
      app.container
          .read(ringingControllerProvider)
          .currentSession
          ?.escapeVisibility,
      PuzzleEscapeVisibility.available,
    );
  });

  testWidgets('past the tolerance the controller records it too', (
    tester,
  ) async {
    final app = await ring(tester, gamesOnly('memory_hideout', tolerated: 0));
    final view = tester.widget<MemoryHideoutView>(
      find.byType(MemoryHideoutView),
    );
    final hidden = MemoryHideoutRound.start(
      difficulty: view.difficulty,
      seed: view.seed,
    ).ready(shuffle: true).hiddenAt;
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(ValueKey('memory-hideout-bush-${(hidden + 1) % 3}')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Not there'), findsOneWidget);
    expect(prominentEscape(), findsOneWidget);
    expect(
      app.container
          .read(ringingControllerProvider)
          .currentSession
          ?.escapeVisibility,
      PuzzleEscapeVisibility.prominent,
    );
  });

  testWidgets('the escape still works mid-game', (tester) async {
    final app = await ring(tester, gamesOnly('catch_the_capy'));
    await tester.tap(find.byKey(const ValueKey('catch-the-capy-target')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stop without solving'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop the alarm'));
    await tester.pumpAndSettle();

    expect(find.byType(RingingScreen), findsNothing);
    final rows = await app.repository.listOccurrencesForAlarm('a1');
    expect(rows.where((o) => o.status == AlarmStatus.dismissed), isEmpty);
  });

  testWidgets('under reduce-motion nothing animates while playing', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await ring(tester, gamesOnly('catch_the_capy'));
    expect(tester.binding.transientCallbackCount, 0);

    await tester.tap(find.byKey(const ValueKey('catch-the-capy-target')));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('a default puzzle alarm still gets the puzzle', (tester) async {
    await ring(tester, AlarmPuzzleOverride(taskCount: 1));

    expect(find.byType(PuzzleView), findsOneWidget);
    expect(find.byType(CatchTheCapyView), findsNothing);
  });

  testWidgets('a rebuild keeps the same game and its progress', (
    tester,
  ) async {
    await ring(tester, gamesOnly('catch_the_capy'));
    await tester.tap(find.byKey(const ValueKey('catch-the-capy-target')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 5'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpAndSettle();
    expect(find.text('1 / 5'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('a game sits on a card, not on the scrimmed art (SR1 H1)', (
    tester,
  ) async {
    await ring(tester, gamesOnly('catch_the_capy'));
    expect(
      find.ancestor(
        of: find.text('Catch the capybara 5 times.'),
        matching: find.byType(CapyCard),
      ),
      findsOneWidget,
    );
  });

  group('Rhythm Rescue and Capy Rocket on the real surface', () {
    Finder lit(int pad) => find.byKey(ValueKey('rhythm-rescue-lit-$pad'));

    /// Watches the pads light, as a user would, until it is their turn.
    Future<List<int>> watchRhythm(WidgetTester tester) async {
      final seen = <int>[];
      int? last;
      for (var i = 0; i < 200; i++) {
        if (find.text('Your turn').evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 60));
        int? now;
        for (var p = 0; p < 4; p++) {
          if (lit(p).evaluate().isNotEmpty) now = p;
        }
        if (now != null && now != last) seen.add(now);
        last = now;
      }
      return seen;
    }

    Future<void> tapPads(WidgetTester tester, List<int> pads) async {
      for (final p in pads) {
        await tester.tap(find.byKey(ValueKey('rhythm-rescue-pad-$p')));
        await tester.pump();
      }
    }

    testWidgets('Rhythm Rescue launches on a card, escape beside it', (
      tester,
    ) async {
      await ring(tester, gamesOnly('rhythm_rescue'));
      expect(tester.takeException(), isNull);
      expect(find.byType(RhythmRescueView), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Tap the pads in the order shown.'),
          matching: find.byType(CapyCard),
        ),
        findsOneWidget,
      );
      expect(find.text('Stop without solving'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a wrong pad raises the escape at tolerance 0', (
      tester,
    ) async {
      await ring(tester, gamesOnly('rhythm_rescue', tolerated: 0));
      final pattern = await watchRhythm(tester);
      expect(prominentEscape(), findsNothing);
      await tapPads(tester, [(pattern.first + 1) % 4]);
      await tester.pump();
      expect(prominentEscape(), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('repeating every pattern dismisses the alarm, once', (
      tester,
    ) async {
      final app = await ring(tester, gamesOnly('rhythm_rescue'));
      for (var round = 0; round < 3; round++) {
        await tapPads(tester, await watchRhythm(tester));
      }
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(RingingScreen), findsNothing);
      final rows = await app.repository.listOccurrencesForAlarm('a1');
      expect(
        rows.where((o) => o.status == AlarmStatus.dismissed),
        hasLength(1),
      );
    });

    Finder button(String side) => find.byKey(ValueKey('capy-rocket-$side'));

    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    Future<void> boostCued(WidgetTester tester) async {
      final cueRight = find.text('Swipe right').evaluate().isNotEmpty;
      await tester.tap(button(cueRight ? 'end' : 'start'));
      await tester.pump();
    }

    testWidgets('Capy Rocket launches on a card, escape beside it', (
      tester,
    ) async {
      await ring(tester, gamesOnly('capy_rocket'));
      expect(tester.takeException(), isNull);
      expect(find.byType(CapyRocketView), findsOneWidget);
      expect(find.text('Stop without solving'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a wrong-way boost raises the escape at tolerance 0', (
      tester,
    ) async {
      phone(tester);
      await ring(tester, gamesOnly('capy_rocket', tolerated: 0));
      final cueRight = find.text('Swipe right').evaluate().isNotEmpty;
      await tester.tap(button(cueRight ? 'start' : 'end'));
      await tester.pump();
      expect(prominentEscape(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('flying all the way up dismisses the alarm, once', (
      tester,
    ) async {
      phone(tester);
      final app = await ring(tester, gamesOnly('capy_rocket'));
      for (var i = 0; i < 8; i++) {
        await boostCued(tester);
      }
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(RingingScreen), findsNothing);
      final rows = await app.repository.listOccurrencesForAlarm('a1');
      expect(
        rows.where((o) => o.status == AlarmStatus.dismissed),
        hasLength(1),
      );
    });
  });

  group('authored games', () {
    int oddCell(WidgetTester tester) {
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

    Future<Map<String, bool>> usefulByName() async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      return {
        for (final item in MorningItem.values)
          morningItemName(l10n, item): item.useful,
      };
    }

    Future<int> sortCard(WidgetTester tester, {required bool useful}) async {
      final byName = await usefulByName();
      for (var i = 0; ; i++) {
        final card = find.byKey(ValueKey('morning-sort-card-$i'));
        final name = tester
            .widget<Text>(
              find.descendant(of: card, matching: find.byType(Text)),
            )
            .data!;
        final done = find
            .descendant(of: card, matching: find.byType(Icon))
            .evaluate()
            .isNotEmpty;
        if (byName[name] == useful && !done) return i;
      }
    }

    testWidgets('Find the Impostor launches on a card, escape beside it', (
      tester,
    ) async {
      await ring(tester, gamesOnly('find_the_impostor'));
      expect(tester.takeException(), isNull);
      expect(find.byType(FindTheImpostorView), findsOneWidget);
      expect(find.text('Stop without solving'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a matching Capy raises the escape at tolerance 0', (
      tester,
    ) async {
      await ring(tester, gamesOnly('find_the_impostor', tolerated: 0));
      final odd = oddCell(tester);
      expect(prominentEscape(), findsNothing);
      await tester.tap(
        find.byKey(ValueKey('find-the-impostor-cell-${odd == 0 ? 1 : 0}')),
      );
      await tester.pump();
      expect(prominentEscape(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('finding every odd Capy dismisses the alarm, once', (
      tester,
    ) async {
      final app = await ring(tester, gamesOnly('find_the_impostor'));
      for (var i = 0; i < 3; i++) {
        await tester.tap(
          find.byKey(ValueKey('find-the-impostor-cell-${oddCell(tester)}')),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(RingingScreen), findsNothing);
      final rows = await app.repository.listOccurrencesForAlarm('a1');
      expect(
        rows.where((o) => o.status == AlarmStatus.dismissed),
        hasLength(1),
      );
    });

    testWidgets('Morning Sort launches on a card, escape beside it', (
      tester,
    ) async {
      await ring(tester, gamesOnly('morning_sort'));
      expect(tester.takeException(), isNull);
      expect(find.byType(MorningSortView), findsOneWidget);
      expect(find.text('Stop without solving'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a decoy raises the escape at tolerance 0', (tester) async {
      await ring(tester, gamesOnly('morning_sort', tolerated: 0));
      expect(prominentEscape(), findsNothing);
      final decoy = await sortCard(tester, useful: false);
      await tester.tap(find.byKey(ValueKey('morning-sort-card-$decoy')));
      await tester.pump();
      expect(prominentEscape(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('packing every bag dismisses the alarm, once', (
      tester,
    ) async {
      final app = await ring(tester, gamesOnly('morning_sort'));
      for (var i = 0; i < 9; i++) {
        final card = await sortCard(tester, useful: true);
        await tester.tap(find.byKey(ValueKey('morning-sort-card-$card')));
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(RingingScreen), findsNothing);
      final rows = await app.repository.listOccurrencesForAlarm('a1');
      expect(
        rows.where((o) => o.status == AlarmStatus.dismissed),
        hasLength(1),
      );
    });
  });

  group('motion games', () {
    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    FakeMotionSensor sensorOf(ProviderContainer container) =>
        container.read(motionSensorProvider) as FakeMotionSensor;

    Future<void> dismissedOnce(
      WidgetTester tester,
      CapyWakeRepository repository,
    ) async {
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(RingingScreen), findsNothing);
      final rows = await repository.listOccurrencesForAlarm('a1');
      expect(
        rows.where((o) => o.status == AlarmStatus.dismissed),
        hasLength(1),
      );
    }

    testWidgets('Shake DJ launches on a card, escape beside it', (
      tester,
    ) async {
      final app = await ring(tester, gamesOnly('shake_dj'));
      expect(tester.takeException(), isNull);
      expect(find.byType(ShakeDjView), findsOneWidget);
      expect(find.text('Stop without solving'), findsOneWidget);
      expect(sensorOf(app.container).hasListener, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a stalled beat raises the escape at tolerance 0', (
      tester,
    ) async {
      phone(tester);
      await ring(tester, gamesOnly('shake_dj', tolerated: 0));
      expect(prominentEscape(), findsNothing);
      await tester.pump(ShakeDjRound.stallAfter);
      expect(prominentEscape(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('shaking the phone to the goal dismisses the alarm, once', (
      tester,
    ) async {
      phone(tester);
      final app = await ring(tester, gamesOnly('shake_dj'));
      final sensor = sensorOf(app.container);
      for (var i = 0; i < 30; i++) {
        sensor
          ..emit(const MotionSample(x: 0, y: 0, z: 22))
          ..emit(FakeMotionSensor.still);
        await tester.pump();
      }
      await dismissedOnce(tester, app.repository);
      expect(sensor.hasListener, isFalse);
    });

    testWidgets('Tilt Maze launches on a card, escape beside it', (
      tester,
    ) async {
      await ring(tester, gamesOnly('tilt_maze'));
      expect(tester.takeException(), isNull);
      expect(find.byType(TiltMazeView), findsOneWidget);
      expect(find.text('Stop without solving'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a wall raises the escape at tolerance 0', (tester) async {
      final handle = tester.ensureSemantics();
      phone(tester);
      await ring(tester, gamesOnly('tilt_maze', tolerated: 0));
      final wall = TiltDirection.values.firstWhere(
        (d) => tester.getSemantics(mazeArrow(d)).label.contains('wall'),
      );
      await tester.tap(mazeArrow(wall));
      await tester.pump();
      expect(prominentEscape(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      handle.dispose();
    });

    testWidgets('three mazes solved by ear dismiss the alarm, once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      phone(tester);
      final app = await ring(tester, gamesOnly('tilt_maze'));
      for (var maze = 0; maze < 3; maze++) {
        await solveMazeByEar(tester);
      }
      await dismissedOnce(tester, app.repository);
      handle.dispose();
    });
  });

  group('Step Quest', () {
    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    FakeStepSensor stepsOf(ProviderContainer container) =>
        container.read(stepSensorProvider) as FakeStepSensor;

    testWidgets('a ring never asks for step counting, nor opens the sensor '
        '(M5)', (tester) async {
      final app = await ring(
        tester,
        gamesOnly('step_quest'),
        stepAccess: DeviceAccess.needsPermission,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(StepQuestView), findsOneWidget);
      expect(find.text('Stop without solving'), findsOneWidget);
      expect(find.byType(DeviceAccessPrompt), findsNothing);
      final steps = stepsOf(app.container);
      expect(steps.requestCount, 0);
      expect(steps.listenCount, 0);
      expect(sensorOfMotion(app.container).hasListener, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a long pause raises the escape at tolerance 0', (
      tester,
    ) async {
      phone(tester);
      await ring(tester, gamesOnly('step_quest', tolerated: 0));
      expect(prominentEscape(), findsNothing);
      await tester.pump(StepQuestRound.stallAfter);
      expect(prominentEscape(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('walking to the goal on the step sensor dismisses, once', (
      tester,
    ) async {
      phone(tester);
      final app = await ring(
        tester,
        gamesOnly('step_quest'),
        stepAccess: DeviceAccess.ready,
      );
      final steps = stepsOf(app.container);
      expect(steps.hasListener, isTrue);
      for (var i = 0; i < 10; i++) {
        steps.emit(4);
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(RingingScreen), findsNothing);
      final rows = await app.repository.listOccurrencesForAlarm('a1');
      expect(
        rows.where((o) => o.status == AlarmStatus.dismissed),
        hasLength(1),
      );
      expect(steps.hasListener, isFalse);
    });
  });

  group('QR Treasure Hunt', () {
    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    FakeCodeScanner scannerOf(ProviderContainer container) =>
        container.read(codeScannerProvider) as FakeCodeScanner;

    FakeCameraAccess cameraOf(ProviderContainer container) =>
        container.read(cameraAccessProvider) as FakeCameraAccess;

    testWidgets('ready, it rings with the camera off until a tap (H1)', (
      tester,
    ) async {
      final app = await ring(
        tester,
        gamesOnly('qr_treasure_hunt'),
        cameraAccess: DeviceAccess.ready,
        checkpoint: 'MIRROR',
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QrTreasureHuntView), findsOneWidget);
      expect(find.text('Stop without solving'), findsOneWidget);
      expect(scannerOf(app.container).starts, 0);
      expect(cameraOf(app.container).requestCount, 0);
      await tester.pumpWidget(const SizedBox());
    });

    for (final (why, access, code) in [
      ('no checkpoint', DeviceAccess.ready, null),
      ('no camera grant', DeviceAccess.needsPermission, 'MIRROR'),
      ('no camera', DeviceAccess.unavailable, 'MIRROR'),
    ]) {
      testWidgets('with $why it never rings; a puzzle does', (tester) async {
        final app = await ring(
          tester,
          gamesOnly('qr_treasure_hunt'),
          cameraAccess: access,
          checkpoint: code,
        );
        expect(find.byType(QrTreasureHuntView), findsNothing);
        expect(find.byType(PuzzleView), findsOneWidget);
        expect(cameraOf(app.container).requestCount, 0, reason: 'no prompt');
        expect(scannerOf(app.container).starts, 0);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('a cold start waits for readiness, then rings without it '
        '(R2, R5)', (tester) async {
      final app = await pumpApp(
        tester,
        extra: [cameraAccessProvider.overrideWithValue(_SilentCamera())],
      );
      await app.repository.saveQrCheckpoint(
        QrCheckpoint.of('MIRROR', savedAt: clock),
      );
      await app.repository.upsertAlarm(
        _alarm(
          dismissMethod: DismissMethod.puzzle,
          puzzleOverride: gamesOnly('qr_treasure_hunt'),
        ),
      );
      await tester.pumpAndSettle();
      app.engine.fire('a1', firedAt: clock);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('challenge-pending')), findsOneWidget);
      expect(find.text('Stop without solving'), findsOneWidget);
      expect(find.byType(PuzzleView), findsNothing);
      await tester.pump(RingingHost.readinessWait);
      await tester.pump();
      expect(find.byKey(const ValueKey('challenge-pending')), findsNothing);
      expect(find.byType(PuzzleView), findsOneWidget);
      expect(find.byType(QrTreasureHuntView), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a wrong code raises the escape at tolerance 0', (
      tester,
    ) async {
      phone(tester);
      final app = await ring(
        tester,
        gamesOnly('qr_treasure_hunt', tolerated: 0),
        cameraAccess: DeviceAccess.ready,
        checkpoint: 'MIRROR',
      );
      await tester.tap(find.byKey(const ValueKey('qr-hunt-scan')));
      await tester.pump();
      scannerOf(app.container).show('COFFEE');
      await tester.pump();
      expect(prominentEscape(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('scanning the checkpoint dismisses the alarm, once', (
      tester,
    ) async {
      phone(tester);
      final app = await ring(
        tester,
        gamesOnly('qr_treasure_hunt'),
        cameraAccess: DeviceAccess.ready,
        checkpoint: 'MIRROR',
      );
      final scanner = scannerOf(app.container);
      await tester.tap(find.byKey(const ValueKey('qr-hunt-scan')));
      await tester.pump();
      scanner
        ..show('MIRROR')
        ..show('MIRROR');
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(RingingScreen), findsNothing);
      final rows = await app.repository.listOccurrencesForAlarm('a1');
      expect(
        rows.where((o) => o.status == AlarmStatus.dismissed),
        hasLength(1),
      );
      expect(scanner.isLive, isFalse);
    });
  });

  const allGames = [
    'catch_the_capy',
    'memory_hideout',
    'rhythm_rescue',
    'capy_rocket',
    'morning_sort',
    'find_the_impostor',
    'shake_dj',
    'tilt_maze',
    'step_quest',
    'qr_treasure_hunt',
  ];

  Future<({Rect clock, Rect card})> ringOn(
    WidgetTester tester,
    String game, {
    required Size size,
    required double ratio,
    required double top,
    required double bottom,
  }) async {
    tester.view.physicalSize = size * ratio;
    tester.view.devicePixelRatio = ratio;
    tester.view.padding = FakeViewPadding(
      top: top * ratio,
      bottom: bottom * ratio,
    );
    addTearDown(tester.view.reset);
    await ring(
      tester,
      gamesOnly(game),
      cameraAccess: DeviceAccess.ready,
      checkpoint: 'MIRROR',
    );
    final clock = tester.getRect(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Clock'),
    );
    final card = tester.getRect(
      find
          .ancestor(
            of: find.byType(GameHeader),
            matching: find.byType(CapyCard),
          )
          .first,
    );
    await tester.pumpWidget(const SizedBox());
    return (clock: clock, card: card);
  }

  for (final game in allGames) {
    testWidgets('$game on the reference phone never covers the clock', (
      tester,
    ) async {
      final at = await ringOn(
        tester,
        game,
        size: const Size(393, 852),
        ratio: 3,
        top: 47,
        bottom: 34,
      );
      expect(at.card.top, greaterThan(at.clock.bottom), reason: game);
    });
  }

  // On a 375 x 667 phone Catch the Capy already reaches over the clock's
  // foot; until the owner settles that trade-off, no game may reach further.
  testWidgets('on a small phone no game reaches higher than Catch the Capy', (
    tester,
  ) async {
    final tops = <String, double>{};
    for (final game in allGames) {
      final at = await ringOn(
        tester,
        game,
        size: const Size(375, 667),
        ratio: 2,
        top: 20,
        bottom: 0,
      );
      tops[game] = at.card.top;
    }
    for (final game in allGames) {
      expect(
        tops[game],
        greaterThanOrEqualTo(tops['catch_the_capy']! - 0.5),
        reason: game,
      );
    }
  });
}

/// A camera whose access is never answered, as on a slow cold start.
class _SilentCamera extends FakeCameraAccess {
  @override
  Future<DeviceAccess> access() => Completer<DeviceAccess>().future;
}
