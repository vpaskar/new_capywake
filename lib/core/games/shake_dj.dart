import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:meta/meta.dart';

enum ShakeDjOutcome { stalled }

/// Shake DJ: every shake (or tap of the beat button) is one beat. A long pause
/// stalls the beat and counts as a struggle; no beat is lost.
@immutable
class ShakeDjRound {
  const ShakeDjRound._({
    required this.target,
    required this.beats,
    required this.stalls,
    required this.lastOutcome,
  });

  factory ShakeDjRound.start({required PuzzleDifficulty difficulty}) =>
      ShakeDjRound._(
        target: targetFor(difficulty),
        beats: 0,
        stalls: 0,
        lastOutcome: null,
      );

  static int targetFor(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => 20,
    PuzzleDifficulty.medium => 30,
    PuzzleDifficulty.hard => 40,
  };

  /// One bob of Capy's groove: the difficulty is the tempo.
  static Duration grooveFor(PuzzleDifficulty difficulty) =>
      switch (difficulty) {
        PuzzleDifficulty.easy => const Duration(milliseconds: 900),
        PuzzleDifficulty.medium => const Duration(milliseconds: 750),
        PuzzleDifficulty.hard => const Duration(milliseconds: 600),
      };

  static const stallAfter = Duration(seconds: 8);

  /// Progress is shown in phrases: forty pips would not fit, or be heard.
  static const beatsPerPhrase = 5;

  final int target;
  final int beats;
  final int stalls;
  final ShakeDjOutcome? lastOutcome;

  bool get isComplete => beats >= target;

  int get phrases => target ~/ beatsPerPhrase;
  int get phrasesDone => beats ~/ beatsPerPhrase;

  /// Share of the beat pumped up, `0` at the start and `1` once complete.
  double get level => beats / target;

  GameChallenge get challenge => GameChallenge.motion(
    target: target,
    completed: beats,
    struggleCount: stalls,
    fallback: GameChallenge.touch(
      target: target,
      completed: beats,
      struggleCount: stalls,
    ),
  );

  ShakeDjRound beat() => isComplete
      ? this
      : ShakeDjRound._(
          target: target,
          beats: beats + 1,
          stalls: stalls,
          lastOutcome: null,
        );

  ShakeDjRound stall() => isComplete
      ? this
      : ShakeDjRound._(
          target: target,
          beats: beats,
          stalls: stalls + 1,
          lastOutcome: ShakeDjOutcome.stalled,
        );
}
