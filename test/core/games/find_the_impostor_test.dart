import 'package:capywake/core/games/find_the_impostor.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

FindTheImpostorRound _start({
  PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
  int seed = 1,
}) => FindTheImpostorRound.start(difficulty: difficulty, seed: seed);

int _wrong(FindTheImpostorRound r) => (r.oddAt + 1) % r.cellCount;

void main() {
  test('cells and finds follow difficulty; medium has the poster three', () {
    for (final (difficulty, cells, finds) in [
      (PuzzleDifficulty.easy, 4, 2),
      (PuzzleDifficulty.medium, 6, 3),
      (PuzzleDifficulty.hard, 8, 4),
    ]) {
      final round = _start(difficulty: difficulty);
      expect([round.cellCount, round.target], [cells, finds]);
    }
  });

  test('the drift is calmer on easier levels', () {
    expect(
      [
        for (final d in PuzzleDifficulty.values)
          FindTheImpostorRound.swapEveryFor(d),
      ],
      [
        const Duration(milliseconds: 3200),
        const Duration(milliseconds: 2600),
        const Duration(milliseconds: 2000),
      ],
    );
  });

  test('the bank is four groups of four', () {
    for (final group in CapyPoseGroup.values) {
      expect(CapyPose.values.where((p) => p.group == group), hasLength(4));
    }
  });

  test('easy and medium pair across groups, hard within one', () {
    for (final difficulty in PuzzleDifficulty.values) {
      final pairs = FindTheImpostorRound.pairsFor(difficulty);
      expect(pairs, isNotEmpty);
      for (final (common, odd) in pairs) {
        expect(common, isNot(odd));
        expect(
          common.group == odd.group,
          difficulty == PuzzleDifficulty.hard,
          reason: '$difficulty $common/$odd',
        );
      }
    }
  });

  test('no deal is ever an excluded pair, either way round', () {
    expect(
      FindTheImpostorRound.isExcluded(CapyPose.partying, CapyPose.cheering),
      isTrue,
    );
    for (final difficulty in PuzzleDifficulty.values) {
      for (var seed = 0; seed < 60; seed++) {
        var round = _start(difficulty: difficulty, seed: seed);
        while (!round.isComplete) {
          expect(
            FindTheImpostorRound.isExcluded(round.common, round.odd),
            isFalse,
          );
          round = round.tap(round.oddAt);
        }
      }
    }
  });

  test('one cell shows the odd pose, the rest the common one', () {
    final round = _start(difficulty: PuzzleDifficulty.hard, seed: 4);
    final poses = [for (var c = 0; c < round.cellCount; c++) round.poseAt(c)];
    expect(poses.where((p) => p == round.odd), hasLength(1));
    expect(poses.indexOf(round.odd), round.oddAt);
    expect(poses.where((p) => p == round.common), hasLength(7));
  });

  test('the same seed deals the same set', () {
    final a = _start(seed: 5);
    final b = _start(seed: 5);
    expect([a.common, a.odd, a.oddAt], [b.common, b.odd, b.oddAt]);
  });

  test('a find counts, deals a new set and never repeats the common', () {
    for (var seed = 0; seed < 40; seed++) {
      final start = _start(seed: seed);
      final next = start.tap(start.oddAt);
      expect(next.found, 1);
      expect(next.lastOutcome, FindTheImpostorOutcome.found);
      expect(next.common, isNot(start.common));
      expect(next.challenge.completed, 1);
    }
  });

  test('a wrong tap is struggle and keeps the same set', () {
    final start = _start();
    final next = start.tap(_wrong(start));
    expect(next.found, 0);
    expect(next.wrongTaps, 1);
    expect(next.challenge.struggleCount, 1);
    expect(
      [next.common, next.odd, next.oddAt],
      [
        start.common,
        start.odd,
        start.oddAt,
      ],
    );
    expect(next.lastOutcome, FindTheImpostorOutcome.missed);
  });

  test('the final find keeps the set on show', () {
    var round = _start(difficulty: PuzzleDifficulty.easy);
    round = round.tap(round.oddAt);
    final last = round;
    round = round.tap(round.oddAt);
    expect(round.isComplete, isTrue);
    expect(
      [round.common, round.odd, round.oddAt],
      [
        last.common,
        last.odd,
        last.oddAt,
      ],
    );
    expect(round.lastOutcome, FindTheImpostorOutcome.found);
  });

  test('every find completes the game; a late tap is a no-op', () {
    var round = _start(difficulty: PuzzleDifficulty.easy);
    for (var i = 0; i < 2; i++) {
      round = round.tap(round.oddAt);
    }
    expect(round.isComplete, isTrue);
    expect(round.challenge.isComplete, isTrue);
    expect(identical(round.tap(0), round), isTrue);
  });

  test('a tap outside the grid throws', () {
    expect(() => _start().tap(-1), throwsRangeError);
    expect(() => _start().tap(6), throwsRangeError);
  });
}
