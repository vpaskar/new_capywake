import 'dart:math' as math;

import 'package:capywake/core/puzzle/puzzle_type.dart';

/// Chooses which puzzle type to serve next.
///
/// "A different puzzle every morning" is the thing the product is sold on, and
/// it comes from two places: infinite in-type generation (the generators) and
/// rotation between types (here). The selector guarantees:
///
/// - **Never the same type twice in a row** — whenever more than one type is
///   enabled. With a single enabled type there is nothing else to serve; the
///   variety then comes entirely from generation, and the settings layer is
///   what stops the set being empty.
/// - **No starvation.** Selection always prefers the least-recently-served
///   enabled types, so a type cannot sit unused indefinitely just because the
///   draw kept missing it.
abstract final class PuzzleTypeSelector {
  /// Pick the next type from [enabled].
  ///
  /// [recent] is the recently-served history, **oldest first**, so
  /// `recent.last` is the previous morning's type. It may contain types that
  /// are no longer enabled; those are simply ignored.
  ///
  /// Its **length is what controls variety**, and callers should pass a
  /// bounded window rather than the whole history. Selection is strict
  /// least-recently-used, so once every enabled type appears in [recent]
  /// exactly one candidate is stalest, ties never happen, and [seed] stops
  /// mattering — the rotation settles into a fixed repeating cycle. That still
  /// honours both guarantees below, and is a reasonable thing to want; it is
  /// simply not random, and a caller expecting randomness should keep the
  /// window short enough that several types tie.
  ///
  /// [seed] makes the choice reproducible for tests and for the debug
  /// gallery. Throws [ArgumentError] when [enabled] is empty — an empty set is
  /// unrepresentable in `PuzzleSettings`, so reaching this is a caller bug.
  static PuzzleType next({
    required Set<PuzzleType> enabled,
    required List<PuzzleType> recent,
    required int seed,
  }) {
    if (enabled.isEmpty) {
      throw ArgumentError.value(
        enabled,
        'enabled',
        'At least one puzzle type must be enabled',
      );
    }

    final previous = recent.isEmpty ? null : recent.last;
    // Walk the enum rather than the set so the candidate order — and therefore
    // the result for a given seed — does not depend on the enabled set's own
    // iteration order. With a single enabled type the previous-type filter is
    // skipped: there is nothing else to serve.
    //
    // Note that this exclusion is **belt-and-braces, not the mechanism**. The
    // staleness ranking below already scores the previous type at exactly 1
    // and every other enabled type at 2 or more, so it can never win on its
    // own — removing this filter changes no result. It is kept because it
    // states the guarantee at the point a reader looks for it. Neither this
    // nor the ranking may be removed on the assumption that the other covers
    // it: deleting the ranking alone would break the guarantee silently, and
    // the tests assert the *property*, not either mechanism.
    final onlyOneEnabled = enabled.length == 1;
    final candidates = <PuzzleType>[
      for (final type in PuzzleType.values)
        if (enabled.contains(type) && (onlyOneEnabled || type != previous))
          type,
    ];

    // Prefer whichever candidates were served longest ago; never-served types
    // are the stalest of all, so no enabled type can starve. This is a
    // rotation measure, not a performance score — nothing about how the user
    // answered feeds into it.
    var stalest = -1;
    final best = <PuzzleType>[];
    for (final candidate in candidates) {
      final lastUsed = recent.lastIndexOf(candidate);
      final staleness = lastUsed == -1
          ? recent.length + 1
          : recent.length - lastUsed;
      if (staleness > stalest) {
        stalest = staleness;
        best
          ..clear()
          ..add(candidate);
      } else if (staleness == stalest) {
        best.add(candidate);
      }
    }

    return best[math.Random(seed).nextInt(best.length)];
  }
}
