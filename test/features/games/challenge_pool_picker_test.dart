import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/challenge_pool_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_pump.dart';

CapyToggle _toggle(WidgetTester tester, String label) => tester.widget(
  find.byWidgetPredicate((w) => w is CapyToggle && w.semanticLabel == label),
);

void main() {
  testWidgets('lists the puzzles and every playable game', (tester) async {
    await pumpInApp(
      tester,
      ChallengePoolPicker(
        includePuzzles: true,
        enabledGames: const {},
        onPuzzlesChanged: (_) {},
        onGameChanged: (_, {required enabled}) {},
      ),
    );
    expect(find.text('Puzzles'), findsOneWidget);
    expect(find.text('Catch the Capy'), findsOneWidget);
    expect(find.text('Memory Hideout'), findsOneWidget);
    expect(find.text('Rhythm Rescue'), findsOneWidget);
    expect(find.text('Capy Rocket'), findsOneWidget);
    expect(find.text('Shake DJ'), findsNothing);
    expect(find.text('Try it'), findsNothing);
  });

  testWidgets('the last member on cannot be switched off', (tester) async {
    await pumpInApp(
      tester,
      ChallengePoolPicker(
        includePuzzles: true,
        enabledGames: const {},
        onPuzzlesChanged: (_) {},
        onGameChanged: (_, {required enabled}) {},
      ),
    );
    expect(_toggle(tester, 'Puzzles').onChanged, isNull);
    expect(_toggle(tester, 'Catch the Capy').onChanged, isNotNull);
  });

  testWidgets('a lone game is held on the same way', (tester) async {
    await pumpInApp(
      tester,
      ChallengePoolPicker(
        includePuzzles: false,
        enabledGames: const {'memory_hideout'},
        onPuzzlesChanged: (_) {},
        onGameChanged: (_, {required enabled}) {},
      ),
    );
    expect(_toggle(tester, 'Memory Hideout').onChanged, isNull);
    expect(_toggle(tester, 'Puzzles').onChanged, isNotNull);
  });

  testWidgets('switches and Try it report the right game', (tester) async {
    final changes = <String>[];
    final tried = <String>[];
    await pumpInApp(
      tester,
      ChallengePoolPicker(
        includePuzzles: true,
        enabledGames: const {'catch_the_capy'},
        onPuzzlesChanged: (on) => changes.add('puzzles:$on'),
        onGameChanged: (id, {required enabled}) => changes.add('$id:$enabled'),
        onTryGame: tried.add,
      ),
    );

    _toggle(tester, 'Memory Hideout').onChanged!(true);
    _toggle(tester, 'Puzzles').onChanged!(false);
    await tester.tap(find.text('Try it').at(2));
    await tester.tap(find.text('Try it').last);

    expect(changes, ['memory_hideout:true', 'puzzles:false']);
    expect(tried, ['memory_hideout', 'capy_rocket']);
  });

  testWidgets('Try it names its game for a screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpInApp(
      tester,
      ChallengePoolPicker(
        includePuzzles: true,
        enabledGames: const {},
        onPuzzlesChanged: (_) {},
        onGameChanged: (_, {required enabled}) {},
        onTryGame: (_) {},
      ),
    );
    expect(find.bySemanticsLabel('Try it, Catch the Capy'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Try it is drawn in ink, not the failing accent (SR1 M1)', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      ChallengePoolPicker(
        includePuzzles: true,
        enabledGames: const {},
        onPuzzlesChanged: (_) {},
        onGameChanged: (_, {required enabled}) {},
        onTryGame: (_) {},
      ),
    );
    final text = tester.widget<RichText>(
      find.descendant(
        of: find.text('Try it').first,
        matching: find.byType(RichText),
      ),
    );
    expect(text.text.style?.color, CapyColors.cocoa);
  });
}
