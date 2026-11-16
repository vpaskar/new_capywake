import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/trim_comments.dart';

/// Enforces `CLAUDE.md`'s "the code explains itself" rule: Protio's trimmer,
/// Gastrowerk's ratchet. Rationale in `docs/phases/PHASE_03_PLAN.md`.
void main() {
  group('comment budget', () {
    test('no file exceeds its recorded comment baseline', () {
      final baselineFile = File(_baselinePath);
      final baseline = baselineFile.existsSync()
          ? (jsonDecode(baselineFile.readAsStringSync())
                    as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, v as int))
          : <String, int>{};

      final measured = _measure();

      final grown = <String>[];
      final newOffenders = <String>[];
      final improved = <String>[];

      for (final entry in measured.entries) {
        final allowed = baseline[entry.key];
        if (allowed == null) {
          newOffenders.add('  ${entry.value} excess chars  ${entry.key}');
        } else if (entry.value > allowed) {
          grown.add(
            '  ${entry.key}: $allowed -> ${entry.value} excess chars',
          );
        }
      }

      for (final entry in baseline.entries) {
        final now = measured[entry.key] ?? 0;
        if (now < entry.value) {
          improved.add('  ${entry.key}: ${entry.value} -> $now');
        }
      }

      expect(
        newOffenders,
        isEmpty,
        reason:
            'A new or newly-commented file is over budget ($maxBlockLines '
            'lines / $maxBlockChars chars per block). Comments are for a fact '
            'the code cannot express; try deleting the comment by renaming '
            'first. Run:\n\n'
            '  dart run tool/trim_comments.dart --fix\n\n'
            'then re-read each trimmed spot — the trimmer keeps whole '
            'sentences but the result may now read as half a thought.\n\n'
            '${newOffenders.join('\n')}',
      );

      expect(
        grown,
        isEmpty,
        reason:
            'These files carried inherited prose and have grown. The baseline '
            'may only shrink.\n\n${grown.join('\n')}',
      );

      expect(
        improved,
        isEmpty,
        reason:
            'These files improved — tighten the baseline so the gain cannot '
            'be given back:\n\n'
            '  dart run tool/trim_comments.dart --update-baseline\n\n'
            '${improved.join('\n')}',
      );
    });

    test('the baseline only lists files that still exist', () {
      final baselineFile = File(_baselinePath);
      if (!baselineFile.existsSync()) return;

      final baseline =
          jsonDecode(baselineFile.readAsStringSync()) as Map<String, dynamic>;
      final missing = baseline.keys.where((p) => !File(p).existsSync());

      expect(
        missing,
        isEmpty,
        reason:
            'The baseline names files that are gone. Refresh it:\n'
            '  dart run tool/trim_comments.dart --update-baseline',
      );
    });
  });
}

const _baselinePath = 'test/style/comment_budget_baseline.json';

Map<String, int> _measure() {
  final out = <String, int>{};
  for (final dir in ['lib', 'test', 'tool']) {
    final root = Directory(dir);
    if (!root.existsSync()) continue;

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (skipPath(entity.path)) continue;

      final result = trimSource(entity.readAsLinesSync());
      if (result.trimmed > 0) out[entity.path] = result.trimmed;
    }
  }
  return out;
}
