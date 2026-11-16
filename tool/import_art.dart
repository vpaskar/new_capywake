// Imports art from reference/02_ASSETS into assets/art, normalizing alpha and
// downscaling each file to 2x its largest on-screen render box.
//
//   dart run tool/import_art.dart
//
// Source of truth is reference/02_ASSETS, never ../capywake/assets, whose art
// was processed for the old vector-first design.

import 'dart:io';

import 'package:capywake/design/art.dart';
import 'package:capywake/design/art_audit.dart';
import 'package:image/image.dart' as img;

const _src = 'reference/02_ASSETS';
const _dst = 'assets/art';

/// The reference device (iPhone 14 Pro) renders at 3x.
const devicePixelRatio = 3;

class _Job {
  const _Job(this.from, this.to, this.renderBoxPt, {this.cutout = true});

  final String from;
  final String to;
  final double renderBoxPt;
  final bool cutout;

  int get targetWidth => (renderBoxPt * devicePixelRatio).ceil();
}

const _jobs = <_Job>[
  _Job(
    'header_scenes/today_integrated.png',
    'scenes/today.webp',
    393,
    cutout: false,
  ),
  _Job(
    'header_scenes/alarms_integrated.png',
    'scenes/alarms.webp',
    393,
    cutout: false,
  ),
  _Job(
    'header_scenes/history_integrated.png',
    'scenes/history.webp',
    393,
    cutout: false,
  ),
  _Job(
    'header_scenes/settings_integrated.png',
    'scenes/settings.webp',
    393,
    cutout: false,
  ),
  _Job(
    'game_tiles/step_quest.png',
    'tiles/step_quest.webp',
    120,
    cutout: false,
  ),
  _Job('game_tiles/shake_dj.png', 'tiles/shake_dj.webp', 120, cutout: false),
  _Job(
    'game_tiles/catch_the_capy.png',
    'tiles/catch_the_capy.webp',
    120,
    cutout: false,
  ),
  _Job(
    'game_tiles/find_the_impostor.png',
    'tiles/find_the_impostor.webp',
    120,
    cutout: false,
  ),
  _Job('wordmark.png', 'wordmark.webp', 175),
];

int _bytes = 0;
int _files = 0;
final _problems = <String>[];

Future<void> main() async {
  stdout.writeln('Importing art from $_src\n');

  for (final job in _jobs) {
    final input = File('$_src/${job.from}');
    if (!input.existsSync()) {
      _problems.add('MISSING  ${job.from}');
      continue;
    }
    final decoded = img.decodeImage(await input.readAsBytes());
    if (decoded == null) {
      _problems.add('UNREADABLE  ${job.from}');
      continue;
    }
    _process(decoded, job);
  }

  _sliceSheets();

  stdout.writeln(
    '\n$_files files, ${(_bytes / 1024).toStringAsFixed(0)} KB '
    '(${(_bytes / 1048576).toStringAsFixed(2)} MB)',
  );

  if (_problems.isEmpty) {
    stdout.writeln('No problems.');
    return;
  }
  stderr.writeln('\nProblems:');
  for (final p in _problems) {
    stderr.writeln('  $p');
  }
  exitCode = 1;
}

void _process(img.Image source, _Job job) {
  final before = auditImage(source);
  var image = source;

  if (before.hasAlpha) {
    image = normalizeAlpha(image);
    if (job.cutout) image = trimToInk(image);
  }

  if (image.width > job.targetWidth) {
    image = img.copyResize(
      image,
      width: job.targetWidth,
      interpolation: img.Interpolation.cubic,
    );
    // Resampling smears near-zero alpha back across the edge, so the band is
    // re-normalized after the downscale, not only before it.
    if (before.hasAlpha) image = normalizeAlpha(image);
  }

  final after = auditImage(image);
  if (after.hasAlpha && after.ghostPixels > 0) {
    _problems.add(
      'GHOSTS REMAIN  ${job.to} (${after.ghostPixels} px after re-normalize)',
    );
  }
  if (job.cutout && after.hasAlpha && after.edgeContactPixels > 20) {
    _problems.add(
      'SEVERED CROP?  ${job.to} (${after.edgeContactPixels} edge px)',
    );
  }
  if (image.width < (job.renderBoxPt * 3).ceil()) {
    _problems.add(
      'UNDER-RESOLVED ${job.to} '
      '(${image.width}px < ${(job.renderBoxPt * 3).ceil()}px needed at 3x)',
    );
  }

  _write('$_dst/${job.to}', image, lossless: job.cutout);
}

void _sliceSheets() {
  const sheets = {
    'sticker_sheets/cozy_capybara_sticker_collection.png': 'collection',
    'sticker_sheets/capybara_cozy_moments_sticker_sheet.png': 'moments',
  };

  for (final entry in sheets.entries) {
    final file = File('$_src/${entry.key}');
    if (!file.existsSync()) {
      _problems.add('MISSING  ${entry.key}');
      continue;
    }
    final sheet = img.decodeImage(file.readAsBytesSync());
    if (sheet == null) {
      _problems.add('UNREADABLE  ${entry.key}');
      continue;
    }

    normalizeAlpha(sheet);
    final cells = [
      for (final c in sliceSheet(sheet, minBandSize: 8))
        ...splitWideCell(sheet, c),
    ];
    stdout.writeln('  ${entry.key}: ${cells.length} poses');

    final target = (ArtUse.mascotLarge.renderBoxPt * devicePixelRatio).ceil();
    for (var i = 0; i < cells.length; i++) {
      final r = cells[i];
      var cell = img.copyCrop(
        sheet,
        x: r.left,
        y: r.top,
        width: r.width,
        height: r.height,
      );
      if (cell.width > target) {
        cell = img.copyResize(
          cell,
          width: target,
          interpolation: img.Interpolation.cubic,
        );
        normalizeAlpha(cell);
      }
      final name = '${entry.value}_${i.toString().padLeft(2, '0')}';
      _write('$_dst/mascots/$name.webp', cell, lossless: true);
    }
  }
}

void _write(String path, img.Image image, {required bool lossless}) {
  final out = File(path)..parent.createSync(recursive: true);
  final tmp = File('${out.path}.tmp.png')
    ..writeAsBytesSync(img.encodePng(image));

  // cwebp rather than the `image` package: it has no lossy WebP encoder, and
  // the photographic scenes are most of the budget.
  final args = lossless
      ? ['-lossless', '-z', '9', '-quiet', tmp.path, '-o', out.path]
      : ['-q', '82', '-quiet', tmp.path, '-o', out.path];
  final r = Process.runSync('cwebp', args);
  tmp.deleteSync();

  if (r.exitCode != 0) {
    _problems.add('ENCODE FAILED  $path: ${r.stderr}');
    return;
  }

  final size = out.lengthSync();
  _bytes += size;
  _files++;
  stdout.writeln(
    '  ${path.padRight(46)} ${image.width}x${image.height} '
    '${(size / 1024).toStringAsFixed(0)}KB',
  );
}
