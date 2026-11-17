import 'package:capywake/core/models/dismiss_method.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:meta/meta.dart';

/// One alarm's departures from the app-wide [PuzzleSettings].
///
/// Every field is nullable and the rule is uniform: **`null` means "follow the
/// app default"**. An alarm that has never been customised carries no override
/// at all, and an override that only pins the task count still tracks the
/// default enabled types as the user edits them in Settings. That is what makes
/// the acceptance criterion honest — "an alarm without an override follows the
/// default as it changes" holds field by field, not just all-or-nothing.
///
/// Difficulty is deliberately **not** a field here. It already has a dedicated
/// persisted column on the alarm row ([DismissChallengeDifficulty], since Phase
/// 03) with [DismissChallengeDifficulty.toPuzzleDifficulty] as its documented
/// single bridge to the engine's scale. Duplicating it in this type would give
/// one user-facing setting two storage locations — the exact footgun the
/// existing bridge was introduced to avoid. It joins the other fields in
/// [resolveFor], which is the one place a final [PuzzleSettings] is composed,
/// and it follows the same `null` = "follow the app default" rule.
///
/// Validation is delegated to [PuzzleSettings.checkInvariants] so a value the
/// app-wide settings reject cannot be smuggled in through an alarm.
@immutable
class AlarmPuzzleOverride {
  AlarmPuzzleOverride({
    Set<PuzzleType>? enabledTypes,
    this.taskCount,
    this.toleratedWrongAnswers,
    this.escapeStrictness,
    Set<String>? enabledGames,
    this.includePuzzles,
  }) : enabledTypes = enabledTypes == null
           ? null
           : Set.unmodifiable(enabledTypes),
       enabledGames = enabledGames == null
           ? null
           : Set.unmodifiable(enabledGames) {
    PuzzleSettings.checkInvariants(
      enabledTypes: this.enabledTypes,
      taskCount: taskCount,
      toleratedWrongAnswers: toleratedWrongAnswers,
      enabledGames: this.enabledGames,
    );
    if (includePuzzles == false) {
      PuzzleSettings.checkPool(
        includePuzzles: false,
        enabledGames: this.enabledGames ?? const {},
      );
    }
  }

  /// Pin every field to the given settings.
  ///
  /// Used when the user switches an alarm from "follow my defaults" to its own
  /// configuration: the alarm starts from exactly what it would have done a
  /// moment ago, so nothing changes under the user until they change it.
  factory AlarmPuzzleOverride.from(PuzzleSettings settings) =>
      AlarmPuzzleOverride(
        enabledTypes: settings.enabledTypes,
        taskCount: settings.taskCount,
        toleratedWrongAnswers: settings.toleratedWrongAnswers,
        escapeStrictness: settings.escapeStrictness,
        enabledGames: settings.enabledGames,
        includePuzzles: settings.includePuzzles,
      );

  /// An override that changes nothing — every field follows the default.
  ///
  /// Lets [resolveFor] keep a single code path instead of branching on
  /// "is there an override at all".
  static final AlarmPuzzleOverride none = AlarmPuzzleOverride();

  /// Types this alarm draws from, or `null` to follow the default set.
  final Set<PuzzleType>? enabledTypes;

  /// Puzzles to solve on this alarm, or `null` to follow the default.
  final int? taskCount;

  /// Wrong answers tolerated on this alarm before the emergency escape is
  /// offered prominently, or `null` to follow the default.
  ///
  /// As on [PuzzleSettings], this is a *reachability* setting. No value here
  /// withdraws the escape.
  final int? toleratedWrongAnswers;

  /// How deliberate reaching the escape has to be on this alarm, or `null` to
  /// follow the default.
  ///
  /// [PuzzleEscapeStrictness] has no "off" value, so — as on the app-wide
  /// settings — an override can make the escape more deliberate but can never
  /// remove it.
  final PuzzleEscapeStrictness? escapeStrictness;

  /// Games this alarm draws from, or `null` to follow the default.
  final Set<String>? enabledGames;

  /// Whether this alarm's pool holds puzzles, or `null` to follow the
  /// default. `false` requires this override's own non-empty [enabledGames].
  final bool? includePuzzles;

  /// Whether this override changes nothing (every field follows the default).
  bool get isEmpty =>
      enabledTypes == null &&
      taskCount == null &&
      toleratedWrongAnswers == null &&
      escapeStrictness == null &&
      enabledGames == null &&
      includePuzzles == null;

  /// Compose the settings one alarm should actually wake someone with.
  ///
  /// The single resolution implementation in the app: `Alarm` and `AlarmDraft`
  /// both delegate here, so the ringing surface and the edit form can never
  /// disagree about what an alarm is configured to do.
  static PuzzleSettings resolveFor({
    required PuzzleSettings defaults,
    AlarmPuzzleOverride? override,
    DismissChallengeDifficulty? difficulty,
  }) {
    final o = override ?? none;
    final games = o.enabledGames ?? defaults.enabledGames;
    return PuzzleSettings(
      enabledTypes: o.enabledTypes ?? defaults.enabledTypes,
      taskCount: o.taskCount ?? defaults.taskCount,
      difficulty: difficulty?.toPuzzleDifficulty() ?? defaults.difficulty,
      toleratedWrongAnswers:
          o.toleratedWrongAnswers ?? defaults.toleratedWrongAnswers,
      escapeStrictness: o.escapeStrictness ?? defaults.escapeStrictness,
      enabledGames: games,
      // An empty pool would leave a ringing alarm nothing to solve.
      includePuzzles:
          games.isEmpty || (o.includePuzzles ?? defaults.includePuzzles),
    );
  }

  AlarmPuzzleOverride copyWith({
    Set<PuzzleType>? enabledTypes,
    int? taskCount,
    int? toleratedWrongAnswers,
    PuzzleEscapeStrictness? escapeStrictness,
    Set<String>? enabledGames,
    bool? includePuzzles,
  }) => AlarmPuzzleOverride(
    enabledTypes: enabledTypes ?? this.enabledTypes,
    taskCount: taskCount ?? this.taskCount,
    toleratedWrongAnswers: toleratedWrongAnswers ?? this.toleratedWrongAnswers,
    escapeStrictness: escapeStrictness ?? this.escapeStrictness,
    enabledGames: enabledGames ?? this.enabledGames,
    includePuzzles: includePuzzles ?? this.includePuzzles,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlarmPuzzleOverride &&
        _setEquals(other.enabledTypes, enabledTypes) &&
        other.taskCount == taskCount &&
        other.toleratedWrongAnswers == toleratedWrongAnswers &&
        other.escapeStrictness == escapeStrictness &&
        _setEquals(other.enabledGames, enabledGames) &&
        other.includePuzzles == includePuzzles;
  }

  @override
  int get hashCode => Object.hash(
    enabledTypes == null ? null : Object.hashAllUnordered(enabledTypes!),
    taskCount,
    toleratedWrongAnswers,
    escapeStrictness,
    enabledGames == null ? null : Object.hashAllUnordered(enabledGames!),
    includePuzzles,
  );

  @override
  String toString() =>
      'AlarmPuzzleOverride(types: ${enabledTypes?.length}, '
      'tasks: $taskCount, tolerated: $toleratedWrongAnswers, '
      'escape: ${escapeStrictness?.name}, games: ${enabledGames?.length}, '
      'puzzles: $includePuzzles)';

  static bool _setEquals<T>(Set<T>? a, Set<T>? b) {
    if (a == null || b == null) return a == null && b == null;
    return a.length == b.length && a.containsAll(b);
  }
}
