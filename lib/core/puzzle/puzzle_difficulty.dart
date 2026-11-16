import 'package:meta/meta.dart';

/// How hard a generated puzzle is.
///
/// A deliberately small ordered scale. The user picks one as their ceiling
/// (see `PuzzleSettings.difficulty`); the engine may ease *below* it after a
/// wrong answer but never climbs above it.
enum PuzzleDifficulty {
  easy,
  medium,
  hard;

  /// The floor easing can reach.
  static PuzzleDifficulty get easiest => PuzzleDifficulty.easy;

  /// The ceiling a user can choose.
  static PuzzleDifficulty get hardest => PuzzleDifficulty.hard;

  /// One step easier, clamped at [easiest].
  ///
  /// The clamp is what makes easing safe: repeated wrong answers walk down to
  /// [easy] and then stay there. There is no state in which the puzzle gets
  /// harder because the user is struggling.
  PuzzleDifficulty get easier =>
      index == 0 ? this : PuzzleDifficulty.values[index - 1];

  /// One step harder, clamped at [hardest].
  PuzzleDifficulty get harder => index == PuzzleDifficulty.values.length - 1
      ? this
      : PuzzleDifficulty.values[index + 1];

  /// The easier of `this` and [other].
  PuzzleDifficulty atMost(PuzzleDifficulty other) =>
      index <= other.index ? this : other;
}

/// The adaptive-difficulty state for one wake round.
///
/// Immutable and pure — the caller threads it through a round and the engine
/// never stores it. Two rules, both required by `CLAUDE.md`:
///
/// - **A wrong answer eases the *next* puzzle.** Difficulty steps down one
///   level immediately and floors at [PuzzleDifficulty.easy]. The alarm keeps
///   ringing — that is the point — but the user can never be locked out by a
///   puzzle they cannot solve.
/// - **Difficulty never exceeds the user's [ceiling].** Sustained quick correct
///   answers may climb back toward it after a dip, and stop there. A user who
///   chose `easy` never sees a `medium` puzzle.
///
/// There is no score, streak display, or "personal best" here.
/// [consecutiveCorrect] exists only to decide whether to step back up, is
/// reset on every step, and is never surfaced.
@immutable
class PuzzleEasingState {
  const PuzzleEasingState._({
    required this.ceiling,
    required this.difficulty,
    required this.consecutiveCorrect,
    required this.consecutiveWrong,
    required this.wrongThisRound,
  });

  /// Begin a round at the user's configured [ceiling].
  factory PuzzleEasingState.start(PuzzleDifficulty ceiling) =>
      PuzzleEasingState._(
        ceiling: ceiling,
        difficulty: ceiling,
        consecutiveCorrect: 0,
        consecutiveWrong: 0,
        wrongThisRound: 0,
      );

  /// How many quick correct answers in a row are needed before difficulty
  /// steps back up toward [ceiling].
  static const int stepUpStreak = 3;

  /// The hardest level this round may ever reach — the user's own choice.
  final PuzzleDifficulty ceiling;

  /// The difficulty the *next* generated puzzle should use.
  final PuzzleDifficulty difficulty;

  /// Quick correct answers since the last step change or wrong answer.
  final int consecutiveCorrect;

  /// Wrong answers in a row. Reset by any correct answer.
  final int consecutiveWrong;

  /// Every wrong answer so far this round, across all of its tasks.
  ///
  /// This — not [consecutiveWrong] — is what escape prominence is measured
  /// against (see `PuzzleSettings.escapeVisibilityFor`). It never decreases
  /// until the round ends, because a person who has got four answers wrong
  /// this morning is still having a hard morning after they get one right. A
  /// consecutive counter would let the escape recede exactly as someone
  /// alternating wrong/right/wrong/right needs it most, and with `taskCount`
  /// up to 5 that user would never reach the threshold at all.
  ///
  /// It is not a score, is never displayed, and does not affect difficulty.
  final int wrongThisRound;

  /// Whether difficulty has already walked down to the floor.
  bool get isAtFloor => difficulty == PuzzleDifficulty.easiest;

  /// Record a wrong answer: ease one step (floored) and reset the up-streak.
  PuzzleEasingState recordWrong() => PuzzleEasingState._(
    ceiling: ceiling,
    difficulty: difficulty.easier,
    consecutiveCorrect: 0,
    consecutiveWrong: consecutiveWrong + 1,
    wrongThisRound: wrongThisRound + 1,
  );

  /// Record a correct answer.
  ///
  /// Only answers the caller judges *quick* ([wasQuick]) count toward stepping
  /// back up; a slow correct answer holds the current level. Stepping up is
  /// clamped to [ceiling].
  PuzzleEasingState recordCorrect({bool wasQuick = false}) {
    if (!wasQuick) {
      return PuzzleEasingState._(
        ceiling: ceiling,
        difficulty: difficulty,
        consecutiveCorrect: 0,
        consecutiveWrong: 0,
        wrongThisRound: wrongThisRound,
      );
    }
    final streak = consecutiveCorrect + 1;
    final shouldStepUp = streak >= stepUpStreak;
    return PuzzleEasingState._(
      ceiling: ceiling,
      difficulty: shouldStepUp ? difficulty.harder.atMost(ceiling) : difficulty,
      consecutiveCorrect: shouldStepUp ? 0 : streak,
      consecutiveWrong: 0,
      wrongThisRound: wrongThisRound,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PuzzleEasingState &&
        other.ceiling == ceiling &&
        other.difficulty == difficulty &&
        other.consecutiveCorrect == consecutiveCorrect &&
        other.consecutiveWrong == consecutiveWrong &&
        other.wrongThisRound == wrongThisRound;
  }

  @override
  int get hashCode => Object.hash(
    ceiling,
    difficulty,
    consecutiveCorrect,
    consecutiveWrong,
    wrongThisRound,
  );

  @override
  String toString() =>
      'PuzzleEasingState(ceiling: ${ceiling.name}, '
      'difficulty: ${difficulty.name}, '
      'consecutiveCorrect: $consecutiveCorrect, '
      'consecutiveWrong: $consecutiveWrong, '
      'wrongThisRound: $wrongThisRound)';
}
