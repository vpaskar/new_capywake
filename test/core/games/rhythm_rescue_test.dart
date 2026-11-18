import 'package:capywake/core/games/rhythm_rescue.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:flutter_test/flutter_test.dart';

RhythmRescueRound _start({
  PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
  int seed = 1,
}) => RhythmRescueRound.start(difficulty: difficulty, seed: seed);

RhythmRescueRound _playPattern(RhythmRescueRound round) {
  var r = round.heard();
  for (final pad in r.pattern) {
    r = r.tap(pad);
  }
  return r;
}

int _wrong(RhythmRescueRound r) =>
    (r.pattern[r.entered] + 1) % RhythmRescueRound.padCount;

void main() {
  test('length, target and tempo follow difficulty; medium is the poster', () {
    for (final (difficulty, length, target, beatMs) in [
      (PuzzleDifficulty.easy, 3, 2, 750),
      (PuzzleDifficulty.medium, 4, 3, 600),
      (PuzzleDifficulty.hard, 5, 4, 480),
    ]) {
      final round = _start(difficulty: difficulty);
      expect(round.pattern, hasLength(length), reason: '$difficulty');
      expect(round.target, target, reason: '$difficulty');
      expect(
        RhythmRescueRound.beatFor(difficulty),
        Duration(milliseconds: beatMs),
      );
    }
  });

  test('starts listening, with no outcome and nothing entered', () {
    final round = _start();
    expect(round.phase, RhythmRescuePhase.listening);
    expect(round.lastOutcome, isNull);
    expect([round.entered, round.rescued, round.wrongTaps], [0, 0, 0]);
  });

  test('every pattern stays on the pads and never repeats one in a row', () {
    for (var seed = 0; seed < 200; seed++) {
      final round = _start(seed: seed, difficulty: PuzzleDifficulty.hard);
      for (var i = 0; i < round.pattern.length; i++) {
        expect(round.pattern[i], inInclusiveRange(0, 3));
        if (i > 0) expect(round.pattern[i], isNot(round.pattern[i - 1]));
      }
    }
  });

  test('the same seed gives the same pattern; seeds differ', () {
    expect(_start(seed: 7).pattern, _start(seed: 7).pattern);
    final patterns = {for (var s = 0; s < 20; s++) _start(seed: s).pattern};
    expect(patterns.length, greaterThan(1));
  });

  test('the pattern is unmodifiable', () {
    expect(() => _start().pattern.add(0), throwsUnsupportedError);
  });

  test('a tap while listening is ignored, never a struggle', () {
    final round = _start();
    expect(identical(round.tap(round.pattern.first), round), isTrue);
    expect(identical(round.tap(_wrong(round)), round), isTrue);
  });

  test('heard starts repeating; a second heard is a no-op', () {
    final repeating = _start().heard();
    expect(repeating.phase, RhythmRescuePhase.repeating);
    expect(identical(repeating.heard(), repeating), isTrue);
  });

  test('right pads advance entered, staying in repeating', () {
    final repeating = _start().heard();
    final one = repeating.tap(repeating.pattern[0]);
    expect(one.entered, 1);
    expect(one.phase, RhythmRescuePhase.repeating);
    expect(one.lastOutcome, isNull);
  });

  test('the whole pattern rescues: a new pattern, listening again', () {
    final start = _start();
    final done = _playPattern(start);
    expect(done.rescued, 1);
    expect(done.entered, 0);
    expect(done.phase, RhythmRescuePhase.listening);
    expect(done.lastOutcome, RhythmRescueOutcome.rescued);
    expect(done.pattern, hasLength(start.pattern.length));
  });

  test('a wrong pad keeps the same pattern and counts one struggle', () {
    final repeating = _start().heard();
    final one = repeating.tap(repeating.pattern[0]);
    final missed = one.tap(_wrong(one));
    expect(missed.wrongTaps, 1);
    expect(missed.entered, 0);
    expect(missed.pattern, repeating.pattern);
    expect(missed.phase, RhythmRescuePhase.listening);
    expect(missed.lastOutcome, RhythmRescueOutcome.missed);
    expect(missed.rescued, 0);
  });

  test('replay restarts the pattern for free; only while repeating', () {
    final repeating = _start().heard();
    final one = repeating.tap(repeating.pattern[0]);
    final replayed = one.replay();
    expect(replayed.phase, RhythmRescuePhase.listening);
    expect(replayed.entered, 0);
    expect(replayed.wrongTaps, 0);
    expect(replayed.pattern, repeating.pattern);
    expect(identical(replayed.replay(), replayed), isTrue);
  });

  test('a pad outside the row throws', () {
    final repeating = _start().heard();
    expect(() => repeating.tap(-1), throwsRangeError);
    expect(() => repeating.tap(4), throwsRangeError);
  });

  test('completes at target and then every move is a no-op', () {
    var round = _start(difficulty: PuzzleDifficulty.easy);
    while (!round.isComplete) {
      round = _playPattern(round);
    }
    expect(round.rescued, 2);
    expect(identical(round.heard(), round), isTrue);
    expect(identical(round.replay(), round), isTrue);
    expect(identical(round.tap(0), round), isTrue);
  });

  test('challenge carries progress and wrong taps', () {
    final repeating = _start().heard();
    final missed = repeating.tap(_wrong(repeating));
    final challenge = _playPattern(missed).challenge;
    expect(challenge.target, 3);
    expect(challenge.completed, 1);
    expect(challenge.struggleCount, 1);
    expect(challenge.requiresMotion, isFalse);
    expect(
      challenge.escapeVisibilityFor(toleratedStruggles: 0),
      PuzzleEscapeVisibility.prominent,
    );
  });
}
