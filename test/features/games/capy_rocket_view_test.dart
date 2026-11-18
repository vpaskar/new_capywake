import 'dart:io';

import 'package:capywake/core/games/capy_rocket.dart';
import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/features/games/capy_rocket_view.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '_pump.dart';

const _seed = 5;

Finder _button(RocketSide side) =>
    find.byKey(ValueKey('capy-rocket-${side.name}'));
final Finder _rocket = find.byKey(const ValueKey('capy-rocket-rocket'));
final Finder _cue = find.byKey(const ValueKey('capy-rocket-cue'));
final Finder _swipe = find.byKey(const ValueKey('capy-rocket-swipe'));

typedef _Calls = ({List<GameChallenge> progress, List<int> completed});

Future<_Calls> _pump(
  WidgetTester tester, {
  PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
  bool reduceMotion = true,
  bool accessibleNavigation = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
}) async {
  final progress = <GameChallenge>[];
  final completed = <int>[];
  await pumpInApp(
    tester,
    CapyRocketView(
      seed: _seed,
      difficulty: difficulty,
      onProgress: progress.add,
      onCompleted: () => completed.add(1),
      reduceMotion: reduceMotion,
    ),
    accessibleNavigation: accessibleNavigation,
    textScale: textScale,
    brightness: brightness,
    locale: locale,
  );
  return (progress: progress, completed: completed);
}

CapyRocketRound _mirror([PuzzleDifficulty d = PuzzleDifficulty.easy]) =>
    CapyRocketRound.start(difficulty: d, seed: _seed);

RocketSide _other(RocketSide side) =>
    side == RocketSide.start ? RocketSide.end : RocketSide.start;

Future<void> _swipeBy(WidgetTester tester, double dx) async {
  await tester.drag(find.byType(Image).first, Offset(dx, 0));
  await tester.pump();
}

void main() {
  testWidgets('shows the instruction, 0 / goal and the cue', (tester) async {
    await _pump(tester);
    expect(
      find.text('Swipe the way the arrow points.'),
      findsOneWidget,
    );
    expect(find.text('0 / 6'), findsOneWidget);
    expect(
      find.text(
        _mirror().cue == RocketSide.start ? 'Swipe left' : 'Swipe right',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping the cued button boosts and climbs', (tester) async {
    final calls = await _pump(tester);
    final before = tester.getTopLeft(_rocket).dy;
    await tester.tap(_button(_mirror().cue));
    await tester.pump();
    expect(calls.progress.last.completed, 1);
    expect(find.text('Up we go.'), findsOneWidget);
    expect(tester.getTopLeft(_rocket).dy, lessThan(before));
  });

  testWidgets('the other button wobbles: struggle, no climb', (tester) async {
    final calls = await _pump(tester);
    final before = tester.getTopLeft(_rocket).dy;
    await tester.tap(_button(_other(_mirror().cue)));
    await tester.pump();
    expect(calls.progress.last.struggleCount, 1);
    expect(calls.progress.last.completed, 0);
    expect(find.text('Other way. Follow the arrow.'), findsOneWidget);
    expect(tester.getTopLeft(_rocket).dy, before);
  });

  testWidgets('a swipe toward the cue boosts; a short drag does nothing', (
    tester,
  ) async {
    final calls = await _pump(tester);
    final right = _mirror().cue == RocketSide.end;
    await _swipeBy(tester, right ? 8 : -8);
    expect(calls.progress, isEmpty);
    await _swipeBy(tester, right ? 120 : -120);
    expect(calls.progress.last.completed, 1);
  });

  testWidgets('a swipe the other way wobbles', (tester) async {
    final calls = await _pump(tester);
    await _swipeBy(tester, _mirror().cue == RocketSide.end ? -120 : 120);
    expect(calls.progress.last.struggleCount, 1);
  });

  testWidgets('in RTL the start side is on the right, for swipes and words', (
    tester,
  ) async {
    final calls = await _pump(tester, locale: const Locale('ar'));
    expect(tester.takeException(), isNull);
    expect(
      tester.getCenter(_button(RocketSide.start)).dx,
      greaterThan(tester.getCenter(_button(RocketSide.end)).dx),
    );
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(_button(RocketSide.start)).label,
      'طِر إلى اليمين',
    );
    handle.dispose();
    final cue = _mirror().cue;
    await _swipeBy(tester, cue == RocketSide.start ? 120 : -120);
    expect(calls.progress.last.completed, 1);
  });

  testWidgets('buttons are labelled by the side they sit on', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    expect(tester.getSemantics(_button(RocketSide.start)).label, 'Fly left');
    expect(tester.getSemantics(_button(RocketSide.end)).label, 'Fly right');
    handle.dispose();
  });

  testWidgets('the cue is announced', (tester) async {
    await _pump(tester);
    final semantics = tester.widget<Semantics>(
      find.ancestor(of: _cue, matching: find.byType(Semantics)).first,
    );
    expect(semantics.properties.liveRegion, isTrue);
  });

  testWidgets('finishing reports completion once; the rocket tops out', (
    tester,
  ) async {
    final calls = await _pump(tester);
    var round = _mirror();
    while (!round.isComplete) {
      await tester.tap(_button(round.cue));
      await tester.pump();
      round = round.boost(round.cue);
    }
    expect(calls.completed, [1]);
    expect(
      tester.getTopLeft(_rocket).dy -
          tester.getTopLeft(find.byType(Image).first).dy,
      closeTo(CapyRocketView.skyGap, 0.5),
    );
    await tester.tap(_button(RocketSide.start));
    await tester.pump();
    expect(calls.completed, [1]);
  });

  testWidgets('the rocket is drawn no larger than its pixels allow (H3)', (
    tester,
  ) async {
    await _pump(tester);
    final pose = img.decodeImage(
      File(CapyArt.byId('pose.capyRocket').path).readAsBytesSync(),
    )!;
    final size = tester.getSize(_rocket);
    expect(size.width, CapyRocketView.rocketSize);
    expect(size.width * 3, lessThanOrEqualTo(pose.width));
    expect(size.width, lessThanOrEqualTo(ArtUse.winPose.renderBoxPt));
  });

  testWidgets('buttons are large targets and stay put (H2, M3)', (
    tester,
  ) async {
    await _pump(tester, locale: const Locale('de'));
    final start = tester.getRect(_button(RocketSide.start));
    expect(start.width, greaterThanOrEqualTo(64));
    expect(start.height, greaterThanOrEqualTo(56));
    final outcome = tester.getSize(find.byType(GameOutcomeLine));
    var round = _mirror();
    for (var i = 0; i < 3; i++) {
      await tester.tap(_button(round.cue));
      await tester.pump();
      round = round.boost(round.cue);
      expect(tester.getRect(_button(RocketSide.start)), start);
      expect(tester.getSize(find.byType(GameOutcomeLine)), outcome);
    }
  });

  testWidgets('the field keeps its fixed height in a scroll view', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      tester.getSize(find.byType(Image).first).height,
      CapyRocketView.fieldHeight,
    );
  });

  group('moving', () {
    testWidgets('the rocket hovers, then rests so frames can settle', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: false);
      expect(tester.hasRunningAnimations, isFalse);
      final rest = tester.getTopLeft(_rocket).dy;
      for (var cycle = 0; cycle < 2; cycle++) {
        await tester.pump(CapyRocketView.hoverRest);
        await tester.pump(CapyRocketView.hover * 0.5);
        expect(tester.getTopLeft(_rocket).dy, lessThan(rest));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(_rocket).dy, closeTo(rest, 0.01));
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a boost climbs over the difficulty climb time', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: false);
      final start = tester.getTopLeft(_rocket).dy;
      await tester.tap(_button(_mirror().cue));
      await tester.pump();
      await tester.pump(
        CapyRocketRound.climbFor(PuzzleDifficulty.easy) * 0.3,
      );
      final mid = tester.getTopLeft(_rocket).dy;
      expect(mid, lessThan(start));
      await tester.pump(CapyRocketRound.climbFor(PuzzleDifficulty.easy));
      expect(tester.getTopLeft(_rocket).dy, lessThan(mid));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a wrong swipe wobbles the rocket', (tester) async {
      await _pump(tester, reduceMotion: false);
      await tester.tap(_button(_other(_mirror().cue)));
      await tester.pump();
      await tester.pump(CapyRocketView.wobble * 0.1);
      final rotations = tester.widgetList<Transform>(
        find.ancestor(of: _rocket, matching: find.byType(Transform)),
      );
      expect(
        rotations.any((t) => t.transform.getRotation().entry(0, 1) != 0),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with a screen reader nothing hovers (H5)', (tester) async {
      await _pump(tester, reduceMotion: false, accessibleNavigation: true);
      await tester.pump(CapyRocketView.hover * 0.5);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('disposing mid-hover leaves no timer behind (M2)', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: false);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('under reduce-motion the climb jumps and nothing animates', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(_button(_mirror().cue));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
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
        expect(_swipe, findsOneWidget);
      });
    }
  }
}
