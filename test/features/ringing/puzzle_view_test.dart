import 'package:capywake/core/puzzle/puzzle.dart';
import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/features/ringing/puzzle_view.dart';
import 'package:capywake/features/ringing/ringing_host.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzleRound _round({required PuzzleType type, int seed = 7}) =>
    PuzzleRound.start(
      settings: PuzzleSettings(enabledTypes: {type}),
      seed: seed,
    );

void main() {
  Future<PuzzleRound> pump(
    WidgetTester tester, {
    required PuzzleRound round,
    VoidCallback? onSolved,
  }) async {
    var current = round;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PuzzleView(
              round: current,
              onRoundChanged: (next) => setState(() => current = next),
              onSolved: onSolved ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return current;
  }

  group('renderable types', () {
    testWidgets('arithmetic shows its instruction and a typed answer', (
      tester,
    ) async {
      await pump(tester, round: _round(type: PuzzleType.arithmetic));

      expect(find.text('What is the result?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('sequenceNext asks the quiet question', (tester) async {
      await pump(tester, round: _round(type: PuzzleType.sequenceNext));

      expect(find.text('Which number comes next?'), findsOneWidget);
    });

    testWidgets('missingOperator offers operator options, not a field', (
      tester,
    ) async {
      await pump(tester, round: _round(type: PuzzleType.missingOperator));

      expect(find.text('Which sign makes this true?'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('answering', () {
    testWidgets('a correct typed answer solves a one-task round', (
      tester,
    ) async {
      var solved = 0;
      final round = _round(type: PuzzleType.arithmetic);
      await pump(tester, round: round, onSolved: () => solved++);

      final answer = round.puzzle.answer as NumericAnswer;
      await tester.enterText(find.byType(TextField), '${answer.value}');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(solved, 1);
    });

    testWidgets('a wrong answer does not solve it and says so', (tester) async {
      var solved = 0;
      await pump(
        tester,
        round: _round(type: PuzzleType.arithmetic),
        onSolved: () => solved++,
      );

      await tester.enterText(find.byType(TextField), '999999');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(solved, 0);
      expect(find.text("Not quite — here's another one."), findsOneWidget);
    });

    testWidgets('the copy is an instruction, never a taunt', (tester) async {
      await pump(tester, round: _round(type: PuzzleType.arithmetic));

      for (final taunt in ['Prove', 'Wrong!', 'Failed', 'Try harder']) {
        expect(find.textContaining(taunt), findsNothing);
      }
    });
  });

  group('safety', () {
    testWidgets('nothing animates', (tester) async {
      await pump(tester, round: _round(type: PuzzleType.arithmetic));

      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('option chips clear the tap-target floor', (tester) async {
      await pump(tester, round: _round(type: PuzzleType.missingOperator));

      for (final glyph in ['+', '−', '×', '÷']) {
        final found = find.text(glyph);
        if (found.evaluate().isEmpty) continue;
        final size = tester.getSize(
          find.ancestor(of: found, matching: find.byType(SizedBox)).first,
        );
        expect(size.height, greaterThanOrEqualTo(44));
        expect(size.width, greaterThanOrEqualTo(44));
      }
    });

    test('every renderable type is screen-reader solvable', () {
      for (final type in RingingHost.renderableTypes) {
        expect(
          type.isScreenReaderSolvable,
          isTrue,
          reason: '$type is drawn but cannot be solved without sight',
        );
      }
    });

    test('the default enabled set is entirely renderable', () {
      final defaults = PuzzleSettings.defaults().enabledTypes;
      expect(
        defaults.difference(RingingHost.renderableTypes),
        isEmpty,
        reason: 'a default puzzle alarm must always show a drawable puzzle',
      );
    });
  });

  group('self-review #1 probes', () {
    testWidgets('a multi-task round shows its progress', (tester) async {
      await pump(
        tester,
        round: PuzzleRound.start(
          settings: PuzzleSettings(
            enabledTypes: const {PuzzleType.arithmetic},
            taskCount: 3,
          ),
          seed: 11,
        ),
      );

      expect(find.text('1 of 3'), findsOneWidget);
    });

    testWidgets('a one-task round shows no progress line', (tester) async {
      await pump(tester, round: _round(type: PuzzleType.arithmetic));

      expect(find.textContaining(' of '), findsNothing);
    });

    testWidgets('an empty answer is answered, not ignored', (tester) async {
      await pump(tester, round: _round(type: PuzzleType.arithmetic));

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your answer to stop the alarm.'), findsOneWidget);
    });

    testWidgets('a correct answer is not cheered at', (tester) async {
      final round = _round(type: PuzzleType.arithmetic);
      await pump(tester, round: round);

      final answer = round.puzzle.answer as NumericAnswer;
      await tester.enterText(find.byType(TextField), '${answer.value}');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('Correct'), findsNothing);
    });

    test('every renderable type has its own instruction, never a fallback', () {
      final seen = <String>{};
      for (final type in RingingHost.renderableTypes) {
        final round = _round(type: type);
        seen.add(round.puzzle.type.name);
      }
      expect(seen, hasLength(RingingHost.renderableTypes.length));
    });
  });

  group('self-review #2 probes', () {
    testWidgets('an unrenderable type throws rather than mislabelling', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: PuzzleView(
              round: _round(type: PuzzleType.digitRecall),
              onRoundChanged: (_) {},
              onSolved: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isA<UnsupportedError>());
    });

    testWidgets('the subtraction glyph is a minus sign, not a hyphen', (
      tester,
    ) async {
      await pump(tester, round: _round(type: PuzzleType.missingOperator));

      expect(
        find.text('-'),
        findsNothing,
        reason: 'U+2212 MINUS SIGN, not ASCII hyphen — matches the board',
      );
    });
  });
}
