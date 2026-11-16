import 'package:capywake/design/art_audit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

img.Image _blank(int w, int h) =>
    img.Image(width: w, height: h, numChannels: 4)
      ..clear(img.ColorRgba8(0, 0, 0, 0));

void _fill(img.Image im, ArtRect r, int alpha) {
  for (var y = r.top; y <= r.bottom; y++) {
    for (var x = r.left; x <= r.right; x++) {
      im.setPixel(x, y, img.ColorRgba8(200, 140, 80, alpha));
    }
  }
}

void main() {
  group('auditImage', () {
    test('reports an empty image as having no ink', () {
      final result = auditImage(_blank(10, 10));
      expect(result.isEmpty, isTrue);
      expect(result.trimRect, isNull);
    });

    test('finds the ink bounds', () {
      final im = _blank(20, 20);
      _fill(im, const ArtRect(5, 6, 9, 12), 255);
      final result = auditImage(im);
      expect(result.trimRect, const ArtRect(5, 6, 9, 12));
      expect(result.trimRect!.width, 5);
      expect(result.trimRect!.height, 7);
    });

    test('counts ghost pixels but excludes them from the ink bounds', () {
      final im = _blank(20, 20);
      _fill(im, const ArtRect(8, 8, 10, 10), 255);
      _fill(im, const ArtRect(0, 0, 1, 1), 8);

      final result = auditImage(im);
      expect(result.ghostPixels, 4);
      expect(result.trimRect, const ArtRect(8, 8, 10, 10));
    });

    test('separates the near-solid band from true opacity', () {
      final im = _blank(10, 10);
      _fill(im, const ArtRect(0, 0, 4, 4), 252);
      _fill(im, const ArtRect(5, 5, 6, 6), 255);
      final result = auditImage(im);
      expect(result.nearSolidPixels, 25);
      expect(result.opaquePixels, 4);
    });

    test('counts opaque pixels touching an edge as a severed crop signal', () {
      final im = _blank(10, 10);
      _fill(im, const ArtRect(0, 0, 9, 2), 255);
      final result = auditImage(im);
      expect(result.edgeContactPixels, greaterThan(0));
    });

    test('a centred subject touches no edge', () {
      final im = _blank(10, 10);
      _fill(im, const ArtRect(3, 3, 6, 6), 255);
      expect(auditImage(im).edgeContactPixels, 0);
    });

    test('isTrimmed is true only when ink fills the frame', () {
      final tight = _blank(4, 4);
      _fill(tight, const ArtRect(0, 0, 3, 3), 255);
      final loose = _blank(8, 8);
      _fill(loose, const ArtRect(1, 1, 6, 6), 255);

      expect(auditImage(tight).isTrimmed, isTrue);
      expect(auditImage(loose).isTrimmed, isFalse);
    });
  });

  group('normalizeAlpha', () {
    test('clears ghosts and snaps the near-solid band', () {
      final im = _blank(6, 1)
        ..setPixel(0, 0, img.ColorRgba8(1, 1, 1, 0))
        ..setPixel(1, 0, img.ColorRgba8(1, 1, 1, 9))
        ..setPixel(2, 0, img.ColorRgba8(1, 1, 1, 16))
        ..setPixel(3, 0, img.ColorRgba8(1, 1, 1, 180))
        ..setPixel(4, 0, img.ColorRgba8(1, 1, 1, 252))
        ..setPixel(5, 0, img.ColorRgba8(1, 1, 1, 255));

      normalizeAlpha(im);

      expect(im.getPixel(0, 0).a, 0);
      expect(im.getPixel(1, 0).a, 0, reason: 'ghost cleared');
      expect(im.getPixel(2, 0).a, 0, reason: 'ceiling is inclusive');
      expect(im.getPixel(3, 0).a, 180, reason: 'real antialiasing is kept');
      expect(im.getPixel(4, 0).a, 255, reason: 'near-solid snapped');
      expect(im.getPixel(5, 0).a, 255);
    });

    test('leaves antialiased edges alone', () {
      final im = _blank(3, 1)
        ..setPixel(0, 0, img.ColorRgba8(1, 1, 1, 40))
        ..setPixel(1, 0, img.ColorRgba8(1, 1, 1, 128))
        ..setPixel(2, 0, img.ColorRgba8(1, 1, 1, 220));
      normalizeAlpha(im);
      expect(im.getPixel(0, 0).a, 40);
      expect(im.getPixel(1, 0).a, 128);
      expect(im.getPixel(2, 0).a, 220);
    });
  });

  group('trimToInk', () {
    test('crops away the transparent margin', () {
      final im = _blank(20, 20);
      _fill(im, const ArtRect(4, 7, 11, 13), 255);
      final trimmed = trimToInk(im);
      expect(trimmed.width, 8);
      expect(trimmed.height, 7);
      expect(auditImage(trimmed).isTrimmed, isTrue);
    });

    test('returns a fully transparent image unchanged', () {
      final im = _blank(5, 5);
      expect(trimToInk(im).width, 5);
    });
  });

  group('sliceSheet', () {
    test('splits a 2x2 grid into four trimmed cells', () {
      final sheet = _blank(100, 100);
      _fill(sheet, const ArtRect(10, 10, 30, 30), 255);
      _fill(sheet, const ArtRect(65, 10, 85, 30), 255);
      _fill(sheet, const ArtRect(10, 65, 30, 85), 255);
      _fill(sheet, const ArtRect(65, 65, 85, 85), 255);

      final cells = sliceSheet(sheet);

      expect(cells, hasLength(4));
      expect(cells.first, const ArtRect(10, 10, 30, 30));
      expect(cells.last, const ArtRect(65, 65, 85, 85));
    });

    test('skips empty cells', () {
      final sheet = _blank(100, 100);
      _fill(sheet, const ArtRect(10, 10, 30, 30), 255);
      _fill(sheet, const ArtRect(65, 65, 85, 85), 255);
      expect(sliceSheet(sheet), hasLength(2));
    });

    test('a sheet with no gutters yields a single cell', () {
      final sheet = _blank(40, 40);
      _fill(sheet, const ArtRect(0, 0, 39, 39), 255);
      expect(sliceSheet(sheet), hasLength(1));
    });
  });

  group('findTransparentBands', () {
    test('ignores bands narrower than the minimum', () {
      final im = _blank(20, 20);
      _fill(im, const ArtRect(0, 0, 19, 8), 255);
      _fill(im, const ArtRect(0, 11, 19, 19), 255);
      expect(
        findTransparentBands(im, horizontal: true),
        isEmpty,
      );
      expect(
        findTransparentBands(im, horizontal: true, minBandSize: 2),
        hasLength(1),
      );
    });
  });

  group('splitWideCell', () {
    test('leaves a normally-proportioned cell alone', () {
      final im = _blank(60, 50);
      _fill(im, const ArtRect(5, 5, 54, 44), 255);
      final parts = splitWideCell(im, const ArtRect(0, 0, 59, 49));
      expect(parts, hasLength(1));
    });

    test('splits two touching subjects into separate cells', () {
      final im = _blank(200, 60);
      _fill(im, const ArtRect(5, 5, 90, 54), 255);
      _fill(im, const ArtRect(96, 5, 190, 54), 255);
      final parts = splitWideCell(im, const ArtRect(0, 0, 199, 59));
      expect(parts, hasLength(2));
      expect(parts[0].right, lessThan(parts[1].left));
    });

    test('each split part is trimmed to its own ink', () {
      final im = _blank(200, 60);
      _fill(im, const ArtRect(10, 12, 80, 50), 255);
      _fill(im, const ArtRect(110, 8, 180, 46), 255);
      final parts = splitWideCell(im, const ArtRect(0, 0, 199, 59));
      expect(parts, hasLength(2));
      expect(parts[0], const ArtRect(10, 12, 80, 50));
      expect(parts[1], const ArtRect(110, 8, 180, 46));
    });

    test('cuts at the sparsest column, not blindly at the midpoint', () {
      final im = _blank(200, 60);
      _fill(im, const ArtRect(5, 5, 110, 54), 255);
      _fill(im, const ArtRect(125, 5, 195, 54), 255);
      final parts = splitWideCell(im, const ArtRect(0, 0, 199, 59));
      expect(parts, hasLength(2));
      expect(parts[0].right, 110);
      expect(parts[1].left, 125);
    });
  });

  group('requiredPixels', () {
    test('scales the render box by the device pixel ratio', () {
      expect(requiredPixels(120), 360);
      expect(requiredPixels(96), 288);
      expect(requiredPixels(44), 132);
    });

    test('rounds up a fractional result', () {
      expect(requiredPixels(55.4), 167);
    });
  });
}
