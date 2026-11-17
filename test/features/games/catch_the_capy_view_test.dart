import 'package:capywake/core/games/catch_the_capy.dart';
import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/features/games/catch_the_capy_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_pump.dart';

final Finder _target = find.byKey(const ValueKey('catch-the-capy-target'));
Duration _interval(PuzzleDifficulty d) =>
    CatchTheCapyRound.runFor(d) + CatchTheCapyView.footfall;

void _ignore(Object? _) {}
void _noop() {}

final Finder _meadow = find.byKey(const ValueKey('catch-the-capy-meadow'));

Future<({List<GameChallenge> progress, List<int> completed})> _pump(
  WidgetTester tester, {
  PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
  bool reduceMotion = false,
}) async {
  final progress = <GameChallenge>[];
  final completed = <int>[];
  await pumpInApp(
    tester,
    CatchTheCapyView(
      seed: 3,
      difficulty: difficulty,
      onProgress: progress.add,
      onCompleted: () => completed.add(1),
      reduceMotion: reduceMotion,
    ),
  );
  return (progress: progress, completed: completed);
}

void main() {
  testWidgets('shows the instruction and 0 / goal', (tester) async {
    await _pump(tester, difficulty: PuzzleDifficulty.medium);
    expect(find.text('Catch the capybara 5 times.'), findsOneWidget);
    expect(find.text('0 / 5'), findsOneWidget);
  });

  testWidgets('a catch counts and moves the capybara', (tester) async {
    final calls = await _pump(tester);
    final before = tester.getTopLeft(_target);

    await tester.tap(_target);
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(tester.getTopLeft(_target), isNot(before));
    expect(calls.progress.single.completed, 1);
    expect(calls.progress.single.struggleCount, 0);
  });

  testWidgets('a tap on the meadow is a miss, reported as struggle', (
    tester,
  ) async {
    final calls = await _pump(tester);
    final field = tester.getRect(_meadow);
    final capy = tester.getRect(_target);
    final away = capy.center.dx > field.center.dx
        ? field.centerLeft + const Offset(10, 0)
        : field.centerRight - const Offset(10, 0);

    await tester.tapAt(away);
    await tester.pumpAndSettle();

    expect(find.text('0 / 3'), findsOneWidget);
    expect(calls.progress.single.struggleCount, 1);
  });

  testWidgets('completion is reported once, even on a double tap (H7)', (
    tester,
  ) async {
    final calls = await _pump(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(_target);
      await tester.pump();
    }
    await tester.tap(_target);
    await tester.pump();

    expect(calls.completed, [1]);
  });

  testWidgets('the capybara is a large target', (tester) async {
    await _pump(tester);
    final size = tester.getSize(_target);
    expect(size.width, greaterThanOrEqualTo(88));
    expect(size.height, greaterThanOrEqualTo(88));
  });

  testWidgets('the field has a fixed height inside a scroll view (H1)', (
    tester,
  ) async {
    await _pump(tester);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(_meadow).height, CatchTheCapyView.fieldHeight);
  });

  testWidgets('a screen reader finds a button and can catch with it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    final node = tester.getSemantics(_target);
    expect(node.label, 'Catch the capybara');
    expect(node.flagsCollection.isButton, isTrue);
    tester.semantics.tap(find.semantics.byLabel('Catch the capybara'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the capybara wanders on its own, uncounted', (tester) async {
    final calls = await _pump(tester);
    final before = tester.getTopLeft(_target);

    await tester.pump(_interval(PuzzleDifficulty.easy));
    await tester.pump(CatchTheCapyRound.runFor(PuzzleDifficulty.easy) ~/ 2);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(_target), isNot(before));
    expect(calls.progress, isEmpty);
    expect(find.text('0 / 3'), findsOneWidget);
  });

  testWidgets('under reduce-motion it holds still and nothing animates', (
    tester,
  ) async {
    await _pump(tester, reduceMotion: true);
    final before = tester.getTopLeft(_target);

    await tester.pump(_interval(PuzzleDifficulty.easy) * 3);
    expect(tester.getTopLeft(_target), before);

    await tester.tap(_target);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('with a screen reader on it holds still', (tester) async {
    await pumpInApp(
      tester,
      CatchTheCapyView(
        seed: 3,
        difficulty: PuzzleDifficulty.easy,
        onProgress: (_) {},
        onCompleted: () {},
        reduceMotion: false,
      ),
      accessibleNavigation: true,
    );
    final before = tester.getTopLeft(_target);
    await tester.pump(_interval(PuzzleDifficulty.easy) * 3);
    expect(tester.getTopLeft(_target), before);
  });

  testWidgets('it stops wandering once caught enough', (tester) async {
    await _pump(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(_target);
      await tester.pumpAndSettle();
    }
    final done = tester.getTopLeft(_target);
    await tester.pump(_interval(PuzzleDifficulty.easy) * 2);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_target), done);
  });

  testWidgets('stays inside the field at every spot', (tester) async {
    await _pump(tester, difficulty: PuzzleDifficulty.hard);
    for (
      var i = 0;
      i < CatchTheCapyRound.targetFor(PuzzleDifficulty.hard) - 1;
      i++
    ) {
      final field = tester.getRect(_meadow);
      final capy = tester.getRect(_target);
      expect(field.contains(capy.topLeft), isTrue);
      expect(field.contains(capy.bottomRight - const Offset(1, 1)), isTrue);
      await tester.tap(_target);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('mirrors in RTL without overflow', (tester) async {
    await pumpInApp(
      tester,
      CatchTheCapyView(
        seed: 3,
        difficulty: PuzzleDifficulty.medium,
        onProgress: (_) {},
        onCompleted: () {},
        reduceMotion: false,
      ),
      locale: const Locale('ar'),
    );
    expect(tester.takeException(), isNull);
    expect(_target, findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('renders at ${scale}x text, $brightness, no overflow', (
        tester,
      ) async {
        await pumpInApp(
          tester,
          CatchTheCapyView(
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

  test('it never rests, and the difficulty sets how fast it runs', () {
    final easy = CatchTheCapyRound.runFor(PuzzleDifficulty.easy);
    final medium = CatchTheCapyRound.runFor(PuzzleDifficulty.medium);
    final hard = CatchTheCapyRound.runFor(PuzzleDifficulty.hard);
    expect(hard, lessThan(medium));
    expect(medium, lessThan(easy));
    const view = CatchTheCapyView(
      seed: 1,
      difficulty: PuzzleDifficulty.hard,
      onProgress: _ignore,
      onCompleted: _noop,
      reduceMotion: false,
    );
    expect(view.wanderInterval, hard + CatchTheCapyView.footfall);
  });

  testWidgets('a miss counts and the capybara bolts away from the tap', (
    tester,
  ) async {
    final calls = await _pump(tester);
    final field = tester.getRect(_meadow);
    final capy = tester.getRect(_target);
    final tapLeft = capy.center.dx > field.center.dx;
    final tap = tapLeft
        ? field.centerLeft + const Offset(10, 0)
        : field.centerRight - const Offset(10, 0);

    await tester.tapAt(tap);
    await tester.pump();
    await tester.pump(CatchTheCapyRound.runFor(PuzzleDifficulty.easy));

    expect(calls.progress.single.struggleCount, 1);
    final after = tester.getRect(_target).center.dx;
    expect(
      (after - tap.dx).abs(),
      greaterThan(field.width / 2),
      reason: 'it runs to the far side of the meadow',
    );
  });

  testWidgets('under reduce-motion a miss does not move it', (tester) async {
    await _pump(tester, reduceMotion: true);
    final before = tester.getTopLeft(_target);
    final field = tester.getRect(_meadow);
    final capy = tester.getRect(_target);
    await tester.tapAt(
      capy.center.dx > field.center.dx
          ? field.centerLeft + const Offset(10, 0)
          : field.centerRight - const Offset(10, 0),
    );
    await tester.pump();
    expect(tester.getTopLeft(_target), before);
  });

  testWidgets('it faces the way it runs', (tester) async {
    await _pump(tester, difficulty: PuzzleDifficulty.hard);
    var lefts = 0;
    var rights = 0;
    for (var i = 0; i < 6; i++) {
      final from = tester.getCenter(_target).dx;
      await tester.tap(_target);
      await tester.pump();
      await tester.pump(CatchTheCapyRound.runFor(PuzzleDifficulty.hard));
      final to = tester.getCenter(_target).dx;
      final flip = tester.widget<Transform>(
        find.descendant(of: _target, matching: find.byType(Transform)).first,
      );
      final mirrored = flip.transform.storage[0] < 0;
      if (to < from) {
        lefts++;
        expect(mirrored, isTrue, reason: 'ran left, must face left');
      }
      if (to > from) {
        rights++;
        expect(mirrored, isFalse, reason: 'ran right, must face right');
      }
    }
    expect(lefts + rights, greaterThan(0));
  });

  testWidgets('in RTL it still bolts to the far side of the tap', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      CatchTheCapyView(
        seed: 3,
        difficulty: PuzzleDifficulty.easy,
        onProgress: (_) {},
        onCompleted: () {},
        reduceMotion: false,
      ),
      locale: const Locale('ar'),
    );
    final field = tester.getRect(_meadow);
    final capy = tester.getRect(_target);
    final tapLeft = capy.center.dx > field.center.dx;
    final tap = tapLeft
        ? field.centerLeft + const Offset(10, 0)
        : field.centerRight - const Offset(10, 0);

    await tester.tapAt(tap);
    await tester.pump();
    await tester.pump(CatchTheCapyRound.runFor(PuzzleDifficulty.easy));

    final after = tester.getRect(_target).center.dx;
    expect((after - tap.dx).abs(), greaterThan(field.width / 2));
  });

  Finder frame(int i) => find.byKey(ValueKey('catch-the-capy-frame-$i'));

  testWidgets('the legs run through the whole cycle during a run', (
    tester,
  ) async {
    await _pump(tester);
    expect(frame(0), findsOneWidget, reason: 'standing frame before a run');
    await tester.tap(_target);
    await tester.pump();

    final run = CatchTheCapyRound.runFor(PuzzleDifficulty.easy);
    final seen = <int>{};
    for (var step = 0; step < 32; step++) {
      await tester.pump(run ~/ 32);
      for (var i = 0; i < CapyArt.runFrames.length; i++) {
        if (frame(i).evaluate().isNotEmpty) seen.add(i);
      }
    }
    expect(seen, hasLength(CapyArt.runFrames.length));
  });

  testWidgets('a run leaves dust where it began and alternating prints', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(_target);
    await tester.pump();
    final run = CatchTheCapyRound.runFor(PuzzleDifficulty.easy);
    final dust = find.byKey(const ValueKey('catch-the-capy-dust'));
    expect(dust, findsOneWidget);

    await tester.pump(run * 0.4);
    final p0 = tester.getCenter(
      find.byKey(const ValueKey('catch-the-capy-paw-0')),
    );
    final p1 = tester.getCenter(
      find.byKey(const ValueKey('catch-the-capy-paw-1')),
    );
    expect(p0, isNot(p1));

    await tester.pump(run * 0.6);
    expect(dust, findsNothing, reason: 'gone by the end of its run');
    expect(find.byKey(const ValueKey('catch-the-capy-paw-0')), findsNothing);
  });

  testWidgets('under reduce-motion: one still frame, no dust, no prints', (
    tester,
  ) async {
    await _pump(tester, reduceMotion: true);
    await tester.tap(_target);
    await tester.pump();
    expect(frame(0), findsOneWidget);
    expect(find.byKey(const ValueKey('catch-the-capy-dust')), findsNothing);
    expect(find.byKey(const ValueKey('catch-the-capy-paw-0')), findsNothing);
  });

  testWidgets('it always runs on the grass, never in the sky', (
    tester,
  ) async {
    await _pump(tester, difficulty: PuzzleDifficulty.hard);
    final field = tester.getRect(_meadow);
    for (var i = 0; i < 6; i++) {
      final capy = tester.getRect(_target);
      expect(
        capy.top - field.top,
        greaterThanOrEqualTo(
          CatchTheCapyView.fieldHeight * CatchTheCapyView.groundTop - 0.5,
        ),
      );
      await tester.tap(_target);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('the dust stays inside the field', (tester) async {
    await _pump(tester, difficulty: PuzzleDifficulty.hard);
    final field = tester.getRect(_meadow);
    final dust = find.byKey(const ValueKey('catch-the-capy-dust'));
    for (var i = 0; i < 6; i++) {
      await tester.tap(_target);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final rect = tester.getRect(dust);
      expect(rect.left, greaterThanOrEqualTo(field.left - 0.5));
      expect(rect.right, lessThanOrEqualTo(field.right + 0.5));
      await tester.pumpAndSettle();
    }
  });
}
