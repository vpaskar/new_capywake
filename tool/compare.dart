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

const referenceBlocks = <String, double>{
  'header band lower edge': 103.9 - statusBarPt,
  'hero scene lower edge': 292.3 - statusBarPt,
  'card top (overlap)': 303.4 - statusBarPt,
  'nav bar top': 774.5 - statusBarPt,
};

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

  for (final entry in referenceBlocks.entries) {
    final nearest = _nearest(captureEdges, entry.value);
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

/// Rows where the mean luminance jumps — the structural block boundaries.
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

  final edges = <double>[];
  for (var y = 1; y < means.length; y++) {
    if ((means[y] - means[y - 1]).abs() > 18) edges.add(y / scale);
  }
  return edges;
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

double? _nearest(List<double> edges, double target) {
  double? best;
  var bestDistance = double.infinity;
  for (final e in edges) {
    final d = (e - target).abs();
    if (d < bestDistance) {
      bestDistance = d;
      best = e;
    }
  }
  return bestDistance > 40 ? null : best;
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
