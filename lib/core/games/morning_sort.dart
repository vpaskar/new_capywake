import 'dart:math' as math;

import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:meta/meta.dart';

/// Morning Sort's authored bank (owner lifted the content-bank ban for this
/// game, 2026-11-15). Decoys are absurd on purpose: a fair, quick decision.
enum MorningItem {
  toothbrush(useful: true),
  toothpaste(useful: true),
  apple(useful: true),
  banana(useful: true),
  waterBottle(useful: true),
  keys(useful: true),
  socks(useful: true),
  shoes(useful: true),
  comb(useful: true),
  towel(useful: true),
  brick(useful: false),
  anchor(useful: false),
  trafficCone(useful: false),
  bowlingBall(useful: false),
  cactus(useful: false),
  rubberDuck(useful: false),
  anvil(useful: false),
  snowman(useful: false);

  const MorningItem({required this.useful});

  /// Whether Capy needs it this morning.
  final bool useful;
}

enum MorningSortOutcome { packed, leftOut, bagDone }

/// Morning Sort: pack what Capy needs this morning. A decoy is set aside and
/// counts as a struggle; nothing packed is ever lost.
@immutable
class MorningSortRound {
  MorningSortRound._(
    this._seed,
    this._decks, {
    required this.pockets,
    required List<MorningItem> items,
    required List<int> packed,
    required Set<int> leftOut,
    required this.target,
    required this.bags,
    required this.wrongTaps,
    required this.lastOutcome,
  }) : items = List.unmodifiable(items),
       packed = List.unmodifiable(packed),
       leftOut = Set.unmodifiable(leftOut);

  factory MorningSortRound.start({
    required PuzzleDifficulty difficulty,
    required int seed,
  }) {
    final random = math.Random(seed);
    final decks = (
      useful: [
        for (final item in MorningItem.values)
          if (item.useful) item,
      ]..shuffle(random),
      decoy: [
        for (final item in MorningItem.values)
          if (!item.useful) item,
      ]..shuffle(random),
      decoys: decoysFor(difficulty),
    );
    final pockets = pocketsFor(difficulty);
    return MorningSortRound._(
      PuzzleRound.advanceSeed(seed),
      decks,
      pockets: pockets,
      items: _deal(decks, pockets, bag: 0, seed: seed),
      packed: const [],
      leftOut: const {},
      target: targetFor(difficulty),
      bags: 0,
      wrongTaps: 0,
      lastOutcome: null,
    );
  }

  static int pocketsFor(PuzzleDifficulty difficulty) =>
      difficulty == PuzzleDifficulty.easy ? 2 : 3;

  static int decoysFor(PuzzleDifficulty difficulty) =>
      difficulty == PuzzleDifficulty.easy ? 2 : 3;

  static int targetFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => 2,
    PuzzleDifficulty.medium => 3,
    PuzzleDifficulty.hard => 4,
  };

  /// How long the cards rest between two drifting swaps.
  static Duration swapEveryFor(PuzzleDifficulty difficulty) =>
      switch (difficulty) {
        PuzzleDifficulty.easy => const Duration(milliseconds: 3200),
        PuzzleDifficulty.medium => const Duration(milliseconds: 2600),
        PuzzleDifficulty.hard => const Duration(milliseconds: 2000),
      };

  static List<MorningItem> _deal(
    _Decks decks,
    int pockets, {
    required int bag,
    required int seed,
  }) => [
    for (var i = 0; i < pockets; i++)
      decks.useful[(bag * pockets + i) % decks.useful.length],
    for (var i = 0; i < decks.decoys; i++)
      decks.decoy[(bag * decks.decoys + i) % decks.decoy.length],
  ]..shuffle(math.Random(seed));

  final int _seed;
  final _Decks _decks;

  /// Useful items per bag: the pockets to fill.
  final int pockets;

  /// The cards on show for the current bag.
  final List<MorningItem> items;

  /// Indices into [items], in the order they were packed.
  final List<int> packed;

  /// Indices into [items] set aside as not needed.
  final Set<int> leftOut;

  final int target;
  final int bags;
  final int wrongTaps;

  /// The result of the last tap, `null` before the first.
  final MorningSortOutcome? lastOutcome;

  bool get isComplete => bags >= target;

  bool isResolved(int index) =>
      packed.contains(index) || leftOut.contains(index);

  GameChallenge get challenge => GameChallenge.touch(
    target: target,
    completed: bags,
    struggleCount: wrongTaps,
  );

  /// A no-op once complete or on a card already decided, so a double tap
  /// counts once.
  MorningSortRound tap(int index) {
    RangeError.checkValidIndex(index, items, 'index');
    if (isComplete || isResolved(index)) return this;
    if (!items[index].useful) {
      return _copy(
        leftOut: {...leftOut, index},
        wrongTaps: wrongTaps + 1,
        lastOutcome: MorningSortOutcome.leftOut,
      );
    }
    if (packed.length + 1 < pockets) {
      return _copy(
        packed: [...packed, index],
        lastOutcome: MorningSortOutcome.packed,
      );
    }
    final bag = bags + 1;
    if (bag >= target) {
      return MorningSortRound._(
        _seed,
        _decks,
        pockets: pockets,
        items: items,
        packed: [...packed, index],
        leftOut: leftOut,
        target: target,
        bags: bag,
        wrongTaps: wrongTaps,
        lastOutcome: MorningSortOutcome.bagDone,
      );
    }
    return MorningSortRound._(
      PuzzleRound.advanceSeed(_seed),
      _decks,
      pockets: pockets,
      items: _deal(_decks, pockets, bag: bag, seed: _seed),
      packed: const [],
      leftOut: const {},
      target: target,
      bags: bag,
      wrongTaps: wrongTaps,
      lastOutcome: MorningSortOutcome.bagDone,
    );
  }

  MorningSortRound _copy({
    required MorningSortOutcome lastOutcome,
    List<int>? packed,
    Set<int>? leftOut,
    int? wrongTaps,
  }) => MorningSortRound._(
    _seed,
    _decks,
    pockets: pockets,
    items: items,
    packed: packed ?? this.packed,
    leftOut: leftOut ?? this.leftOut,
    target: target,
    bags: bags,
    wrongTaps: wrongTaps ?? this.wrongTaps,
    lastOutcome: lastOutcome,
  );
}

typedef _Decks = ({
  List<MorningItem> useful,
  List<MorningItem> decoy,
  int decoys,
});
