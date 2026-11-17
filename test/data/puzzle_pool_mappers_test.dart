import 'dart:convert';

import 'package:capywake/core/puzzle/alarm_puzzle_override.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/data/database/mappers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PuzzleSettingsMapper pool', () {
    test('round-trips a games-only pool', () {
      final settings = PuzzleSettings(
        enabledTypes: const {PuzzleType.arithmetic},
        enabledGames: const {'catch_the_capy', 'memory_hideout'},
        includePuzzles: false,
      );
      expect(
        PuzzleSettingsMapper.fromJson(PuzzleSettingsMapper.toJson(settings)),
        settings,
      );
    });

    test('a stored row from before games reads as puzzles only', () {
      final read = PuzzleSettingsMapper.fromJson(
        jsonEncode({
          'enabledTypes': ['arithmetic'],
        }),
      );
      expect(read.includePuzzles, isTrue);
      expect(read.enabledGames, isEmpty);
    });

    test('unknown game ids are dropped, not thrown on', () {
      final read = PuzzleSettingsMapper.fromJson(
        jsonEncode({
          'enabledTypes': ['arithmetic'],
          'enabledGames': ['retired_game', 'catch_the_capy', 7],
        }),
      );
      expect(read.enabledGames, {'catch_the_capy'});
    });

    test('a pool emptied by dropping restores the puzzles (H5)', () {
      final read = PuzzleSettingsMapper.fromJson(
        jsonEncode({
          'enabledTypes': ['arithmetic'],
          'enabledGames': ['retired_game'],
          'includePuzzles': false,
        }),
      );
      expect(read.enabledGames, isEmpty);
      expect(read.includePuzzles, isTrue);
    });
  });

  group('AlarmPuzzleOverrideMapper pool', () {
    test('round-trips a specific game only', () {
      final o = AlarmPuzzleOverride(
        enabledGames: const {'memory_hideout'},
        includePuzzles: false,
      );
      expect(
        AlarmPuzzleOverrideMapper.fromJson(AlarmPuzzleOverrideMapper.toJson(o)),
        o,
      );
    });

    test('an empty game list is a real choice, not "follow default"', () {
      final read = AlarmPuzzleOverrideMapper.fromJson(
        AlarmPuzzleOverrideMapper.toJson(
          AlarmPuzzleOverride(enabledGames: const {}),
        ),
      );
      expect(read.enabledGames, isNotNull);
      expect(read.enabledGames, isEmpty);
    });

    test('absent pool keys follow the default', () {
      final read = AlarmPuzzleOverrideMapper.fromJson(
        jsonEncode({'taskCount': 2}),
      );
      expect(read.enabledGames, isNull);
      expect(read.includePuzzles, isNull);
    });

    test('puzzles off with every game dropped falls back to default (H5)', () {
      final read = AlarmPuzzleOverrideMapper.fromJson(
        jsonEncode({
          'enabledGames': ['retired_game'],
          'includePuzzles': false,
        }),
      );
      expect(read.includePuzzles, isNull);
      expect(read.enabledGames, isEmpty);
    });

    test('puzzles off with no game key at all falls back to default', () {
      final read = AlarmPuzzleOverrideMapper.fromJson(
        jsonEncode({'includePuzzles': false}),
      );
      expect(read.includePuzzles, isNull);
    });

    test('a non-boolean includePuzzles is ignored', () {
      final read = AlarmPuzzleOverrideMapper.fromJson(
        jsonEncode({'includePuzzles': 'no'}),
      );
      expect(read.includePuzzles, isNull);
    });
  });
}
