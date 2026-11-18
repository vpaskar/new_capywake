import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:meta/meta.dart';

/// Alpha at or below this is a ghost pixel — the scatter left by automatic
/// background masking. Cleared to fully transparent on import.
const ghostAlphaCeiling = 16;

/// Alpha at or above this is meant to be opaque. The supplied art carries ~91%
/// of its ink at 250–254 (a lossy-compression artifact), which leaves it
/// faintly translucent; snapping the band closes it.
const solidAlphaFloor = 250;

@immutable
class ArtAuditResult {
  const ArtAuditResult({
    required this.width,
    required this.height,
    required this.hasAlpha,
    required this.ghostPixels,
    required this.nearSolidPixels,
    required this.opaquePixels,
    required this.trimRect,
    required this.edgeContactPixels,
  });

  final int width;
  final int height;
  final bool hasAlpha;
  final int ghostPixels;
  final int nearSolidPixels;
  final int opaquePixels;

  /// Bounds of the visible ink, or `null` when the image is fully transparent.
  final ArtRect? trimRect;

  /// Opaque pixels touching an outer edge. A high count on a cutout means the
  /// crop severed the subject.
  final int edgeContactPixels;

  bool get isTrimmed =>
      trimRect != null &&
      trimRect!.left == 0 &&
      trimRect!.top == 0 &&
      trimRect!.right == width - 1 &&
      trimRect!.bottom == height - 1;

  bool get isEmpty => trimRect == null;
}

@immutable
class ArtRect {
  const ArtRect(this.left, this.top, this.right, this.bottom);

  final int left;
  final int top;
  final int right;
  final int bottom;

  int get width => right - left + 1;
  int get height => bottom - top + 1;

  @override
  bool operator ==(Object other) =>
      other is ArtRect &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'ArtRect($left, $top, $right, $bottom)';
}

ArtAuditResult auditImage(img.Image image) {
  final w = image.width;
  final h = image.height;
  final hasAlpha = image.numChannels == 4;

  var ghost = 0;
  var nearSolid = 0;
  var opaque = 0;
  var edgeContact = 0;
  int? minX;
  int? minY;
  int? maxX;
  int? maxY;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final a = hasAlpha ? image.getPixel(x, y).a.toInt() : 255;
      if (a <= ghostAlphaCeiling) {
        if (a > 0) ghost++;
        continue;
      }
      if (a >= solidAlphaFloor && a < 255) nearSolid++;
      if (a == 255) opaque++;
      if (a > 200 && (x == 0 || y == 0 || x == w - 1 || y == h - 1)) {
        edgeContact++;
      }
      minX = minX == null || x < minX ? x : minX;
      maxX = maxX == null || x > maxX ? x : maxX;
      minY = minY == null || y < minY ? y : minY;
      maxY = maxY == null || y > maxY ? y : maxY;
    }
  }

  return ArtAuditResult(
    width: w,
    height: h,
    hasAlpha: hasAlpha,
    ghostPixels: ghost,
    nearSolidPixels: nearSolid,
    opaquePixels: opaque,
    trimRect: minX == null ? null : ArtRect(minX, minY!, maxX!, maxY!),
    edgeContactPixels: edgeContact,
  );
}

/// Clears ghost pixels to fully transparent and snaps the near-solid band to
/// opaque. Mutates and returns [image].
img.Image normalizeAlpha(img.Image image) {
  if (image.numChannels != 4) return image;
  for (final p in image) {
    final a = p.a.toInt();
    if (a == 0 || a == 255) continue;
    if (a <= ghostAlphaCeiling) {
      p.a = 0;
    } else if (a >= solidAlphaFloor) {
      p.a = 255;
    }
  }
  return image;
}

/// A sticker cutout whose silhouette edge is mostly light lost its dark
/// outline to background masking. Bundled stickers measure 0.30 and up.
const minOutlineCoverage = 0.25;

const _outlineReach = 3;
const _outlineLuminance = 0.3;

/// The share of a cutout's silhouette edge with dark ink within a few pixels
/// inward: near 1 for an outlined sticker, near 0 when the outline was masked.
double outlineCoverage(img.Image image) {
  if (image.numChannels != 4) return 1;
  final w = image.width;
  final h = image.height;
  int alpha(int x, int y) =>
      x < 0 || y < 0 || x >= w || y >= h ? 0 : image.getPixel(x, y).a.toInt();
  bool isDark(int x, int y) {
    final p = image.getPixel(x, y);
    final luminance =
        (0.2126 * p.r.toInt() + 0.7152 * p.g.toInt() + 0.0722 * p.b.toInt()) /
        255;
    return luminance < _outlineLuminance;
  }

  var edge = 0;
  var outlined = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (alpha(x, y) <= ghostAlphaCeiling) continue;
      final onEdge =
          alpha(x + 1, y) <= ghostAlphaCeiling ||
          alpha(x - 1, y) <= ghostAlphaCeiling ||
          alpha(x, y + 1) <= ghostAlphaCeiling ||
          alpha(x, y - 1) <= ghostAlphaCeiling;
      if (!onEdge) continue;
      edge++;
      search:
      for (var dy = -_outlineReach; dy <= _outlineReach; dy++) {
        for (var dx = -_outlineReach; dx <= _outlineReach; dx++) {
          if (alpha(x + dx, y + dy) > 200 && isDark(x + dx, y + dy)) {
            outlined++;
            break search;
          }
        }
      }
    }
  }
  return edge == 0 ? 1 : outlined / edge;
}

/// An animation's frames audited together: one canvas, and the worst
/// frame's ghosts, edge contact and outline coverage.
@immutable
class AnimationAuditResult {
  const AnimationAuditResult({
    required this.frameCount,
    required this.sameCanvas,
    required this.width,
    required this.ghostPixels,
    required this.edgeContactPixels,
    required this.outlineCoverage,
  });

  final int frameCount;
  final bool sameCanvas;
  final int width;
  final int ghostPixels;
  final int edgeContactPixels;
  final double outlineCoverage;
}

AnimationAuditResult auditAnimation(List<img.Image> frames) {
  var ghosts = 0;
  var edge = 0;
  var coverage = 1.0;
  for (final frame in frames) {
    final audit = auditImage(frame);
    ghosts = math.max(ghosts, audit.ghostPixels);
    edge = math.max(edge, audit.edgeContactPixels);
    coverage = math.min(coverage, outlineCoverage(frame));
  }
  return AnimationAuditResult(
    frameCount: frames.length,
    sameCanvas: frames.map((f) => (f.width, f.height)).toSet().length <= 1,
    width: frames.isEmpty ? 0 : frames.first.width,
    ghostPixels: ghosts,
    edgeContactPixels: edge,
    outlineCoverage: coverage,
  );
}

img.Image trimToInk(img.Image image) {
  final rect = auditImage(image).trimRect;
  if (rect == null) return image;
  return img.copyCrop(
    image,
    x: rect.left,
    y: rect.top,
    width: rect.width,
    height: rect.height,
  );
}

/// Inclusive index ranges of rows (or columns) whose every sampled pixel is
/// transparent. Used to find a sticker sheet's gutters.
List<ArtRect> findTransparentBands(
  img.Image image, {
  required bool horizontal,
  int minBandSize = 5,
}) {
  final length = horizontal ? image.height : image.width;
  final across = horizontal ? image.width : image.height;
  final empty = <int>[];

  for (var i = 0; i < length; i++) {
    var clear = true;
    for (var j = 0; j < across; j++) {
      final p = horizontal ? image.getPixel(j, i) : image.getPixel(i, j);
      if (p.a.toInt() > ghostAlphaCeiling) {
        clear = false;
        break;
      }
    }
    if (clear) empty.add(i);
  }

  final bands = <ArtRect>[];
  if (empty.isEmpty) return bands;

  var start = empty.first;
  var prev = empty.first;
  for (final i in empty.skip(1)) {
    if (i != prev + 1) {
      if (prev - start + 1 >= minBandSize) {
        bands.add(ArtRect(start, 0, prev, 0));
      }
      start = i;
    }
    prev = i;
  }
  if (prev - start + 1 >= minBandSize) bands.add(ArtRect(start, 0, prev, 0));
  return bands;
}

/// Cell bounds between the transparent gutters, in reading order.
List<ArtRect> sliceSheet(img.Image sheet, {int minBandSize = 5}) {
  final rowBands = findTransparentBands(
    sheet,
    horizontal: true,
    minBandSize: minBandSize,
  );
  final colBands = findTransparentBands(
    sheet,
    horizontal: false,
    minBandSize: minBandSize,
  );

  final rows = _spansBetween(rowBands, sheet.height);
  final cols = _spansBetween(colBands, sheet.width);

  final cells = <ArtRect>[];
  for (final r in rows) {
    for (final c in cols) {
      final cell = img.copyCrop(
        sheet,
        x: c.left,
        y: r.left,
        width: c.right - c.left + 1,
        height: r.right - r.left + 1,
      );
      final ink = auditImage(cell).trimRect;
      if (ink == null) continue;
      cells.add(
        ArtRect(
          c.left + ink.left,
          r.left + ink.top,
          c.left + ink.right,
          r.left + ink.bottom,
        ),
      );
    }
  }
  return cells;
}

List<ArtRect> _spansBetween(List<ArtRect> bands, int extent) {
  final spans = <ArtRect>[];
  var cursor = 0;
  for (final b in bands) {
    if (b.left > cursor) spans.add(ArtRect(cursor, 0, b.left - 1, 0));
    cursor = b.right + 1;
  }
  if (cursor < extent) spans.add(ArtRect(cursor, 0, extent - 1, 0));
  return spans;
}

/// Pixels needed to render [renderBoxPt] sharply at [devicePixelRatio].
int requiredPixels(double renderBoxPt, {double devicePixelRatio = 3}) =>
    (renderBoxPt * devicePixelRatio).ceil();

/// Splits a cell whose subjects touch, by cutting at the sparsest interior
/// column rather than requiring a fully transparent gutter.
///
/// A sticker sheet laid out loosely leaves gutters, which [sliceSheet] finds.
/// A tighter one lets neighbouring poses overlap horizontally, and those cells
/// arrive merged — two capybaras in one asset, useless as a mascot.
List<ArtRect> splitWideCell(
  img.Image image,
  ArtRect cell, {
  double maxAspect = 1.9,
}) {
  final w = cell.width;
  final h = cell.height;
  if (w / h <= maxAspect) return [cell];

  final coverage = List<int>.filled(w, 0);
  for (var x = 0; x < w; x++) {
    var count = 0;
    for (var y = 0; y < h; y++) {
      if (image.getPixel(cell.left + x, cell.top + y).a.toInt() >
          ghostAlphaCeiling) {
        count++;
      }
    }
    coverage[x] = count;
  }

  // Cut only where the art genuinely thins out. Deriving a part count from the
  // aspect ratio and then forcing that many cuts splits a single wide subject;
  // the valleys say how many subjects there actually are.
  final threshold = (h * 0.06).ceil().clamp(1, h);
  final minSubjectWidth = (h * 0.45).round();

  final cuts = <int>[];
  var x = minSubjectWidth;
  while (x < w - minSubjectWidth) {
    if (coverage[x] > threshold) {
      x++;
      continue;
    }
    var end = x;
    while (end < w - 1 && coverage[end + 1] <= threshold) {
      end++;
    }
    cuts.add((x + end) ~/ 2);
    x = end + minSubjectWidth;
  }

  if (cuts.isEmpty) return [cell];

  final bounds = [0, ...cuts, w];
  final out = <ArtRect>[];
  for (var i = 0; i < bounds.length - 1; i++) {
    final slice = img.copyCrop(
      image,
      x: cell.left + bounds[i],
      y: cell.top,
      width: bounds[i + 1] - bounds[i],
      height: h,
    );
    final ink = auditImage(slice).trimRect;
    if (ink == null) continue;
    out.add(
      ArtRect(
        cell.left + bounds[i] + ink.left,
        cell.top + ink.top,
        cell.left + bounds[i] + ink.right,
        cell.top + ink.bottom,
      ),
    );
  }
  return out.isEmpty ? [cell] : out;
}
