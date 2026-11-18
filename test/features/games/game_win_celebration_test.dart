import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/games/win_art.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/features/games/game_names.dart';
import 'package:capywake/features/games/game_win_celebration.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_pump.dart';

String _shownFrame(WidgetTester tester) =>
    (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName;

void main() {
  group('GameWinPanel', winPanelTests);

  const label = 'Capy cheering, with confetti';
  final playTime = GameWinCelebration.frameDuration * CapyArt.winFrames.length;

  testWidgets('steps through every frame, then rests on the first', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      const GameWinCelebration(semanticLabel: label),
    );
    expect(_shownFrame(tester), CapyArt.winFrames.first.path);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          key: UniqueKey(),
          child: const GameWinCelebration(semanticLabel: label),
        ),
      ),
    );
    final seen = <String>{};
    for (
      var t = Duration.zero;
      t < playTime;
      t += const Duration(milliseconds: 55)
    ) {
      await tester.pump(const Duration(milliseconds: 55));
      seen.add(_shownFrame(tester));
    }
    expect(seen, containsAll(CapyArt.winFrames.map((f) => f.path)));

    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(_shownFrame(tester), CapyArt.winFrames.first.path);
  });

  testWidgets('a game can pass its own frames', (tester) async {
    final own = [CapyArt.runFrames[2], CapyArt.runFrames[3]];
    await pumpInApp(
      tester,
      GameWinCelebration(semanticLabel: label, frames: own),
    );
    expect(_shownFrame(tester), own.first.path);
  });

  for (final (name, reduce, reader) in [
    ('reduce-motion', true, false),
    ('a screen reader', false, true),
  ]) {
    testWidgets('under $name it is one still frame', (tester) async {
      await pumpInApp(
        tester,
        const GameWinCelebration(semanticLabel: label),
        disableAnimations: reduce,
        accessibleNavigation: reader,
      );
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(playTime);
      expect(_shownFrame(tester), CapyArt.winFrames.first.path);
    });
  }

  bool loopTicks(WidgetTester tester) => TickerMode.valuesOf(
    tester.element(find.byKey(const ValueKey('win-loop'))),
  ).enabled;

  testWidgets('an asset missing from the bundle shows the cutout, not an '
      'error box', (tester) async {
    await pumpInApp(
      tester,
      const GameWinCelebration(
        semanticLabel: label,
        loop: ArtAsset(
          'loop.missing',
          'assets/art/animations/not_bundled.webp',
          ArtUse.animation,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('win-art-fallback')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a loop plays while motion is on', (tester) async {
    await pumpInApp(
      tester,
      const GameWinCelebration(
        semanticLabel: label,
        loop: CapyArt.celebrationLoop,
      ),
    );
    expect(_shownFrame(tester), CapyArt.celebrationLoop.path);
    expect(loopTicks(tester), isTrue);
  });

  for (final (name, reduce, reader) in [
    ('reduce-motion', true, false),
    ('a screen reader', false, true),
  ]) {
    testWidgets('under $name a loop holds its first frame', (tester) async {
      await pumpInApp(
        tester,
        const GameWinCelebration(
          semanticLabel: label,
          loop: CapyArt.celebrationLoop,
        ),
        disableAnimations: reduce,
        accessibleNavigation: reader,
      );
      expect(loopTicks(tester), isFalse);
    });
  }

  testWidgets('is announced as an image with its label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpInApp(
      tester,
      const GameWinCelebration(semanticLabel: label),
    );
    expect(
      tester.getSemantics(find.byType(GameWinCelebration)),
      matchesSemantics(label: label, isImage: true),
    );
    handle.dispose();
  });
}

void winPanelTests() {
  testWidgets("the cheer replaces even a game's own pose", (tester) async {
    await pumpInApp(
      tester,
      const GameWinPanel(
        gameId: 'catch_the_capy',
        subline: 's',
        art: WinArt.cheer,
      ),
    );
    expect(_shownFrame(tester), CapyArt.winFrames.first.path);
    expect(find.text('Nice catch!'), findsOneWidget);
  });

  testWidgets('the trophy is the celebration loop', (tester) async {
    await pumpInApp(
      tester,
      const GameWinPanel(
        gameId: 'catch_the_capy',
        subline: 's',
        art: WinArt.trophy,
      ),
    );
    expect(_shownFrame(tester), CapyArt.celebrationLoop.path);
  });

  testWidgets('a game with a pose springs it in, then holds it', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      const GameWinPanel(gameId: 'catch_the_capy', subline: 'Practice done'),
    );
    expect(
      _shownFrame(tester),
      CapyArt.byId('pose.catchTheCapy').path,
    );
    expect(find.text('Nice catch!'), findsOneWidget);
    expect(find.text('Practice done'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('the pose enters with motion when motion is on', (
    tester,
  ) async {
    await pumpInApp(tester, const SizedBox());
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameWinPanel(gameId: 'memory_hideout', subline: 's'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final early = tester.widget<Opacity>(find.byType(Opacity)).opacity;
    expect(early, lessThan(1));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });

  testWidgets('under reduce-motion the pose is shown whole at once', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      const GameWinPanel(gameId: 'memory_hideout', subline: 's'),
      disableAnimations: true,
    );
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('an unknown game gets the shared animation and line', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      const GameWinPanel(gameId: 'not_a_game', subline: 's'),
    );
    expect(_shownFrame(tester), CapyArt.winFrames.first.path);
    expect(find.text('You did it!'), findsOneWidget);
  });

  test('every game names a pose that exists', () {
    for (final entry in GameCatalogue.entries) {
      expect(
        CapyArt.byId(entry.winPoseAssetId!).use,
        ArtUse.winPose,
        reason: entry.id,
      );
    }
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('every headline fits at 2x text in ${locale.languageCode}', (
      tester,
    ) async {
      for (final entry in GameCatalogue.entries) {
        await pumpInApp(
          tester,
          GameWinPanel(gameId: entry.id, subline: 'Alarm stopped'),
          locale: locale,
          textScale: 2,
          disableAnimations: true,
        );
        expect(tester.takeException(), isNull, reason: entry.id);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(GameWinPanel)),
        );
        expect(gameWinHeadline(l10n, entry.id), isNotEmpty);
      }
    });
  }
}
