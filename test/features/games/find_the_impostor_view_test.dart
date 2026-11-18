import 'package:capywake/core/games/find_the_impostor.dart';
import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/features/games/drifting_grid.dart';
import 'package:capywake/features/games/find_the_impostor_view.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_pump.dart';

const _seed = 8;

Finder _cell(int i) => find.byKey(ValueKey('find-the-impostor-cell-$i'));

FindTheImpostorRound _mirror([
  PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
]) => FindTheImpostorRound.start(difficulty: difficulty, seed: _seed);

Future<({List<GameChallenge> progress, List<int> completed})> _pump(
  WidgetTester tester, {
  PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
  bool reduceMotion = true,
  bool accessibleNavigation = false,
  Locale locale = const Locale('en'),
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  final progress = <GameChallenge>[];
  final completed = <int>[];
  await pumpInApp(
    tester,
    FindTheImpostorView(
      seed: _seed,
      difficulty: difficulty,
      onProgress: progress.add,
      onCompleted: () => completed.add(1),
      reduceMotion: reduceMotion,
    ),
    locale: locale,
    accessibleNavigation: accessibleNavigation,
    textScale: textScale,
    brightness: brightness,
  );
  return (progress: progress, completed: completed);
}

void main() {
  test('every pose in the bank has its picture and its words', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final names = <String>{};
    for (final pose in CapyPose.values) {
      expect(CapyArt.byId('game.capy.${pose.name}').use, ArtUse.gameCapy);
      names.add(capyPoseName(l10n, pose));
    }
    expect(names, hasLength(CapyPose.values.length));
  });

  testWidgets('shows the instruction, progress and one card per cell', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.text('One Capy is doing something different. Tap it.'),
      findsOneWidget,
    );
    expect(find.text('0 / 3'), findsOneWidget);
    expect(_cell(5), findsOneWidget);
    expect(_cell(6), findsNothing);
  });

  testWidgets('exactly one card shows the odd pose', (tester) async {
    await _pump(tester, difficulty: PuzzleDifficulty.hard);
    final round = _mirror(PuzzleDifficulty.hard);
    expect(
      find.byKey(ValueKey('find-the-impostor-art-${round.odd.name}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('find-the-impostor-art-${round.common.name}')),
      findsNWidgets(7),
    );
  });

  testWidgets('every card is a large target; art at the pose size', (
    tester,
  ) async {
    await _pump(tester, difficulty: PuzzleDifficulty.hard);
    for (var i = 0; i < 8; i++) {
      final size = tester.getSize(_cell(i));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, FindTheImpostorView.cellHeight);
    }
    final art = tester.getSize(find.byType(Image).first);
    expect(art.width, lessThanOrEqualTo(ArtUse.gameCapy.renderBoxPt));
  });

  testWidgets('a find is counted, said, and deals a new set', (tester) async {
    final calls = await _pump(tester);
    final round = _mirror();
    await tester.tap(_cell(round.oddAt));
    await tester.pumpAndSettle();
    expect(find.text('Found the different one.'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(calls.progress.last.completed, 1);
    final next = round.tap(round.oddAt);
    expect(
      find.byKey(ValueKey('find-the-impostor-art-${next.odd.name}')),
      findsOneWidget,
    );
  });

  testWidgets('a wrong tap is struggle, said neutrally, set unchanged', (
    tester,
  ) async {
    final calls = await _pump(tester);
    final round = _mirror();
    await tester.tap(_cell((round.oddAt + 1) % round.cellCount));
    await tester.pumpAndSettle();
    expect(find.text('That one matches. Look again.'), findsOneWidget);
    expect(calls.progress.last.struggleCount, 1);
    expect(calls.progress.last.completed, 0);
    expect(
      find.byKey(ValueKey('find-the-impostor-art-${round.odd.name}')),
      findsOneWidget,
    );
  });

  testWidgets('a second miss in a row is announced again (G4)', (
    tester,
  ) async {
    final said = recordAnnouncements(tester);
    await _pump(tester);
    final wrong = _cell((_mirror().oddAt + 1) % 6);
    await tester.tap(wrong);
    await tester.pump();
    await tester.tap(wrong);
    await tester.pump();
    expect(said, ['That one matches. Look again.']);
  });

  testWidgets('finishing reports completion once', (tester) async {
    final calls = await _pump(tester, difficulty: PuzzleDifficulty.easy);
    var round = _mirror(PuzzleDifficulty.easy);
    for (var i = 0; i < 2; i++) {
      await tester.tap(_cell(round.oddAt));
      await tester.pumpAndSettle();
      round = round.tap(round.oddAt);
    }
    await tester.tap(_cell(0));
    await tester.pumpAndSettle();
    expect(calls.completed, [1]);
    expect(calls.progress.last.isComplete, isTrue);
    expect(
      find.byKey(ValueKey('find-the-impostor-art-${round.odd.name}')),
      findsOneWidget,
    );
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(_cell(0)),
      isSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('each card names its pose for a screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, accessibleNavigation: true);
    final round = _mirror();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final odd = round.oddAt;
    expect(
      tester.getSemantics(_cell(odd)).label,
      'Capy ${odd + 1} of 6: ${capyPoseName(l10n, round.odd)}',
    );
    final other = (odd + 1) % 6;
    expect(
      tester.getSemantics(_cell(other)).label,
      'Capy ${other + 1} of 6: ${capyPoseName(l10n, round.common)}',
    );
    handle.dispose();
  });

  testWidgets('the outcome slot is reserved: nothing moves when it fills', (
    tester,
  ) async {
    await _pump(tester);
    final before = tester.getTopLeft(_cell(0));
    final card = tester.getSize(find.byType(CapyCard));
    await tester.tap(_cell((_mirror().oddAt + 1) % 6));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_cell(0)), before);
    expect(tester.getSize(find.byType(CapyCard)), card);
    expect(find.byType(GameOutcomeLine), findsOneWidget);
  });

  group('moving', () {
    testWidgets(
      'every card moves on a step, so motion never shows the odd one',
      (
        tester,
      ) async {
        await _pump(tester, reduceMotion: false);
        final before = [
          for (var i = 0; i < 6; i++) tester.getTopLeft(_cell(i)),
        ];
        await tester.pump(
          FindTheImpostorRound.swapEveryFor(PuzzleDifficulty.medium),
        );
        await tester.pump(DriftingGrid.slide);
        for (var i = 0; i < 6; i++) {
          expect(tester.getTopLeft(_cell(i)), isNot(before[i]), reason: '$i');
        }
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('the cards drift and the odd one is still found', (
      tester,
    ) async {
      final calls = await _pump(tester, reduceMotion: false);
      final round = _mirror();
      final before = tester.getTopLeft(_cell(0));
      final every = FindTheImpostorRound.swapEveryFor(PuzzleDifficulty.medium);
      final moved = <Offset>{before};
      for (var i = 0; i < 6; i++) {
        await tester.pump(every);
        await tester.pump(DriftingGrid.slide);
        moved.add(tester.getTopLeft(_cell(0)));
      }
      expect(moved.length, greaterThan(1));
      await tester.pumpAndSettle();
      await tester.tap(_cell(round.oddAt));
      await tester.pump();
      expect(calls.progress.last.completed, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a screen reader turned on mid-slide stops the drift (H5)', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: false);
      final home = tester.getTopLeft(_cell(0));
      final every = FindTheImpostorRound.swapEveryFor(PuzzleDifficulty.medium);
      await tester.pump(every);
      await tester.pump(DriftingGrid.slide ~/ 2);
      await _pump(tester, reduceMotion: false, accessibleNavigation: true);
      expect(tester.hasRunningAnimations, isFalse);
      for (var i = 0; i < 4; i++) {
        await tester.pump(every);
        await tester.pump(DriftingGrid.slide);
      }
      expect(tester.getTopLeft(_cell(0)), home);
    });

    testWidgets('completing stops the drift', (tester) async {
      await _pump(
        tester,
        difficulty: PuzzleDifficulty.easy,
        reduceMotion: false,
      );
      var round = _mirror(PuzzleDifficulty.easy);
      for (var i = 0; i < 2; i++) {
        await tester.tap(_cell(round.oddAt));
        await tester.pump();
        round = round.tap(round.oddAt);
      }
      final settled = tester.getTopLeft(_cell(0));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(DriftingGrid.slide);
      }
      expect(tester.getTopLeft(_cell(0)), settled);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  for (final scale in [1.0, 2.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('renders at ${scale}x text, $brightness, no overflow', (
        tester,
      ) async {
        await _pump(
          tester,
          difficulty: PuzzleDifficulty.hard,
          textScale: scale,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('mirrors in RTL without overflow', (tester) async {
    await _pump(tester, locale: const Locale('ar'));
    expect(tester.takeException(), isNull);
    expect(
      tester.getCenter(_cell(0)).dx,
      greaterThan(tester.getCenter(_cell(2)).dx),
    );
  });
}
