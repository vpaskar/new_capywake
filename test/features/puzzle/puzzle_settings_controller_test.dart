import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/puzzle/puzzle_settings_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return container;
}

void main() {
  test('setDifficulty persists through the repository', () async {
    final c = _container();
    final controller = c.read(puzzleSettingsControllerProvider);

    await controller.setDifficulty(PuzzleDifficulty.hard);

    final saved = await c.read(capywakeRepositoryProvider).getPuzzleSettings();
    expect(saved.difficulty, PuzzleDifficulty.hard);
  });

  test('setTaskCount and setToleratedWrongAnswers persist', () async {
    final c = _container();
    final controller = c.read(puzzleSettingsControllerProvider);

    await controller.setTaskCount(4);
    await controller.setToleratedWrongAnswers(2);

    final saved = await c.read(capywakeRepositoryProvider).getPuzzleSettings();
    expect(saved.taskCount, 4);
    expect(saved.toleratedWrongAnswers, 2);
  });

  test('setEscapeStrictness persists', () async {
    final c = _container();
    final controller = c.read(puzzleSettingsControllerProvider);

    await controller.setEscapeStrictness(PuzzleEscapeStrictness.confirmAndHold);

    final saved = await c.read(capywakeRepositoryProvider).getPuzzleSettings();
    expect(saved.escapeStrictness, PuzzleEscapeStrictness.confirmAndHold);
  });

  test('setTypeEnabled adds and removes a type', () async {
    final c = _container();
    final controller = c.read(puzzleSettingsControllerProvider);
    final repo = c.read(capywakeRepositoryProvider);

    await controller.setTypeEnabled(PuzzleType.shapeRotation, enabled: true);
    expect(
      (await repo.getPuzzleSettings()).enabledTypes,
      contains(PuzzleType.shapeRotation),
    );

    await controller.setTypeEnabled(PuzzleType.shapeRotation, enabled: false);
    expect(
      (await repo.getPuzzleSettings()).enabledTypes,
      isNot(contains(PuzzleType.shapeRotation)),
    );
  });

  test('the enabled set is never emptied (H3 floor)', () async {
    final c = _container();
    final controller = c.read(puzzleSettingsControllerProvider);
    final repo = c.read(capywakeRepositoryProvider);

    // Collapse to a single type, then try to remove it.
    await repo.savePuzzleSettings(
      PuzzleSettings(enabledTypes: const {PuzzleType.arithmetic}),
    );
    await controller.setTypeEnabled(PuzzleType.arithmetic, enabled: false);

    final saved = await repo.getPuzzleSettings();
    expect(saved.enabledTypes, contains(PuzzleType.arithmetic));
    expect(saved.enabledTypes, isNotEmpty);
  });

  test('a write reaches the watch stream the ringing surface reads (M3)', () {
    final c = _container();
    final controller = c.read(puzzleSettingsControllerProvider);

    // The ringing controller reads puzzleSettingsStreamProvider; a chooser
    // write must surface there, or the chosen puzzle never reaches the alarm.
    final emitted = <PuzzleDifficulty>[];
    final sub = c.listen(
      puzzleSettingsStreamProvider,
      (_, next) {
        final v = next.value;
        if (v != null) emitted.add(v.difficulty);
      },
      fireImmediately: true,
    );
    addTearDown(sub.close);

    return expectLater(
      () async {
        await controller.setDifficulty(PuzzleDifficulty.easy);
        await Future<void>.delayed(Duration.zero);
      }(),
      completes,
    ).then((_) {
      expect(emitted, contains(PuzzleDifficulty.easy));
    });
  });

  test('a setter re-reads so it cannot drop another field', () async {
    final c = _container();
    final controller = c.read(puzzleSettingsControllerProvider);
    final repo = c.read(capywakeRepositoryProvider);

    await controller.setDifficulty(PuzzleDifficulty.hard);
    await controller.setTaskCount(5);

    final saved = await repo.getPuzzleSettings();
    expect(saved.difficulty, PuzzleDifficulty.hard);
    expect(saved.taskCount, 5);
  });

  group('wake pool floor', () {
    test('dropping the puzzles with no game is refused', () async {
      final c = _container();
      await c
          .read(puzzleSettingsControllerProvider)
          .setPuzzlesIncluded(included: false);
      final saved = await c
          .read(capywakeRepositoryProvider)
          .getPuzzleSettings();
      expect(saved.includePuzzles, isTrue);
    });

    test('dropping the last game with puzzles excluded is refused', () async {
      final c = _container();
      final repo = c.read(capywakeRepositoryProvider);
      await repo.savePuzzleSettings(
        PuzzleSettings(
          enabledTypes: const {PuzzleType.arithmetic},
          enabledGames: const {'catch_the_capy'},
          includePuzzles: false,
        ),
      );
      await c
          .read(puzzleSettingsControllerProvider)
          .setGameEnabled('catch_the_capy', enabled: false);
      expect((await repo.getPuzzleSettings()).enabledGames, {'catch_the_capy'});
    });

    test('games add and drop while the puzzles stay in', () async {
      final c = _container();
      final controller = c.read(puzzleSettingsControllerProvider);
      await controller.setGameEnabled('memory_hideout', enabled: true);
      await controller.setGameEnabled('memory_hideout', enabled: false);
      final saved = await c
          .read(capywakeRepositoryProvider)
          .getPuzzleSettings();
      expect(saved.enabledGames, isEmpty);
    });
  });
}
