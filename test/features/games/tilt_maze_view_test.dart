import 'dart:math' as math;

import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/games/tilt_maze.dart';
import 'package:capywake/core/motion/fake_motion_sensor.dart';
import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/core/motion/tilt_reader.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:capywake/features/games/tilt_maze_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_maze_by_ear.dart';
import '_motion.dart';
import '_pump.dart';

const _g = 9.80665;
const PuzzleDifficulty _difficulty = PuzzleDifficulty.easy;
final Finder _capy = find.byKey(const ValueKey('tilt-maze-capy'));

typedef _Calls = ({List<GameChallenge> progress, List<int> completed});

Future<_Calls> _pump(
  WidgetTester tester, {
  int seed = 1,
  MotionSensor? motion,
  bool reduceMotion = true,
  bool accessibleNavigation = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  PuzzleDifficulty difficulty = _difficulty,
  bool inRingingSlot = false,
  Size size = const Size(393, 852),
}) async {
  final progress = <GameChallenge>[];
  final completed = <int>[];
  final view = TiltMazeView(
    seed: seed,
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

TiltMazeRound _mirror([int seed = 1]) =>
    TiltMazeRound.start(difficulty: _difficulty, seed: seed);

MotionSample _attitude({double pitch = 0, double roll = 0}) {
  final p = pitch * math.pi / 180;
  final r = roll * math.pi / 180;
  return MotionSample(
    x: -_g * math.sin(r),
    y: _g * math.cos(r) * math.sin(p),
    z: _g * math.cos(r) * math.cos(p),
  );
}

MotionSample _tilted(TiltDirection d) => switch (d) {
  TiltDirection.down => _attitude(pitch: 25),
  TiltDirection.up => _attitude(pitch: -25),
  TiltDirection.right => _attitude(roll: 25),
  TiltDirection.left => _attitude(roll: -25),
};

Future<void> _emit(
  WidgetTester tester,
  FakeMotionSensor m,
  MotionSample s,
) async {
  m.emit(s);
  await tester.pump();
  await tester.pump();
}

/// A seed whose start opens a corridor at least [cells] long, and its way.
(int, TiltDirection) _corridor(int cells) {
  for (var seed = 0; seed < 500; seed++) {
    final round = _mirror(seed);
    for (final d in TiltDirection.values) {
      var r = round;
      var run = 0;
      while (r.canMove(d) && run < cells + 1) {
        r = r.move(d);
        run++;
      }
      if (run == cells && !r.canMove(d)) return (seed, d);
    }
  }
  throw StateError('no corridor');
}

int _cell(WidgetTester tester, TiltMazeRound mirror) {
  final field = tester.getRect(find.byKey(const ValueKey('tilt-maze-walls')));
  final capy = tester.getRect(
    find.ancestor(of: _capy, matching: find.byType(AnimatedPositioned)),
  );
  final size = field.width / mirror.maze.columns;
  final column = ((capy.left - field.left) / size).round();
  final row = ((capy.top - field.top) / size).round();
  return row * mirror.maze.columns + column;
}

List<TiltDirection> _pathToFlag(TiltMazeRound round) {
  final path = <TiltDirection>[];
  var r = round;
  while (r.solved == round.solved) {
    final d = TiltDirection.values.firstWhere(
      (d) =>
          r.canMove(d) &&
          r.maze.stepsToFlag(r.maze.neighbour(r.position, d)!) < r.stepsToFlag,
    );
    path.add(d);
    r = r.move(d);
  }
  return path;
}

/// A wall line, then a whole maze to the escape line: the result line keeps
/// its height throughout, so Snooze below never moves. Seed 1, by the map.
Future<void> _keepsOutcomeHeight(WidgetTester tester) async {
  double height() => tester.getSize(find.byType(GameOutcomeLine)).height;
  final before = height();
  final mirror = _mirror();
  await tester.tap(
    mazeArrow(TiltDirection.values.firstWhere((d) => !mirror.canMove(d))),
  );
  await tester.pump();
  expect(height(), before, reason: 'wall line');
  for (final d in _pathToFlag(mirror)) {
    await tester.tap(mazeArrow(d));
    await tester.pump();
    expect(height(), before, reason: 'step line');
  }
  expect(find.text('1 / 3'), findsOneWidget);
  expect(height(), before, reason: 'escape line');
  expect(tester.takeException(), isNull);
}

String? _outcome(WidgetTester tester) =>
    tester.widget<GameOutcomeLine>(find.byType(GameOutcomeLine)).text;

void main() {
  testWidgets('shows the instruction, 0 / 3 and how far the flag is', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.text('Tilt the phone to roll Capy to the flag.'),
      findsOneWidget,
    );
    expect(find.text('0 / 3'), findsOneWidget);
    expect(_outcome(tester), '${_mirror().stepsToFlag} steps to the flag.');
  });

  testWidgets('an open arrow steps; a wall arrow bumps and is a struggle', (
    tester,
  ) async {
    final calls = await _pump(tester);
    final mirror = _mirror();
    final open = TiltDirection.values.firstWhere(mirror.canMove);
    final wall = TiltDirection.values.firstWhere((d) => !mirror.canMove(d));

    await tester.tap(mazeArrow(wall));
    await tester.pump();
    expect(calls.progress.last.struggleCount, 1);
    expect(_outcome(tester), 'A wall. Try another way.');
    expect(_cell(tester, mirror), 0);

    await tester.tap(mazeArrow(open));
    await tester.pump();
    expect(calls.progress.last.struggleCount, 1);
    expect(_cell(tester, mirror), mirror.move(open).position);
  });

  testWidgets('arrows say which way is a wall', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    final mirror = _mirror();
    for (final d in TiltDirection.values) {
      final label = tester.getSemantics(mazeArrow(d)).label;
      final name = '${d.name[0].toUpperCase()}${d.name.substring(1)}';
      expect(label, mirror.canMove(d) ? name : '$name, wall');
    }
    handle.dispose();
  });

  testWidgets('a screen-reader user can finish by ear; win reported once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final motion = FakeMotionSensor();
    final calls = await _pump(
      tester,
      motion: motion,
      accessibleNavigation: true,
    );
    for (var maze = 0; maze < 3; maze++) {
      await solveMazeByEar(tester);
      if (maze < 2) {
        expect(_outcome(tester), 'Out! Next maze.');
        expect(find.text('${maze + 1} / 3'), findsOneWidget);
      }
    }
    expect(calls.completed, [1]);
    expect(calls.progress.last.isComplete, isTrue);
    expect(_outcome(tester), isNull);
    expect(motion.hasListener, isFalse, reason: 'no sensor after the win');
    await tester.tap(mazeArrow(TiltDirection.up));
    expect(calls.completed, [1]);
    handle.dispose();
  });

  group('tilt', () {
    testWidgets('a held tilt rolls cell by cell and stops quietly at the end', (
      tester,
    ) async {
      final (seed, way) = _corridor(2);
      final motion = FakeMotionSensor();
      final calls = await _pump(tester, seed: seed, motion: motion);
      final mirror = _mirror(seed);

      await _emit(tester, motion, _attitude());
      await _emit(tester, motion, _tilted(way));
      expect(_cell(tester, mirror), mirror.move(way).position);
      await tester.pump(TiltMazeRound.rollFor(_difficulty));
      expect(_cell(tester, mirror), mirror.move(way).move(way).position);
      await tester.pump(TiltMazeRound.rollFor(_difficulty) * 3);
      expect(_cell(tester, mirror), mirror.move(way).move(way).position);
      expect(calls.progress.last.struggleCount, 0, reason: 'H2');
      expect(_outcome(tester), contains('to the flag'));
    });

    testWidgets('tilting into a wall from rest is one bump, however long', (
      tester,
    ) async {
      final motion = FakeMotionSensor();
      final calls = await _pump(tester, motion: motion);
      final wall = TiltDirection.values.firstWhere(
        (d) => !_mirror().canMove(d),
      );
      await _emit(tester, motion, _attitude());
      await _emit(tester, motion, _tilted(wall));
      await _emit(tester, motion, _tilted(wall));
      await tester.pump(TiltMazeRound.rollFor(_difficulty) * 4);
      expect(calls.progress, hasLength(1));
      expect(calls.progress.single.struggleCount, 1);
    });

    testWidgets('levelling the phone stops the roll', (tester) async {
      final (seed, way) = _corridor(2);
      final motion = FakeMotionSensor();
      await _pump(tester, seed: seed, motion: motion);
      final mirror = _mirror(seed);
      await _emit(tester, motion, _attitude());
      await _emit(tester, motion, _tilted(way));
      await _emit(tester, motion, _attitude());
      await tester.pump(TiltMazeRound.rollFor(_difficulty) * 3);
      expect(_cell(tester, mirror), mirror.move(way).position);
    });

    testWidgets('an arrow press sets tilt aside until the phone is level', (
      tester,
    ) async {
      final (seed, way) = _corridor(2);
      final motion = FakeMotionSensor();
      final calls = await _pump(tester, seed: seed, motion: motion);
      final mirror = _mirror(seed);
      final back = switch (way) {
        TiltDirection.up => TiltDirection.down,
        TiltDirection.down => TiltDirection.up,
        TiltDirection.left => TiltDirection.right,
        TiltDirection.right => TiltDirection.left,
      };

      await _emit(tester, motion, _attitude());
      await _emit(tester, motion, _tilted(way));
      await tester.tap(mazeArrow(back));
      await tester.pump();
      expect(_cell(tester, mirror), 0);
      await tester.pump(TiltMazeRound.rollFor(_difficulty) * 3);
      expect(_cell(tester, mirror), 0, reason: 'the roll stopped');
      await _emit(tester, motion, _tilted(way));
      expect(_cell(tester, mirror), 0, reason: 'still tilted: set aside');
      final seen = calls.progress.length;
      await _emit(tester, motion, _attitude());
      expect(calls.progress, hasLength(seen), reason: 'level is not reverse');
      await _emit(tester, motion, _tilted(way));
      expect(_cell(tester, mirror), mirror.move(way).position);
    });

    testWidgets('held upright, tilting further rolls down', (tester) async {
      final seed = List.generate(500, (s) => s).firstWhere(
        (s) => _mirror(s).canMove(TiltDirection.down),
      );
      final motion = FakeMotionSensor();
      await _pump(tester, seed: seed, motion: motion);
      await _emit(tester, motion, _attitude(pitch: 60));
      await _emit(tester, motion, _attitude(pitch: 82));
      expect(
        _cell(tester, _mirror(seed)),
        _mirror(seed).move(TiltDirection.down).position,
      );
    });

    testWidgets('with a screen reader, tilt is ignored (H3)', (tester) async {
      final motion = FakeMotionSensor();
      final calls = await _pump(
        tester,
        motion: motion,
        accessibleNavigation: true,
      );
      await _emit(tester, motion, _attitude());
      for (final d in TiltDirection.values) {
        await _emit(tester, motion, _tilted(d));
      }
      expect(calls.progress, isEmpty);
    });

    testWidgets('turning a screen reader on mid-roll stops it', (
      tester,
    ) async {
      final (seed, way) = _corridor(2);
      final motion = FakeMotionSensor();
      await _pump(tester, seed: seed, motion: motion);
      await _emit(tester, motion, _attitude());
      await _emit(tester, motion, _tilted(way));
      await _pump(
        tester,
        seed: seed,
        motion: motion,
        accessibleNavigation: true,
      );
      await tester.pump(TiltMazeRound.rollFor(_difficulty) * 3);
      expect(_cell(tester, _mirror(seed)), _mirror(seed).move(way).position);
    });

    testWidgets('a new maze starts level: a held tilt does not carry over', (
      tester,
    ) async {
      // A seed whose last step into the flag points where the next maze is
      // open, so a roll that carried over would show.
      for (var seed = 0; ; seed++) {
        final path = _pathToFlag(_mirror(seed));
        var next = _mirror(seed);
        for (final d in path) {
          next = next.move(d);
        }
        if (!next.canMove(path.last)) continue;

        final motion = FakeMotionSensor();
        final calls = await _pump(tester, seed: seed, motion: motion);
        await _emit(tester, motion, _attitude());
        for (final (i, d) in path.indexed) {
          await _emit(tester, motion, _tilted(d));
          if (i < path.length - 1) await _emit(tester, motion, _attitude());
        }
        expect(find.text('1 / 3'), findsOneWidget);
        final seen = calls.progress.length;
        await tester.pump(TiltMazeRound.rollFor(_difficulty) * 3);
        await _emit(tester, motion, _tilted(path.last));
        await tester.pump(TiltMazeRound.rollFor(_difficulty) * 3);
        expect(calls.progress, hasLength(seen), reason: 'seed $seed');
        await _emit(tester, motion, _attitude());
        expect(calls.progress, hasLength(seen), reason: 'no bump on levelling');
        return;
      }
    });

    testWidgets('disposing mid-roll stops the sensor and the timer', (
      tester,
    ) async {
      final (seed, way) = _corridor(2);
      final motion = FakeMotionSensor();
      await _pump(tester, seed: seed, motion: motion);
      await _emit(tester, motion, _attitude());
      await _emit(tester, motion, _tilted(way));
      await tester.pumpWidget(const SizedBox());
      expect(motion.hasListener, isFalse);
    });

    testWidgets('a new sensor on rebuild is heard; the old one is let go', (
      tester,
    ) async {
      final first = FakeMotionSensor();
      final second = FakeMotionSensor();
      await _pump(tester, motion: first);
      await _pump(tester, motion: second);
      expect(first.hasListener, isFalse);
      expect(second.hasListener, isTrue);
    });

    testWidgets('a failing sensor is ignored; the arrows still work', (
      tester,
    ) async {
      final motion = FailingMotionSensor();
      final calls = await _pump(tester, motion: motion);
      motion.fail();
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(mazeArrow(TiltDirection.up));
      await tester.pump();
      expect(calls.progress, hasLength(1));
    });
  });

  group('moving', () {
    testWidgets('Capy rolls over the roll time, and wobbles on a bump', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: false);
      final mirror = _mirror();
      final open = TiltDirection.values.firstWhere(mirror.canMove);
      final start = tester.getTopLeft(_capy);
      await tester.tap(mazeArrow(open));
      await tester.pump();
      await tester.pump(TiltMazeRound.rollFor(_difficulty) * 0.4);
      final mid = tester.getTopLeft(_capy);
      expect(mid, isNot(start));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_capy), isNot(mid));

      final wall = TiltDirection.values.firstWhere(
        (d) => !mirror.move(open).canMove(d),
      );
      final rest = tester.getTopLeft(_capy);
      await tester.tap(mazeArrow(wall));
      await tester.pump();
      await tester.pump(TiltMazeView.wobble * 0.1);
      expect(tester.getTopLeft(_capy).dx, isNot(closeTo(rest.dx, 0.01)));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_capy).dx, closeTo(rest.dx, 0.01));
    });

    testWidgets('turning reduce-motion on mid-game stops the slide', (
      tester,
    ) async {
      final motion = FakeMotionSensor();
      await _pump(tester, motion: motion, reduceMotion: false);
      await _pump(tester, motion: motion);
      final open = TiltDirection.values.firstWhere(_mirror().canMove);
      await tester.tap(mazeArrow(open));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('with a screen reader nothing slides or wobbles', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: false, accessibleNavigation: true);
      await tester.tap(mazeArrow(TiltDirection.up));
      await tester.tap(mazeArrow(TiltDirection.left));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('under reduce-motion a step jumps and nothing animates', (
    tester,
  ) async {
    await _pump(tester);
    final open = TiltDirection.values.firstWhere(_mirror().canMove);
    await tester.tap(mazeArrow(open));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(_cell(tester, _mirror()), _mirror().move(open).position);
  });

  testWidgets('the arrows sit left, up, down, right — also in Arabic', (
    tester,
  ) async {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, locale: locale);
      final xs = [
        for (final d in TiltMazeView.arrowOrder)
          tester.getCenter(mazeArrow(d)).dx,
      ];
      expect(xs, [...xs]..sort(), reason: locale.languageCode);
      final field = tester.getRect(
        find.byKey(const ValueKey('tilt-maze-walls')),
      );
      final flag = tester.getCenter(
        find.byKey(const ValueKey('tilt-maze-flag')),
      );
      expect(flag.dx, greaterThan(field.center.dx), reason: 'flag stays right');
    }
  });

  testWidgets('arrows are large targets', (tester) async {
    await _pump(tester);
    for (final d in TiltDirection.values) {
      final size = tester.getSize(mazeArrow(d));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('the maze fits its field at every difficulty', (tester) async {
    for (final difficulty in PuzzleDifficulty.values) {
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, difficulty: difficulty, inRingingSlot: true);
      final field = tester.getSize(
        find.byKey(const ValueKey('tilt-maze-walls')),
      );
      expect(field.height, lessThanOrEqualTo(TiltMazeView.fieldHeight));
      final (columns, rows) = TiltMazeRound.sizeFor(difficulty);
      expect(field.width / columns, closeTo(field.height / rows, 0.01));
    }
  });

  for (final locale in AppLocalizations.supportedLocales) {
    for (final screenReader in [false, true]) {
      testWidgets(
        'the card stays within 424 pt in ${locale.languageCode}'
        '${screenReader ? ' with a screen reader' : ''}',
        (tester) async {
          await _pump(
            tester,
            locale: locale,
            inRingingSlot: true,
            accessibleNavigation: screenReader,
          );
          expect(
            tester.getSize(find.byType(CapyCard)).height,
            lessThanOrEqualTo(424),
          );
          await _keepsOutcomeHeight(tester);
        },
      );
    }
  }

  for (final locale in const [Locale('en'), Locale('de'), Locale('ru')]) {
    testWidgets('at 2x text no result line grows (${locale.languageCode})', (
      tester,
    ) async {
      await _pump(tester, locale: locale, inRingingSlot: true, textScale: 2);
      await _keepsOutcomeHeight(tester);
    });
  }

  testWidgets('with a screen reader the instruction names the arrows', (
    tester,
  ) async {
    await _pump(tester, accessibleNavigation: true);
    expect(
      find.text('Use the arrows to guide Capy to the flag.'),
      findsOneWidget,
    );
    expect(find.text('Tilt the phone to roll Capy to the flag.'), findsNothing);
  });

  testWidgets('fits a 320 pt phone: arrows narrow, nothing overflows', (
    tester,
  ) async {
    await _pump(
      tester,
      difficulty: PuzzleDifficulty.hard,
      inRingingSlot: true,
      size: const Size(320, 568),
    );
    expect(tester.takeException(), isNull);
    for (final d in TiltDirection.values) {
      expect(tester.getSize(mazeArrow(d)).width, greaterThanOrEqualTo(44));
    }
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
        expect(find.text('0 / 3'), findsOneWidget);
      });
    }
  }
}
