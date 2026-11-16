/// Small value-equality helpers for the puzzle value types.
///
/// Hand-rolled on purpose: `package:collection` is not a dependency, and
/// `foundation.listEquals` would drag a Flutter import into `lib/core/puzzle/`,
/// which must stay pure Dart.
library;

/// Order-sensitive element-wise list equality.
bool puzzleListEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Order-insensitive multiset equality.
///
/// Used where the answer genuinely does not care about order — reproducing a
/// flashed grid pattern is about *which* cells, not the order they are tapped
/// in. Requiring an order would be a needless trap at 03:00.
bool puzzleUnorderedEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  final counts = <T, int>{};
  for (final item in a) {
    counts[item] = (counts[item] ?? 0) + 1;
  }
  for (final item in b) {
    final remaining = counts[item];
    if (remaining == null || remaining == 0) return false;
    counts[item] = remaining - 1;
  }
  return true;
}

/// Order-sensitive hash for a list, consistent with [puzzleListEquals].
int puzzleListHash(List<Object?> items) => Object.hashAll(items);
