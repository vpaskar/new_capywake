import 'package:capywake/core/puzzle/puzzle.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_exposure.dart';
import 'package:capywake/core/puzzle/puzzle_generator.dart';
import 'package:capywake/core/puzzle/puzzle_selector.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/core/puzzle/puzzle_validator.dart';
import 'package:meta/meta.dart';

/// One morning's worth of puzzle: everything between the alarm ringing and the
/// user being allowed to stop it.
///
/// Immutable and pure. Each answer produces a *new* round rather than mutating
/// this one, so the whole flow — task counting, type rotation, easing after a
/// wrong answer, and when the alarm may finally be dismissed — is ordinary
/// unit-tested arithmetic instead of widget state. That placement is
/// deliberate: `CLAUDE.md` requires every calculation to be unit-tested and
/// holds `lib/core` at >=95% coverage, and "may this alarm stop now?" is not a
/// question that should be answered inside a `setState`.
///
/// ## What a round guarantees
///
/// - **The alarm can always be stopped.** A round never becomes unsolvable:
///   every wrong answer eases the *next* puzzle (floored at
///   [PuzzleDifficulty.easy]), and [escapeVisibility] surfaces the emergency
///   escape more prominently the harder the morning has been. The escape
///   itself is never withdrawn — see [PuzzleSettings.escapeVisibilityFor].
/// - **An input artefact is not a wrong answer.** [PuzzleAnswerOutcome.empty]
///   and [PuzzleAnswerOutcome.unparseable] leave the easing state untouched
///   and do not count toward the escape threshold. A double-tapped grid cell
///   or a submitted-blank field is not something the user got wrong.
/// - **Nothing on screen is ever unanswerable.** The artefact outcomes keep
///   the same puzzle *unless* it is a show-then-hide type whose stimulus has
///   already been taken away, in which case a fresh one is generated — see
///   [submit].
/// - **No two tasks in a row are the same type**, as far as the enabled set
///   allows — the round threads a bounded recent-type window through
///   [PuzzleTypeSelector].
///
/// There is no score, no streak and no timer here. [PuzzleEasingState] carries
/// counters, but they exist to steer difficulty and escape prominence and are
/// never surfaced as an achievement.
@immutable
class PuzzleRound {
  const PuzzleRound._({
    required this.settings,
    required this.easing,
    required this.recentTypes,
    required this.solvedCount,
    required this.puzzle,
    required this.lastOutcome,
    required this.seed,
  });

  /// Begin a round.
  ///
  /// [seed] makes the whole round reproducible — the same seed and settings
  /// always produce the same sequence of puzzles, which is what the tests and
  /// the debug gallery rely on.
  ///
  /// [recentTypes] is the recently-served history, **oldest first**. Phase 18
  /// starts every round with an empty history; Phase 19 may carry it across
  /// mornings. It is trimmed to [recentWindow] before use.
  factory PuzzleRound.start({
    required PuzzleSettings settings,
    required int seed,
    List<PuzzleType> recentTypes = const <PuzzleType>[],
  }) {
    final easing = PuzzleEasingState.start(settings.difficulty);
    return PuzzleRound._generated(
      settings: settings,
      easing: easing,
      recentTypes: _trim(recentTypes),
      solvedCount: 0,
      lastOutcome: null,
      seed: seed,
    );
  }

  /// Build a round whose current puzzle is freshly generated from [seed].
  factory PuzzleRound._generated({
    required PuzzleSettings settings,
    required PuzzleEasingState easing,
    required List<PuzzleType> recentTypes,
    required int solvedCount,
    required PuzzleAnswerOutcome? lastOutcome,
    required int seed,
  }) {
    final type = PuzzleTypeSelector.next(
      enabled: settings.enabledTypes,
      recent: recentTypes,
      seed: seed,
    );
    final puzzleSeed = advanceSeed(seed);
    return PuzzleRound._(
      settings: settings,
      easing: easing,
      recentTypes: _trim([...recentTypes, type]),
      solvedCount: solvedCount,
      puzzle: PuzzleGenerator.generate(
        type: type,
        difficulty: easing.difficulty,
        seed: puzzleSeed,
      ),
      lastOutcome: lastOutcome,
      seed: advanceSeed(puzzleSeed),
    );
  }

  /// How long an answer may take and still count as *quick* for the purposes
  /// of stepping difficulty back up.
  ///
  /// Generous, because the alternative is a hidden clock: a tighter threshold
  /// would quietly reward hurrying, and `CLAUDE.md` bans timers that create
  /// panic. Nothing is displayed and nothing is lost by being slow — a slow
  /// correct answer simply holds the current level.
  static const Duration quickAnswer = Duration(seconds: 8);

  /// How many past types the selector is told about.
  ///
  /// Short on purpose. `PuzzleTypeSelector` is strict least-recently-used, so
  /// once every enabled type appears in the window exactly one candidate is
  /// stalest and the rotation settles into a fixed cycle. A window of four
  /// keeps several types tied, so the seed still matters and a user with the
  /// seven default types does not walk the same carousel every morning.
  static const int recentWindow = 4;

  /// The user's puzzle configuration for this round.
  final PuzzleSettings settings;

  /// Adaptive-difficulty state. Feeds the next generated puzzle and, via
  /// [PuzzleSettings.escapeVisibilityFor], the escape's prominence.
  final PuzzleEasingState easing;

  /// The bounded recent-type window, oldest first, including [puzzle]'s type.
  final List<PuzzleType> recentTypes;

  /// How many tasks have been answered correctly so far.
  final int solvedCount;

  /// The puzzle currently on screen. When the round [isSolved] this is the
  /// last puzzle that was solved, kept so the surface can finish its exit
  /// transition without a null.
  final Puzzle puzzle;

  /// The outcome of the most recent [submit], or `null` before the first one.
  ///
  /// The surface reads this to choose its calm feedback line — "not quite",
  /// "enter your answer", "digits only" — which is exactly why
  /// `PuzzleValidator` distinguishes them.
  final PuzzleAnswerOutcome? lastOutcome;

  /// The seed the *next* generated puzzle will use.
  final int seed;

  /// Whether every required task has been answered and the alarm may stop.
  bool get isSolved => solvedCount >= settings.taskCount;

  /// How many tasks this round asks for.
  int get taskCount => settings.taskCount;

  /// The 1-based number of the task on screen, clamped to [taskCount] once
  /// the round is solved.
  int get taskNumber => isSolved ? taskCount : solvedCount + 1;

  /// Whether progress is worth showing at all. A single-task round showing
  /// "1 of 1" is noise on a screen that has to be readable at 03:00.
  bool get showsProgress => taskCount > 1;

  /// How prominently the emergency escape should be offered right now.
  PuzzleEscapeVisibility get escapeVisibility =>
      settings.escapeVisibilityFor(easing);

  /// How long [puzzle]'s stimulus should stay visible, or `null` when the
  /// type shows nothing that is later hidden.
  Duration? get exposure => PuzzleExposure.forPuzzle(puzzle);

  /// Answer the current task.
  ///
  /// [wasQuick] is the caller's judgement of whether the answer came fast
  /// enough to count toward stepping difficulty back up; only correct answers
  /// consult it. Returns the round unchanged once [isSolved] — a late tap
  /// arriving after the alarm stopped must not start a new task.
  PuzzleRound submit(PuzzleResponse response, {bool wasQuick = false}) {
    if (isSolved) return this;
    final outcome = PuzzleValidator.validate(
      puzzle: puzzle,
      response: response,
    );
    switch (outcome) {
      case PuzzleAnswerOutcome.empty:
      case PuzzleAnswerOutcome.unparseable:
        // Not a real attempt: the easing state and the escape threshold are
        // untouched either way, because the user did not get anything wrong.
        //
        // What the puzzle does next depends on whether it can still be
        // answered. A show-then-hide type has already taken its stimulus away
        // by the time an answer can be submitted, so keeping it would leave
        // someone who submitted blank staring at digits they can no longer
        // see — unsolvable except by the emergency escape. Those get a fresh
        // puzzle, with a fresh exposure.
        //
        // Yes, that means blank submissions can be used to re-roll a recall
        // puzzle. That is a deliberate trade: it costs another exposure, the
        // alarm keeps ringing throughout, and it never eases the difficulty —
        // so it buys nothing except a puzzle that can actually be answered,
        // which is the point.
        //
        // The grid is the case worth naming, because it is the one where the
        // puzzle *looks* like it is still there: the cells stay tappable after
        // the reveal, so replacing it on a stray Submit discards something the
        // user could seemingly still have answered. They could not — what is
        // gone is the memory of which cells lit, which is the whole puzzle —
        // and the replacement is the same difficulty with a fresh reveal, so
        // the worst case is one more exposure rather than a lost task.
        if (PuzzleExposure.hidesStimulus(puzzle)) {
          return PuzzleRound._generated(
            settings: settings,
            easing: easing,
            recentTypes: recentTypes,
            solvedCount: solvedCount,
            lastOutcome: outcome,
            seed: seed,
          );
        }
        // Everything else is still on screen and still answerable — same
        // puzzle, only the feedback line changes.
        return PuzzleRound._(
          settings: settings,
          easing: easing,
          recentTypes: recentTypes,
          solvedCount: solvedCount,
          puzzle: puzzle,
          lastOutcome: outcome,
          seed: seed,
        );
      case PuzzleAnswerOutcome.correct:
        final nextEasing = easing.recordCorrect(wasQuick: wasQuick);
        final solved = solvedCount + 1;
        if (solved >= settings.taskCount) {
          // Done. Deliberately does not generate another puzzle: the round is
          // over and the surface is about to stop the alarm.
          return PuzzleRound._(
            settings: settings,
            easing: nextEasing,
            recentTypes: recentTypes,
            solvedCount: solved,
            puzzle: puzzle,
            lastOutcome: outcome,
            seed: seed,
          );
        }
        return PuzzleRound._generated(
          settings: settings,
          easing: nextEasing,
          recentTypes: recentTypes,
          solvedCount: solved,
          lastOutcome: outcome,
          seed: seed,
        );
      case PuzzleAnswerOutcome.incorrect:
        // The alarm keeps ringing — that is the point — but the next puzzle
        // is one step easier, and it is a different puzzle rather than the
        // same one to stare at again.
        return PuzzleRound._generated(
          settings: settings,
          easing: easing.recordWrong(),
          recentTypes: recentTypes,
          solvedCount: solvedCount,
          lastOutcome: outcome,
          seed: seed,
        );
    }
  }

  /// Deterministically derive the next seed from [seed].
  ///
  /// A plain linear congruential step, masked to stay non-negative. It only
  /// has to spread consecutive seeds apart so two tasks in one round do not
  /// generate near-identical puzzles; the generators do their own mixing.
  /// Written out rather than using `Random` so a round stays a pure value —
  /// no hidden mutable state to thread through `copyWith`.
  static int advanceSeed(int seed) => (seed * 1103515245 + 12345) & 0x3FFFFFFF;

  static List<PuzzleType> _trim(List<PuzzleType> types) => List.unmodifiable(
    types.length <= recentWindow
        ? types
        : types.sublist(types.length - recentWindow),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PuzzleRound &&
        other.settings == settings &&
        other.easing == easing &&
        _listEquals(other.recentTypes, recentTypes) &&
        other.solvedCount == solvedCount &&
        other.puzzle == puzzle &&
        other.lastOutcome == lastOutcome &&
        other.seed == seed;
  }

  @override
  int get hashCode => Object.hash(
    settings,
    easing,
    Object.hashAll(recentTypes),
    solvedCount,
    puzzle,
    lastOutcome,
    seed,
  );

  @override
  String toString() =>
      'PuzzleRound(task $taskNumber of $taskCount, '
      '${puzzle.type.name}, ${easing.difficulty.name}, '
      'lastOutcome: ${lastOutcome?.name})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
