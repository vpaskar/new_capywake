import 'dart:math';

/// What a win shows: the game's own pose, the shared cheer, or the trophy
/// bounce — picked per win so a morning does not always end the same way.
enum WinArt {
  pose,
  cheer,
  trophy;

  /// Salted so the art does not move in step with a pick made from the same
  /// ring seed, such as which game rang.
  static const _salt = 0x2b6f;

  static WinArt forSeed(int seed) =>
      values[Random(seed ^ _salt).nextInt(values.length)];
}
