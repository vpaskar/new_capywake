import 'dart:io';

import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/features/puzzle/puzzle_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every puzzle type has its own bundled painted icon (G21)', () {
    final paths = {
      for (final type in PuzzleType.values) puzzleTypeArt(type).path,
    };
    expect(paths, hasLength(PuzzleType.values.length));
    for (final path in paths) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('icons are catalogued at their own render box', () {
    expect(
      puzzleTypeArt(PuzzleType.digitRecallReversed).id,
      'icon.puzzle.digit_recall_reversed',
    );
    expect(
      CapyArt.puzzleIcons.map((a) => a.use).toSet(),
      {ArtUse.puzzleIcon},
    );
  });
}
