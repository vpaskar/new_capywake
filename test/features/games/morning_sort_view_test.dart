import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/games/morning_sort.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/features/games/drifting_grid.dart';
import 'package:capywake/features/games/morning_sort_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '_pump.dart';

const _seed = 4;

Finder _card(int i) => find.byKey(ValueKey('morning-sort-card-$i'));
Finder _pocket(int i) => find.byKey(ValueKey('morning-sort-pocket-$i'));

MorningSortRound _mirror([
  PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
]) => MorningSortRound.start(difficulty: difficulty, seed: _seed);

int _useful(MorningSortRound r) => [
  for (var i = 0; i < r.items.length; i++)
    if (r.items[i].useful && !r.isResolved(i)) i,
].first;

int _decoy(MorningSortRound r) => [
  for (var i = 0; i < r.items.length; i++)
    if (!r.items[i].useful && !r.isResolved(i)) i,
].first;

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
    MorningSortView(
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

Future<void> _tapAndSettle(WidgetTester tester, int index) async {
  await tester.ensureVisible(_card(index));
  await tester.pumpAndSettle();
  await tester.tap(_card(index));
  await tester.pumpAndSettle();
}

void main() {
  test('every item in the bank has a distinct name in every locale', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      final names = {
        for (final item in MorningItem.values) morningItemName(l10n, item),
      };
      expect(names, hasLength(MorningItem.values.length), reason: '$locale');
    }
  });

  testWidgets('shows the instruction, the bag and the item names', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text('Tap what Capy needs this morning.'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    expect(_pocket(2), findsOneWidget);
    expect(_pocket(3), findsNothing);
    for (final item in _mirror().items) {
      expect(find.text(morningItemName(l10n, item)), findsOneWidget);
    }
  });

  testWidgets('easy lays four cards in two columns', (tester) async {
    await _pump(tester, difficulty: PuzzleDifficulty.easy);
    expect(_card(3), findsOneWidget);
    expect(_card(4), findsNothing);
    expect(tester.getTopLeft(_card(2)).dx, tester.getTopLeft(_card(0)).dx);
  });

  testWidgets('every card is a large target', (tester) async {
    await _pump(tester);
    for (var i = 0; i < 6; i++) {
      final size = tester.getSize(_card(i));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(MorningSortView.cellMinHeight));
    }
  });

  testWidgets('a useful item packs into the next pocket', (tester) async {
    final calls = await _pump(tester);
    final index = _useful(_mirror());
    await _tapAndSettle(tester, index);
    expect(find.text('In the bag.'), findsOneWidget);
    expect(
      find.byKey(ValueKey('morning-sort-packed-$index')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _pocket(0),
        matching: find.byKey(const ValueKey('morning-sort-pocket-filled')),
      ),
      findsOneWidget,
    );
    expect(calls.progress.last.struggleCount, 0);
  });

  testWidgets('a decoy is set aside as struggle and cannot count twice', (
    tester,
  ) async {
    final calls = await _pump(tester);
    final index = _decoy(_mirror());
    await _tapAndSettle(tester, index);
    expect(find.text('Capy can leave that at home.'), findsOneWidget);
    expect(
      find.byKey(ValueKey('morning-sort-left-out-$index')),
      findsOneWidget,
    );
    expect(calls.progress.last.struggleCount, 1);
    await _tapAndSettle(tester, index);
    expect(calls.progress, hasLength(1));
  });

  testWidgets('filling every pocket packs the bag and deals the next', (
    tester,
  ) async {
    final calls = await _pump(tester);
    var round = _mirror();
    for (var i = 0; i < 3; i++) {
      final index = _useful(round);
      await _tapAndSettle(tester, index);
      round = round.tap(index);
    }
    expect(find.text('Bag packed.'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(calls.progress.last.completed, 1);
    expect(
      find.byKey(const ValueKey('morning-sort-pocket-filled')),
      findsNothing,
    );
  });

  testWidgets('packing every bag reports completion once', (tester) async {
    final calls = await _pump(tester, difficulty: PuzzleDifficulty.easy);
    var round = _mirror(PuzzleDifficulty.easy);
    while (!round.isComplete) {
      final index = _useful(round);
      await _tapAndSettle(tester, index);
      round = round.tap(index);
    }
    await tester.tap(_card(0));
    await tester.pumpAndSettle();
    expect(calls.completed, [1]);
    expect(calls.progress.last.isComplete, isTrue);
  });

  testWidgets('cards, pockets and states speak for a screen reader', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, accessibleNavigation: true);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final round = _mirror();
    final useful = _useful(round);
    final decoy = _decoy(round);
    final usefulName = morningItemName(l10n, round.items[useful]);
    final decoyName = morningItemName(l10n, round.items[decoy]);

    expect(tester.getSemantics(_card(useful)).label, usefulName);
    expect(tester.getSemantics(_pocket(0)).label, 'Pocket 1 of 3: empty');

    await _tapAndSettle(tester, useful);
    await _tapAndSettle(tester, decoy);
    expect(tester.getSemantics(_card(useful)).label, '$usefulName: packed');
    expect(
      tester.getSemantics(_card(decoy)).label,
      '$decoyName: left at home',
    );
    expect(tester.getSemantics(_pocket(0)).label, 'Pocket 1 of 3: $usefulName');
    handle.dispose();
  });

  testWidgets('nothing moves between bags or when an outcome appears (M6)', (
    tester,
  ) async {
    await _pump(tester);
    final card = tester.getSize(find.byType(CapyCard));
    final cell = tester.getSize(_card(0));
    var round = _mirror();
    for (var i = 0; i < 3; i++) {
      final index = _useful(round);
      await _tapAndSettle(tester, index);
      round = round.tap(index);
      expect(tester.getSize(find.byType(CapyCard)), card);
    }
    expect(tester.getSize(_card(0)), cell);
  });

  for (final locale in const [Locale('de'), Locale('ru'), Locale('fr')]) {
    for (final difficulty in [PuzzleDifficulty.easy, PuzzleDifficulty.hard]) {
      testWidgets('no name is clipped: $locale, 2x text, $difficulty (M6)', (
        tester,
      ) async {
        await _pump(
          tester,
          locale: locale,
          textScale: 2,
          difficulty: difficulty,
        );
        final l10n = await AppLocalizations.delegate.load(locale);
        var round = _mirror(difficulty);
        while (!round.isComplete) {
          for (final item in round.items) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.text(morningItemName(l10n, item)),
            );
            expect(
              paragraph.getMaxIntrinsicHeight(paragraph.size.width),
              lessThanOrEqualTo(paragraph.size.height + 0.5),
              reason: morningItemName(l10n, item),
            );
          }
          for (var p = 0; p < round.pockets; p++) {
            final index = _useful(round);
            await _tapAndSettle(tester, index);
            round = round.tap(index);
          }
        }
      });
    }
  }

  group('moving', () {
    testWidgets('the unresolved cards drift; a packed card stays put', (
      tester,
    ) async {
      final calls = await _pump(tester, reduceMotion: false);
      final round = _mirror();
      final packed = _useful(round);
      await tester.tap(_card(packed));
      await tester.pump();
      final at = tester.getTopLeft(_card(packed));
      final every = MorningSortRound.swapEveryFor(PuzzleDifficulty.medium);
      final others = <Offset>{};
      for (var i = 0; i < 6; i++) {
        await tester.pump(every);
        await tester.pump(DriftingGrid.slide);
        expect(tester.getTopLeft(_card(packed)), at);
        others.add(tester.getTopLeft(_card(_decoy(round))));
      }
      expect(others.length, greaterThan(1));
      expect(calls.progress.last.completed, 0);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a screen reader turned on mid-slide stops the drift (H5)', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: false);
      final home = tester.getTopLeft(_card(0));
      final every = MorningSortRound.swapEveryFor(PuzzleDifficulty.medium);
      await tester.pump(every);
      await tester.pump(DriftingGrid.slide ~/ 2);
      await _pump(tester, reduceMotion: false, accessibleNavigation: true);
      expect(tester.hasRunningAnimations, isFalse);
      for (var i = 0; i < 4; i++) {
        await tester.pump(every);
        await tester.pump(DriftingGrid.slide);
      }
      expect(tester.getTopLeft(_card(0)), home);
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
      tester.getCenter(_card(0)).dx,
      greaterThan(tester.getCenter(_card(2)).dx),
    );
  });
}
