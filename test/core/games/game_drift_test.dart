import 'package:capywake/core/games/game_drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fewer than two movable cards never swap', () {
    expect(const GameDrift(1).next(const []), isNull);
    expect(const GameDrift(1).next(const [3]), isNull);
  });

  test('a swap is two distinct movable cards', () {
    var drift = const GameDrift(7);
    for (var i = 0; i < 200; i++) {
      final (a, b, next) = drift.next(const [0, 2, 5])!;
      expect(a, isNot(b));
      expect([0, 2, 5], containsAll([a, b]));
      drift = next;
    }
  });

  test('two cards always swap with each other', () {
    final (a, b, _) = const GameDrift(3).next(const [4, 9])!;
    expect({a, b}, {4, 9});
  });

  test('the same seed drifts the same way; the next drift moves on', () {
    List<(int, int)> run(int seed) {
      var drift = GameDrift(seed);
      return [
        for (var i = 0; i < 12; i++)
          () {
            final (a, b, next) = drift.next(const [0, 1, 2, 3, 4, 5])!;
            drift = next;
            return (a, b);
          }(),
      ];
    }

    expect(run(11), run(11));
    expect(run(11).toSet().length, greaterThan(1));
  });
}
