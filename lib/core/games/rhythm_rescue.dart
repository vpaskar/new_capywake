import 'dart:math' as math;

import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:meta/meta.dart';

enum RhythmRescuePhase {
  /// The pattern is being shown; taps do nothing.
  listening,

  /// The user repeats the pattern, pad by pad.
  repeating,
}

enum RhythmRescueOutcome { rescued, missed }

/// Rhythm Rescue: repeat a short pattern of pads in order. Timing is never
/// judged, and a wrong pad replays the same pattern — it never gets harder.
@immutable
class RhythmRescueRound {
  RhythmRescueRound._(
    this._seed,
    this._difficulty, {
    required List<int> pattern,
    required this.target,
    required this.rescued,
    required this.entered,
    required this.wrongTaps,
    required this.phase,
    required this.lastOutcome,
  }) : pattern = List.unmodifiable(pattern);

  factory RhythmRescueRound.start({
    required PuzzleDifficulty difficulty,
    required int seed,
  }) => RhythmRescueRound._(
    PuzzleRound.advanceSeed(seed),
    difficulty,
    pattern: _patternFrom(seed, patternLengthFor(difficulty)),
    target: targetFor(difficulty),
    rescued: 0,
    entered: 0,
    wrongTaps: 0,
    phase: RhythmRescuePhase.listening,
    lastOutcome: null,
  );

  static const padCount = 4;

  static int patternLengthFor(PuzzleDifficulty difficulty) =>
      switch (difficulty) {
        PuzzleDifficulty.easy => 3,
        PuzzleDifficulty.medium => 4,
        PuzzleDifficulty.hard => 5,
      };

  static int targetFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => 2,
    PuzzleDifficulty.medium => 3,
    PuzzleDifficulty.hard => 4,
  };

  /// Time from one lit pad to the next: the difficulty is the tempo.
  static Duration beatFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => const Duration(milliseconds: 750),
    PuzzleDifficulty.medium => const Duration(milliseconds: 600),
    PuzzleDifficulty.hard => const Duration(milliseconds: 480),
  };

  /// Never the same pad twice in a row: two lights on one pad read as one.
  static List<int> _patternFrom(int seed, int length) {
    final random = math.Random(seed);
    final pads = [random.nextInt(padCount)];
    while (pads.length < length) {
      pads.add((pads.last + 1 + random.nextInt(padCount - 1)) % padCount);
    }
    return pads;
  }

  final int _seed;
  final PuzzleDifficulty _difficulty;

  /// Pads in the order to tap, each in `0 ..< padCount`.
  final List<int> pattern;
  final int target;
  final int rescued;

  /// Pads of [pattern] tapped correctly so far.
  final int entered;
  final int wrongTaps;
  final RhythmRescuePhase phase;

  /// The result of the last finished attempt, `null` before the first.
  final RhythmRescueOutcome? lastOutcome;

  bool get isComplete => rescued >= target;

  GameChallenge get challenge => GameChallenge.touch(
    target: target,
    completed: rescued,
    struggleCount: wrongTaps,
  );

  /// The pattern has been shown (or there was nothing to play).
  RhythmRescueRound heard() {
    if (isComplete || phase != RhythmRescuePhase.listening) return this;
    return _copy(phase: RhythmRescuePhase.repeating);
  }

  /// Show the pattern again from the first beat. Free: not a struggle.
  RhythmRescueRound replay() {
    if (isComplete || phase != RhythmRescuePhase.repeating) return this;
    return _copy(phase: RhythmRescuePhase.listening, entered: 0);
  }

  /// A no-op unless repeating and unfinished, so a tap while listening never
  /// counts against the user.
  RhythmRescueRound tap(int pad) {
    RangeError.checkValueInInterval(pad, 0, padCount - 1, 'pad');
    if (isComplete || phase != RhythmRescuePhase.repeating) return this;
    if (pad != pattern[entered]) {
      return _copy(
        phase: RhythmRescuePhase.listening,
        entered: 0,
        wrongTaps: wrongTaps + 1,
        lastOutcome: RhythmRescueOutcome.missed,
      );
    }
    if (entered + 1 < pattern.length) {
      return _copy(phase: phase, entered: entered + 1);
    }
    return _copy(
      phase: RhythmRescuePhase.listening,
      entered: 0,
      rescued: rescued + 1,
      lastOutcome: RhythmRescueOutcome.rescued,
      pattern: _patternFrom(_seed, patternLengthFor(_difficulty)),
      seed: PuzzleRound.advanceSeed(_seed),
    );
  }

  RhythmRescueRound _copy({
    required RhythmRescuePhase phase,
    int? entered,
    int? rescued,
    int? wrongTaps,
    RhythmRescueOutcome? lastOutcome,
    List<int>? pattern,
    int? seed,
  }) => RhythmRescueRound._(
    seed ?? _seed,
    _difficulty,
    pattern: pattern ?? this.pattern,
    target: target,
    rescued: rescued ?? this.rescued,
    entered: entered ?? this.entered,
    wrongTaps: wrongTaps ?? this.wrongTaps,
    phase: phase,
    lastOutcome: lastOutcome ?? this.lastOutcome,
  );
}
