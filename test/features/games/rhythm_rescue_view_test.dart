import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/games/rhythm_rescue.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:capywake/features/games/rhythm_rescue_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_pump.dart';

const _seed = 5;

Finder _pad(int i) => find.byKey(ValueKey('rhythm-rescue-pad-$i'));
Finder _slot(int i) => find.byKey(ValueKey('rhythm-rescue-slot-$i'));
final Finder _replay = find.byKey(const ValueKey('rhythm-rescue-replay'));
final Finder _status = find.byKey(const ValueKey('rhythm-rescue-status'));

typedef _Calls = ({List<GameChallenge> progress, List<int> completed});

Future<_Calls> _pump(
  WidgetTester tester, {
  PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
  bool reduceMotion = true,
  bool accessibleNavigation = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
}) async {
  final progress = <GameChallenge>[];
  final completed = <int>[];
  await pumpInApp(
    tester,
    RhythmRescueView(
      seed: _seed,
      difficulty: difficulty,
      onProgress: progress.add,
      onCompleted: () => completed.add(1),
      reduceMotion: reduceMotion,
    ),
    accessibleNavigation: accessibleNavigation,
    textScale: textScale,
    brightness: brightness,
    locale: locale,
  );
  return (progress: progress, completed: completed);
}

RhythmRescueRound _mirror([PuzzleDifficulty d = PuzzleDifficulty.easy]) =>
    RhythmRescueRound.start(difficulty: d, seed: _seed);

Duration _beat([PuzzleDifficulty d = PuzzleDifficulty.easy]) =>
    RhythmRescueRound.beatFor(d);

/// Watches the pads light, beat by beat, and returns the pads seen lit.
Future<List<int>> _watch(WidgetTester tester, int beats) async {
  final seen = <int>[];
  await tester.pump(RhythmRescueView.leadIn);
  for (var b = 0; b < beats; b++) {
    for (var p = 0; p < 4; p++) {
      if (find.byKey(ValueKey('rhythm-rescue-lit-$p')).evaluate().isNotEmpty) {
        seen.add(p);
      }
    }
    await tester.pump(_beat());
  }
  return seen;
}

Future<void> _tapAll(WidgetTester tester, List<int> pads) async {
  for (final p in pads) {
    await tester.tap(_pad(p));
    await tester.pump();
  }
}

void main() {
  group('still (reduce-motion)', () {
    testWidgets('shows the instruction, 0 / goal and the pattern', (
      tester,
    ) async {
      await _pump(tester);
      final round = _mirror();
      expect(find.text('Tap the pads in the order shown.'), findsOneWidget);
      expect(find.text('0 / 2'), findsOneWidget);
      expect(find.text('Your turn'), findsOneWidget);
      for (var b = 0; b < round.pattern.length; b++) {
        expect(
          find.descendant(
            of: _slot(b),
            matching: find.text('${round.pattern[b] + 1}'),
          ),
          findsOneWidget,
        );
      }
      expect(_replay, findsNothing);
    });

    testWidgets('the right pads count; nothing animates', (tester) async {
      final calls = await _pump(tester);
      await _tapAll(tester, _mirror().pattern);
      expect(calls.progress.last.completed, 1);
      expect(find.text("That's the rhythm."), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a wrong pad is a struggle and the same pattern stays', (
      tester,
    ) async {
      final calls = await _pump(tester);
      final pattern = _mirror().pattern;
      await tester.tap(_pad((pattern.first + 1) % 4));
      await tester.pump();
      expect(calls.progress.last.struggleCount, 1);
      expect(calls.progress.last.completed, 0);
      expect(
        find.text('Not quite. Start again from the first beat.'),
        findsOneWidget,
      );
      expect(find.text('Your turn'), findsOneWidget);
      await _tapAll(tester, pattern);
      expect(calls.progress.last.completed, 1);
    });

    testWidgets('finishing reports completion once', (tester) async {
      final calls = await _pump(tester);
      var round = _mirror();
      while (!round.isComplete) {
        final pattern = round.heard().pattern;
        await _tapAll(tester, pattern);
        for (final p in pattern) {
          round = round.heard().tap(p);
        }
      }
      expect(calls.completed, [1]);
      await tester.tap(_pad(0));
      await tester.pump();
      expect(calls.completed, [1]);
    });

    testWidgets('pads and slots speak for a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, reduceMotion: false, accessibleNavigation: true);
      final pattern = _mirror().pattern;
      expect(tester.getSemantics(_pad(2)).label, 'Pad 3');
      expect(
        tester.getSemantics(_slot(0)).label,
        'Beat 1: pad ${pattern[0] + 1}',
      );
      expect(_replay, findsNothing);
      handle.dispose();
    });

    testWidgets('the pads are large targets in every mode', (tester) async {
      await _pump(tester);
      for (var p = 0; p < 4; p++) {
        final size = tester.getSize(_pad(p));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(RhythmRescueView.padMinSize));
      }
    });

    testWidgets('the pads do not move when an outcome appears (M3)', (
      tester,
    ) async {
      await _pump(tester);
      final before = tester.getTopLeft(_pad(0));
      final outcomeBefore = tester.getSize(find.byType(GameOutcomeLine));
      await tester.tap(_pad((_mirror().pattern.first + 1) % 4));
      await tester.pump();
      expect(tester.getTopLeft(_pad(0)), before);
      expect(tester.getSize(find.byType(GameOutcomeLine)), outcomeBefore);
    });

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
        });
      }
    }

    testWidgets('mirrors in RTL without overflow', (tester) async {
      await _pump(tester, locale: const Locale('ar'));
      expect(tester.takeException(), isNull);
      expect(
        tester.getCenter(_pad(0)).dx,
        greaterThan(tester.getCenter(_pad(3)).dx),
      );
    });
  });

  group('moving', () {
    testWidgets('lights the pattern in order, then it is your turn', (
      tester,
    ) async {
      final calls = await _pump(tester, reduceMotion: false);
      final pattern = _mirror().pattern;
      expect(find.text('Watch the pads'), findsOneWidget);
      expect(_slot(0), findsOneWidget);
      expect(
        find.descendant(of: _slot(0), matching: find.byType(Text)),
        findsNothing,
      );

      expect(await _watch(tester, pattern.length), pattern);
      await tester.pump(_beat());
      expect(find.text('Your turn'), findsOneWidget);
      expect(calls.progress, isEmpty);
    });

    testWidgets('a tap while the pattern plays does nothing (L1)', (
      tester,
    ) async {
      final calls = await _pump(tester, reduceMotion: false);
      await tester.tap(_pad(0), warnIfMissed: false);
      await tester.pump();
      expect(calls.progress, isEmpty);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('while repeating the pattern is hidden; entered beats fill', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: false);
      final pattern = _mirror().pattern;
      await tester.pump(const Duration(seconds: 5));
      for (var b = 0; b < pattern.length; b++) {
        expect(
          find.descendant(of: _slot(b), matching: find.byType(Text)),
          findsNothing,
        );
      }
      await tester.tap(_pad(pattern[0]));
      await tester.pump();
      expect(
        find.descendant(
          of: _slot(0),
          matching: find.text('${pattern[0] + 1}'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('replay shows the pattern again at no cost', (tester) async {
      final calls = await _pump(tester, reduceMotion: false);
      final pattern = _mirror().pattern;
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(_pad(pattern[0]));
      await tester.pump();
      await tester.tap(_replay);
      await tester.pump();
      expect(find.text('Watch the pads'), findsOneWidget);
      expect(calls.progress.last.struggleCount, 0);
      expect(await _watch(tester, pattern.length), pattern);
      await tester.pump(_beat());
      await _tapAll(tester, pattern);
      expect(calls.progress.last.completed, 1);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a wrong pad replays the same pattern', (tester) async {
      final calls = await _pump(tester, reduceMotion: false);
      final pattern = _mirror().pattern;
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(_pad((pattern[0] + 1) % 4));
      await tester.pump();
      expect(calls.progress.last.struggleCount, 1);
      expect(find.text('Watch the pads'), findsOneWidget);
      expect(await _watch(tester, pattern.length), pattern);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('the pads do not move between watching and your turn (H1)', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: false, locale: const Locale('de'));
      final watching = tester.getTopLeft(_pad(0));
      await tester.pump(const Duration(seconds: 5));
      expect(tester.getTopLeft(_pad(0)), watching);
    });

    testWidgets('a screen reader turning on mid-playback shows the pattern '
        '(H5)', (tester) async {
      final view = RhythmRescueView(
        seed: _seed,
        difficulty: PuzzleDifficulty.easy,
        onProgress: (_) {},
        onCompleted: () {},
        reduceMotion: false,
      );
      await pumpInApp(tester, view);
      await tester.pump(RhythmRescueView.leadIn);
      expect(find.text('Watch the pads'), findsOneWidget);

      await pumpInApp(tester, view, accessibleNavigation: true);
      expect(find.text('Your turn'), findsOneWidget);
      final pattern = _mirror().pattern;
      expect(
        find.descendant(
          of: _slot(0),
          matching: find.text('${pattern[0] + 1}'),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a screen reader turning off keeps the shown pattern', (
      tester,
    ) async {
      final view = RhythmRescueView(
        seed: _seed,
        difficulty: PuzzleDifficulty.easy,
        onProgress: (_) {},
        onCompleted: () {},
        reduceMotion: false,
      );
      await pumpInApp(tester, view, accessibleNavigation: true);
      await pumpInApp(tester, view);
      final pattern = _mirror().pattern;
      expect(find.text('Your turn'), findsOneWidget);
      expect(
        find.descendant(
          of: _slot(1),
          matching: find.text('${pattern[1] + 1}'),
        ),
        findsOneWidget,
      );
      await tester.tap(_replay);
      await tester.pump();
      expect(
        find.descendant(of: _slot(1), matching: find.byType(Text)),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('disposing mid-playback leaves no timer behind (M2)', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: false);
      await tester.pump(RhythmRescueView.leadIn);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a harder setting plays faster', (tester) async {
      expect(
        _beat(PuzzleDifficulty.hard),
        lessThan(_beat()),
      );
      await _pump(
        tester,
        reduceMotion: false,
        difficulty: PuzzleDifficulty.hard,
      );
      final pattern = _mirror(PuzzleDifficulty.hard).pattern;
      await tester.pump(RhythmRescueView.leadIn);
      expect(
        find.byKey(ValueKey('rhythm-rescue-lit-${pattern[0]}')),
        findsOneWidget,
      );
      await tester.pump(_beat(PuzzleDifficulty.hard));
      expect(
        find.byKey(ValueKey('rhythm-rescue-lit-${pattern[1]}')),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
    });
  });

  testWidgets('the beats sit in one row beside the replay button', (
    tester,
  ) async {
    await _pump(tester, reduceMotion: false, difficulty: PuzzleDifficulty.hard);
    final replay = tester.getRect(_replay);
    for (var b = 0; b < 5; b++) {
      final slot = tester.getRect(_slot(b));
      expect(slot.width, RhythmRescueView.slotSize, reason: 'beat $b');
      expect(slot.center.dy, closeTo(replay.center.dy, 0.5), reason: 'beat $b');
    }
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a screen reader can replay and tap through semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final calls = await _pump(tester, reduceMotion: false);
    await tester.pump(const Duration(seconds: 5));
    final pattern = _mirror().pattern;
    tester.semantics.tap(find.semantics.byLabel('Pad ${pattern[0] + 1}'));
    await tester.pump();
    expect(calls.progress.last.completed, 0);
    tester.semantics.tap(find.semantics.byLabel('Show the rhythm again'));
    await tester.pump();
    expect(find.text('Watch the pads'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    handle.dispose();
  });

  testWidgets('a press dragged off a pad does not count', (tester) async {
    final calls = await _pump(tester);
    final gesture = await tester.startGesture(tester.getCenter(_pad(0)));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 300));
    await gesture.up();
    await tester.pump();
    expect(calls.progress, isEmpty);
    expect(tester.getSize(_pad(0)).height, RhythmRescueView.padMinSize);
  });

  testWidgets('the status is announced', (tester) async {
    await _pump(tester);
    final status = tester.widget<Semantics>(
      find.ancestor(of: _status, matching: find.byType(Semantics)).first,
    );
    expect(status.properties.liveRegion, isTrue);
  });
}
