import 'package:capywake/core/puzzle/puzzle.dart';
import 'package:capywake/core/puzzle/puzzle_content.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';

/// How long a show-then-hide puzzle keeps its stimulus on screen.
///
/// Three of the ten types show something and then take it away: the two
/// digit-recall types, the grid pattern, and `spotTheChange` (whose "before"
/// row is shown, hidden, and then replaced by the "after" row). How long that
/// window lasts is a **difficulty lever**, which is why it lives here beside
/// the other difficulty bands rather than as a constant inlined in a widget:
/// a number that decides how hard the puzzle is belongs under the >=95%
/// `lib/core` coverage gate, where it can be reasoned about and tested.
///
/// The scale is deliberately generous. A user reading this is half-asleep in a
/// dim room, and an exposure tuned for an alert daytime tester is the quickest
/// way to make the puzzle feel like a punishment. Missing the stimulus is not
/// a trap either — a wrong answer generates a *new*, easier puzzle with a
/// fresh exposure, and the emergency escape is reachable throughout.
abstract final class PuzzleExposure {
  /// Never shorter than this, whatever the arithmetic says.
  static const Duration minimum = Duration(milliseconds: 1200);

  /// Never longer than this — past a few seconds the surface stops feeling
  /// like a puzzle and starts feeling like waiting.
  static const Duration maximum = Duration(milliseconds: 6000);

  /// Fixed cost of noticing that digits have appeared at all.
  static const Duration digitsBase = Duration(milliseconds: 900);

  /// Added per digit shown.
  static const Duration perDigit = Duration(milliseconds: 500);

  /// Fixed cost of orienting on the grid.
  static const Duration gridBase = Duration(milliseconds: 1200);

  /// Added per lit cell.
  static const Duration perCell = Duration(milliseconds: 450);

  /// Fixed cost of taking in a row of shapes.
  static const Duration shapeRowBase = Duration(milliseconds: 1200);

  /// Added per shape in the row.
  static const Duration perShape = Duration(milliseconds: 350);

  /// Whether the grid's lit cells appear **together** rather than one after
  /// the other.
  ///
  /// They appear together, and that is a decision rather than a shortcut.
  /// Flashing cells in sequence turns pattern *recall* into pattern *tracking*:
  /// the user has to watch continuously or lose the whole puzzle, which is
  /// exactly the panic-inducing timing pressure `CLAUDE.md` bans. Shown
  /// together, the grid is a single glance that a sleepy person can take at
  /// their own pace within the exposure window, and the answer stays
  /// order-insensitive — which is what `PuzzleValidator` already promises.
  static const bool gridCellsAppearTogether = true;

  /// Whether [puzzle] shows a stimulus that is later taken away.
  ///
  /// Equivalent to "[forPuzzle] returns a duration", named because the fact
  /// matters somewhere the duration itself does not: once the exposure has
  /// elapsed, the information needed to answer is **gone**. A round that keeps
  /// such a puzzle on screen after a non-answer is holding a user in front of
  /// something they can no longer solve, so `PuzzleRound.submit` consults this
  /// before deciding whether an input artefact may keep the same puzzle.
  static bool hidesStimulus(Puzzle puzzle) => forPuzzle(puzzle) != null;

  /// The exposure for [puzzle], or `null` when the type shows nothing that is
  /// later taken away (every non-recall type).
  static Duration? forPuzzle(Puzzle puzzle) => switch (puzzle.content) {
    DigitRecallContent(:final digits) => forDigits(
      digitCount: digits.length,
      difficulty: puzzle.difficulty,
    ),
    GridPatternContent(:final cells) => forGrid(
      cellCount: cells.length,
      difficulty: puzzle.difficulty,
    ),
    SpotTheChangeContent(:final before) => forShapeRow(
      shapeCount: before.length,
      difficulty: puzzle.difficulty,
    ),
    ArithmeticContent() ||
    SequenceNextContent() ||
    MissingOperatorContent() ||
    CompareValuesContent() ||
    OddOneOutNumericContent() ||
    ShapeRotationContent() => null,
  };

  /// How long [digitCount] digits stay visible.
  static Duration forDigits({
    required int digitCount,
    required PuzzleDifficulty difficulty,
  }) => _scaled(digitsBase + perDigit * digitCount, difficulty);

  /// How long [cellCount] lit grid cells stay visible.
  static Duration forGrid({
    required int cellCount,
    required PuzzleDifficulty difficulty,
  }) => _scaled(gridBase + perCell * cellCount, difficulty);

  /// How long a row of [shapeCount] shapes stays visible.
  static Duration forShapeRow({
    required int shapeCount,
    required PuzzleDifficulty difficulty,
  }) => _scaled(shapeRowBase + perShape * shapeCount, difficulty);

  /// Apply the per-difficulty multiplier and clamp to [minimum]/[maximum].
  ///
  /// Easy is *longer*, hard is shorter — the difficulty of a recall puzzle is
  /// how little time you had to take it in, as much as how much there was to
  /// remember. Written as integer ratios so the result is exact and the same
  /// on every platform.
  static Duration _scaled(Duration base, PuzzleDifficulty difficulty) {
    final ms = switch (difficulty) {
      PuzzleDifficulty.easy => base.inMilliseconds * 7 ~/ 5, // x1.4
      PuzzleDifficulty.medium => base.inMilliseconds,
      PuzzleDifficulty.hard => base.inMilliseconds * 3 ~/ 4, // x0.75
    };
    return Duration(
      milliseconds: ms.clamp(minimum.inMilliseconds, maximum.inMilliseconds),
    );
  }
}
