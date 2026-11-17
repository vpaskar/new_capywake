import 'package:capywake/core/alarm_draft.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:flutter_test/flutter_test.dart';

AlarmDraft _custom() =>
    AlarmDraft.create(
          id: 'a',
          settings: UserSettings.initial,
          now: DateTime.utc(2026, 11, 17),
        )
        .withDismissMethod(DismissMethod.puzzle)
        .withPuzzleCustomisation(
          enabled: true,
          defaults: PuzzleSettings.defaults(),
        );

void main() {
  test('without an override both pool edits are no-ops', () {
    final draft = AlarmDraft.create(
      id: 'a',
      settings: UserSettings.initial,
      now: DateTime.utc(2026, 11, 17),
    );
    expect(draft.withPuzzlesInPool(included: false), draft);
    expect(draft.withGameInPool('catch_the_capy', enabled: true), draft);
  });

  test('a specific game only: add it, then drop the puzzles', () {
    final draft = _custom()
        .withGameInPool('memory_hideout', enabled: true)
        .withPuzzlesInPool(included: false);
    final resolved = draft.resolvePuzzleSettings(PuzzleSettings.defaults());
    expect(resolved.enabledGames, {'memory_hideout'});
    expect(resolved.includePuzzles, isFalse);
  });

  test('a subset of games keeps the puzzles until told otherwise', () {
    final draft = _custom()
        .withGameInPool('catch_the_capy', enabled: true)
        .withGameInPool('memory_hideout', enabled: true);
    final resolved = draft.resolvePuzzleSettings(PuzzleSettings.defaults());
    expect(resolved.enabledGames, {'catch_the_capy', 'memory_hideout'});
    expect(resolved.includePuzzles, isTrue);
  });

  test('the puzzles cannot leave an empty pool', () {
    final draft = _custom();
    expect(draft.withPuzzlesInPool(included: false), draft);
  });

  test('the last game cannot leave an empty pool', () {
    final draft = _custom()
        .withGameInPool('catch_the_capy', enabled: true)
        .withPuzzlesInPool(included: false);
    expect(draft.withGameInPool('catch_the_capy', enabled: false), draft);
  });

  test('turning a game off again removes it', () {
    final draft = _custom()
        .withGameInPool('catch_the_capy', enabled: true)
        .withGameInPool('catch_the_capy', enabled: false);
    expect(draft.puzzleOverride!.enabledGames, isEmpty);
  });
}
