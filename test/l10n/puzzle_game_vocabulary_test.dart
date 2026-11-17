import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The word for "game" in each locale. Puzzles and games share one screen
/// now, so puzzle copy must not call a puzzle a game.
const _gameStems = <String, String>{
  'en': r'\bgames?\b',
  'de': 'spiel',
  'ru': 'игр',
  'es': 'jueg',
  'tr': 'oyun',
  'fr': r'\bjeux?\b',
  'it': 'gioc',
  'pt': r'\bjog',
  'ar': 'لعب|ألعاب',
  'ja': 'ゲーム',
};

final _placeholder = RegExp(r'\{\w+\}');

bool _isPuzzleKey(String key) =>
    key.startsWith('puzzle') ||
    key.startsWith('alarmPuzzle') ||
    key.startsWith('settingsPuzzle') ||
    key == 'alarmDismissMethodPuzzle' ||
    key == 'ringingSolvePuzzle' ||
    key == 'historyEscapedLabel' ||
    key == 'challengePuzzlesLabel';

void main() {
  for (final entry in _gameStems.entries) {
    test('${entry.key}: puzzle copy never says "game"', () {
      final arb =
          jsonDecode(File('lib/l10n/app_${entry.key}.arb').readAsStringSync())
              as Map<String, dynamic>;
      final stem = RegExp(entry.value, caseSensitive: false);
      final offenders = [
        for (final MapEntry(:key, :value) in arb.entries)
          if (!key.startsWith('@') &&
              _isPuzzleKey(key) &&
              value is String &&
              stem.hasMatch(value.replaceAll(_placeholder, '')))
            '$key: $value',
      ];
      expect(offenders, isEmpty);
    });
  }
}
