import 'package:capywake/app/app.dart';
import 'package:capywake/app/router.dart';
import 'package:capywake/core/engine/fake_alarm_engine.dart';
import 'package:capywake/core/games/memory_hideout.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/alarm_puzzle_override.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/features/games/capy_rocket_view.dart';
import 'package:capywake/features/games/catch_the_capy_view.dart';
import 'package:capywake/features/games/game_header.dart';
import 'package:capywake/features/games/game_win_celebration.dart';
import 'package:capywake/features/games/memory_hideout_view.dart';
import 'package:capywake/features/games/rhythm_rescue_view.dart';
import 'package:capywake/features/ringing/puzzle_view.dart';
import 'package:capywake/features/ringing/ringing_providers.dart';
import 'package:capywake/features/ringing/ringing_screen.dart';
import 'package:capywake/features/ringing/ringing_win_overlay.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata;

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
  pumpApp(WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final engine = FakeAlarmEngine(now: () => clock);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        alarmEngineProvider.overrideWithValue(engine),
        engineNowProvider.overrideWithValue(() => clock),
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
  ring(WidgetTester tester, AlarmPuzzleOverride override) async {
    final app = await pumpApp(tester);
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

  const fourGames = [
    'catch_the_capy',
    'memory_hideout',
    'rhythm_rescue',
    'capy_rocket',
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
    await ring(tester, gamesOnly(game));
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

  for (final game in fourGames) {
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
    for (final game in fourGames) {
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
    for (final game in fourGames) {
      expect(
        tops[game],
        greaterThanOrEqualTo(tops['catch_the_capy']! - 0.5),
        reason: game,
      );
    }
  });
}
