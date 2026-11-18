import 'dart:io';

import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/games/shake_dj.dart';
import 'package:capywake/core/motion/fake_motion_sensor.dart';
import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:capywake/features/games/shake_dj_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '_motion.dart';
import '_pump.dart';

final Finder _beat = find.byKey(const ValueKey('shake-dj-beat'));
final Finder _capy = find.byKey(const ValueKey('shake-dj-capy'));
final Finder _note = find.byKey(const ValueKey('shake-dj-note'));

typedef _Calls = ({List<GameChallenge> progress, List<int> completed});

Future<_Calls> _pump(
  WidgetTester tester, {
  MotionSensor? motion,
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
  final view = ShakeDjView(
    difficulty: difficulty,
    motion: motion ?? FakeMotionSensor(),
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

Future<void> _shake(WidgetTester tester, FakeMotionSensor motion) async {
  motion
    ..emit(shakeSample)
    ..emit(FakeMotionSensor.still);
  // The stream delivers on a microtask; the second pump draws its result.
  await tester.pump();
  await tester.pump();
}

String? _outcome(WidgetTester tester) =>
    tester.widget<GameOutcomeLine>(find.byType(GameOutcomeLine)).text;

void main() {
  testWidgets('shows the instruction, progress in phrases and the button', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.text('Shake the phone to keep the beat going.'),
      findsOneWidget,
    );
    expect(find.text('0 / 4'), findsOneWidget);
    expect(find.text('Tap the beat'), findsOneWidget);
    expect(_outcome(tester), isNull);
  });

  testWidgets('the beat button is a game control, not a twin of Snooze', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.descendant(
        of: find.byType(ShakeDjView),
        matching: find.byType(CapyButton),
      ),
      findsNothing,
    );
    final size = tester.getSize(_beat);
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThan(200));
  });

  testWidgets('the beat button names itself to a screen reader', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final calls = await _pump(tester);
    expect(find.bySemanticsLabel('Tap the beat'), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('Tap the beat'));
    await tester.pump();
    expect(calls.progress, hasLength(1));
    handle.dispose();
  });

  testWidgets('a shake is a beat; five beats fill a phrase', (tester) async {
    final motion = FakeMotionSensor();
    final calls = await _pump(tester, motion: motion);
    await _shake(tester, motion);
    expect(calls.progress.single.completed, 1);
    expect(calls.progress.single.requiresMotion, isTrue);
    for (var i = 0; i < 4; i++) {
      await _shake(tester, motion);
    }
    expect(find.text('1 / 4'), findsOneWidget);
  });

  testWidgets('one long jolt is one beat', (tester) async {
    final motion = FakeMotionSensor();
    final calls = await _pump(tester, motion: motion);
    motion
      ..emit(shakeSample)
      ..emit(shakeSample)
      ..emit(shakeSample);
    await tester.pump();
    expect(calls.progress, hasLength(1));
  });

  testWidgets('the button beats, and finishing reports once', (tester) async {
    final motion = FakeMotionSensor();
    final calls = await _pump(tester, motion: motion);
    expect(motion.hasListener, isTrue);
    for (var i = 0; i < 25; i++) {
      await tester.tap(_beat);
      await tester.pump();
    }
    expect(calls.progress.last.isComplete, isTrue);
    expect(calls.progress, hasLength(20));
    expect(calls.completed, [1]);
    expect(find.text('4 / 4'), findsOneWidget);
    expect(motion.hasListener, isFalse, reason: 'no sensor after the win');
    await _shake(tester, motion);
    expect(calls.progress, hasLength(20));
    await tester.pump(ShakeDjRound.stallAfter * 2);
    expect(calls.progress, hasLength(20), reason: 'no stall after the win');
  });

  testWidgets('eight quiet seconds stall the beat: a struggle, nothing lost', (
    tester,
  ) async {
    final calls = await _pump(tester);
    await tester.pump(ShakeDjRound.stallAfter - const Duration(seconds: 1));
    expect(calls.progress, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(calls.progress.single.struggleCount, 1);
    expect(
      _outcome(tester),
      'Beat stopped. Shake or tap.',
    );
    await tester.pump(ShakeDjRound.stallAfter);
    expect(calls.progress.last.struggleCount, 2);
    expect(calls.progress.last.completed, 0);
  });

  testWidgets('a long pause is announced once, not every eight seconds', (
    tester,
  ) async {
    final said = recordAnnouncements(tester);
    await _pump(tester);
    for (var stall = 0; stall < 3; stall++) {
      await tester.pump(ShakeDjRound.stallAfter);
    }
    expect(said, isEmpty, reason: 'the live region speaks the first one');
  });

  testWidgets('fits a 320 pt phone', (tester) async {
    await _pump(tester, inRingingSlot: true, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a beat clears the stall line and restarts the wait', (
    tester,
  ) async {
    final calls = await _pump(tester);
    await tester.pump(ShakeDjRound.stallAfter);
    await tester.tap(_beat);
    await tester.pump(ShakeDjRound.stallAfter - const Duration(seconds: 1));
    expect(_outcome(tester), isNull);
    expect(calls.progress.last.struggleCount, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(calls.progress.last.struggleCount, 2);
  });

  testWidgets('disposing stops the sensor and the stall clock', (
    tester,
  ) async {
    final motion = FakeMotionSensor();
    final calls = await _pump(tester, motion: motion);
    await tester.pumpWidget(const SizedBox());
    expect(motion.hasListener, isFalse);
    await tester.pump(ShakeDjRound.stallAfter * 2);
    expect(calls.progress, isEmpty);
  });

  testWidgets('a new sensor on rebuild is heard; the old one is let go', (
    tester,
  ) async {
    final first = FakeMotionSensor();
    final second = FakeMotionSensor();
    final calls = await _pump(tester, motion: first);
    await _pump(tester, motion: second);
    expect(first.hasListener, isFalse);
    expect(second.hasListener, isTrue);
    await _shake(tester, first);
    expect(calls.progress, isEmpty);
  });

  testWidgets('a failing sensor is ignored; the button still works', (
    tester,
  ) async {
    final motion = FailingMotionSensor();
    final calls = await _pump(tester, motion: motion);
    motion.fail();
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(_beat);
    await tester.pump();
    expect(calls.progress.single.completed, 1);
  });

  testWidgets('the equalizer rises with the beat', (tester) async {
    await _pump(tester);
    double tallest() => tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => c.constraints!.maxHeight)
        .reduce((a, b) => a > b ? a : b);
    final quiet = tallest();
    for (var i = 0; i < 10; i++) {
      await tester.tap(_beat);
    }
    await tester.pump();
    expect(tallest(), greaterThan(quiet));
    expect(tallest(), lessThanOrEqualTo(ShakeDjView.barMaxHeight));
  });

  group('moving', () {
    testWidgets('Capy grooves, then rests so frames can settle', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: false);
      expect(tester.hasRunningAnimations, isFalse);
      final rest = tester.getTopLeft(_capy).dy;
      for (var cycle = 0; cycle < 2; cycle++) {
        await tester.pump(ShakeDjView.grooveRest);
        await tester.pump(
          ShakeDjRound.grooveFor(PuzzleDifficulty.easy) * 0.5,
        );
        expect(tester.getTopLeft(_capy).dy, lessThan(rest));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(_capy).dy, closeTo(rest, 0.01));
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a beat kicks Capy and sends up a note', (tester) async {
      await _pump(tester, reduceMotion: false);
      expect(_note, findsNothing);
      await tester.tap(_beat);
      await tester.pump();
      await tester.pump(ShakeDjView.kick * 0.5);
      expect(_note, findsOneWidget);
      final scales = tester.widgetList<Transform>(
        find.ancestor(of: _capy, matching: find.byType(Transform)),
      );
      expect(
        scales.any((t) => t.transform.getMaxScaleOnAxis() > 1.01),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with a screen reader nothing moves (H5)', (tester) async {
      await _pump(tester, reduceMotion: false, accessibleNavigation: true);
      await tester.tap(_beat);
      await tester.pump();
      expect(_note, findsNothing);
      await tester.pump(ShakeDjView.kick);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('turning a screen reader on mid-groove stops it', (
      tester,
    ) async {
      final motion = FakeMotionSensor();
      await _pump(tester, motion: motion, reduceMotion: false);
      await tester.pump(ShakeDjView.grooveRest);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await _pump(
        tester,
        motion: motion,
        reduceMotion: false,
        accessibleNavigation: true,
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(
        find.ancestor(
          of: _capy,
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
        findsNothing,
      );
    });
  });

  testWidgets('under reduce-motion a beat animates nothing', (tester) async {
    await _pump(tester);
    await tester.tap(_beat);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(_note, findsNothing);
  });

  testWidgets('Capy is drawn no larger than its pixels allow', (
    tester,
  ) async {
    await _pump(tester);
    final file = img.decodeWebP(
      File(CapyArt.byId('game.capy.listening').path).readAsBytesSync(),
    )!;
    expect(
      tester.getSize(_capy).width * 3,
      lessThanOrEqualTo(file.width + 1),
    );
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('the card stays within 424 pt in ${locale.languageCode}', (
      tester,
    ) async {
      await _pump(tester, locale: locale, inRingingSlot: true);
      final before = tester.getSize(find.byType(GameOutcomeLine)).height;
      await tester.pump(ShakeDjRound.stallAfter);
      expect(
        tester.getSize(find.byType(GameOutcomeLine)).height,
        before,
        reason: 'the stall line must fit the two reserved lines',
      );
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
      await tester.pump(ShakeDjRound.stallAfter);
      expect(tester.getSize(find.byType(GameOutcomeLine)).height, before);
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
      });
    }
  }
}
