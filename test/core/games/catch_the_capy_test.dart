import 'package:capywake/core/games/catch_the_capy.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

CatchTheCapyRound _start({
  PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
  int seed = 1,
}) => CatchTheCapyRound.start(difficulty: difficulty, seed: seed);

void main() {
  test('the goal follows difficulty; medium is the poster five', () {
    expect(_start(difficulty: PuzzleDifficulty.easy).target, 3);
    expect(_start().target, 5);
    expect(_start(difficulty: PuzzleDifficulty.hard).target, 7);
  });

  test('starts with nothing caught and nothing missed', () {
    final round = _start();
    expect(round.caught, 0);
    expect(round.misses, 0);
    expect(round.isComplete, isFalse);
    expect(round.spot, inInclusiveRange(0, CatchTheCapyRound.spotCount - 1));
  });

  test('a catch always moves the capybara to a different spot', () {
    for (var seed = 0; seed < 200; seed++) {
      final round = _start(seed: seed, difficulty: PuzzleDifficulty.hard);
      final next = round.catchCapy();
      expect(next.spot, isNot(round.spot), reason: 'seed $seed');
      expect(next.caught, 1);
    }
  });

  test('a miss counts as struggle and leaves the capybara in place', () {
    final round = _start().miss();
    expect(round.misses, 1);
    expect(round.spot, _start().spot);
    expect(round.challenge.struggleCount, 1);
  });

  test('column and row index the 3x3 grid row-major', () {
    for (var seed = 0; seed < 30; seed++) {
      final round = _start(seed: seed);
      expect(round.row * CatchTheCapyRound.columns + round.column, round.spot);
    }
  });

  test('reaching the goal completes, then catches and misses are no-ops', () {
    var round = _start(difficulty: PuzzleDifficulty.easy);
    for (var i = 0; i < 3; i++) {
      round = round.catchCapy();
    }
    expect(round.isComplete, isTrue);
    expect(round.challenge.isComplete, isTrue);
    expect(identical(round.catchCapy(), round), isTrue);
    expect(identical(round.miss(), round), isTrue);
  });

  test('the same seed replays the same spots', () {
    var a = _start(seed: 42);
    var b = _start(seed: 42);
    for (var i = 0; i < 4; i++) {
      expect(a.spot, b.spot);
      a = a.catchCapy();
      b = b.catchCapy();
    }
  });

  test('wandering moves the capybara without counting anything', () {
    for (var seed = 0; seed < 100; seed++) {
      final round = _start(seed: seed);
      final next = round.wander();
      expect(next.spot, isNot(round.spot));
      expect([next.caught, next.misses], [0, 0]);
    }
  });

  test('a finished round no longer wanders', () {
    var round = _start(difficulty: PuzzleDifficulty.easy);
    for (var i = 0; i < 3; i++) {
      round = round.catchCapy();
    }
    expect(identical(round.wander(), round), isTrue);
  });

  test('it flees to a spot farthest from the tap', () {
    for (var seed = 0; seed < 60; seed++) {
      final round = _start(seed: seed);
      final fled = round.fleeFrom(column: 0, row: 0);
      expect(fled.spot, isNot(round.spot));
      expect(
        [fled.column, fled.row],
        anyOf(equals([2, 2]), equals([2, 1]), equals([1, 2])),
        reason: 'farthest from the top-left corner',
      );
      expect([fled.caught, fled.misses], [0, 0]);
    }
  });

  test('a finished round no longer flees', () {
    var round = _start(difficulty: PuzzleDifficulty.easy);
    for (var i = 0; i < 3; i++) {
      round = round.catchCapy();
    }
    expect(identical(round.fleeFrom(column: 0, row: 0), round), isTrue);
  });

  test('harder means faster', () {
    expect(
      CatchTheCapyRound.runFor(PuzzleDifficulty.hard),
      lessThan(CatchTheCapyRound.runFor(PuzzleDifficulty.easy)),
    );
    expect(
      CatchTheCapyRound.runFor(PuzzleDifficulty.medium),
      const Duration(seconds: 1),
    );
  });

  test('once caught it lands clear of where it was caught', () {
    for (var seed = 0; seed < 300; seed++) {
      final round = _start(seed: seed, difficulty: PuzzleDifficulty.hard);
      final next = round.catchCapy();
      final dc = next.column - round.column;
      final dr = next.row - round.row;
      final fromCentre = round.column == 1 && round.row == 1;
      expect(
        dc * dc + dr * dr,
        greaterThanOrEqualTo(fromCentre ? 2 : 4),
        reason: 'seed $seed: ${round.spot} -> ${next.spot}',
      );
    }
  });

  test('where it lands after a catch still varies', () {
    final landings = {
      for (var seed = 0; seed < 300; seed++)
        _start(seed: seed).catchCapy().spot,
    };
    expect(landings.length, greaterThan(4));
  });
}
