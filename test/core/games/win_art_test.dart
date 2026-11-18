import 'package:capywake/core/games/win_art.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one seed always gives the same art', () {
    for (var seed = 0; seed < 50; seed++) {
      expect(WinArt.forSeed(seed), WinArt.forSeed(seed));
    }
  });

  test('over many wins every art turns up', () {
    final seen = {for (var seed = 0; seed < 60; seed++) WinArt.forSeed(seed)};
    expect(seen, WinArt.values.toSet());
  });

  test('no art dominates a run of wins', () {
    final counts = {for (final art in WinArt.values) art: 0};
    for (var seed = 0; seed < 3000; seed++) {
      counts[WinArt.forSeed(seed)] = counts[WinArt.forSeed(seed)]! + 1;
    }
    for (final count in counts.values) {
      expect(count, inInclusiveRange(800, 1200));
    }
  });
}
