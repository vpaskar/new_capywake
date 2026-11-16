// Coverage gate. Parses `coverage/lcov.info` and fails (exit 1) if total line
// coverage is below the threshold. Run as part of every phase's validation:
//
//   flutter test --coverage
//   dart run tool/check_coverage.dart            # gate whole-project at 85%
//   dart run tool/check_coverage.dart --min 95 --path lib/core   # core at 95%
//
// Flags:
//   --min <int>     Minimum percentage required (default 85).
//   --path <glob>   Only count files whose source path contains this substring
//                   (repeatable). When omitted, counts everything in lcov.
//   --lcov <file>   Path to the lcov file (default coverage/lcov.info).
//
// Generated files are excluded by default: *.g.dart and lib/l10n/generated/**.
// They are machine-generated and would dilute the signal from hand-written
// code.

import 'dart:io';

void main(List<String> args) {
  var minPercent = 85.0;
  var lcovPath = 'coverage/lcov.info';
  final pathFilters = <String>[];

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--min':
        minPercent = double.parse(args[++i]);
      case '--lcov':
        lcovPath = args[++i];
      case '--path':
        pathFilters.add(args[++i]);
      default:
        stderr.writeln('Unknown argument: ${args[i]}');
        exit(2);
    }
  }

  final file = File(lcovPath);
  if (!file.existsSync()) {
    stderr.writeln(
      'Coverage file not found: $lcovPath\n'
      'Run `flutter test --coverage` first.',
    );
    exit(2);
  }

  var totalFound = 0;
  var totalHit = 0;
  var currentPath = '';
  var include = true;
  final perFile = <String, ({int found, int hit})>{};

  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      currentPath = line.substring(3);
      final isGenerated =
          currentPath.endsWith('.g.dart') ||
          currentPath.contains('lib/l10n/generated/');
      final matchesFilter =
          pathFilters.isEmpty ||
          pathFilters.any((f) => currentPath.contains(f));
      include = !isGenerated && matchesFilter;
    } else if (line.startsWith('DA:') && include) {
      // DA:<lineNo>,<hitCount>
      final parts = line.substring(3).split(',');
      final hits = int.parse(parts[1]);
      totalFound++;
      if (hits > 0) totalHit++;
      final existing = perFile[currentPath] ?? (found: 0, hit: 0);
      perFile[currentPath] = (
        found: existing.found + 1,
        hit: existing.hit + (hits > 0 ? 1 : 0),
      );
    }
  }

  if (totalFound == 0) {
    stderr.writeln(
      'No coverage data matched '
      '${pathFilters.isEmpty ? "(whole project)" : pathFilters.join(", ")}.',
    );
    exit(2);
  }

  final percent = totalHit / totalFound * 100;
  final scope = pathFilters.isEmpty ? 'project' : pathFilters.join(', ');
  stdout.writeln(
    'Coverage ($scope): '
    '${percent.toStringAsFixed(2)}% '
    '($totalHit/$totalFound lines) — gate ${minPercent.toStringAsFixed(0)}%',
  );

  if (percent + 1e-9 < minPercent) {
    // List the weakest files to make the gap actionable.
    final ranked = perFile.entries.where((e) => e.value.found > 0).toList()
      ..sort((a, b) {
        final pa = a.value.hit / a.value.found;
        final pb = b.value.hit / b.value.found;
        return pa.compareTo(pb);
      });
    stderr.writeln(
      'FAIL: below ${minPercent.toStringAsFixed(0)}%. Weakest files:',
    );
    for (final e in ranked.take(10)) {
      final p = e.value.hit / e.value.found * 100;
      stderr.writeln(
        '  ${p.toStringAsFixed(0).padLeft(3)}%  '
        '${e.value.hit}/${e.value.found}  ${e.key}',
      );
    }
    exit(1);
  }

  stdout.writeln('PASS');
}
