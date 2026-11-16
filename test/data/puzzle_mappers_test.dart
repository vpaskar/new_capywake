import 'dart:convert';

import 'package:capywake/core/puzzle/alarm_puzzle_override.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/data/database/mappers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PuzzleSettingsMapper', () {
    test('round-trips every field', () {
      final settings = PuzzleSettings(
        enabledTypes: const {
          PuzzleType.arithmetic,
          PuzzleType.gridPatternRecall,
          PuzzleType.shapeRotation,
        },
        taskCount: 4,
        difficulty: PuzzleDifficulty.hard,
        toleratedWrongAnswers: 7,
        escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
      );
      final decoded = PuzzleSettingsMapper.fromJson(
        PuzzleSettingsMapper.toJson(settings),
      );
      expect(decoded, settings);
      expect(decoded.enabledTypes, settings.enabledTypes);
      expect(decoded.taskCount, 4);
      expect(decoded.difficulty, PuzzleDifficulty.hard);
      expect(decoded.toleratedWrongAnswers, 7);
      expect(
        decoded.escapeStrictness,
        PuzzleEscapeStrictness.confirmAndHold,
      );
    });

    test('round-trips the shipped defaults', () {
      final defaults = PuzzleSettings.defaults();
      expect(
        PuzzleSettingsMapper.fromJson(PuzzleSettingsMapper.toJson(defaults)),
        defaults,
      );
    });

    test('falls back to the defaults for missing keys', () {
      final decoded = PuzzleSettingsMapper.fromJson('{}');
      expect(decoded, PuzzleSettings.defaults());
    });

    test('drops type names this build does not recognise', () {
      final decoded = PuzzleSettingsMapper.fromJson(
        jsonEncode({
          'enabledTypes': ['arithmetic', 'somethingRetiredInV9'],
        }),
      );
      expect(decoded.enabledTypes, {PuzzleType.arithmetic});
    });

    test('falls back rather than throwing when no type survives', () {
      // The alternative is an exception on the path that decides how an
      // alarm behaves at 03:00 — `PuzzleSettings` rightly refuses an empty
      // set, so the mapper must never hand it one.
      final decoded = PuzzleSettingsMapper.fromJson(
        jsonEncode({
          'enabledTypes': ['somethingRetiredInV9'],
        }),
      );
      expect(decoded.enabledTypes, PuzzleSettings.defaults().enabledTypes);
    });

    test('falls back for an empty, wrongly-typed, or absent type list', () {
      for (final raw in <Object?>[
        <String>[],
        'arithmetic',
        null,
      ]) {
        final decoded = PuzzleSettingsMapper.fromJson(
          jsonEncode({'enabledTypes': raw}),
        );
        expect(decoded.enabledTypes, PuzzleSettings.defaults().enabledTypes);
      }
    });

    test('falls back for out-of-range and wrongly-typed numbers', () {
      final defaults = PuzzleSettings.defaults();
      for (final raw in <Object?>[
        PuzzleSettings.minTaskCount - 1,
        PuzzleSettings.maxTaskCount + 1,
        'three',
        null,
      ]) {
        final decoded = PuzzleSettingsMapper.fromJson(
          jsonEncode({'taskCount': raw}),
        );
        expect(decoded.taskCount, defaults.taskCount);
      }
      for (final raw in <Object?>[
        PuzzleSettings.minToleratedWrongAnswers - 1,
        PuzzleSettings.maxToleratedWrongAnswers + 1,
        false,
      ]) {
        final decoded = PuzzleSettingsMapper.fromJson(
          jsonEncode({'toleratedWrongAnswers': raw}),
        );
        expect(decoded.toleratedWrongAnswers, defaults.toleratedWrongAnswers);
      }
    });

    test('keeps in-range bounds exactly', () {
      final decoded = PuzzleSettingsMapper.fromJson(
        jsonEncode({
          'taskCount': PuzzleSettings.maxTaskCount,
          'toleratedWrongAnswers': PuzzleSettings.minToleratedWrongAnswers,
        }),
      );
      expect(decoded.taskCount, PuzzleSettings.maxTaskCount);
      expect(
        decoded.toleratedWrongAnswers,
        PuzzleSettings.minToleratedWrongAnswers,
      );
    });

    test('falls back for unknown enum values', () {
      final decoded = PuzzleSettingsMapper.fromJson(
        jsonEncode({
          'difficulty': 'impossible',
          'escapeStrictness': 'never',
        }),
      );
      final defaults = PuzzleSettings.defaults();
      expect(decoded.difficulty, defaults.difficulty);
      expect(decoded.escapeStrictness, defaults.escapeStrictness);
      // Crucially, there is no stored value that removes the escape.
      expect(
        PuzzleEscapeStrictness.values,
        contains(decoded.escapeStrictness),
      );
    });
  });

  group('AlarmPuzzleOverrideMapper', () {
    test('round-trips a fully-populated override', () {
      final override = AlarmPuzzleOverride(
        enabledTypes: const {PuzzleType.digitRecall, PuzzleType.spotTheChange},
        taskCount: 3,
        toleratedWrongAnswers: 0,
        escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
      );
      expect(
        AlarmPuzzleOverrideMapper.fromJson(
          AlarmPuzzleOverrideMapper.toJson(override),
        ),
        override,
      );
    });

    test('writes only the overridden fields', () {
      final json = AlarmPuzzleOverrideMapper.toJson(
        AlarmPuzzleOverride(taskCount: 2),
      );
      final map = jsonDecode(json) as Map<String, dynamic>;
      expect(map.keys, ['taskCount']);
    });

    test('an absent key round-trips as "follows the default"', () {
      final override = AlarmPuzzleOverride(taskCount: 2);
      final decoded = AlarmPuzzleOverrideMapper.fromJson(
        AlarmPuzzleOverrideMapper.toJson(override),
      );
      expect(decoded.taskCount, 2);
      expect(decoded.enabledTypes, isNull);
      expect(decoded.toleratedWrongAnswers, isNull);
      expect(decoded.escapeStrictness, isNull);
    });

    test('an empty object decodes to the empty override', () {
      final decoded = AlarmPuzzleOverrideMapper.fromJson('{}');
      expect(decoded.isEmpty, isTrue);
    });

    test('an unusable stored value reads as "not overridden"', () {
      // Out of range, wrong type, and unknown enum names all mean the same
      // thing: this did not come from the UI, so do not invent an intent.
      final decoded = AlarmPuzzleOverrideMapper.fromJson(
        jsonEncode({
          'enabledTypes': ['somethingRetiredInV9'],
          'taskCount': 99,
          'toleratedWrongAnswers': -4,
          'escapeStrictness': 'off',
        }),
      );
      expect(decoded.isEmpty, isTrue);
    });

    test('keeps the recognised half of a partly-unknown type list', () {
      final decoded = AlarmPuzzleOverrideMapper.fromJson(
        jsonEncode({
          'enabledTypes': ['sequenceNext', 'somethingRetiredInV9'],
        }),
      );
      expect(decoded.enabledTypes, {PuzzleType.sequenceNext});
    });
  });
}
