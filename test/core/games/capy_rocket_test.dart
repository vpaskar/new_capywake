import 'package:capywake/core/games/capy_rocket.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:flutter_test/flutter_test.dart';

CapyRocketRound _start({
  PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
  int seed = 1,
}) => CapyRocketRound.start(difficulty: difficulty, seed: seed);

RocketSide _other(RocketSide side) =>
    side == RocketSide.start ? RocketSide.end : RocketSide.start;

void main() {
  test('boosts and climb speed follow difficulty', () {
    for (final (difficulty, target, climbMs) in [
      (PuzzleDifficulty.easy, 6, 700),
      (PuzzleDifficulty.medium, 8, 550),
      (PuzzleDifficulty.hard, 10, 420),
    ]) {
      expect(_start(difficulty: difficulty).target, target);
      expect(
        CapyRocketRound.climbFor(difficulty),
        Duration(milliseconds: climbMs),
      );
    }
  });

  test('starts on the ground with no outcome', () {
    final round = _start();
    expect([round.boosts, round.wobbles], [0, 0]);
    expect(round.altitude, 0);
    expect(round.lastOutcome, isNull);
  });

  test('the cue is seeded and both sides occur', () {
    expect(_start(seed: 9).cue, _start(seed: 9).cue);
    final cues = {for (var s = 0; s < 20; s++) _start(seed: s).cue};
    expect(cues, {RocketSide.start, RocketSide.end});
  });

  test('a swipe toward the cue boosts and draws the next cue', () {
    final round = _start();
    final boosted = round.boost(round.cue);
    expect(boosted.boosts, 1);
    expect(boosted.wobbles, 0);
    expect(boosted.altitude, 1 / 8);
    expect(boosted.lastOutcome, CapyRocketOutcome.boosted);
  });

  test('cues along a climb vary', () {
    var round = _start(seed: 3);
    final cues = <RocketSide>{};
    while (!round.isComplete) {
      cues.add(round.cue);
      round = round.boost(round.cue);
    }
    expect(cues, {RocketSide.start, RocketSide.end});
  });

  test('a swipe the other way wobbles: no climb lost, cue kept', () {
    final up = _start().boost(_start().cue);
    final wobbled = up.boost(_other(up.cue));
    expect(wobbled.boosts, 1);
    expect(wobbled.wobbles, 1);
    expect(wobbled.cue, up.cue);
    expect(wobbled.lastOutcome, CapyRocketOutcome.wobbled);
  });

  test('completes at target; a later swipe is a no-op', () {
    var round = _start(difficulty: PuzzleDifficulty.easy);
    while (!round.isComplete) {
      round = round.boost(round.cue);
    }
    expect(round.boosts, 6);
    expect(round.altitude, 1);
    expect(identical(round.boost(RocketSide.start), round), isTrue);
    expect(identical(round.boost(RocketSide.end), round), isTrue);
  });

  test('challenge carries boosts and wobbles', () {
    final round = _start();
    final challenge = round.boost(_other(round.cue)).challenge;
    expect(challenge.target, 8);
    expect(challenge.completed, 0);
    expect(challenge.struggleCount, 1);
    expect(challenge.requiresMotion, isFalse);
    expect(
      challenge.escapeVisibilityFor(toleratedStruggles: 1),
      PuzzleEscapeVisibility.available,
    );
  });
}
