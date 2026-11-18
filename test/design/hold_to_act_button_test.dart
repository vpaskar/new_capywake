import 'package:capywake/design/hold_to_act_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<int> pumpAndHold(
    WidgetTester tester, {
    required Duration hold,
    Duration holdDuration = HoldToActButton.defaultHold,
  }) async {
    var fired = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoldToActButton(
            label: 'Hold',
            onCompleted: () => fired++,
            holdDuration: holdDuration,
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HoldToActButton)),
    );
    await tester.pump(hold);
    await gesture.up();
    await tester.pumpAndSettle();
    return fired;
  }

  testWidgets('a sustained hold fires exactly once', (tester) async {
    final fired = await pumpAndHold(
      tester,
      hold: const Duration(milliseconds: 1500),
    );

    expect(fired, 1);
  });

  testWidgets('a short press does not fire', (tester) async {
    final fired = await pumpAndHold(
      tester,
      hold: const Duration(milliseconds: 200),
    );

    expect(fired, 0);
  });

  testWidgets('a tap does not fire', (tester) async {
    var fired = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoldToActButton(label: 'Hold', onCompleted: () => fired++),
        ),
      ),
    );

    await tester.tap(find.byType(HoldToActButton));
    await tester.pumpAndSettle();

    expect(fired, 0);
  });

  testWidgets('releasing early resets, and a second hold still works', (
    tester,
  ) async {
    var fired = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoldToActButton(label: 'Hold', onCompleted: () => fired++),
        ),
      ),
    );

    final abandoned = await tester.startGesture(
      tester.getCenter(find.byType(HoldToActButton)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await abandoned.up();
    await tester.pumpAndSettle();
    expect(fired, 0);

    final completed = await tester.startGesture(
      tester.getCenter(find.byType(HoldToActButton)),
    );
    await tester.pump(const Duration(milliseconds: 1400));
    await completed.up();
    await tester.pumpAndSettle();

    expect(fired, 1, reason: 'a failed hold must not lock the control out');
  });

  testWidgets('it clears the tap-target floor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoldToActButton(label: 'Hold', onCompleted: () {}),
        ),
      ),
    );

    final size = tester.getSize(find.byType(HoldToActButton));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('it is a button to a screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoldToActButton(label: 'Hold to stop', onCompleted: () {}),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Hold to stop'), findsOneWidget);
    handle.dispose();
  });

  for (final action in [SemanticsAction.tap, SemanticsAction.longPress]) {
    testWidgets('a screen reader ${action.name} completes it at once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToActButton(
              label: 'Hold to stop',
              onCompleted: () => completed++,
            ),
          ),
        ),
      );

      tester.semantics.performAction(
        find.semantics.byLabel('Hold to stop'),
        action,
      );
      await tester.pump();

      expect(completed, 1);
      handle.dispose();
    });
  }

  testWidgets('nothing is left running after a completed hold', (tester) async {
    await pumpAndHold(tester, hold: const Duration(milliseconds: 1400));

    expect(tester.binding.transientCallbackCount, 0);
  });
}
