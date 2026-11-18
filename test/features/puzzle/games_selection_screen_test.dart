import 'package:capywake/app/router.dart';
import 'package:capywake/core/camera/fake_camera_access.dart';
import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/motion/fake_step_sensor.dart';
import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/features/games/game_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'puzzle_harness.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  PuzzleSettings? seed,
  StepSensor? steps,
  FakeCameraAccess? camera,
  bool checkpoint = false,
}) => pumpPuzzleRoute(
  tester,
  Routes.settingsPuzzleGames,
  seed: seed,
  steps: steps,
  camera: camera,
  checkpoint: checkpoint,
);

Future<PuzzleSettings> _saved(ProviderContainer c) => savedPuzzleSettings(c);

Future<void> _flip(WidgetTester tester, String label) async {
  await tester.ensureVisible(toggleLabelled(label));
  await tester.pumpAndSettle();
  await tester.tap(toggleLabelled(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists every playable game, in catalogue order', (tester) async {
    await _pump(tester);
    final l10n = puzzleL10n(tester);
    final names = [for (final g in GameCatalogue.playable) gameName(l10n, g)];
    final toggles = tester
        .widgetList<CapyToggle>(find.byType(CapyToggle))
        .map((t) => t.semanticLabel)
        .toList();
    expect(toggles, names);
    expect(find.text(l10n.challengePuzzlesLabel), findsNothing);
  });

  testWidgets('enabling a game persists it', (tester) async {
    final c = await _pump(tester);
    await _flip(tester, 'Catch the Capy');
    expect((await _saved(c)).enabledGames, {'catch_the_capy'});
  });

  testWidgets('the last pool member is locked, with the reason (H1)', (
    tester,
  ) async {
    final c = await _pump(
      tester,
      seed: PuzzleSettings(
        enabledTypes: const {PuzzleType.arithmetic},
        enabledGames: const {'memory_hideout'},
        includePuzzles: false,
      ),
    );
    final l10n = puzzleL10n(tester);
    final reason = l10n.challengePoolFloorReason;
    final locked = toggleLabelled('Memory Hideout. $reason');
    expect(locked, findsOneWidget);
    expect(tester.widget<CapyToggle>(locked).onChanged, isNull);
    expect(find.text(reason), findsOneWidget);
    await tester.tap(locked);
    await tester.pumpAndSettle();
    expect((await _saved(c)).enabledGames, {'memory_hideout'});
  });

  testWidgets('the locked game links to Puzzle types', (tester) async {
    await _pump(
      tester,
      seed: PuzzleSettings(
        enabledTypes: const {PuzzleType.arithmetic},
        enabledGames: const {'memory_hideout'},
        includePuzzles: false,
      ),
    );
    final l10n = puzzleL10n(tester);
    await showAndTap(tester, find.text(l10n.puzzleSettingsTypesLabel));
    expect(find.text(l10n.puzzleTypesHelp), findsOneWidget);
  });

  testWidgets('with puzzles in the pool, no game is locked', (tester) async {
    await _pump(
      tester,
      seed: PuzzleSettings(
        enabledTypes: const {PuzzleType.arithmetic},
        enabledGames: const {'memory_hideout'},
      ),
    );
    expect(
      find.text(puzzleL10n(tester).challengePoolFloorReason),
      findsNothing,
    );
    expect(
      tester.widget<CapyToggle>(toggleLabelled('Memory Hideout')).onChanged,
      isNotNull,
    );
  });

  testWidgets('Try it opens practice for that game', (tester) async {
    await _pump(tester);
    final tryIt = find.byWidgetPredicate(
      (w) => w is Text && w.semanticsLabel == 'Try it, Shake DJ',
    );
    await tester.ensureVisible(tryIt);
    await tester.pumpAndSettle();
    await tester.tap(tryIt);
    await tester.pumpAndSettle();
    expect(find.text('practice:shake_dj'), findsOneWidget);
  });

  testWidgets('a screen reader can flip a switch (tap action)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final c = await _pump(tester);
    final node = tester.getSemantics(toggleLabelled('Shake DJ'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect((await _saved(c)).enabledGames, contains('shake_dj'));
    handle.dispose();
  });

  group('switching Step Quest on offers the step sensor', () {
    final sheet = find.byKey(const ValueKey('step-access-sheet'));

    testWidgets('after the switch is saved, never instead of it (M4)', (
      tester,
    ) async {
      final steps = FakeStepSensor(current: DeviceAccess.needsPermission);
      final c = await _pump(tester, steps: steps);
      await _flip(tester, 'Step Quest');
      expect(sheet, findsOneWidget);
      expect((await _saved(c)).enabledGames, contains('step_quest'));
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(steps.requestCount, 0);
      expect((await _saved(c)).enabledGames, contains('step_quest'));
    });

    testWidgets('Allow shows the OS prompt and closes', (tester) async {
      final steps = FakeStepSensor(
        current: DeviceAccess.needsPermission,
        afterRequest: DeviceAccess.ready,
      );
      await _pump(tester, steps: steps);
      await _flip(tester, 'Step Quest');
      await tester.tap(find.text('Allow step counting'));
      await tester.pumpAndSettle();
      expect(steps.requestCount, 1);
      expect(sheet, findsNothing);
    });

    testWidgets('Open Settings closes the sheet', (tester) async {
      final steps = FakeStepSensor(current: DeviceAccess.permanentlyDenied);
      await _pump(tester, steps: steps);
      await _flip(tester, 'Step Quest');
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(steps.settingsCount, 1);
      expect(sheet, findsNothing);
    });

    testWidgets('nothing is offered when there is nothing to ask', (
      tester,
    ) async {
      for (final access in [DeviceAccess.ready, DeviceAccess.unavailable]) {
        await _pump(tester, steps: FakeStepSensor(current: access));
        await _flip(tester, 'Step Quest');
        expect(sheet, findsNothing, reason: access.name);
      }
    });

    testWidgets('switching it off, or another game on, offers nothing', (
      tester,
    ) async {
      final steps = FakeStepSensor(current: DeviceAccess.needsPermission);
      await _pump(
        tester,
        steps: steps,
        seed: PuzzleSettings(
          enabledTypes: const {PuzzleType.arithmetic},
          enabledGames: const {'step_quest'},
        ),
      );
      await _flip(tester, 'Step Quest');
      expect(sheet, findsNothing);
      await _flip(tester, 'Shake DJ');
      expect(sheet, findsNothing);
    });
  });

  group('switching QR Treasure Hunt on offers the checkpoint setup', () {
    final sheet = find.byKey(const ValueKey('qr-setup-sheet'));

    testWidgets('not ready: the switch is saved, then the sheet (M7)', (
      tester,
    ) async {
      final c = await _pump(tester);
      await _flip(tester, 'QR Treasure Hunt');
      expect(sheet, findsOneWidget);
      expect(
        find.textContaining('Alarms skip QR Treasure Hunt'),
        findsOneWidget,
      );
      expect((await _saved(c)).enabledGames, contains('qr_treasure_hunt'));
      await tester.tap(find.text('Set a checkpoint'));
      await tester.pumpAndSettle();
      expect(find.text('practice:qr_treasure_hunt'), findsOneWidget);
    });

    testWidgets('Not now closes it', (tester) async {
      await _pump(tester);
      await _flip(tester, 'QR Treasure Hunt');
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
    });

    testWidgets('ready: nothing is offered', (tester) async {
      await _pump(
        tester,
        camera: FakeCameraAccess(current: DeviceAccess.ready),
        checkpoint: true,
      );
      await _flip(tester, 'QR Treasure Hunt');
      expect(sheet, findsNothing);
    });
  });
}
