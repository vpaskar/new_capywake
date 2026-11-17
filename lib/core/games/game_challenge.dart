import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:meta/meta.dart';

/// Headless state of a wake-up game — the shape every game (phases 12-17)
/// slots into. Pure Dart: no Flutter, no sensor, no score.
@immutable
class GameChallenge {
  /// A game played by touch: no motion, no [motionFallback].
  const GameChallenge.touch({
    required this.target,
    required this.completed,
    this.struggleCount = 0,
  }) : assert(target > 0, 'a game needs a goal to reach'),
       assert(completed >= 0, 'progress cannot be negative'),
       assert(struggleCount >= 0, 'struggle cannot be negative'),
       requiresMotion = false,
       motionFallback = null;

  /// A motion game. A non-motion [fallback] is required at the call site (the
  /// a11y safety rule) and asserted to not itself need motion.
  GameChallenge.motion({
    required this.target,
    required this.completed,
    required GameChallenge fallback,
    this.struggleCount = 0,
  }) : assert(target > 0, 'a game needs a goal to reach'),
       assert(completed >= 0, 'progress cannot be negative'),
       assert(struggleCount >= 0, 'struggle cannot be negative'),
       assert(!fallback.requiresMotion, 'the fallback must not need motion'),
       requiresMotion = true,
       motionFallback = fallback;

  /// Steps the game asks for before the alarm may stop.
  final int target;

  /// Steps done so far.
  final int completed;

  /// Struggles this game (a missed tap, a reset); each game defines these.
  final int struggleCount;

  /// Whether this game needs device motion to play.
  final bool requiresMotion;

  /// The non-motion way to play, present only when [requiresMotion].
  final GameChallenge? motionFallback;

  /// Whether the goal is reached and the alarm may stop.
  bool get isComplete => completed >= target;

  /// Escape prominence against the user's [toleratedStruggles]. Never hidden:
  /// `available` is still a labelled, reachable control.
  PuzzleEscapeVisibility escapeVisibilityFor({
    required int toleratedStruggles,
  }) {
    return struggleCount > toleratedStruggles
        ? PuzzleEscapeVisibility.prominent
        : PuzzleEscapeVisibility.available;
  }
}
