// Compares a capture against its mockup and prints per-block deltas in pt.
//
//   dart run tool/compare.dart shell 01_HOME
//
// Normalization (pre-review finding M6): the mockups are 851x1847 px at
// 2.1654 px/pt = 393x853 pt; the device captures 1179x2556 px = 393x852 pt.
// Width is exact, height is 1 pt short. The reference is scaled to the
// captured height and +-1 pt is rounding, not signal. Every report prints the
// normalization it used so a reader can tell measurement from tolerance.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const tierATolerancePt = 4.0;
const roundingTolerancePt = 1.0;

/// Blocks reported for every screen, so a screen cannot pick the ones it
/// already matches (pre-review finding M5). A screen's phase may add rows; it
/// may never remove one. Positions are from docs/visual/tier_a_blocks.md.
///
/// Offsets are measured from the bottom of the status bar, not from the top of
/// the screen. The mockup draws a 44pt status bar; the iPhone 14 Pro simulator
/// reports a 59.1pt top inset. That difference is the device's, not the
/// layout's, and comparing absolute offsets would charge every block below the
/// header a constant 15pt error that no code change could fix.
const statusBarPt = 44.0;

/// Blocks every screen is measured against. A screen may add rows to its
/// own table, never drop one of these (Phase 01 M5).
const sharedBlocks = <String, double>{
  'header band lower edge': 103.9 - statusBarPt,
};

/// Per-screen blocks: nine of Home's fourteen cannot exist on a pushed
/// route. See `PHASE_04_PRE_REVIEW.md` M4.
const screenBlocks = <String, Map<String, double>>{
  'home': {
    'hero scene lower edge': 292.3 - statusBarPt,
    'card top (overlap)': 303.4 - statusBarPt,
    'next-alarm card top': 320.0 - statusBarPt,
    'next-alarm card bottom': 385.1 - statusBarPt,
    'section label baseline': 383.3 - statusBarPt,
    'primary CTA top': 400.4 - statusBarPt,
    'primary CTA bottom': 455.8 - statusBarPt,
    'next section top': 498.8 - statusBarPt,
    // Measured from the status bar, unlike the rows above.
    'game rail tiles top': 485.7,
    'game rail labels end': 593.9,
    'my stats row top': 617.0,
    'meadow footer top': 672.4,
    'nav bar top': 774.5 - statusBarPt,
  },
  // Phase 04. Methods are named per row in docs/visual/tier_a_blocks.md.
  'alarms': {
    'hero scene lower edge': 252.5 - statusBarPt,
    'alarm card 1 top': 329.7 - statusBarPt,
    'alarm card 1 bottom': 419.3 - statusBarPt,
    'alarm card 2 top': 431.8 - statusBarPt,
    'alarm card 2 bottom': 518.6 - statusBarPt,
    'alarm card 3 top': 530.4 - statusBarPt,
    'alarm card 3 bottom': 617.9 - statusBarPt,
    'alarm card 4 top': 630.4 - statusBarPt,
    'alarm card 4 bottom': 716.7 - statusBarPt,
    'meadow footer top': 728.3 - statusBarPt,
    'nav bar top': 774.5 - statusBarPt,
  },
  'add_edit_alarm': {
    'hero scene lower edge': 216.0 - statusBarPt,
    'time stepper card top': 249.8 - statusBarPt,
    'time stepper card bottom': 362.5 - statusBarPt,
    'repeat card top': 399.9 - statusBarPt,
    'repeat card bottom': 482.6 - statusBarPt,
    'label card top': 511.7 - statusBarPt,
    'sound card top': 603.1 - statusBarPt,
    'snooze card top': 660.4 - statusBarPt,
    'save CTA top': 724.6 - statusBarPt,
    'save CTA bottom': 778.1 - statusBarPt,
    'meadow footer top': 793.4 - statusBarPt,
  },
  // Phase 07. Only the blocks the shipped row set cannot move; the cut rows
  // move everything below Appearance's top. See docs/visual/settings/.
  'settings': {
    'hero scene lower edge': 212.9 - statusBarPt,
    'group 1 card top': 231.4 - statusBarPt,
    'group 1 card bottom': 341.8 - statusBarPt,
    'group 2 card top': 355.6 - statusBarPt,
  },
};

Map<String, double> blocksFor(String screen) {
  final own = screenBlocks[screen];
  if (own == null) {
    stderr
      ..writeln('No block table for "$screen". Add one to screenBlocks here')
      ..writeln('and to docs/visual/tier_a_blocks.md: a screen with no')
      ..writeln('blocks is unmeasured, not passing.');
    exit(2);
  }
  return {...sharedBlocks, ...own};
}

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('usage: dart run tool/compare.dart <screen> <mockup>');
    exit(2);
  }
  final screen = args[0];
  final mockupName = args[1];

  final capturePath = 'docs/visual/$screen/actual.png';
  final mockupPath = 'reference/01_REFERENCES/screens/primary/$mockupName.png';

  final capture = _load(capturePath);
  final mockup = _load(mockupPath);

  final captureScale = capture.height / 852.0;
  final mockupScale = mockup.height / 853.0;

  stdout
    ..writeln('Comparing $screen against $mockupName')
    ..writeln(
      '  capture ${capture.width}x${capture.height}px '
      '@ ${captureScale.toStringAsFixed(4)} = '
      '${(capture.width / captureScale).round()}x'
      '${(capture.height / captureScale).round()}pt',
    )
    ..writeln(
      '  mockup  ${mockup.width}x${mockup.height}px '
      '@ ${mockupScale.toStringAsFixed(4)} = '
      '${(mockup.width / mockupScale).round()}x'
      '${(mockup.height / mockupScale).round()}pt',
    )
    ..writeln(
      '  reference scaled to captured height; '
      '+-${roundingTolerancePt}pt is rounding',
    )
    ..writeln();

  final captureInset = _topInsetPt(screen);
  final captureEdges = _edgesPt(
    capture,
    captureScale,
  ).map((e) => e - captureInset).toList();

  stdout
    ..writeln(
      '  capture top inset ${captureInset.toStringAsFixed(1)}pt '
      '(mockup draws ${statusBarPt.toStringAsFixed(0)}pt); '
      'offsets are measured from it',
    )
    ..writeln();

  var worst = 0.0;
  var failures = 0;

  stdout.writeln(
    '  ${'block'.padRight(26)} ${'ref'.padLeft(7)} '
    '${'actual'.padLeft(8)} ${'delta'.padLeft(8)}',
  );

  final blocks = blocksFor(screen);
  final claimed = <double, String>{};

  for (final entry in blocks.entries) {
    final nearest = _nearest(captureEdges, entry.value, claimed: claimed);
    if (nearest == null) {
      stdout.writeln(
        '  ${entry.key.padRight(26)} '
        '${entry.value.toStringAsFixed(1).padLeft(7)} '
        '${'--'.padLeft(8)} ${'absent'.padLeft(8)}',
      );
      failures++;
      continue;
    }
    final delta = nearest - entry.value;
    final abs = delta.abs();
    worst = math.max(worst, abs);
    final flag = abs <= roundingTolerancePt
        ? ''
        : abs <= tierATolerancePt
        ? '  within tolerance'
        : '  TIER A FAIL';
    if (abs > tierATolerancePt) failures++;

    stdout.writeln(
      '  ${entry.key.padRight(26)} '
      '${entry.value.toStringAsFixed(1).padLeft(7)} '
      '${nearest.toStringAsFixed(1).padLeft(8)} '
      '${delta.toStringAsFixed(1).padLeft(8)}$flag',
    );
  }

  _writeSideBySide(capture, mockup, 'docs/visual/$screen/side_by_side.png');

  stdout
    ..writeln()
    ..writeln(
      '  worst delta ${worst.toStringAsFixed(1)}pt '
      '(Tier A tolerance ${tierATolerancePt}pt)',
    )
    ..writeln('  wrote docs/visual/$screen/side_by_side.png');

  if (failures > 0) {
    stderr.writeln('\n$failures block(s) outside Tier A tolerance.');
    exit(1);
  }
}

img.Image _load(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing $path');
    exit(2);
  }
  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Unreadable $path');
    exit(2);
  }
  return decoded;
}

/// Row boundaries: luminance jumps plus card hairlines. A 1px border moves
/// a row mean under 1 unit, so |dL|>18 alone called cards absent.
List<double> _edgesPt(img.Image image, double scale) {
  final means = <double>[];
  for (var y = 0; y < image.height; y++) {
    var total = 0.0;
    var n = 0;
    for (var x = 0; x < image.width; x += 4) {
      final p = image.getPixel(x, y);
      total += 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      n++;
    }
    means.add(total / n);
  }

  final edges = <double>{};
  for (var y = 1; y < means.length; y++) {
    if ((means[y] - means[y - 1]).abs() > 18) edges.add(y / scale);
  }
  for (final y in _hairlines(image, scale)) {
    edges.add(y);
  }
  final sorted = edges.toList()..sort();
  return sorted;
}

/// Luminance minima down text-free columns. Several, because none is clean
/// on every screen: x=360 is clear on Alarms, under the art on Settings.
List<double> _hairlines(img.Image image, double scale) {
  final found = <double>[];
  for (final xPt in const [360.0, 22.0, 8.0]) {
    for (final pt in _hairlinesAt(image, scale, xPt)) {
      if (!found.any((f) => (f - pt).abs() < 3)) found.add(pt);
    }
  }
  return found..sort();
}

List<double> _hairlinesAt(img.Image image, double scale, double xPt) {
  final x = (xPt * scale).round().clamp(0, image.width - 1);
  final column = <double>[];
  for (var y = 0; y < image.height; y++) {
    final p = image.getPixel(x, y);
    column.add(0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
  }

  final found = <double>[];
  for (var y = 2; y < column.length - 2; y++) {
    final v = column[y];
    // 244, not 235: a disabled row's border lands near 236 at 55% opacity.
    if (v >= 244) continue;
    // Below ~150 is painted art: the hero band otherwise contributes
    // dozens of minima that outrank the edge being looked for.
    if (v < 150) continue;
    if (v <= column[y - 1] &&
        v <= column[y + 1] &&
        v < column[y - 2] &&
        v < column[y + 2]) {
      final pt = y / scale;
      if (found.isEmpty || pt - found.last > 3) found.add(pt);
    }
  }
  return found;
}

/// The device's top inset, read from the capture metadata the harness writes
/// beside the PNG.
///
/// It cannot be found in the pixels: the mockup draws a status bar and an
/// integration-test capture does not, so there is no edge to detect. Guessing
/// would charge every block below the header a constant error that no code
/// change could fix.
double _topInsetPt(String screen) {
  final file = File('docs/visual/$screen/inset.txt');
  if (!file.existsSync()) {
    stderr.writeln(
      'Missing docs/visual/$screen/inset.txt — re-run tool/capture.sh.',
    );
    exit(2);
  }
  return double.parse(file.readAsStringSync().trim());
}

/// The unclaimed edge nearest [target], within [searchPt]: reaching further
/// lets an undetected block claim an unrelated edge and report a false delta.
double? _nearest(
  List<double> edges,
  double target, {
  required Map<double, String> claimed,
  double searchPt = 12.0,
}) {
  double? best;
  var bestDistance = double.infinity;
  for (final e in edges) {
    if (claimed.containsKey(e)) continue;
    final d = (e - target).abs();
    if (d < bestDistance) {
      bestDistance = d;
      best = e;
    }
  }
  if (bestDistance > searchPt || best == null) return null;
  claimed[best] = '';
  return best;
}

void _writeSideBySide(img.Image capture, img.Image mockup, String path) {
  final height = math.max(capture.height, mockup.height);
  final scaled = img.copyResize(
    mockup,
    height: height,
    interpolation: img.Interpolation.cubic,
  );
  final canvas = img.Image(
    width: capture.width + scaled.width + 24,
    height: height,
  )..clear(img.ColorRgb8(0x2F, 0x11, 0x06));

  img.compositeImage(canvas, scaled, dstX: 0, dstY: 0);
  img.compositeImage(canvas, capture, dstX: scaled.width + 24, dstY: 0);

  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(canvas));
}
