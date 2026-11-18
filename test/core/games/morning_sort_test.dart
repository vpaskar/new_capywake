import 'package:capywake/core/games/morning_sort.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

MorningSortRound _start({
  PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
  int seed = 1,
}) => MorningSortRound.start(difficulty: difficulty, seed: seed);

int _useful(MorningSortRound r) {
  for (var i = 0; i < r.items.length; i++) {
    if (r.items[i].useful && !r.isResolved(i)) return i;
  }
  throw StateError('no useful card left');
}

int _decoy(MorningSortRound r) {
  for (var i = 0; i < r.items.length; i++) {
    if (!r.items[i].useful && !r.isResolved(i)) return i;
  }
  throw StateError('no decoy left');
}

MorningSortRound _packBag(MorningSortRound r) {
  var round = r;
  final bags = round.bags;
  while (round.bags == bags) {
    round = round.tap(_useful(round));
  }
  return round;
}

void main() {
  test('the bank holds ten useful items and eight decoys', () {
    final useful = MorningItem.values.where((i) => i.useful);
    expect(useful, hasLength(10));
    expect(MorningItem.values.length - useful.length, 8);
  });

  test('pockets, decoys and bags follow difficulty', () {
    for (final (difficulty, pockets, decoys, bags) in [
      (PuzzleDifficulty.easy, 2, 2, 2),
      (PuzzleDifficulty.medium, 3, 3, 3),
      (PuzzleDifficulty.hard, 3, 3, 4),
    ]) {
      final round = _start(difficulty: difficulty);
      expect(round.pockets, pockets);
      expect(round.items.where((i) => i.useful), hasLength(pockets));
      expect(round.items.where((i) => !i.useful), hasLength(decoys));
      expect(round.target, bags);
      expect(MorningSortRound.pocketsFor(difficulty), pockets);
      expect(MorningSortRound.decoysFor(difficulty), decoys);
      expect(MorningSortRound.targetFor(difficulty), bags);
    }
  });

  test('the drift is calmer on easier levels', () {
    final rests = [
      for (final d in PuzzleDifficulty.values) MorningSortRound.swapEveryFor(d),
    ];
    expect(rests, [
      const Duration(milliseconds: 3200),
      const Duration(milliseconds: 2600),
      const Duration(milliseconds: 2000),
    ]);
  });

  test('starts with nothing packed and no outcome', () {
    final round = _start();
    expect(round.packed, isEmpty);
    expect(round.leftOut, isEmpty);
    expect(round.bags, 0);
    expect(round.lastOutcome, isNull);
    expect(round.challenge.isComplete, isFalse);
  });

  test('a bag never shows one item twice, on any level, over every bag', () {
    for (final difficulty in PuzzleDifficulty.values) {
      for (var seed = 0; seed < 40; seed++) {
        var round = _start(difficulty: difficulty, seed: seed);
        while (!round.isComplete) {
          expect(round.items.toSet(), hasLength(round.items.length));
          round = _packBag(round);
        }
      }
    }
  });

  test('the same seed deals the same bags', () {
    expect(_start(seed: 9).items, _start(seed: 9).items);
    expect(_packBag(_start(seed: 9)).items, _packBag(_start(seed: 9)).items);
  });

  test('a useful item is packed, in order, without ending the bag', () {
    final start = _start();
    final first = _useful(start);
    final next = start.tap(first);
    expect(next.packed, [first]);
    expect(next.isResolved(first), isTrue);
    expect(next.lastOutcome, MorningSortOutcome.packed);
    expect(next.bags, 0);
    expect(next.items, start.items);
  });

  test('the last pocket finishes the bag and deals a new one', () {
    final start = _start();
    final next = _packBag(start);
    expect(next.bags, 1);
    expect(next.packed, isEmpty);
    expect(next.leftOut, isEmpty);
    expect(next.lastOutcome, MorningSortOutcome.bagDone);
    expect(next.challenge.completed, 1);
    expect(next.items, isNot(start.items));
  });

  test('a decoy is set aside as a struggle and cannot count twice', () {
    final start = _start();
    final decoy = _decoy(start);
    final next = start.tap(decoy);
    expect(next.leftOut, {decoy});
    expect(next.wrongTaps, 1);
    expect(next.challenge.struggleCount, 1);
    expect(next.lastOutcome, MorningSortOutcome.leftOut);
    expect(identical(next.tap(decoy), next), isTrue);
  });

  test('a decoy never undoes packing', () {
    final packed = _start().tap(_useful(_start()));
    final next = packed.tap(_decoy(packed));
    expect(next.packed, packed.packed);
  });

  test('a packed card tapped again is a no-op', () {
    final start = _start();
    final index = _useful(start);
    final packed = start.tap(index);
    expect(identical(packed.tap(index), packed), isTrue);
  });

  test('the last pocket keeps the final bag on show, all packed', () {
    var round = _start(difficulty: PuzzleDifficulty.easy);
    round = _packBag(round);
    final lastBag = round.items;
    round = _packBag(round);
    expect(round.isComplete, isTrue);
    expect(round.items, lastBag);
    expect(round.packed, hasLength(round.pockets));
    expect(round.lastOutcome, MorningSortOutcome.bagDone);
  });

  test('every bag packed completes the game; a late tap is a no-op', () {
    var round = _start(difficulty: PuzzleDifficulty.hard);
    while (!round.isComplete) {
      round = _packBag(round);
    }
    expect(round.bags, 4);
    expect(round.challenge.isComplete, isTrue);
    expect(identical(round.tap(0), round), isTrue);
  });

  test('a tap outside the cards throws', () {
    expect(() => _start().tap(-1), throwsRangeError);
    expect(() => _start().tap(6), throwsRangeError);
  });

  test('state lists are read-only', () {
    final round = _start().tap(_useful(_start()));
    expect(() => round.items.add(MorningItem.apple), throwsUnsupportedError);
    expect(() => round.packed.add(0), throwsUnsupportedError);
    expect(() => round.leftOut.add(0), throwsUnsupportedError);
  });
}
