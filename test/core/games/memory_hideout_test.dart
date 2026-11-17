import 'package:capywake/core/games/memory_hideout.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

MemoryHideoutRound _start({
  PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
  int seed = 1,
}) => MemoryHideoutRound.start(difficulty: difficulty, seed: seed);

int _wrong(MemoryHideoutRound r) => (r.hiddenAt + 1) % r.bushCount;

void main() {
  test('rounds and bushes follow difficulty; medium is the poster 3 x 3', () {
    final easy = _start(difficulty: PuzzleDifficulty.easy);
    final medium = _start();
    final hard = _start(difficulty: PuzzleDifficulty.hard);
    expect([easy.target, easy.bushCount], [2, 3]);
    expect([medium.target, medium.bushCount], [3, 3]);
    expect([hard.target, hard.bushCount], [4, 4]);
  });

  test('starts revealing, with no outcome yet', () {
    final round = _start();
    expect(round.phase, MemoryHideoutPhase.revealing);
    expect(round.lastOutcome, isNull);
    expect(round.hiddenAt, inInclusiveRange(0, round.bushCount - 1));
  });

  test('a pick before Ready is ignored', () {
    final round = _start();
    expect(identical(round.pick(round.hiddenAt), round), isTrue);
  });

  test('Ready hides Capy; a second Ready is a no-op', () {
    final guessing = _start().ready();
    expect(guessing.phase, MemoryHideoutPhase.guessing);
    expect(identical(guessing.ready(), guessing), isTrue);
  });

  test('a right pick counts and reveals again, marked found', () {
    final start = _start().ready();
    final next = start.pick(start.hiddenAt);
    expect(next.found, 1);
    expect(next.wrongPicks, 0);
    expect(next.phase, MemoryHideoutPhase.revealing);
    expect(next.lastOutcome, MemoryHideoutOutcome.found);
  });

  test('a wrong pick is struggle and shows the same bush again', () {
    final start = _start().ready();
    final next = start.pick(_wrong(start));
    expect(next.found, 0);
    expect(next.wrongPicks, 1);
    expect(next.hiddenAt, start.hiddenAt);
    expect(next.phase, MemoryHideoutPhase.revealing);
    expect(next.lastOutcome, MemoryHideoutOutcome.missed);
    expect(next.challenge.struggleCount, 1);
  });

  test('a pick outside the row throws', () {
    final round = _start().ready();
    expect(() => round.pick(-1), throwsRangeError);
    expect(() => round.pick(round.bushCount), throwsRangeError);
  });

  test('completes at the goal, then ignores Ready and picks', () {
    var round = _start(difficulty: PuzzleDifficulty.easy);
    for (var i = 0; i < 2; i++) {
      round = round.ready();
      round = round.pick(round.hiddenAt);
    }
    expect(round.isComplete, isTrue);
    expect(round.challenge.isComplete, isTrue);
    expect(identical(round.ready(), round), isTrue);
    expect(identical(round.pick(0), round), isTrue);
  });

  test('the same seed hides Capy in the same places', () {
    var a = _start(seed: 9);
    var b = _start(seed: 9);
    for (var i = 0; i < 3; i++) {
      expect(a.hiddenAt, b.hiddenAt);
      a = a.ready().pick(a.hiddenAt);
      b = b.ready().pick(b.hiddenAt);
    }
  });

  group('shuffle', () {
    test('swap count follows difficulty', () {
      expect(MemoryHideoutRound.swapCountFor(PuzzleDifficulty.easy), 1);
      expect(MemoryHideoutRound.swapCountFor(PuzzleDifficulty.medium), 2);
      expect(MemoryHideoutRound.swapCountFor(PuzzleDifficulty.hard), 3);
    });

    test('Capy follows its bush through every swap', () {
      for (var seed = 0; seed < 200; seed++) {
        final start = _start(seed: seed, difficulty: PuzzleDifficulty.hard);
        final shuffled = start.ready(shuffle: true);
        var at = start.hiddenAt;
        for (final (a, b) in shuffled.swaps) {
          expect(a, isNot(b));
          if (at == a) {
            at = b;
          } else if (at == b) {
            at = a;
          }
        }
        expect(shuffled.hiddenAt, at, reason: 'seed $seed');
        expect(shuffled.phase, MemoryHideoutPhase.shuffling);
      }
    });

    test('picks wait for the shuffle to finish', () {
      final shuffled = _start().ready(shuffle: true);
      expect(identical(shuffled.pick(shuffled.hiddenAt), shuffled), isTrue);
      final guessing = shuffled.finishShuffle();
      expect(guessing.phase, MemoryHideoutPhase.guessing);
      expect(guessing.swaps, isEmpty);
      expect(guessing.pick(guessing.hiddenAt).found, 1);
      expect(identical(guessing.finishShuffle(), guessing), isTrue);
    });
  });
}
