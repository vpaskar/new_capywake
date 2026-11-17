import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {required bool disableAnimations}) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GameRingingSlot(
          builder: ({required reduceMotion}) =>
              Text('reduceMotion:$reduceMotion'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the slot passes disableAnimations through as reduceMotion', (
    tester,
  ) async {
    await _pump(tester, disableAnimations: true);
    expect(find.text('reduceMotion:true'), findsOneWidget);
  });

  testWidgets('reduceMotion is false when the platform does not ask for it', (
    tester,
  ) async {
    await _pump(tester, disableAnimations: false);
    expect(find.text('reduceMotion:false'), findsOneWidget);
  });
}
