import 'package:capywake/core/games/game_drift.dart';
import 'package:capywake/features/games/drifting_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _every = Duration(seconds: 2);
const _seed = 3;

Finder _cell(int i) => find.byKey(ValueKey('cell-$i'));

Future<void> _pump(
  WidgetTester tester, {
  bool moves = true,
  int generation = 0,
  bool Function(int)? canMove,
  int cells = 6,
  DriftStyle style = DriftStyle.swap,
}) => tester.pumpWidget(
  Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 300,
        child: DriftingGrid(
          cellCount: cells,
          columns: 3,
          cellHeightFor: (_) => 50,
          cellBuilder: (_, i) => ColoredBox(
            key: ValueKey('cell-$i'),
            color: const Color(0xFF000000),
          ),
          moves: moves,
          swapEvery: _every,
          seed: _seed,
          generation: generation,
          canMove: canMove,
          style: style,
        ),
      ),
    ),
  ),
);

Future<void> _beats(WidgetTester tester, int beats) async {
  for (var i = 0; i < beats; i++) {
    await tester.pump(_every);
    await tester.pump(DriftingGrid.slide);
  }
}

List<Offset> _positions(WidgetTester tester, [int cells = 6]) => [
  for (var i = 0; i < cells; i++) tester.getTopLeft(_cell(i)),
];

void main() {
  testWidgets('lays cells out in rows and columns, at the given height', (
    tester,
  ) async {
    await _pump(tester, moves: false);
    expect(tester.getSize(_cell(0)).height, 50);
    expect(tester.getTopLeft(_cell(3)).dy, 50 + DriftingGrid.gap);
    expect(tester.getTopLeft(_cell(1)).dx, greaterThan(0));
  });

  testWidgets('still: nothing ever moves and nothing animates', (
    tester,
  ) async {
    await _pump(tester, moves: false);
    final before = _positions(tester);
    await _beats(tester, 5);
    expect(_positions(tester), before);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('moving: the seeded pair swaps after the rest, sliding', (
    tester,
  ) async {
    await _pump(tester);
    final before = _positions(tester);
    final (a, b, _) = const GameDrift(_seed).next([0, 1, 2, 3, 4, 5])!;
    await tester.pump(_every);
    await tester.pump(DriftingGrid.slide ~/ 2);
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(DriftingGrid.slide);
    final after = _positions(tester);
    expect(after[a], before[b]);
    expect(after[b], before[a]);
    for (var i = 0; i < 6; i++) {
      if (i != a && i != b) expect(after[i], before[i]);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('no swap starts while a finger is down (H3)', (tester) async {
    await _pump(tester);
    final before = _positions(tester);
    final gesture = await tester.startGesture(tester.getCenter(_cell(0)));
    await _beats(tester, 3);
    expect(_positions(tester), before);
    await gesture.up();
    await tester.pump(_every);
    await tester.pump(DriftingGrid.slide);
    expect(_positions(tester), isNot(before));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('turning still mid-slide puts every card back at once (H5)', (
    tester,
  ) async {
    await _pump(tester);
    final home = _positions(tester);
    await tester.pump(_every);
    await tester.pump(DriftingGrid.slide ~/ 2);
    await _pump(tester, moves: false);
    await tester.pump();
    expect(_positions(tester), home);
    expect(tester.hasRunningAnimations, isFalse);
    await _beats(tester, 3);
    expect(_positions(tester), home);
  });

  testWidgets('new content starts in place, without sliding back', (
    tester,
  ) async {
    await _pump(tester);
    final home = _positions(tester);
    await tester.pump(_every);
    await tester.pump(DriftingGrid.slide);
    expect(_positions(tester), isNot(home));
    await _pump(tester, generation: 1);
    await tester.pump();
    expect(_positions(tester), home);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('only movable cards drift; one movable card stays', (
    tester,
  ) async {
    await _pump(tester, canMove: (i) => i == 2 || i == 4);
    final before = _positions(tester);
    await tester.pump(_every);
    await tester.pump(DriftingGrid.slide);
    final after = _positions(tester);
    expect(after[2], before[4]);
    expect(after[4], before[2]);

    await _pump(tester, generation: 1, canMove: (i) => i == 2);
    final settled = _positions(tester);
    await _beats(tester, 3);
    expect(_positions(tester), settled);
  });

  testWidgets('carousel: every card steps to its neighbour round the ring', (
    tester,
  ) async {
    await _pump(tester, style: DriftStyle.carousel);
    final home = _positions(tester);
    await tester.pump(_every);
    await tester.pump(DriftingGrid.slide);
    final after = _positions(tester);
    // Ring on two rows of three: 0 1 2 / 5 4 3.
    for (final (from, to) in [(0, 1), (1, 2), (2, 5), (5, 4), (4, 3), (3, 0)]) {
      expect(after[from], home[to], reason: 'cell $from');
    }
    await tester.pump(_every);
    await tester.pump(DriftingGrid.slide);
    expect(_positions(tester)[0], home[2]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('disposing mid-slide leaves no timer behind (M5)', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pump(_every);
    await tester.pump(DriftingGrid.slide ~/ 3);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('a finger in the gap between cards also holds the drift', (
    tester,
  ) async {
    await _pump(tester);
    final before = _positions(tester);
    final below = tester.getBottomLeft(_cell(0));
    final gesture = await tester.startGesture(
      below.translate(4, DriftingGrid.gap / 2),
    );
    await _beats(tester, 3);
    expect(_positions(tester), before);
    await gesture.up();
    await tester.pumpWidget(const SizedBox());
  });

  for (final share in [0.3, 0.5, 0.7]) {
    testWidgets(
      'a tap ${share * 100}% into a slide goes to the card aimed at',
      (
        tester,
      ) async {
        final tapped = <int>[];
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 300,
                child: DriftingGrid(
                  cellCount: 6,
                  columns: 3,
                  cellHeightFor: (_) => 50,
                  cellBuilder: (_, i) => GestureDetector(
                    key: ValueKey('cell-$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => tapped.add(i),
                  ),
                  moves: true,
                  swapEvery: _every,
                  seed: _seed,
                  generation: 0,
                  style: DriftStyle.carousel,
                ),
              ),
            ),
          ),
        );
        final aimed = tester.getCenter(_cell(0));
        await tester.pump(_every);
        await tester.pump(DriftingGrid.slide * share);
        expect(tester.getCenter(_cell(0)), isNot(aimed));
        await tester.tapAt(aimed);
        expect(tapped, [0]);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('mirrors in RTL', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: 300,
          child: DriftingGrid(
            cellCount: 4,
            columns: 2,
            cellHeightFor: (_) => 40,
            cellBuilder: (_, i) => ColoredBox(
              key: ValueKey('cell-$i'),
              color: const Color(0xFF000000),
            ),
            moves: false,
            swapEvery: _every,
            seed: _seed,
            generation: 0,
          ),
        ),
      ),
    );
    expect(
      tester.getTopLeft(_cell(0)).dx,
      greaterThan(tester.getTopLeft(_cell(1)).dx),
    );
  });
}
