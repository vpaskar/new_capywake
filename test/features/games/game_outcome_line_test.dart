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
  _reservesTallest();

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

void _reservesTallest() {
  testWidgets('reserves the tallest result it may show, at any text size', (
    tester,
  ) async {
    const long =
        'A much longer result that wraps onto a third line at this width.';
    for (final scale in [1.0, 2.0]) {
      Future<double> heightOf(String? text) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 240,
                    child: GameOutcomeLine(
                      text: text,
                      reserveFor: const ['Short.', long],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        return tester.getSize(find.byType(GameOutcomeLine)).height;
      }

      final empty = await heightOf(null);
      expect(await heightOf('Short.'), empty, reason: '${scale}x');
      expect(await heightOf(long), empty, reason: '${scale}x');
    }
  });
}
