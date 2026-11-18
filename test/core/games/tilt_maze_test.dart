import 'package:capywake/core/games/tilt_maze.dart';
import 'package:capywake/core/motion/tilt_reader.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:flutter_test/flutter_test.dart';

TiltMazeRound _start({
  PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
  int seed = 3,
}) => TiltMazeRound.start(difficulty: difficulty, seed: seed);

/// The first step on the shortest way to the flag.
TiltDirection _towardFlag(TiltMazeRound round) {
  final here = round.stepsToFlag;
  return TiltDirection.values.firstWhere(
    (d) =>
        round.canMove(d) &&
        round.maze.stepsToFlag(round.maze.neighbour(round.position, d)!) < here,
  );
}

TiltDirection _wall(TiltMazeRound round) =>
    TiltDirection.values.firstWhere((d) => !round.canMove(d));

TiltMazeRound _solveOne(TiltMazeRound round) {
  final solved = round.solved;
  var r = round;
  while (r.solved == solved) {
    r = r.move(_towardFlag(r));
  }
  return r;
}

void main() {
  group('MazeGrid', () {
    test('is perfect: connected, and a tree, across 200 seeds', () {
      for (var seed = 0; seed < 200; seed++) {
        for (final (cols, rows) in [(5, 4), (6, 4), (7, 4)]) {
          final maze = MazeGrid.generate(
            columns: cols,
            rows: rows,
            seed: seed,
          );
          var openEdges = 0;
          for (var cell = 0; cell < maze.cellCount; cell++) {
            maze.stepsToFlag(cell);
            for (final d in [TiltDirection.right, TiltDirection.down]) {
              if (maze.isOpen(cell, d)) openEdges++;
            }
          }
          expect(openEdges, maze.cellCount - 1, reason: 'seed $seed');
        }
      }
    });

    test('is seeded', () {
      MazeGrid make(int seed) =>
          MazeGrid.generate(columns: 6, rows: 4, seed: seed);
      List<bool> walls(MazeGrid m) => [
        for (var c = 0; c < m.cellCount; c++)
          for (final d in TiltDirection.values) m.isOpen(c, d),
      ];
      expect(walls(make(7)), walls(make(7)));
      expect(walls(make(7)), isNot(walls(make(8))));
    });

    test('edges read the same from both sides; the rim is closed', () {
      final maze = MazeGrid.generate(columns: 5, rows: 4, seed: 1);
      for (var cell = 0; cell < maze.cellCount; cell++) {
        expect(
          maze.isOpen(cell, TiltDirection.up),
          cell >= 5 && maze.isOpen(cell - 5, TiltDirection.down),
        );
        expect(
          maze.isOpen(cell, TiltDirection.left),
          cell % 5 > 0 && maze.isOpen(cell - 1, TiltDirection.right),
        );
      }
      expect(maze.neighbour(4, TiltDirection.right), isNull);
      expect(maze.neighbour(19, TiltDirection.down), isNull);
      expect([maze.start, maze.flag], [0, 19]);
      expect(maze.stepsToFlag(maze.flag), 0);
    });

    test('needs room to turn', () {
      expect(
        () => MazeGrid.generate(columns: 1, rows: 4, seed: 1),
        throwsAssertionError,
      );
    });
  });

  test('size and roll speed follow difficulty; always three mazes', () {
    for (final (difficulty, cols, rollMs) in [
      (PuzzleDifficulty.easy, 5, 420),
      (PuzzleDifficulty.medium, 6, 340),
      (PuzzleDifficulty.hard, 7, 280),
    ]) {
      final round = _start(difficulty: difficulty);
      expect([round.maze.columns, round.maze.rows], [cols, 4]);
      expect(TiltMazeRound.rollFor(difficulty), Duration(milliseconds: rollMs));
    }
    expect(TiltMazeRound.target, 3);
  });

  test('starts top-left with no outcome', () {
    final round = _start();
    expect(
      [round.position, round.solved, round.bumps, round.moves],
      [
        0,
        0,
        0,
        0,
      ],
    );
    expect(round.lastOutcome, isNull);
  });

  test('a step moves Capy one cell closer or further', () {
    final round = _start();
    final step = round.move(_towardFlag(round));
    expect(step.lastOutcome, TiltMazeOutcome.stepped);
    expect(step.stepsToFlag, round.stepsToFlag - 1);
    expect(step.moves, 1);
    expect(step.bumps, 0);
  });

  test('a wall is a bump: Capy stays, a struggle is counted', () {
    final round = _start();
    final bump = round.move(_wall(round));
    expect(bump.position, round.position);
    expect(bump.bumps, 1);
    expect(bump.moves, 1);
    expect(bump.lastOutcome, TiltMazeOutcome.bumped);
  });

  test('reaching the flag opens a fresh maze back at the start', () {
    final first = _start();
    final next = _solveOne(first);
    expect(next.solved, 1);
    expect(next.position, 0);
    expect(next.lastOutcome, TiltMazeOutcome.escaped);
    expect(next.maze, isNot(same(first.maze)));
    expect(next.bumps, 0);
  });

  test('three mazes complete it; later moves are no-ops', () {
    var round = _start();
    for (var i = 0; i < 3; i++) {
      round = _solveOne(round);
    }
    expect(round.isComplete, isTrue);
    expect(round.move(TiltDirection.down), same(round));
  });

  test('the challenge is a motion game with a touch fallback', () {
    final round = _start();
    final challenge = round.move(_wall(round)).challenge;
    expect(challenge.requiresMotion, isTrue);
    expect(
      [challenge.target, challenge.completed, challenge.struggleCount],
      [
        3,
        0,
        1,
      ],
    );
    expect(challenge.motionFallback!.requiresMotion, isFalse);
    expect(challenge.motionFallback!.struggleCount, 1);
    expect(
      challenge.escapeVisibilityFor(toleratedStruggles: 0),
      PuzzleEscapeVisibility.prominent,
    );
  });

  test('the first maze is seeded by the ring', () {
    expect(_start(seed: 4).stepsToFlag, _start(seed: 4).stepsToFlag);
  });
}
