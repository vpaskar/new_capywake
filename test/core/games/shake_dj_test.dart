import 'package:capywake/core/games/shake_dj.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:flutter_test/flutter_test.dart';

ShakeDjRound _start([PuzzleDifficulty d = PuzzleDifficulty.easy]) =>
    ShakeDjRound.start(difficulty: d);

void main() {
  test('beats and groove follow difficulty', () {
    for (final (difficulty, target, grooveMs) in [
      (PuzzleDifficulty.easy, 20, 900),
      (PuzzleDifficulty.medium, 30, 750),
      (PuzzleDifficulty.hard, 40, 600),
    ]) {
      expect(_start(difficulty).target, target);
      expect(
        ShakeDjRound.grooveFor(difficulty),
        Duration(milliseconds: grooveMs),
      );
    }
  });

  test('starts silent with no outcome', () {
    final round = _start();
    expect([round.beats, round.stalls, round.level], [0, 0, 0]);
    expect(round.lastOutcome, isNull);
    expect(round.isComplete, isFalse);
  });

  test('a beat pumps the level and clears a stall line', () {
    final round = _start().stall().beat();
    expect(round.beats, 1);
    expect(round.level, 1 / 20);
    expect(round.lastOutcome, isNull);
    expect(round.stalls, 1);
  });

  test('a stall is a struggle and loses no beat', () {
    final round = _start().beat().stall().stall();
    expect(round.beats, 1);
    expect(round.stalls, 2);
    expect(round.lastOutcome, ShakeDjOutcome.stalled);
  });

  test('completes at the target, then ignores beats and stalls', () {
    var round = _start();
    for (var i = 0; i < 20; i++) {
      round = round.beat();
    }
    expect(round.isComplete, isTrue);
    expect(round.level, 1);
    expect(round.beat(), same(round));
    expect(round.stall(), same(round));
  });

  test('the challenge is a motion game with a touch fallback', () {
    final challenge = _start().beat().stall().challenge;
    expect(challenge.requiresMotion, isTrue);
    expect(
      [challenge.target, challenge.completed, challenge.struggleCount],
      [
        20,
        1,
        1,
      ],
    );
    final fallback = challenge.motionFallback!;
    expect(fallback.requiresMotion, isFalse);
    expect(
      [fallback.target, fallback.completed, fallback.struggleCount],
      [
        20,
        1,
        1,
      ],
    );
    expect(
      challenge.escapeVisibilityFor(toleratedStruggles: 0),
      PuzzleEscapeVisibility.prominent,
    );
  });

  test('progress is shown in five-beat phrases', () {
    for (final d in PuzzleDifficulty.values) {
      final round = _start(d);
      expect(round.target % ShakeDjRound.beatsPerPhrase, 0);
      expect(round.phrases, lessThanOrEqualTo(8));
    }
    var round = _start();
    expect([round.phrases, round.phrasesDone], [4, 0]);
    for (var i = 0; i < 9; i++) {
      round = round.beat();
    }
    expect(round.phrasesDone, 1);
    expect(round.beat().phrasesDone, 2);
  });

  test('a stall arrives after eight quiet seconds', () {
    expect(ShakeDjRound.stallAfter, const Duration(seconds: 8));
  });
}
