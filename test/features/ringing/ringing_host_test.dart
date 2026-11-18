import 'package:capywake/app/app.dart';
import 'package:capywake/app/router.dart';
import 'package:capywake/core/engine/fake_alarm_engine.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/alarm_puzzle_override.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/capy_nav_bar.dart';
import 'package:capywake/features/ringing/puzzle_view.dart';
import 'package:capywake/features/ringing/ringing_host.dart';
import 'package:capywake/features/ringing/ringing_providers.dart';
import 'package:capywake/features/ringing/ringing_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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

  testWidgets('no ringing surface is shown when nothing is ringing', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(RingingScreen), findsNothing);
  });

  testWidgets('a platform ring puts the surface over the app', (tester) async {
    final app = await pumpApp(tester);
    await app.repository.upsertAlarm(_alarm());
    await tester.pumpAndSettle();

    app.engine.fire('a1', firedAt: clock);
    await tester.pumpAndSettle();

    expect(find.byType(RingingScreen), findsOneWidget);
  });

  testWidgets('dismissing it takes the surface away', (tester) async {
    final app = await pumpApp(tester);
    await app.repository.upsertAlarm(_alarm());
    await tester.pumpAndSettle();

    app.engine.fire('a1', firedAt: clock);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop alarm'));
    await tester.pumpAndSettle();

    expect(find.byType(RingingScreen), findsNothing);
  });

  testWidgets('the ringing clock follows the saved clock preference', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await app.repository.saveSettings(
      UserSettings.initial.copyWith(timeFormat: TimeFormatPreference.h24),
    );
    await app.repository.upsertAlarm(_alarm());
    await tester.pumpAndSettle();

    app.engine.fire('a1', firedAt: clock);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(RingingScreen),
        matching: find.text('07:00'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the app beneath a ring stays live', (tester) async {
    final app = await pumpApp(tester);
    await app.repository.upsertAlarm(_alarm());
    await tester.pumpAndSettle();
    final beneath = find.byType(Scaffold).first;

    app.engine.fire('a1', firedAt: clock);
    await tester.pumpAndSettle();

    expect(
      TickerMode.valuesOf(tester.element(beneath)).enabled,
      isTrue,
      reason: 'muting it pauses the shell watch that keeps alarms armed',
    );
  });

  testWidgets(
    'a puzzle alarm shows a puzzle and the escape, not a plain stop',
    (tester) async {
      final app = await pumpApp(tester);
      await app.repository.upsertAlarm(
        _alarm(dismissMethod: DismissMethod.puzzle),
      );
      await tester.pumpAndSettle();

      app.engine.fire('a1', firedAt: clock);
      await tester.pumpAndSettle();

      expect(find.byType(PuzzleView), findsOneWidget);
      expect(find.text('Stop alarm'), findsNothing);
      expect(find.text('Stop without solving'), findsOneWidget);
    },
  );

  test('the renderable set is never empty', () {
    expect(RingingHost.renderableTypes, isNotEmpty);
  });

  test(
    'a visual-only override leaves nothing drawable, so the host falls back',
    () {
      final settings = PuzzleSettings(
        enabledTypes: const {PuzzleType.gridPatternRecall},
      );

      expect(
        settings.enabledTypes.intersection(RingingHost.renderableTypes),
        isEmpty,
        reason: 'the fallback path in _renderableSettings is reachable',
      );
    },
  );

  group('self-review #1 probes', () {
    testWidgets('confirmAndHold needs a hold, not a tap', (tester) async {
      final app = await pumpApp(tester);
      await app.repository.upsertAlarm(
        _alarm(
          dismissMethod: DismissMethod.puzzle,
          puzzleOverride: AlarmPuzzleOverride(
            escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
          ),
        ),
      );
      await tester.pumpAndSettle();

      app.engine.fire('a1', firedAt: clock);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop without solving'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stop the alarm'));
      await tester.pumpAndSettle();
      expect(
        find.byType(RingingScreen),
        findsOneWidget,
        reason: 'a tap must not complete the stricter escape',
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Stop the alarm')),
      );
      await tester.pump(const Duration(milliseconds: 1400));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(RingingScreen), findsNothing);
    });

    testWidgets('wrong answers past the tolerance make the escape prominent', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await app.repository.upsertAlarm(
        _alarm(
          dismissMethod: DismissMethod.puzzle,
          puzzleOverride: AlarmPuzzleOverride(
            toleratedWrongAnswers: 0,
            enabledTypes: const {PuzzleType.arithmetic},
          ),
        ),
      );
      await tester.pumpAndSettle();

      app.engine.fire('a1', firedAt: clock);
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.text('Stop without solving'),
          matching: find.byType(CapyButton),
        ),
        findsNothing,
        reason: 'it starts available, not prominent',
      );

      await tester.enterText(find.byType(TextField), '999999');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.text('Stop without solving'),
          matching: find.byType(CapyButton),
        ),
        findsOneWidget,
        reason: 'past the tolerance the escape must stand out',
      );
    });

    testWidgets('an all-unrenderable alarm still shows a solvable puzzle', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await app.repository.upsertAlarm(
        _alarm(
          dismissMethod: DismissMethod.puzzle,
          puzzleOverride: AlarmPuzzleOverride(
            enabledTypes: const {PuzzleType.gridPatternRecall},
          ),
        ),
      );
      await tester.pumpAndSettle();

      app.engine.fire('a1', firedAt: clock);
      await tester.pumpAndSettle();

      expect(find.byType(PuzzleView), findsOneWidget);
      expect(find.text('Stop without solving'), findsOneWidget);
    });
  });

  group('self-review #2 probes', () {
    testWidgets('nothing animates on the composed puzzle surface', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await app.repository.upsertAlarm(
        _alarm(
          dismissMethod: DismissMethod.puzzle,
          puzzleOverride: AlarmPuzzleOverride(
            enabledTypes: const {PuzzleType.arithmetic},
          ),
        ),
      );
      await tester.pumpAndSettle();

      app.engine.fire('a1', firedAt: clock);
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleView), findsOneWidget);
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'CLAUDE.md forbids animation on the ringing surface',
      );

      await tester.enterText(find.byType(TextField), '999999');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'regenerating the puzzle must not introduce one either',
      );
    });

    testWidgets('a frame-local promotion is also recorded on the controller', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await app.repository.upsertAlarm(
        _alarm(
          dismissMethod: DismissMethod.puzzle,
          puzzleOverride: AlarmPuzzleOverride(
            toleratedWrongAnswers: 0,
            enabledTypes: const {PuzzleType.arithmetic},
          ),
        ),
      );
      await tester.pumpAndSettle();

      app.engine.fire('a1', firedAt: clock);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '999999');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(
        app.container
            .read(ringingControllerProvider)
            .currentSession
            ?.escapeVisibility,
        PuzzleEscapeVisibility.prominent,
        reason: 'the screen and the controller must not drift apart',
      );
    });

    testWidgets('the ringing surface blocks the app beneath it', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await app.repository.upsertAlarm(_alarm());
      await tester.pumpAndSettle();

      app.engine.fire('a1', firedAt: clock);
      await tester.pumpAndSettle();

      // The nav bar is still mounted underneath. Hit-testing at its icon
      // must reach the ringing surface, not the tab behind it.
      final navIcon = find
          .descendant(
            of: find.byType(CapyNavBar),
            matching: find.byIcon(Icons.bar_chart_rounded),
          )
          .first;
      final hit = tester.hitTestOnBinding(tester.getCenter(navIcon));
      final reachesNavBar = hit.path.any(
        (e) => e.target is RenderBox && _isUnder(tester, e.target, navIcon),
      );

      expect(
        reachesNavBar,
        isFalse,
        reason: 'a stray tap must not reach the app behind the alarm',
      );
    });
  });
}

/// Whether [target] belongs to the subtree [finder] names.
bool _isUnder(WidgetTester tester, Object target, Finder finder) {
  final box = tester.renderObject(finder);
  var node = target;
  while (node is RenderObject) {
    if (identical(node, box)) return true;
    final parent = node.parent;
    if (parent == null) return false;
    node = parent;
  }
  return false;
}
