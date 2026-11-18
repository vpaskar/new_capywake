import 'dart:async';
import 'dart:io';

import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/games/step_quest.dart';
import 'package:capywake/core/motion/fake_motion_sensor.dart';
import 'package:capywake/core/motion/fake_step_sensor.dart';
import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/core/motion/step_tally.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:capywake/features/games/step_quest_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../core/motion/_walk.dart';
import '_motion.dart';
import '_pump.dart';

final Finder _step = find.byKey(const ValueKey('step-quest-step'));
final Finder _capy = find.byKey(const ValueKey('step-quest-capy'));
final Finder _source = find.byKey(const ValueKey('step-quest-source'));

const _sensorCaption = 'Counted by your step sensor';
const _motionCaption = 'Counted from motion';

typedef _Calls = ({List<GameChallenge> progress, List<int> completed});

Future<_Calls> _pump(
  WidgetTester tester, {
  MotionSensor? motion,
  StepSensor? steps,
  PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
  bool reduceMotion = true,
  bool accessibleNavigation = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  bool inRingingSlot = false,
  Size size = const Size(393, 852),
}) async {
  final progress = <GameChallenge>[];
  final completed = <int>[];
  final view = StepQuestView(
    difficulty: difficulty,
    motion: motion ?? FakeMotionSensor(),
    steps: steps ?? FakeStepSensor(),
    onProgress: progress.add,
    onCompleted: () => completed.add(1),
    reduceMotion: reduceMotion,
  );
  await pumpInApp(
    tester,
    inRingingSlot ? ringingSlotWidth(view) : view,
    accessibleNavigation: accessibleNavigation,
    textScale: textScale,
    brightness: brightness,
    locale: locale,
    size: size,
  );
  return (progress: progress, completed: completed);
}

Future<void> _walk(
  WidgetTester tester,
  FakeMotionSensor motion, {
  required int steps,
  int startMs = 0,
}) async {
  for (final sample in walk(steps: steps, startMs: startMs)) {
    motion.emit(sample);
  }
  await tester.pump();
  await tester.pump();
}

Future<void> _sensorSteps(
  WidgetTester tester,
  FakeStepSensor sensor,
  int count,
) async {
  sensor.emit(count);
  await tester.pump();
  await tester.pump();
}

String? _outcome(WidgetTester tester) =>
    tester.widget<GameOutcomeLine>(find.byType(GameOutcomeLine)).text;

/// A step sensor whose access answer arrives only when the test says so.
class _SlowStepSensor extends FakeStepSensor {
  _SlowStepSensor() : super(current: DeviceAccess.ready);

  final answer = Completer<DeviceAccess>();

  @override
  Future<DeviceAccess> access() => answer.future;
}

String _caption(WidgetTester tester) => tester.widget<Text>(_source).data!;

void main() {
  testWidgets('shows the goal, the count, the button and the counter used', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.text('Walk with the phone to move Capy.'),
      findsOneWidget,
    );
    expect(find.text('0 / 20 steps'), findsOneWidget);
    expect(find.text('0 / 4'), findsOneWidget);
    expect(find.text('Take a step'), findsOneWidget);
    expect(_caption(tester), _motionCaption);
    expect(_outcome(tester), isNull);
  });

  testWidgets('the step button is a game control, not a twin of Snooze', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.descendant(
        of: find.byType(StepQuestView),
        matching: find.byType(CapyButton),
      ),
      findsNothing,
    );
    final size = tester.getSize(_step);
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThan(200));
  });

  testWidgets('a screen-reader user finishes by the button alone', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final calls = await _pump(tester, accessibleNavigation: true);
    for (var i = 0; i < 20; i++) {
      tester.semantics.tap(find.semantics.byLabel('Take a step'));
      await tester.pump();
    }
    expect(calls.completed, [1]);
    handle.dispose();
  });

  testWidgets('the button walks, and finishing reports once and lets go', (
    tester,
  ) async {
    final motion = FakeMotionSensor();
    final steps = FakeStepSensor(current: DeviceAccess.ready);
    final calls = await _pump(tester, motion: motion, steps: steps);
    for (var i = 0; i < 25; i++) {
      await tester.tap(_step);
      await tester.pump();
    }
    expect(calls.progress, hasLength(20));
    expect(calls.progress.last.isComplete, isTrue);
    expect(calls.completed, [1]);
    expect(find.text('20 / 20 steps'), findsOneWidget);
    expect(motion.hasListener, isFalse, reason: 'no accelerometer after');
    expect(steps.hasListener, isFalse, reason: 'no step sensor after');
    await tester.pump(StepQuestRound.stallAfter * 2);
    expect(calls.progress, hasLength(20), reason: 'no stall after the win');
  });

  group('the accelerometer counts when there is no step sensor', () {
    testWidgets('a walk moves Capy along, four at a time at first', (
      tester,
    ) async {
      final motion = FakeMotionSensor();
      final calls = await _pump(tester, motion: motion);
      await _walk(tester, motion, steps: 3);
      expect(calls.progress, isEmpty, reason: 'three steps are not a walk');
      await _walk(tester, motion, steps: 3, startMs: 1500);
      expect(calls.progress.map((c) => c.completed), [4, 5, 6]);
      expect(find.text('6 / 20 steps'), findsOneWidget);
      expect(calls.progress.last.requiresMotion, isTrue);
    });

    testWidgets('a failing accelerometer is ignored; the button works', (
      tester,
    ) async {
      final motion = FailingMotionSensor();
      final calls = await _pump(tester, motion: motion);
      motion.fail();
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(_step);
      await tester.pump();
      expect(calls.progress.single.completed, 1);
    });
  });

  group('the step sensor', () {
    testWidgets('counts once access is ready, and the accelerometer stops '
        'after its first delivery (M1)', (tester) async {
      final motion = FakeMotionSensor();
      final steps = FakeStepSensor(current: DeviceAccess.ready);
      final calls = await _pump(tester, motion: motion, steps: steps);
      expect(steps.hasListener, isTrue);
      expect(_caption(tester), _sensorCaption);
      expect(motion.hasListener, isTrue, reason: 'it watches the sensor');
      await _sensorSteps(tester, steps, 3);
      expect(calls.progress.single.completed, 3);
      expect(motion.hasListener, isFalse);
      await _sensorSteps(tester, steps, 2);
      expect(find.text('5 / 20 steps'), findsOneWidget);
    });

    for (final access in [
      DeviceAccess.needsPermission,
      DeviceAccess.permanentlyDenied,
      DeviceAccess.unavailable,
    ]) {
      testWidgets('is never opened when access is ${access.name} (H1)', (
        tester,
      ) async {
        final steps = FakeStepSensor(current: access);
        await _pump(tester, steps: steps);
        await tester.tap(_step);
        await tester.pump(const Duration(seconds: 1));
        expect(steps.listenCount, 0);
        expect(steps.requestCount, 0, reason: 'a game never prompts');
        expect(_caption(tester), _motionCaption);
      });
    }

    testWidgets('accelerometer steps are not doubled while it counts', (
      tester,
    ) async {
      final motion = FakeMotionSensor();
      final steps = FakeStepSensor(current: DeviceAccess.ready);
      final calls = await _pump(tester, motion: motion, steps: steps);
      await _walk(tester, motion, steps: 6);
      expect(calls.progress, isEmpty);
      await _sensorSteps(tester, steps, 6);
      expect(calls.progress.single.completed, 6);
    });

    testWidgets('a failed stream hands over to the accelerometer at once '
        '(H2)', (tester) async {
      final motion = FakeMotionSensor();
      final steps = FakeStepSensor(current: DeviceAccess.ready);
      final calls = await _pump(tester, motion: motion, steps: steps);
      await _sensorSteps(tester, steps, 2);
      expect(motion.hasListener, isFalse);
      steps.fail();
      await tester.pump();
      await tester.pump();
      expect(_caption(tester), _motionCaption);
      expect(steps.hasListener, isFalse);
      expect(motion.hasListener, isTrue);
      await _walk(tester, motion, steps: 4, startMs: 5000);
      expect(calls.progress.last.completed, 6);
    });

    testWidgets('a stream that closes is a failure too', (tester) async {
      final steps = FakeStepSensor(current: DeviceAccess.ready);
      await _pump(tester, steps: steps);
      await steps.close();
      await tester.pump();
      expect(_caption(tester), _motionCaption);
    });

    testWidgets('silent for 16 steps, it is dropped and the steps are kept', (
      tester,
    ) async {
      final motion = FakeMotionSensor();
      final steps = FakeStepSensor(current: DeviceAccess.ready);
      final calls = await _pump(tester, motion: motion, steps: steps);
      await _walk(tester, motion, steps: StepTally.defaultDemoteAfter - 1);
      expect(calls.progress, isEmpty);
      expect(_caption(tester), _sensorCaption);
      await _walk(tester, motion, steps: 1, startMs: 7500);
      expect(
        calls.progress.single.completed,
        StepTally.defaultDemoteAfter,
      );
      expect(_caption(tester), _motionCaption);
      expect(steps.hasListener, isFalse);
    });

    testWidgets('allowed mid-round, it takes over at once, keeping every '
        'step (H3)', (tester) async {
      final steps = FakeStepSensor(
        current: DeviceAccess.needsPermission,
        afterRequest: DeviceAccess.ready,
      );
      final calls = await _pump(tester, steps: steps);
      await tester.tap(_step);
      await tester.pump();
      await steps.requestAccess();
      await tester.pump();
      expect(steps.hasListener, isTrue);
      await _sensorSteps(tester, steps, 2);
      expect(calls.progress.last.completed, 3);
    });

    testWidgets('a rebuild does not read access again (review #6)', (
      tester,
    ) async {
      final steps = FakeStepSensor(current: DeviceAccess.needsPermission);
      final calls = await _pump(tester, steps: steps);
      expect(steps.accessCount, 1);
      for (var i = 0; i < 5; i++) {
        await tester.tap(_step);
        await tester.pump();
      }
      await _pump(tester, steps: steps);
      expect(calls.progress, hasLength(5));
      expect(steps.accessCount, 1);
    });

    testWidgets('after a demotion, resuming reads nothing', (tester) async {
      final steps = FakeStepSensor(current: DeviceAccess.ready);
      await _pump(tester, steps: steps);
      steps.fail();
      await tester.pump();
      await tester.pump();
      expect(steps.accessCount, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(steps.accessCount, 1);
      expect(steps.listenCount, 1);
    });

    testWidgets('allowed in Settings, it takes over when the app resumes', (
      tester,
    ) async {
      final steps = FakeStepSensor(current: DeviceAccess.permanentlyDenied);
      await _pump(tester, steps: steps);
      steps.current = DeviceAccess.ready;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(steps.hasListener, isTrue);
      expect(_caption(tester), _sensorCaption);
    });

    testWidgets('a new step sensor on rebuild is heard; the old one let go', (
      tester,
    ) async {
      final first = FakeStepSensor(current: DeviceAccess.ready);
      final second = FakeStepSensor(current: DeviceAccess.ready);
      final calls = await _pump(tester, steps: first);
      await _pump(tester, steps: second);
      expect(first.hasListener, isFalse);
      expect(second.hasListener, isTrue);
      await _sensorSteps(tester, first, 3);
      expect(calls.progress, isEmpty);
    });

    testWidgets('changing the counter does not move the button', (
      tester,
    ) async {
      final steps = FakeStepSensor(current: DeviceAccess.ready);
      for (final locale in const [Locale('en'), Locale('de')]) {
        await _pump(tester, steps: steps, locale: locale, textScale: 2);
        final top = tester.getTopLeft(_step).dy;
        steps.fail();
        await tester.pump();
        expect(tester.getTopLeft(_step).dy, top);
      }
    });
  });

  testWidgets('each step is spoken: the count is a live region', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    await tester.tap(_step);
    await tester.pump();
    final count = find.semantics.byLabel('1 / 20 steps');
    expect(count, findsOne);
    expect(
      count.evaluate().single.getSemanticsData().flagsCollection.isLiveRegion,
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('a sensor swapped while its access is read is still read', (
    tester,
  ) async {
    final slow = _SlowStepSensor();
    final ready = FakeStepSensor(current: DeviceAccess.ready);
    await _pump(tester, steps: slow);
    await _pump(tester, steps: ready);
    slow.answer.complete(DeviceAccess.ready);
    await tester.pump();
    expect(slow.hasListener, isFalse);
    expect(ready.hasListener, isTrue);
  });

  testWidgets('a proven sensor swapped for none hands back to motion', (
    tester,
  ) async {
    final motion = FakeMotionSensor();
    final steps = FakeStepSensor(current: DeviceAccess.ready);
    await _pump(tester, motion: motion, steps: steps);
    await _sensorSteps(tester, steps, 2);
    expect(motion.hasListener, isFalse);
    await _pump(tester, motion: motion, steps: FakeStepSensor());
    expect(motion.hasListener, isTrue);
    expect(_caption(tester), _motionCaption);
  });

  testWidgets('fifteen quiet seconds stall: a struggle, nothing lost', (
    tester,
  ) async {
    final calls = await _pump(tester);
    await tester.pump(StepQuestRound.stallAfter - const Duration(seconds: 1));
    expect(calls.progress, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(calls.progress.single.struggleCount, 1);
    expect(_outcome(tester), 'Capy is waiting. Walk or tap.');
    await tester.tap(_step);
    await tester.pump();
    expect(_outcome(tester), isNull);
    expect(calls.progress.last.completed, 1);
  });

  testWidgets('disposing stops both sensors and the stall clock', (
    tester,
  ) async {
    final motion = FakeMotionSensor();
    final steps = FakeStepSensor(current: DeviceAccess.ready);
    final calls = await _pump(tester, motion: motion, steps: steps);
    await tester.pumpWidget(const SizedBox());
    expect(motion.hasListener, isFalse);
    expect(steps.hasListener, isFalse);
    await tester.pump(StepQuestRound.stallAfter * 2);
    expect(calls.progress, isEmpty);
  });

  testWidgets('a new accelerometer on rebuild is heard; the old let go', (
    tester,
  ) async {
    final first = FakeMotionSensor();
    final second = FakeMotionSensor();
    await _pump(tester, motion: first);
    await _pump(tester, motion: second);
    expect(first.hasListener, isFalse);
    expect(second.hasListener, isTrue);
  });

  testWidgets('Capy walks from the start edge toward the end edge', (
    tester,
  ) async {
    await _pump(tester);
    final start = tester.getCenter(_capy).dx;
    for (var i = 0; i < 10; i++) {
      await tester.tap(_step);
    }
    await tester.pump();
    expect(tester.getCenter(_capy).dx, greaterThan(start));
  });

  testWidgets('right-to-left, Capy walks the other way, facing it', (
    tester,
  ) async {
    await _pump(tester, locale: const Locale('ar'));
    final start = tester.getCenter(_capy).dx;
    for (var i = 0; i < 10; i++) {
      await tester.tap(_step);
    }
    await tester.pump();
    expect(tester.getCenter(_capy).dx, lessThan(start));
    expect(
      tester
          .widget<Transform>(
            find.ancestor(of: _capy, matching: find.byType(Transform)).first,
          )
          .transform
          .storage[0],
      -1,
    );
  });

  group('moving', () {
    testWidgets('a step lifts Capy and glides it on', (tester) async {
      await _pump(tester, reduceMotion: false);
      final rest = tester.getTopLeft(_capy).dy;
      await tester.tap(_step);
      await tester.pump();
      await tester.pump(StepQuestView.stride * 0.5);
      expect(tester.getTopLeft(_capy).dy, lessThan(rest));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_capy).dy, closeTo(rest, 0.01));
    });

    testWidgets('with a screen reader nothing moves', (tester) async {
      await _pump(tester, reduceMotion: false, accessibleNavigation: true);
      await tester.tap(_step);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('turning a screen reader on mid-stride stops it', (
      tester,
    ) async {
      final motion = FakeMotionSensor();
      final steps = FakeStepSensor();
      await _pump(tester, motion: motion, steps: steps, reduceMotion: false);
      await tester.tap(_step);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isTrue);
      await _pump(
        tester,
        motion: motion,
        steps: steps,
        reduceMotion: false,
        accessibleNavigation: true,
      );
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('under reduce-motion a step animates nothing', (tester) async {
    await _pump(tester);
    await tester.tap(_step);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Capy is drawn no larger than its pixels allow', (
    tester,
  ) async {
    await _pump(tester);
    final file = img.decodeWebP(
      File(CapyArt.byId('game.capy.hiking').path).readAsBytesSync(),
    )!;
    expect(
      tester.getSize(_capy).width * 3,
      lessThanOrEqualTo(file.width + 1),
    );
  });

  testWidgets('fits a 320 pt phone', (tester) async {
    await _pump(tester, inRingingSlot: true, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('the card stays within 424 pt in ${locale.languageCode}', (
      tester,
    ) async {
      await _pump(tester, locale: locale, inRingingSlot: true);
      final before = tester.getSize(find.byType(GameOutcomeLine)).height;
      await tester.pump(StepQuestRound.stallAfter);
      expect(tester.getSize(find.byType(GameOutcomeLine)).height, before);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(CapyCard)).height,
        lessThanOrEqualTo(424),
      );
    });
  }

  for (final locale in const [Locale('en'), Locale('de'), Locale('ru')]) {
    testWidgets('at 2x text the stall line fits (${locale.languageCode})', (
      tester,
    ) async {
      await _pump(tester, locale: locale, inRingingSlot: true, textScale: 2);
      final before = tester.getSize(find.byType(GameOutcomeLine)).height;
      await tester.pump(StepQuestRound.stallAfter);
      expect(tester.getSize(find.byType(GameOutcomeLine)).height, before);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 2.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('renders at ${scale}x text, $brightness, no overflow', (
        tester,
      ) async {
        await _pump(
          tester,
          difficulty: PuzzleDifficulty.hard,
          textScale: scale,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('0 / 8'), findsOneWidget);
        expect(find.text('0 / 40 steps'), findsOneWidget);
      });
    }
  }
}
