// Imports art from reference/02_ASSETS into assets/art, normalizing alpha and
// downscaling each file to 2x its largest on-screen render box.
//
//   dart run tool/import_art.dart
//
// Source of truth is reference/02_ASSETS, never ../capywake/assets, whose art
// was processed for the old vector-first design.

import 'dart:io';
import 'dart:math' as math;

import 'package:capywake/design/art.dart';
import 'package:capywake/design/art_audit.dart';
import 'package:image/image.dart' as img;

const _src = 'reference/02_ASSETS';
const _dst = 'assets/art';

/// The reference device (iPhone 14 Pro) renders at 3x.
const devicePixelRatio = 3;

class _Job {
  const _Job(
    this.from,
    this.to,
    this.renderBoxPt, {
    this.cutout = true,
    this.inset = 0,
    this.margin = 0,
    this.knownShort = false,
    this.lossyColour = false,
  });

  final String from;
  final String to;
  final double renderBoxPt;
  final bool cutout;

  /// Pixels cut from every side first: a supplied frame the app draws itself.
  final int inset;

  /// Transparent padding, so a flat base is not read as a severed crop.
  final int margin;

  /// Supplied under-resolution, recorded in `art_manifest_test.dart`.
  final bool knownShort;

  /// A cutout written with lossy colour and lossless alpha, to save budget.
  final bool lossyColour;

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
  _Job('game_art/plain_bush.png', 'games/plain_bush.webp', 96, margin: 2),
  _Job(
    'game_art/meadow_background.png',
    'games/meadow.webp',
    360,
    cutout: false,
  ),
  // Supplied with a baked frame on black corners; cut inside it.
  _Job(
    'game_art/memory_hideout_tile.png',
    'tiles/memory_hideout.webp',
    120,
    cutout: false,
    inset: 64,
  ),
  _Job('game_tiles/tilt_maze.png', 'tiles/tilt_maze.webp', 120, cutout: false),
  _Job(
    'game_tiles/capy_rocket.png',
    'tiles/capy_rocket.webp',
    120,
    cutout: false,
  ),
  // Enlarged from a sheet with a rounded frame on white; cut inside it.
  _Job(
    'game_tiles/morning_sort.png',
    'tiles/morning_sort.webp',
    120,
    cutout: false,
    inset: 72,
  ),
  _Job(
    'game_tiles/rhythm_rescue.png',
    'tiles/rhythm_rescue.webp',
    120,
    cutout: false,
    inset: 72,
  ),
  _Job(
    'game_tiles/qr_treasure_hunt.png',
    'tiles/qr_treasure_hunt.webp',
    120,
    cutout: false,
    inset: 80,
  ),
  // Edge-to-edge bands: meant to touch the sides, so not trimmed as cutouts.
  _Job(
    'decor/meadow_footer.png',
    'decor/meadow_footer.webp',
    393,
    cutout: false,
  ),
  _Job(
    'decor/cloud_edge_cream.png',
    'decor/cloud_edge.webp',
    393,
    cutout: false,
    inset: 1,
    knownShort: true,
  ),
  _Job(
    'alarm_thumbnails/sleeping.png',
    'thumbnails/sleeping.webp',
    124,
    cutout: false,
    inset: 20,
    knownShort: true,
  ),
  _Job(
    'alarm_thumbnails/workout.png',
    'thumbnails/workout.webp',
    124,
    cutout: false,
    inset: 20,
    knownShort: true,
  ),
  _Job(
    'alarm_thumbnails/backpack_walk.png',
    'thumbnails/walk.webp',
    124,
    cutout: false,
    inset: 20,
    knownShort: true,
  ),
  _Job(
    'alarm_thumbnails/headphones.png',
    'thumbnails/music.webp',
    124,
    cutout: false,
    inset: 20,
    knownShort: true,
  ),
  _Job(
    'themes/system.png',
    'themes/system.webp',
    57,
    cutout: false,
    inset: 13,
    knownShort: true,
  ),
  // A 3:2 scene covering a 1.27:1 tile is scaled to its height, 44.8 x 1.5 pt.
  _Job('themes/morning_sunrise.png', 'themes/light.webp', 68, cutout: false),
  _Job('themes/night_sky.png', 'themes/dark.webp', 68, cutout: false),
  _Job(
    'onboarding/welcome_scene.png',
    'scenes/welcome.webp',
    393,
    cutout: false,
  ),
  _Job(
    'header_scenes/puzzle_hero.png',
    'scenes/puzzle_hero.webp',
    240,
    cutout: false,
  ),
  ..._puzzleIconJobs,
  ..._winPoseJobs,
];

/// Per-game win poses. `09_capy_step_quest.png` is cut through the nightcap
/// at the cell's top edge in the source sheet too, so it is not imported.
const _winPoseJobs = <_Job>[
  _Job(
    'animations/07_game_celebrations/poses/01_catch_the_capy.png',
    'animations/pose_catch_the_capy.webp',
    100,
    lossyColour: true,
  ),
  _Job(
    'animations/07_game_celebrations/poses/02_memory_hideout.png',
    'animations/pose_memory_hideout.webp',
    100,
    lossyColour: true,
  ),
  _Job(
    'animations/07_game_celebrations/poses/03_rhythm_rescue.png',
    'animations/pose_rhythm_rescue.webp',
    100,
    lossyColour: true,
  ),
  _Job(
    'animations/07_game_celebrations/poses/04_capy_rocket.png',
    'animations/pose_capy_rocket.webp',
    100,
    lossyColour: true,
  ),
  _Job(
    'animations/07_game_celebrations/poses/05_morning_sort.png',
    'animations/pose_morning_sort.webp',
    100,
    lossyColour: true,
  ),
  _Job(
    'animations/07_game_celebrations/poses/06_find_the_impostor.png',
    'animations/pose_find_the_impostor.webp',
    100,
    lossyColour: true,
  ),
  _Job(
    'animations/07_game_celebrations/poses/07_shake_dj.png',
    'animations/pose_shake_dj.webp',
    100,
    lossyColour: true,
  ),
  _Job(
    'animations/07_game_celebrations/poses/08_tilt_maze.png',
    'animations/pose_tilt_maze.webp',
    100,
    lossyColour: true,
  ),
  _Job(
    'animations/07_game_celebrations/poses/10_qr_treasure_hunt.png',
    'animations/pose_qr_treasure_hunt.webp',
    100,
    lossyColour: true,
  ),
];

/// Four supplied file names are shifted against their drawings; each icon is
/// matched by what it shows (`asset_gaps.md` G21).
const _puzzleIconJobs = <_Job>[
  _Job(
    'puzzle_icons/arithmetic.png',
    'icons/puzzle_arithmetic.webp',
    32,
    cutout: false,
    inset: 14,
  ),
  _Job(
    'puzzle_icons/number_sequences.png',
    'icons/puzzle_sequence_next.webp',
    32,
    cutout: false,
    inset: 14,
  ),
  _Job(
    'puzzle_icons/missing_sign.png',
    'icons/puzzle_missing_operator.webp',
    32,
    cutout: false,
    inset: 14,
  ),
  _Job(
    'puzzle_icons/compare_numbers.png',
    'icons/puzzle_compare_values.webp',
    32,
    cutout: false,
    inset: 14,
  ),
  _Job(
    'puzzle_icons/odd_one_out.png',
    'icons/puzzle_odd_one_out.webp',
    32,
    cutout: false,
    inset: 14,
  ),
  _Job(
    'puzzle_icons/digits_backwards.png',
    'icons/puzzle_digit_recall.webp',
    32,
    cutout: false,
    inset: 14,
  ),
  _Job(
    'puzzle_icons/grid_patterns.png',
    'icons/puzzle_digit_recall_reversed.webp',
    32,
    cutout: false,
    inset: 14,
  ),
  _Job(
    'puzzle_icons/spot_the_change.png',
    'icons/puzzle_grid_pattern.webp',
    32,
    cutout: false,
    inset: 14,
  ),
  _Job(
    'puzzle_icons/remember_digits.png',
    'icons/puzzle_spot_the_change.webp',
    32,
    cutout: false,
    inset: 14,
  ),
  _Job(
    'puzzle_icons/rotated_shapes.png',
    'icons/puzzle_shape_rotation.webp',
    32,
    cutout: false,
    inset: 14,
  ),
];

int _bytes = 0;
int _files = 0;
final _problems = <String>[];
final _notes = <String>[];

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
  _sliceFrameSheets();
  _importFrameFolders();

  stdout.writeln(
    '\n$_files files, ${(_bytes / 1024).toStringAsFixed(0)} KB '
    '(${(_bytes / 1048576).toStringAsFixed(2)} MB)',
  );

  for (final n in _notes) {
    stdout.writeln('Known: $n');
  }
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
  var image = job.inset == 0
      ? source
      : img.copyCrop(
          source,
          x: job.inset,
          y: job.inset,
          width: source.width - 2 * job.inset,
          height: source.height - 2 * job.inset,
        );
  final before = auditImage(image);

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

  if (job.margin > 0) {
    final padded = img.Image(
      width: image.width + 2 * job.margin,
      height: image.height + 2 * job.margin,
      numChannels: 4,
    );
    image = img.compositeImage(
      padded,
      image,
      dstX: job.margin,
      dstY: job.margin,
    );
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
    (job.knownShort ? _notes : _problems).add(
      'UNDER-RESOLVED ${job.to} '
      '(${image.width}px < ${(job.renderBoxPt * 3).ceil()}px needed at 3x)',
    );
  }

  _write(
    '$_dst/${job.to}',
    image,
    lossless: job.cutout && !job.lossyColour,
    quality: job.lossyColour ? 90 : 82,
  );
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
      _write('$_dst/mascots/$name.webp', cell, lossless: false, quality: 90);
    }
  }
}

/// A grid sprite sheet cut into frames on one canvas, aligned right (the
/// nose) and bottom (the foot baseline) so playback does not jitter.
class _FrameSheet {
  const _FrameSheet(
    this.from,
    this.toPrefix,
    this.columns,
    this.rows,
    this.renderBoxPt, {
    this.take,
  });

  final String from;
  final String toPrefix;
  final int columns;
  final int rows;
  final double renderBoxPt;

  /// Only these cells, in order; all cells when null.
  final List<int>? take;
}

const _frameSheets = <_FrameSheet>[
  _FrameSheet('game_art/run_cycle_sprite_sheet.png', 'games/run', 4, 2, 96),
  _FrameSheet('game_art/dust_puff_sprite_sheet.png', 'games/dust', 2, 2, 48),
  _FrameSheet(
    'game_art/paw_footprints.png',
    'games/paw',
    2,
    1,
    24,
    take: [0],
  ),
];

/// Faint specks below this alpha do not widen a frame's bounds.
const _frameInkAlpha = 100;

void _sliceFrameSheets() {
  for (final sheet in _frameSheets) {
    final file = File('$_src/${sheet.from}');
    if (!file.existsSync()) {
      _problems.add('MISSING  ${sheet.from}');
      continue;
    }
    final source = img.decodeImage(file.readAsBytesSync());
    if (source == null) {
      _problems.add('UNREADABLE  ${sheet.from}');
      continue;
    }
    normalizeAlpha(source);

    final cellW = source.width ~/ sheet.columns;
    final cellH = source.height ~/ sheet.rows;
    final cells =
        sheet.take ?? List.generate(sheet.columns * sheet.rows, (i) => i);
    final inks = <img.Image>[];
    for (final i in cells) {
      final cell = img.copyCrop(
        source,
        x: (i % sheet.columns) * cellW,
        y: (i ~/ sheet.columns) * cellH,
        width: cellW,
        height: cellH,
      );
      final bounds = _inkBounds(cell);
      if (bounds == null) {
        _problems.add('EMPTY FRAME  ${sheet.from} cell $i');
        continue;
      }
      inks.add(
        img.copyCrop(
          cell,
          x: bounds.left,
          y: bounds.top,
          width: bounds.width,
          height: bounds.height,
        ),
      );
    }

    final canvasW = inks.map((f) => f.width).reduce(math.max);
    final canvasH = inks.map((f) => f.height).reduce(math.max);
    final target = (sheet.renderBoxPt * devicePixelRatio).ceil();
    if (canvasW < target) {
      _problems.add(
        'UNDER-RESOLVED ${sheet.toPrefix} (${canvasW}px < ${target}px)',
      );
    }
    for (var i = 0; i < inks.length; i++) {
      var frame = img.Image(width: canvasW, height: canvasH, numChannels: 4);
      img.compositeImage(
        frame,
        inks[i],
        dstX: canvasW - inks[i].width,
        dstY: canvasH - inks[i].height,
      );
      if (frame.width > target) {
        frame = img.copyResize(
          frame,
          width: target,
          interpolation: img.Interpolation.cubic,
        );
      }
      normalizeAlpha(frame);
      final after = auditImage(frame);
      if (after.ghostPixels > 0) {
        _problems.add('GHOSTS REMAIN  ${sheet.toPrefix} frame $i');
      }
      final name = inks.length == 1
          ? '${sheet.toPrefix}.webp'
          : '${sheet.toPrefix}_${i.toString().padLeft(2, "0")}.webp';
      // Lossy colour, lossless alpha: a quarter of the size, exact edges.
      _write('$_dst/$name', frame, lossless: false, quality: 90);
    }
  }
}

/// Frames supplied one file each, already on a shared canvas.
const _frameFolders = {
  'animations/06_win_celebration/frames': 'animations/win',
};

void _importFrameFolders() {
  for (final entry in _frameFolders.entries) {
    final dir = Directory('$_src/${entry.key}');
    if (!dir.existsSync()) {
      _problems.add('MISSING  ${entry.key}');
      continue;
    }
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.png'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final frames = [
      for (final f in files)
        normalizeAlpha(img.decodeImage(f.readAsBytesSync())!),
    ];
    final size = (frames.first.width, frames.first.height);
    final baselines = {for (final f in frames) _inkBounds(f)?.bottom};
    if (frames.any((f) => (f.width, f.height) != size)) {
      _problems.add('MIXED CANVAS  ${entry.key}');
    }
    if (baselines.length != 1) {
      _problems.add('BASELINE DRIFT  ${entry.key} $baselines');
    }
    final target = (ArtUse.animation.renderBoxPt * devicePixelRatio).ceil();
    if (size.$1 < target) {
      _problems.add(
        'UNDER-RESOLVED ${entry.value} (${size.$1}px < ${target}px)',
      );
    }
    for (var i = 0; i < frames.length; i++) {
      var frame = frames[i];
      if (frame.width > target) {
        frame = normalizeAlpha(
          img.copyResize(
            frame,
            width: target,
            interpolation: img.Interpolation.cubic,
          ),
        );
      }
      if (auditImage(frame).ghostPixels > 0) {
        _problems.add('GHOSTS REMAIN  ${entry.value} frame $i');
      }
      final name = '${entry.value}_${i.toString().padLeft(2, "0")}.webp';
      _write('$_dst/$name', frame, lossless: false, quality: 90);
    }
  }
}

ArtRect? _inkBounds(img.Image image) {
  int? minX;
  int? minY;
  int? maxX;
  int? maxY;
  for (final p in image) {
    if (p.a < _frameInkAlpha) continue;
    minX = minX == null || p.x < minX ? p.x : minX;
    maxX = maxX == null || p.x > maxX ? p.x : maxX;
    minY = minY == null || p.y < minY ? p.y : minY;
    maxY = maxY == null || p.y > maxY ? p.y : maxY;
  }
  return minX == null ? null : ArtRect(minX, minY!, maxX!, maxY!);
}

void _write(
  String path,
  img.Image image, {
  required bool lossless,
  int quality = 82,
}) {
  final out = File(path)..parent.createSync(recursive: true);
  final tmp = File('${out.path}.tmp.png')
    ..writeAsBytesSync(img.encodePng(image));

  // cwebp rather than the `image` package: it has no lossy WebP encoder, and
  // the photographic scenes are most of the budget.
  final args = lossless
      ? ['-lossless', '-z', '9', '-quiet', tmp.path, '-o', out.path]
      : [
          '-q',
          '$quality',
          '-alpha_q',
          '100',
          '-quiet',
          tmp.path,
          '-o',
          out.path,
        ];
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
