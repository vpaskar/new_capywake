// Art budget gate.
//
//   dart run tool/check_bundle_size.dart
//
// The budget is measured, not guessed — but the expectation was written BEFORE
// encoding (pre-review finding M4), because "measure, then set the gate at
// measured + 20%" can never fail in the phase that sets it and would ratchet
// around a misconfigured encode.
//
// Predicted from render box x 3 x format, 2026-11-16, before the first run:
//
//   4 scenes   1179x786 lossy q82   ~80 KB each   ~320 KB
//   4 tiles     360x360 lossy q82   ~18 KB each    ~72 KB
//   31 mascots  ~288px  lossless    ~45 KB each  ~1395 KB
//   1 wordmark  525px   lossless    ~25 KB         ~25 KB
//                                        predicted ~1812 KB
//
// Measured: 1818 KB across 40 files — 0.3% over the prediction, well inside
// the +-30% band that would have required an explanation.
//
// Budget = measured + 20% headroom.

import 'dart:io';

const budgetKb = 2182;
const artRoot = 'assets/art';

void main(List<String> args) {
  var limit = budgetKb;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--max') limit = int.parse(args[++i]);
  }

  final dir = Directory(artRoot);
  if (!dir.existsSync()) {
    stderr.writeln('No $artRoot directory. Run tool/import_art.dart first.');
    exit(2);
  }

  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => !f.path.endsWith('.gitkeep'))
      .toList();

  if (files.isEmpty) {
    stderr.writeln('$artRoot is empty. Run tool/import_art.dart first.');
    exit(2);
  }

  final byDir = <String, ({int count, int bytes})>{};
  var total = 0;
  for (final f in files) {
    final size = f.lengthSync();
    total += size;
    final group = f.parent.path.replaceFirst('$artRoot/', '');
    final prev = byDir[group] ?? (count: 0, bytes: 0);
    byDir[group] = (count: prev.count + 1, bytes: prev.bytes + size);
  }

  final groups = byDir.keys.toList()..sort();
  for (final g in groups) {
    final v = byDir[g]!;
    stdout.writeln(
      '  ${g.padRight(12)} ${v.count.toString().padLeft(3)} files  '
      '${(v.bytes / 1024).toStringAsFixed(0).padLeft(5)} KB',
    );
  }

  final kb = total / 1024;
  stdout.writeln(
    '\n  ${'TOTAL'.padRight(12)} ${files.length.toString().padLeft(3)} files  '
    '${kb.toStringAsFixed(0).padLeft(5)} KB of $limit KB budget',
  );

  if (kb > limit) {
    stderr.writeln(
      '\nFAIL: art bundle is ${kb.toStringAsFixed(0)} KB, over the '
      '$limit KB budget by ${(kb - limit).toStringAsFixed(0)} KB.',
    );
    exit(1);
  }
  stdout.writeln(
    'OK: ${(100 * kb / limit).toStringAsFixed(0)}% of budget used.',
  );
}
