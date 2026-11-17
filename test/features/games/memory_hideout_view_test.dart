import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/games/memory_hideout.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/features/games/memory_hideout_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_pump.dart';

const _seed = 5;

Finder _bush(int i) => find.byKey(ValueKey('memory-hideout-bush-$i'));

Future<({List<GameChallenge> progress, List<int> completed})> _pump(
  WidgetTester tester, {
  PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
  bool reduceMotion = true,
}) async {
  final progress = <GameChallenge>[];
  final completed = <int>[];
  await pumpInApp(
    tester,
    MemoryHideoutView(
      seed: _seed,
      difficulty: difficulty,
      onProgress: progress.add,
      onCompleted: () => completed.add(1),
      reduceMotion: reduceMotion,
    ),
  );
  return (progress: progress, completed: completed);
}

MemoryHideoutRound _mirror(PuzzleDifficulty d) =>
    MemoryHideoutRound.start(difficulty: d, seed: _seed);

void main() {
  testWidgets('reveals Capy behind one bush, with Ready', (tester) async {
    await _pump(tester);
    expect(find.text('Remember where Capy hid.'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('0 / 2'), findsOneWidget);
    expect(_bush(0), findsOneWidget);
    expect(_bush(2), findsOneWidget);
    expect(_bush(3), findsNothing);
  });

  testWidgets('hard has four bushes, still a large target each', (
    tester,
  ) async {
    await _pump(tester, difficulty: PuzzleDifficulty.hard);
    expect(tester.takeException(), isNull);
    expect(_bush(3), findsOneWidget);
    expect(tester.getSize(_bush(3)).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(_bush(3)).height, MemoryHideoutView.cardHeight);
  });

  testWidgets('the reveal is announced on the right bush', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    final hidden = _mirror(PuzzleDifficulty.easy).hiddenAt;
    expect(
      tester.getSemantics(_bush(hidden)).label,
      'Bush ${hidden + 1} of 3. Capy is behind bush ${hidden + 1}.',
    );
    final other = (hidden + 1) % 3;
    expect(tester.getSemantics(_bush(other)).label, 'Bush ${other + 1} of 3');
    handle.dispose();
  });

  testWidgets('taps on bushes before Ready do nothing', (tester) async {
    final calls = await _pump(tester);
    await tester.tap(_bush(0));
    await tester.pumpAndSettle();
    expect(calls.progress, isEmpty);
  });

  testWidgets('a right pick is counted and said, neutrally (H4)', (
    tester,
  ) async {
    final calls = await _pump(tester);
    final hidden = _mirror(PuzzleDifficulty.easy).hiddenAt;
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();
    expect(find.text('Where is Capy hiding?'), findsOneWidget);

    await tester.tap(_bush(hidden));
    await tester.pumpAndSettle();

    expect(find.text('Found Capy.'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(calls.progress.last.completed, 1);
  });

  testWidgets('a wrong pick is struggle and shows where Capy was (H4)', (
    tester,
  ) async {
    final calls = await _pump(tester);
    final hidden = _mirror(PuzzleDifficulty.easy).hiddenAt;
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();

    await tester.tap(_bush((hidden + 1) % 3));
    await tester.pumpAndSettle();

    expect(
      find.text('Not there. Capy is behind bush ${hidden + 1}.'),
      findsOneWidget,
    );
    expect(calls.progress.last.struggleCount, 1);
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('the outcome line is a live region', (tester) async {
    await _pump(tester);
    final hidden = _mirror(PuzzleDifficulty.easy).hiddenAt;
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();
    await tester.tap(_bush(hidden));
    await tester.pumpAndSettle();

    final semantics = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.text('Found Capy.'),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantics.properties.liveRegion, isTrue);
  });

  testWidgets('finishing reports completion once (H7)', (tester) async {
    final calls = await _pump(tester);
    var mirror = _mirror(PuzzleDifficulty.easy);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Ready'));
      await tester.pumpAndSettle();
      await tester.tap(_bush(mirror.hiddenAt));
      await tester.pump();
      mirror = mirror.ready().pick(mirror.hiddenAt);
    }
    await tester.tap(_bush(0));
    await tester.pump();

    expect(calls.completed, [1]);
    expect(find.text('Ready'), findsNothing);
  });

  testWidgets('nothing animates', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Ready'));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
  });

  for (final scale in [1.0, 2.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('renders at ${scale}x text, $brightness, no overflow', (
        tester,
      ) async {
        await pumpInApp(
          tester,
          MemoryHideoutView(
            seed: 3,
            difficulty: PuzzleDifficulty.hard,
            onProgress: (_) {},
            onCompleted: () {},
            reduceMotion: false,
          ),
          textScale: scale,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Ready does not move when the outcome appears (SR2)', (
    tester,
  ) async {
    await _pump(tester);
    final hidden = _mirror(PuzzleDifficulty.easy).hiddenAt;
    final before = tester.getTopLeft(find.text('Ready'));
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();
    await tester.tap(_bush((hidden + 1) % 3));
    await tester.pumpAndSettle();

    expect(find.textContaining('Not there'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Ready')), before);
  });

  testWidgets('the outcome is gone while guessing (SR2)', (tester) async {
    await _pump(tester);
    final hidden = _mirror(PuzzleDifficulty.easy).hiddenAt;
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();
    await tester.tap(_bush((hidden + 1) % 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Capy is behind'), findsNothing);
    expect(find.text('Where is Capy hiding?'), findsOneWidget);
  });

  testWidgets('Ready is an in-card outline, not a twin of Snooze', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.ancestor(of: find.text('Ready'), matching: find.byType(CapyButton)),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.text('Ready'),
        matching: find.byType(OutlinedButton),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(OutlinedButton)).height,
      greaterThanOrEqualTo(CapyButton.height),
    );
  });

  testWidgets('a small capybara sits beside the outcome line', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    final hidden = _mirror(PuzzleDifficulty.easy).hiddenAt;
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();
    await tester.tap(_bush(hidden));
    await tester.pumpAndSettle();

    final capy = find.byKey(const ValueKey('memory-hideout-outcome-capy'));
    expect(capy, findsOneWidget);
    final icon = tester.getRect(capy);
    final text = tester.getRect(find.text('Found Capy.'));
    expect(icon.height, MemoryHideoutView.outcomeIconSize);
    expect(icon.right, lessThanOrEqualTo(text.left));
    expect((icon.center.dy - text.center.dy).abs(), lessThan(4));
    expect(find.bySemanticsLabel('Found Capy.'), findsOneWidget);
    handle.dispose();
  });

  group('the shuffle', () {
    testWidgets('after Ready the bushes swap, then you guess', (tester) async {
      await _pump(tester, reduceMotion: false);
      final mirror = _mirror(PuzzleDifficulty.easy).ready(shuffle: true);
      final before = tester.getTopLeft(
        find.byKey(const ValueKey('memory-hideout-card-0')),
      );

      await tester.tap(find.text('Ready'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Watch the bushes.'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.pumpAndSettle();
      expect(find.text('Where is Capy hiding?'), findsOneWidget);
      expect(mirror.swaps, hasLength(1));
      final (a, b) = mirror.swaps.single;
      if (a == 0 || b == 0) {
        expect(
          tester.getTopLeft(
            find.byKey(const ValueKey('memory-hideout-card-0')),
          ),
          isNot(before),
        );
      }
    });

    testWidgets('the right bush after the shuffle is a find', (tester) async {
      final calls = await _pump(tester, reduceMotion: false);
      final mirror = _mirror(PuzzleDifficulty.easy).ready(shuffle: true);
      await tester.tap(find.text('Ready'));
      await tester.pumpAndSettle();

      await tester.tap(_bush(mirror.hiddenAt));
      await tester.pumpAndSettle();

      expect(find.text('Found Capy.'), findsOneWidget);
      expect(calls.progress.last.completed, 1);
    });

    testWidgets('picks are ignored mid-shuffle', (tester) async {
      final calls = await _pump(tester, reduceMotion: false);
      await tester.tap(find.text('Ready'));
      await tester.pump();
      await tester.tap(_bush(0), warnIfMissed: false);
      await tester.pump();
      expect(calls.progress.where((c) => c.completed > 0), isEmpty);
      await tester.pumpAndSettle();
    });

    testWidgets('hard swaps three times', (tester) async {
      await _pump(
        tester,
        difficulty: PuzzleDifficulty.hard,
        reduceMotion: false,
      );
      final mirror = _mirror(PuzzleDifficulty.hard).ready(shuffle: true);
      expect(mirror.swaps, hasLength(3));
      await tester.tap(find.text('Ready'));
      await tester.pumpAndSettle();
      expect(find.text('Where is Capy hiding?'), findsOneWidget);
    });

    testWidgets('with a screen reader there is no shuffle', (tester) async {
      await pumpInApp(
        tester,
        MemoryHideoutView(
          seed: _seed,
          difficulty: PuzzleDifficulty.easy,
          onProgress: (_) {},
          onCompleted: () {},
          reduceMotion: false,
        ),
        accessibleNavigation: true,
      );
      await tester.tap(find.text('Ready'));
      await tester.pump();
      expect(find.text('Where is Capy hiding?'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  testWidgets('Capy peeks over the bush only on the reveal card', (
    tester,
  ) async {
    await _pump(tester);
    final hidden = _mirror(PuzzleDifficulty.easy).hiddenAt;
    final peek = find.byKey(const ValueKey('memory-hideout-peeking-capy'));
    expect(peek, findsOneWidget);
    expect(
      find.descendant(of: _bush(hidden), matching: peek),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _bush((hidden + 1) % 3),
        matching: find.byType(Image),
      ),
      findsOneWidget,
      reason: 'a hidden card shows only its bush',
    );

    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();
    expect(peek, findsNothing);
  });
}
