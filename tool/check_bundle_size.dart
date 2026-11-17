// Bundled-asset budget gate.
//
//   dart run tool/check_bundle_size.dart
//
// Every bundled asset tree gets its own budget and its own line. Phase 02's
// self-review found the earlier art-only version reporting "83% of budget used"
// while the real asset payload had grown to 10 MB, because `assets/sounds/`
// (7.6 MB) was outside what it measured. A gate that is green for a reason
// unrelated to the risk reads as coverage, so each tree is now named.
//
// Budgets are measured, not guessed — and each art expectation below was
// written BEFORE encoding (Phase 01 pre-review finding M4), because "measure,
// then set the gate at measured + 20%" can never fail in the phase that sets it
// and would ratchet around a misconfigured encode.
//
// art — predicted from render box x 3 x format, 2026-11-16, before the first
// run:
//
//   4 scenes   1179x786 lossy q82   ~80 KB each   ~320 KB
//   4 tiles     360x360 lossy q82   ~18 KB each    ~72 KB
//   31 mascots  ~288px  lossy+alpha ~15 KB each   ~473 KB
//   1 wordmark  525px   lossless    ~25 KB         ~25 KB
//                                        predicted ~1812 KB
//
// Measured: 1818 KB across 40 files — 0.3% over the prediction, well inside
// the +-30% band that would have required an explanation. Budget = +20%.
//
// sounds — 12 generated tones, uncompressed 16-bit mono WAV. The format is
// deliberate and not a miss: MP3/AAC encoder padding clicks at every loop
// junction and `loopAudio` is on (see assets/sounds/LICENSES.md). Measured
// 7757 KB; the budget sits just above it so a re-encode or a thirteenth tone
// fails rather than drifts.
//
// fonts — two variable faces. Baloo 2 covers Latin + Turkish; Nunito carries
// Cyrillic (Phase 01 decided the per-script fallback on rendering tests).

import 'dart:io';

/// One bundled tree and the ceiling it may not cross.
const budgets = <String, int>{
  'assets/art': 2182,
  'assets/sounds': 7800,
  'assets/fonts': 1100,
};

void main(List<String> args) {
  final overrides = <String, int>{};
  for (var i = 0; i < args.length; i++) {
    // --max <kb> keeps working and applies to assets/art, the budget it has
    // always meant. --max-<tree> <kb> targets one tree by name.
    if (args[i] == '--max') {
      overrides['assets/art'] = int.parse(args[++i]);
      continue;
    }
    for (final root in budgets.keys) {
      final flag = '--max-${root.split('/').last}';
      if (args[i] == flag) overrides[root] = int.parse(args[++i]);
    }
  }

  var failed = false;
  var grandTotal = 0;
  var grandLimit = 0;

  for (final root in budgets.keys) {
    final limit = overrides[root] ?? budgets[root]!;
    grandLimit += limit;

    final dir = Directory(root);
    if (!dir.existsSync()) {
      stderr.writeln('FAIL: no $root directory.');
      failed = true;
      continue;
    }

    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => !f.path.endsWith('.gitkeep'))
        .where((f) => !f.path.endsWith('.md'))
        .toList();

    if (files.isEmpty) {
      stderr.writeln('FAIL: $root is empty.');
      failed = true;
      continue;
    }

    final byDir = <String, ({int count, int bytes})>{};
    var total = 0;
    for (final f in files) {
      final size = f.lengthSync();
      total += size;
      final group = f.parent.path == root
          ? '(root)'
          : f.parent.path.replaceFirst('$root/', '');
      final prev = byDir[group] ?? (count: 0, bytes: 0);
      byDir[group] = (count: prev.count + 1, bytes: prev.bytes + size);
    }
    grandTotal += total;

    stdout.writeln('\n$root');
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
      '  ${'TOTAL'.padRight(12)} ${files.length.toString().padLeft(3)} files  '
      '${kb.toStringAsFixed(0).padLeft(5)} KB of $limit KB budget'
      '  (${(100 * kb / limit).toStringAsFixed(0)}%)',
    );

    if (kb > limit) {
      stderr.writeln(
        'FAIL: $root is ${kb.toStringAsFixed(0)} KB, over its $limit KB '
        'budget by ${(kb - limit).toStringAsFixed(0)} KB.',
      );
      failed = true;
    }
  }

  final grandKb = grandTotal / 1024;
  // The note matters: sqlite3_flutter_libs carries prebuilt iOS/Android SQLite,
  // so this gate makes no claim about the shipped binary.
  stdout
    ..writeln(
      '\nALL BUNDLED ASSETS  ${grandKb.toStringAsFixed(0)} KB of '
      '$grandLimit KB (${(100 * grandKb / grandLimit).toStringAsFixed(0)}%)',
    )
    ..writeln(
      'Note: assets only. Native libraries and compiled code are not counted.',
    );

  if (failed) exit(1);
  stdout.writeln('OK: every bundled tree is inside its budget.');
}
