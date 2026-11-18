import 'package:capywake/app/router.dart';
import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/games/all_games_screen.dart';
import 'package:capywake/features/games/game_names.dart';
import 'package:capywake/features/home/game_rail.dart';
import 'package:capywake/features/home/home_screen.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(393, 852),
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: HomeScreen()),
      ),
      GoRoute(
        path: Routes.games,
        builder: (_, _) => const AllGamesScreen(),
      ),
      GoRoute(
        path: '${Routes.games}/:id',
        builder: (_, state) =>
            Scaffold(body: Text('practice:${state.pathParameters['id']}')),
      ),
    ],
  );
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('See All on Home opens every wake-up game', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('See All'));
    await tester.pumpAndSettle();

    final screen = find.byType(AllGamesScreen);
    expect(screen, findsOneWidget);
    expect(
      find.descendant(of: screen, matching: find.byType(GameTile)),
      findsNWidgets(GameCatalogue.entries.length),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    for (final entry in GameCatalogue.entries) {
      expect(
        find.descendant(of: screen, matching: find.text(gameName(l10n, entry))),
        findsOneWidget,
      );
    }
  });

  testWidgets('a game opens its practice, and back returns to the list', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('See All'));
    await tester.pumpAndSettle();

    final playable = GameCatalogue.entries.firstWhere((e) => e.isPlayable);
    final tile = find.descendant(
      of: find.byType(AllGamesScreen),
      matching: find.byWidgetPredicate(
        (w) => w is GameTile && w.entry.id == playable.id,
      ),
    );
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text('practice:${playable.id}'), findsOneWidget);
  });

  testWidgets('fits a 320pt phone without overflow', (tester) async {
    await _pump(tester, size: const Size(320, 568));
    await tester.tap(find.text('See All'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
