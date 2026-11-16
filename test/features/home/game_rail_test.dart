import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/home/game_rail.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpRail(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  double width = 393,
}) async {
  tester.view.physicalSize = Size(width, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: capyTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Center(child: GameRail())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('GameRail', () {
    testWidgets('renders one tile per catalogue entry', (tester) async {
      await _pumpRail(tester);
      expect(
        find.byType(Image),
        findsNWidgets(GameCatalogue.entries.length),
      );
    });

    testWidgets('labels come from l10n, not from the catalogue', (
      tester,
    ) async {
      await _pumpRail(tester);

      expect(find.text('Step Quest'), findsOneWidget);
      expect(find.text('Shake DJ'), findsOneWidget);
      expect(find.text('Catch the Capy'), findsOneWidget);
      expect(find.text('Find the Impostor'), findsOneWidget);
    });

    testWidgets('every tile asset is in the art catalogue', (tester) async {
      for (final entry in GameCatalogue.entries) {
        expect(
          () => CapyArt.byId(entry.tileAssetId),
          returnsNormally,
          reason: '${entry.id} points at an uncatalogued asset',
        );
      }
    });

    testWidgets('a comingSoon tap opens the sheet, never a dead tap', (
      tester,
    ) async {
      await _pumpRail(tester);

      await tester.tap(find.text('Shake DJ'));
      await tester.pumpAndSettle();

      expect(find.text('Not built yet'), findsOneWidget);
      expect(find.textContaining('Shake DJ is on the way'), findsOneWidget);
    });

    testWidgets('a blocked tap explains the permission', (tester) async {
      await _pumpRail(tester);

      await tester.tap(find.text('Step Quest'));
      await tester.pumpAndSettle();

      expect(find.text('Not built yet'), findsOneWidget);
      expect(
        find.textContaining('needs a permission'),
        findsOneWidget,
      );
    });

    testWidgets('no tile is a dead tap', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      for (final entry in GameCatalogue.entries) {
        await _pumpRail(tester);

        // The fourth tile sits past the right edge at 393pt, so reach it the
        // way a user would rather than tapping off-screen coordinates.
        final tile = find.text(gameName(l10n, entry));
        await tester.scrollUntilVisible(
          tile,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();

        expect(
          find.text('Not built yet'),
          findsOneWidget,
          reason: '${entry.id} did not open a sheet',
        );

        // Dismiss before the next iteration: a sheet left open belongs to the
        // old tree and the next pump would assert against it.
        Navigator.of(
          tester.element(find.text('Not built yet')),
        ).pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('the featured tile is ringed in ink, not in success', (
      tester,
    ) async {
      // Palette constraint F1: the mockup rings Step Quest in green, which
      // would be 2.68:1 against cream as a control's only boundary channel.
      await _pumpRail(tester);

      // The ring is a foregroundDecoration so it paints over the art rather
      // than insetting it — a Border would render the featured tile 4pt small.
      final ringed = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (c) => (c.foregroundDecoration as BoxDecoration?)?.border != null,
          )
          .toList();

      expect(ringed, hasLength(1));
      final border =
          (ringed.single.foregroundDecoration! as BoxDecoration).border!
              as Border;
      expect(border.top.color, isNot(CapyColors.success));
      expect(border.top.color, isNot(CapyColors.grass));
      expect(border.top.color, CapyColors.cocoa);
    });

    for (final locale in const [Locale('en'), Locale('de'), Locale('ru')]) {
      testWidgets('tile labels render unclipped in ${locale.languageCode}', (
        tester,
      ) async {
        await _pumpRail(tester, locale: locale);

        expect(tester.takeException(), isNull);
        for (final entry in GameCatalogue.entries) {
          final l10n = await AppLocalizations.delegate.load(locale);
          final name = gameName(l10n, entry);
          final text = tester.widget<Text>(find.text(name));
          expect(
            text.overflow,
            isNot(TextOverflow.ellipsis),
            reason:
                'A product name must not be ellipsised to fit. '
                'If "$name" does not fit, report it as a layout defect.',
          );
        }
      });
    }

    testWidgets('an unavailable tile announces its state to a11y', (
      tester,
    ) async {
      await _pumpRail(tester);

      expect(
        tester.getSemantics(find.byType(InkWell).first).label.contains('Soon'),
        isTrue,
        reason: 'A screen reader must hear that the tile is unavailable.',
      );
    });

    testWidgets('an unavailable tile is marked visibly, not only to a11y', (
      tester,
    ) async {
      // CLAUDE.md: a comingSoon card is "visibly and semantically marked".
      // A semantics-only badge leaves a sighted user with no signal.
      await _pumpRail(tester);

      expect(
        find.text('Soon'),
        findsNWidgets(GameCatalogue.entries.where((e) => !e.isPlayable).length),
      );
    });

    testWidgets('scrolls rather than overflowing at 320pt', (tester) async {
      await _pumpRail(tester, width: 320);
      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
