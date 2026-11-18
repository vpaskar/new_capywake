import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/puzzle/puzzle_chooser_screen.dart';
import 'package:capywake/features/puzzle/puzzle_labels.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  PuzzleSettings? seed,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  if (seed != null) {
    await container.read(capywakeRepositoryProvider).savePuzzleSettings(seed);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PuzzleChooserScreen(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(PuzzleChooserScreen)));

/// The chooser is a lazy list; a row below the fold is not built until shown.
Future<void> scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders all ten puzzle types', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);
    for (final type in PuzzleType.values) {
      await scrollTo(tester, find.text(puzzleTypeLabel(type, l10n)));
      expect(
        find.text(puzzleTypeLabel(type, l10n)),
        findsOneWidget,
        reason: 'missing ${type.name}',
      );
    }
  });

  testWidgets('enabling a type persists it', (tester) async {
    final container = await _pump(
      tester,
      seed: PuzzleSettings(enabledTypes: const {PuzzleType.arithmetic}),
    );
    final l10n = _l10n(tester);

    final tile = find.text(puzzleTypeLabel(PuzzleType.shapeRotation, l10n));
    await scrollTo(tester, tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    final saved = await container
        .read(capywakeRepositoryProvider)
        .getPuzzleSettings();
    expect(saved.enabledTypes, contains(PuzzleType.shapeRotation));
  });

  testWidgets('the last enabled type cannot be turned off (H3)', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      seed: PuzzleSettings(enabledTypes: const {PuzzleType.arithmetic}),
    );
    final l10n = _l10n(tester);

    final arithmetic = find.text(puzzleTypeLabel(PuzzleType.arithmetic, l10n));
    await scrollTo(tester, arithmetic);
    await tester.tap(arithmetic);
    await tester.pumpAndSettle();

    final saved = await container
        .read(capywakeRepositoryProvider)
        .getPuzzleSettings();
    expect(saved.enabledTypes, contains(PuzzleType.arithmetic));
    expect(saved.enabledTypes, isNotEmpty);
  });

  testWidgets('the escape control offers two values and no "never" (M1)', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    await scrollTo(tester, find.text(l10n.puzzleSettingsEscapeExplanation));
    expect(find.text(l10n.puzzleSettingsEscapeConfirm), findsOneWidget);
    expect(find.text(l10n.puzzleSettingsEscapeHold), findsOneWidget);
    // The always-reachable explanation is on the surface.
    expect(find.text(l10n.puzzleSettingsEscapeExplanation), findsOneWidget);
  });

  testWidgets('difficulty persists', (tester) async {
    final container = await _pump(tester);
    final l10n = _l10n(tester);

    await scrollTo(tester, find.text(l10n.alarmDismissDifficultyHard));
    await tester.tap(find.text(l10n.alarmDismissDifficultyHard));
    await tester.pumpAndSettle();
    expect(
      (await container.read(capywakeRepositoryProvider).getPuzzleSettings())
          .difficulty,
      PuzzleDifficulty.hard,
    );
  });

  testWidgets('escape strictness persists', (tester) async {
    final container = await _pump(tester);
    final l10n = _l10n(tester);

    await scrollTo(tester, find.text(l10n.puzzleSettingsEscapeHold));
    await tester.tap(find.text(l10n.puzzleSettingsEscapeHold));
    await tester.pumpAndSettle();
    expect(
      (await container.read(capywakeRepositoryProvider).getPuzzleSettings())
          .escapeStrictness,
      PuzzleEscapeStrictness.confirmAndHold,
    );
  });

  testWidgets('the tolerance stepper raises the count', (tester) async {
    final container = await _pump(tester);
    final l10n = _l10n(tester);
    final repo = container.read(capywakeRepositoryProvider);

    final before = (await repo.getPuzzleSettings()).toleratedWrongAnswers;
    await scrollTo(tester, find.byTooltip(l10n.puzzleSettingsToleranceLater));
    await tester.tap(find.byTooltip(l10n.puzzleSettingsToleranceLater));
    await tester.pumpAndSettle();
    expect((await repo.getPuzzleSettings()).toleratedWrongAnswers, before + 1);
  });

  testWidgets('warns when every enabled type needs sight', (tester) async {
    await _pump(
      tester,
      seed: PuzzleSettings(
        enabledTypes: const {PuzzleType.gridPatternRecall},
      ),
    );
    final l10n = _l10n(tester);
    await scrollTo(tester, find.text(l10n.puzzleSettingsVisualOnlyTitle));
    expect(find.text(l10n.puzzleSettingsVisualOnlyTitle), findsOneWidget);
  });

  testWidgets('does not warn when a spoken type is enabled', (tester) async {
    await _pump(
      tester,
      seed: PuzzleSettings(enabledTypes: const {PuzzleType.arithmetic}),
    );
    final l10n = _l10n(tester);
    await scrollTo(
      tester,
      find.text(puzzleTypeLabel(PuzzleType.values.last, l10n)),
    );
    expect(find.text(l10n.puzzleSettingsVisualOnlyTitle), findsNothing);
  });

  testWidgets('does not overflow at 2x text', (tester) async {
    await _pump(tester, textScaler: const TextScaler.linear(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out in RTL without exception', (tester) async {
    await _pump(tester, locale: const Locale('ar'));
    expect(
      Directionality.of(tester.element(find.byType(PuzzleChooserScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
