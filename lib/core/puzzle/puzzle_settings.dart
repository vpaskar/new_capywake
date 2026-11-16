import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:meta/meta.dart';

/// How reachable the emergency escape should currently be.
///
/// The escape is **always** reachable — that is the safety rule, and no value
/// here withdraws it. This only says how loudly the surface should offer it.
enum PuzzleEscapeVisibility {
  /// Present and labelled, but secondary to the puzzle.
  available,

  /// Offered prominently: this person has had a hard enough morning that the
  /// way out should be obvious without hunting for it.
  prominent,
}

/// How deliberate the emergency escape has to be.
///
/// There is **no "off"**, and there never will be. `CLAUDE.md` states this as
/// a safety rule rather than a UX preference: someone may be ill, about to wake
/// a child, or needing to take an urgent call, and a puzzle they cannot solve
/// in that moment must never stand between them and silence. What the user
/// configures is how hard the escape is to reach *by accident* — not whether it
/// exists.
enum PuzzleEscapeStrictness {
  /// A labelled control plus one confirmation. Enough that a reflex tap cannot
  /// reach it; little enough that a person in trouble is not delayed.
  confirm,

  /// A labelled control, a confirmation, and a short deliberate hold. For a
  /// user who wants the puzzle to genuinely be the path of least resistance.
  confirmAndHold,
}

/// Everything the user decides about their wake puzzle.
///
/// Immutable, validated on construction, and pure: the settings layer
/// persists it and adds per-alarm overrides, this type defends the shape.
///
/// The invariants exist because each one is a way the puzzle could otherwise
/// fail someone at 03:00:
///
/// - [enabledTypes] is **never empty**. An empty set would mean a puzzle-backed
///   alarm with no puzzle to solve.
/// - [taskCount] and [toleratedWrongAnswers] are bounded, so no setting can
///   turn a wake-up into an endurance test.
/// - [escapeStrictness] has no "off" value, so the escape cannot be configured
///   away.
@immutable
class PuzzleSettings {
  /// Construct settings, rejecting anything unrepresentable.
  ///
  /// Throws [ArgumentError] rather than asserting: asserts are stripped from
  /// release builds, and "the enabled set is never empty" has to hold in the
  /// build that actually wakes people.
  PuzzleSettings({
    required Set<PuzzleType> enabledTypes,
    this.taskCount = 1,
    this.difficulty = PuzzleDifficulty.medium,
    this.toleratedWrongAnswers = 3,
    this.escapeStrictness = PuzzleEscapeStrictness.confirm,
  }) : enabledTypes = Set.unmodifiable(enabledTypes) {
    checkInvariants(
      enabledTypes: this.enabledTypes,
      taskCount: taskCount,
      toleratedWrongAnswers: toleratedWrongAnswers,
    );
  }

  /// A short reasoning challenge with a screen-reader-solvable prompt.
  /// Existing saved rotations continue to use their configured types.
  factory PuzzleSettings.defaults() => PuzzleSettings(
    enabledTypes: const {
      PuzzleType.arithmetic,
      PuzzleType.sequenceNext,
      PuzzleType.missingOperator,
    },
  );

  static const int minTaskCount = 1;
  static const int maxTaskCount = 5;
  static const int minToleratedWrongAnswers = 0;
  static const int maxToleratedWrongAnswers = 10;

  /// The rules every puzzle configuration must satisfy.
  ///
  /// Shared by this class and `AlarmPuzzleOverride` so the app-wide defaults
  /// and a per-alarm override cannot drift apart — a value rejected for the
  /// defaults is rejected on an alarm too. Every argument is nullable because
  /// an override only carries the fields the user actually changed; `null`
  /// means "not overridden", and there is nothing to check.
  ///
  /// Throws [ArgumentError] rather than asserting: asserts are stripped from
  /// release builds, and these invariants have to hold in the build that
  /// actually wakes people.
  static void checkInvariants({
    Set<PuzzleType>? enabledTypes,
    int? taskCount,
    int? toleratedWrongAnswers,
  }) {
    if (enabledTypes != null && enabledTypes.isEmpty) {
      throw ArgumentError.value(
        enabledTypes,
        'enabledTypes',
        'At least one puzzle type must be enabled',
      );
    }
    if (taskCount != null &&
        (taskCount < minTaskCount || taskCount > maxTaskCount)) {
      throw ArgumentError.value(
        taskCount,
        'taskCount',
        'Must be between $minTaskCount and $maxTaskCount',
      );
    }
    if (toleratedWrongAnswers != null &&
        (toleratedWrongAnswers < minToleratedWrongAnswers ||
            toleratedWrongAnswers > maxToleratedWrongAnswers)) {
      throw ArgumentError.value(
        toleratedWrongAnswers,
        'toleratedWrongAnswers',
        'Must be between $minToleratedWrongAnswers and '
            '$maxToleratedWrongAnswers',
      );
    }
  }

  /// The types the selector may draw from. Never empty; unmodifiable.
  final Set<PuzzleType> enabledTypes;

  /// How many puzzles must be solved before the alarm can be dismissed.
  final int taskCount;

  /// The user's difficulty ceiling. Easing may go below it, never above.
  final PuzzleDifficulty difficulty;

  /// How many wrong answers pass before the emergency escape is surfaced
  /// prominently.
  ///
  /// This is a *reachability* setting, not a lockout: the escape is always
  /// available, and the alarm always keeps ringing. Nothing here can make a
  /// puzzle unfailable or an alarm unstoppable.
  final int toleratedWrongAnswers;

  /// How deliberate reaching the escape has to be.
  final PuzzleEscapeStrictness escapeStrictness;

  /// How prominently the emergency escape should be offered right now.
  ///
  /// This predicate lives in `lib/core/` deliberately. It is the one rule in
  /// the puzzle layer that `CLAUDE.md` classes as a safety rule, and if the
  /// surface were left to invent it, the decision would sit in a widget —
  /// outside the >=95% core coverage gate, and impossible to unit-test against
  /// the round state. It joins the two halves that otherwise only referred to
  /// each other in prose: [toleratedWrongAnswers] and
  /// [PuzzleEasingState.wrongThisRound].
  ///
  /// Note it counts wrong answers **across the whole round**, not consecutive
  /// ones. Someone alternating wrong and right is struggling just as much as
  /// someone failing repeatedly, and must not be the one person the threshold
  /// never fires for.
  ///
  /// Neither outcome hides the escape: [PuzzleEscapeVisibility.available] is
  /// still a labelled, reachable control.
  PuzzleEscapeVisibility escapeVisibilityFor(PuzzleEasingState state) =>
      state.wrongThisRound > toleratedWrongAnswers
      ? PuzzleEscapeVisibility.prominent
      : PuzzleEscapeVisibility.available;

  /// Whether every enabled type needs sight.
  ///
  /// The settings UI uses this to warn a screen-reader user before they
  /// leave themselves an unsolvable morning.
  bool get isVisualOnly => enabledTypes.every((t) => !t.isScreenReaderSolvable);

  PuzzleSettings copyWith({
    Set<PuzzleType>? enabledTypes,
    int? taskCount,
    PuzzleDifficulty? difficulty,
    int? toleratedWrongAnswers,
    PuzzleEscapeStrictness? escapeStrictness,
  }) => PuzzleSettings(
    enabledTypes: enabledTypes ?? this.enabledTypes,
    taskCount: taskCount ?? this.taskCount,
    difficulty: difficulty ?? this.difficulty,
    toleratedWrongAnswers: toleratedWrongAnswers ?? this.toleratedWrongAnswers,
    escapeStrictness: escapeStrictness ?? this.escapeStrictness,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PuzzleSettings &&
        _setEquals(other.enabledTypes, enabledTypes) &&
        other.taskCount == taskCount &&
        other.difficulty == difficulty &&
        other.toleratedWrongAnswers == toleratedWrongAnswers &&
        other.escapeStrictness == escapeStrictness;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(enabledTypes),
    taskCount,
    difficulty,
    toleratedWrongAnswers,
    escapeStrictness,
  );

  @override
  String toString() =>
      'PuzzleSettings(types: ${enabledTypes.length}, tasks: $taskCount, '
      'difficulty: ${difficulty.name}, '
      'tolerated: $toleratedWrongAnswers, '
      'escape: ${escapeStrictness.name})';

  static bool _setEquals<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
