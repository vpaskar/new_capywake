import 'package:capywake/core/motion/tilt_reader.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Finder mazeArrow(TiltDirection d) =>
    find.byKey(ValueKey('tilt-maze-${d.name}'));

/// The steps the outcome line reports, or `null` when it reports none.
int? stepsHeard(WidgetTester tester) {
  final line = find.byType(GameOutcomeLine);
  if (line.evaluate().isEmpty) return null;
  final text = tester.widget<GameOutcomeLine>(line).text ?? '';
  final digits = RegExp(r'\d+').firstMatch(text);
  return digits == null ? null : int.parse(digits.group(0)!);
}

bool _escaped(WidgetTester tester) =>
    tester
        .widget<GameOutcomeLine>(find.byType(GameOutcomeLine))
        .text
        ?.startsWith(
          'Out!',
        ) ??
    false;

bool _isWall(WidgetTester tester, TiltDirection d) =>
    tester.getSemantics(mazeArrow(d)).label.contains('wall');

const Map<TiltDirection, TiltDirection> _back = {
  TiltDirection.up: TiltDirection.down,
  TiltDirection.down: TiltDirection.up,
  TiltDirection.left: TiltDirection.right,
  TiltDirection.right: TiltDirection.left,
};

/// Solves the current maze the way a screen-reader user can: by the arrows'
/// wall labels and the spoken distance only. Needs semantics enabled.
Future<void> solveMazeByEar(WidgetTester tester) async {
  if (stepsHeard(tester) == null && _escaped(tester)) {
    final open = TiltDirection.values.firstWhere((d) => !_isWall(tester, d));
    await tester.tap(mazeArrow(open));
    await tester.pump();
  }
  for (var guard = 0; guard < 200; guard++) {
    final here = stepsHeard(tester);
    if (here == null) return;
    var advanced = false;
    for (final d in TiltDirection.values) {
      if (_isWall(tester, d)) continue;
      await tester.tap(mazeArrow(d));
      await tester.pump();
      final now = stepsHeard(tester);
      if (now == null || _escaped(tester)) return;
      if (now < here) {
        advanced = true;
        break;
      }
      await tester.tap(mazeArrow(_back[d]!));
      await tester.pump();
    }
    expect(advanced, isTrue, reason: 'no arrow led closer to the flag');
  }
  fail('the maze was never solved');
}
