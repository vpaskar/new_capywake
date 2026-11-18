import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_pump.dart';

Future<void> _show(WidgetTester tester, String? text, int? serial) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameOutcomeLine(text: text, serial: serial),
        ),
      ),
    );

void main() {
  testWidgets('a repeated result from a new answer is announced again', (
    tester,
  ) async {
    final said = recordAnnouncements(tester);
    await _show(tester, null, 0);
    await _show(tester, 'Look again.', 1);
    expect(said, isEmpty, reason: 'a changed text is the live region’s job');
    await _show(tester, 'Look again.', 2);
    expect(said, ['Look again.']);
  });

  testWidgets('a rebuild without a new answer says nothing', (tester) async {
    final said = recordAnnouncements(tester);
    await _show(tester, 'Look again.', 1);
    await _show(tester, 'Look again.', 1);
    await _show(tester, 'Look again.', 1);
    expect(said, isEmpty);
  });

  testWidgets('reserves two lines even when empty', (tester) async {
    await _show(tester, null, null);
    final empty = tester.getSize(find.byType(GameOutcomeLine)).height;
    await _show(tester, 'One line.', 1);
    expect(tester.getSize(find.byType(GameOutcomeLine)).height, empty);
  });
}
