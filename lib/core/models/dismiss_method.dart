import 'package:capywake/core/puzzle/puzzle_difficulty.dart';

/// How a ringing alarm is dismissed.
///
/// Persisted as the [name] string. The legacy `'mathChallenge'` value written
/// by pre-puzzle builds still reads back as [puzzle] — see
/// `AlarmMapper._parseDismissMethod`. The math-only dismiss challenge it named
/// was replaced wholesale by the generated wake puzzle, so there is nothing an
/// old row could degrade into.
enum DismissMethod {
  /// A single tap on a clearly-labelled "Stop" button. Friendly default.
  normalButton,

  /// Press-and-hold for a few seconds. Defends against a sleepy reflexive
  /// tap without making it a puzzle.
  holdToDismiss,

  /// Solve a freshly generated wake puzzle to stop the alarm. Free, and the
  /// reason the product exists. Difficulty is carried by the alarm itself via
  /// [DismissChallengeDifficulty]; which types are enabled and how many tasks
  /// are asked for are user settings.
  puzzle,
}

/// Difficulty for the wake puzzle on a given alarm.
///
/// Only meaningful when the alarm's [DismissMethod] is [DismissMethod.puzzle];
/// for the other dismiss methods the field on `Alarm` is `null`.
///
/// A separate enum from [PuzzleDifficulty] because this one is **persisted**:
/// it is the stored per-alarm setting, and the puzzle engine's own scale stays
/// free to evolve without a schema migration. [toPuzzleDifficulty] is the one
/// place the two meet.
///
/// Persisted as the [name] string.
enum DismissChallengeDifficulty {
  /// Small numbers, short patterns, and a generous look at anything you have
  /// to remember. Solvable while still half-asleep.
  easy,

  /// The recommended default: enough to make you think for a moment.
  medium,

  /// Larger numbers, longer patterns, a briefer look. Genuinely wakes you.
  hard;

  /// The stored setting for a puzzle-engine difficulty.
  ///
  /// The inverse of [toPuzzleDifficulty], kept beside it so both directions of
  /// the bridge stay in the one file that is allowed to know both scales.
  static DismissChallengeDifficulty fromPuzzleDifficulty(
    PuzzleDifficulty difficulty,
  ) => switch (difficulty) {
    PuzzleDifficulty.easy => DismissChallengeDifficulty.easy,
    PuzzleDifficulty.medium => DismissChallengeDifficulty.medium,
    PuzzleDifficulty.hard => DismissChallengeDifficulty.hard,
  };

  /// The puzzle-engine difficulty this stored setting maps to.
  PuzzleDifficulty toPuzzleDifficulty() => switch (this) {
    DismissChallengeDifficulty.easy => PuzzleDifficulty.easy,
    DismissChallengeDifficulty.medium => PuzzleDifficulty.medium,
    DismissChallengeDifficulty.hard => PuzzleDifficulty.hard,
  };
}
