import 'dart:collection';
import 'dart:math' as math;

import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/motion/tilt_reader.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:meta/meta.dart';

/// A perfect maze: every cell reachable, one path between any two. Cells are
/// row-major; Capy starts top-left and the flag is bottom-right.
@immutable
class MazeGrid {
  const MazeGrid._(this.columns, this.rows, this._open);

  /// Seeded iterative depth-first carving.
  factory MazeGrid.generate({
    required int columns,
    required int rows,
    required int seed,
  }) {
    assert(columns > 1 && rows > 1, 'a maze needs room to turn');
    final random = math.Random(seed);
    final open = <int>{};
    final visited = <int>{0};
    final stack = <int>[0];
    final grid = MazeGrid._(columns, rows, const {});
    while (stack.isNotEmpty) {
      final cell = stack.last;
      final fresh = [
        for (final d in TiltDirection.values)
          if (grid.neighbour(cell, d) case final n?)
            if (!visited.contains(n)) (d, n),
      ];
      if (fresh.isEmpty) {
        stack.removeLast();
        continue;
      }
      final (direction, next) = fresh[random.nextInt(fresh.length)];
      open.add(_edge(cell, direction, columns));
      visited.add(next);
      stack.add(next);
    }
    return MazeGrid._(columns, rows, Set.unmodifiable(open));
  }

  final int columns;
  final int rows;
  final Set<int> _open;

  int get cellCount => columns * rows;
  int get start => 0;
  int get flag => cellCount - 1;

  /// The cell beside [cell] toward [direction], or `null` off the grid.
  int? neighbour(int cell, TiltDirection direction) {
    final column = cell % columns;
    final row = cell ~/ columns;
    return switch (direction) {
      TiltDirection.up => row > 0 ? cell - columns : null,
      TiltDirection.down => row < rows - 1 ? cell + columns : null,
      TiltDirection.left => column > 0 ? cell - 1 : null,
      TiltDirection.right => column < columns - 1 ? cell + 1 : null,
    };
  }

  /// Whether Capy can step from [cell] toward [direction].
  bool isOpen(int cell, TiltDirection direction) =>
      neighbour(cell, direction) != null &&
      _open.contains(_edge(cell, direction, columns));

  /// Steps from [cell] to the flag along open edges. A perfect maze always
  /// reaches it, so the queue never runs dry.
  int stepsToFlag(int cell) {
    final distance = <int, int>{cell: 0};
    final queue = Queue<int>.of([cell]);
    while (true) {
      final at = queue.removeFirst();
      if (at == flag) return distance[at]!;
      for (final d in TiltDirection.values) {
        if (!isOpen(at, d)) continue;
        final next = neighbour(at, d)!;
        if (distance.containsKey(next)) continue;
        distance[next] = distance[at]! + 1;
        queue.add(next);
      }
    }
  }

  /// An edge is stored once, on its upper or left cell.
  static int _edge(int cell, TiltDirection direction, int columns) =>
      switch (direction) {
        TiltDirection.right => cell * 2,
        TiltDirection.down => cell * 2 + 1,
        TiltDirection.left => (cell - 1) * 2,
        TiltDirection.up => (cell - columns) * 2 + 1,
      };
}

enum TiltMazeOutcome { stepped, bumped, escaped }

/// Tilt Maze: roll Capy to the flag, three mazes in a row. A step into a wall
/// is a bump, the game's struggle; Capy stays where it was.
@immutable
class TiltMazeRound {
  const TiltMazeRound._(
    this._seed, {
    required this.maze,
    required this.position,
    required this.solved,
    required this.bumps,
    required this.moves,
    required this.lastOutcome,
  });

  factory TiltMazeRound.start({
    required PuzzleDifficulty difficulty,
    required int seed,
  }) {
    final (columns, rows) = sizeFor(difficulty);
    return TiltMazeRound._(
      PuzzleRound.advanceSeed(seed),
      maze: MazeGrid.generate(columns: columns, rows: rows, seed: seed),
      position: 0,
      solved: 0,
      bumps: 0,
      moves: 0,
      lastOutcome: null,
    );
  }

  static const target = 3;

  static (int, int) sizeFor(PuzzleDifficulty difficulty) =>
      switch (difficulty) {
        PuzzleDifficulty.easy => (5, 4),
        PuzzleDifficulty.medium => (6, 4),
        PuzzleDifficulty.hard => (7, 4),
      };

  /// How long one cell's roll takes while the phone is tilted.
  static Duration rollFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => const Duration(milliseconds: 420),
    PuzzleDifficulty.medium => const Duration(milliseconds: 340),
    PuzzleDifficulty.hard => const Duration(milliseconds: 280),
  };

  final int _seed;
  final MazeGrid maze;
  final int position;
  final int solved;
  final int bumps;

  /// Every move tried, bumps included: a serial for repeated outcomes.
  final int moves;
  final TiltMazeOutcome? lastOutcome;

  bool get isComplete => solved >= target;

  int get stepsToFlag => maze.stepsToFlag(position);

  bool canMove(TiltDirection direction) => maze.isOpen(position, direction);

  GameChallenge get challenge => GameChallenge.motion(
    target: target,
    completed: solved,
    struggleCount: bumps,
    fallback: GameChallenge.touch(
      target: target,
      completed: solved,
      struggleCount: bumps,
    ),
  );

  /// A no-op once complete, so a late tilt counts for nothing.
  TiltMazeRound move(TiltDirection direction) {
    if (isComplete) return this;
    if (!canMove(direction)) {
      return _copy(bumps: bumps + 1, outcome: TiltMazeOutcome.bumped);
    }
    final next = maze.neighbour(position, direction)!;
    if (next != maze.flag) {
      return _copy(position: next, outcome: TiltMazeOutcome.stepped);
    }
    return TiltMazeRound._(
      PuzzleRound.advanceSeed(_seed),
      maze: MazeGrid.generate(
        columns: maze.columns,
        rows: maze.rows,
        seed: _seed,
      ),
      position: 0,
      solved: solved + 1,
      bumps: bumps,
      moves: moves + 1,
      lastOutcome: TiltMazeOutcome.escaped,
    );
  }

  TiltMazeRound _copy({
    required TiltMazeOutcome outcome,
    int? position,
    int? bumps,
  }) => TiltMazeRound._(
    _seed,
    maze: maze,
    position: position ?? this.position,
    solved: solved,
    bumps: bumps ?? this.bumps,
    moves: moves + 1,
    lastOutcome: outcome,
  );
}
