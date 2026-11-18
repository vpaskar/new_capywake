import 'dart:math' as math;

import 'package:capywake/design/tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _ratio(Color fg, Color bg) {
  final a = _luminance(fg);
  final b = _luminance(bg);
  final lighter = math.max(a, b);
  final darker = math.min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Phase 02 ports the legacy domain but deliberately drops
/// `lib/core/theme.dart` and its `test/core/theme_test.dart`. Twenty of those
/// tests asserted AA contrast and separator discipline on the *old* palette.
/// CapyWake's palette is `lib/design/tokens.dart`, sampled from the mockups in
/// Phase 01, and nothing asserted its contrast — so the port would have
/// dropped an accessibility invariant rather than relocating it. This file is
/// that invariant, restated
/// against the tokens that ship.
void main() {
  // 4.5:1 body, 3:1 large text and UI components (WCAG 2.1 AA).
  const bodyMin = 4.5;
  const largeMin = 3.0;

  group('light palette clears AA', () {
    const backgrounds = {
      'cream': CapyColors.cream,
      'surface': CapyColors.surface,
      'surfaceAlt': CapyColors.surfaceAlt,
    };

    test('primary ink on every light surface', () {
      backgrounds.forEach((name, bg) {
        expect(
          _ratio(CapyColors.cocoa, bg),
          greaterThanOrEqualTo(bodyMin),
          reason: 'cocoa on $name must clear $bodyMin:1 for body text.',
        );
      });
    });

    test('secondary ink on every light surface clears large-text AA', () {
      backgrounds.forEach((name, bg) {
        expect(
          _ratio(CapyColors.cocoaSoft, bg),
          greaterThanOrEqualTo(largeMin),
          reason: 'cocoaSoft on $name must clear $largeMin:1.',
        );
      });
    });

    test('ink on the accent fill a filled control uses', () {
      // The accent is a *fill*, not a foreground: this is the pairing that has
      // to clear AA, and it does comfortably.
      expect(
        _ratio(CapyColors.cocoa, CapyColors.accent),
        greaterThanOrEqualTo(bodyMin),
      );
      expect(
        _ratio(CapyColors.cocoa, CapyColors.accentDeep),
        greaterThanOrEqualTo(bodyMin),
      );
    });

    test('the accent is never strong enough to be a lone state channel', () {
      // Measured against the sampled palette: accentDeep reaches only
      // 2.26-2.62:1 on the three light surfaces, so it does NOT clear the 3:1
      // UI-component minimum. That is recorded as the constraint it is rather
      // than asserted away — a control may not rely on accent alone to carry
      // its boundary or state in light mode; it needs ink, a shape change or a
      // label too. The same holds for success and grass (2.30-2.68:1).
      //
      // Phase 02 does not retune a palette sampled from the mockups: that is a
      // Tier A decision. See PHASE_02_POST_REVIEW.md finding F1.
      for (final token in [
        CapyColors.accentDeep,
        CapyColors.accent,
        CapyColors.success,
        CapyColors.grass,
      ]) {
        for (final bg in backgrounds.values) {
          expect(
            _ratio(token, bg),
            lessThan(largeMin),
            reason:
                'This token has become strong enough to stand alone. That is '
                'an improvement — update this test and F1 together rather '
                'than leaving the weaker claim in place.',
          );
        }
      }
    });

    test('error text clears body AA on the two primary light surfaces', () {
      // cream 4.53:1 and surface 4.56:1 clear it. surfaceAlt is 3.93:1 and
      // does not, so error text is not placed on surfaceAlt — asserted below
      // so the limit is a checked property rather than a note.
      expect(
        _ratio(CapyColors.error, CapyColors.cream),
        greaterThanOrEqualTo(bodyMin),
      );
      expect(
        _ratio(CapyColors.error, CapyColors.surface),
        greaterThanOrEqualTo(bodyMin),
      );
      expect(
        _ratio(CapyColors.error, CapyColors.surfaceAlt),
        lessThan(bodyMin),
        reason:
            'If error now clears AA on surfaceAlt, the restriction in F2 is '
            'obsolete — lift it deliberately instead of silently.',
      );
    });
  });

  group('dark palette clears AA', () {
    const backgrounds = {
      'darkCream': CapyColors.darkCream,
      'darkSurface': CapyColors.darkSurface,
      'darkSurfaceAlt': CapyColors.darkSurfaceAlt,
    };

    test('primary ink on every dark surface', () {
      backgrounds.forEach((name, bg) {
        expect(
          _ratio(CapyColors.darkInk, bg),
          greaterThanOrEqualTo(bodyMin),
          reason: 'darkInk on $name must clear $bodyMin:1 for body text.',
        );
      });
    });

    test('secondary ink on every dark surface clears large-text AA', () {
      backgrounds.forEach((name, bg) {
        expect(
          _ratio(CapyColors.darkInkSoft, bg),
          greaterThanOrEqualTo(largeMin),
          reason: 'darkInkSoft on $name must clear $largeMin:1.',
        );
      });
    });

    test('the accent reads as a UI component against dark surfaces', () {
      for (final bg in backgrounds.values) {
        expect(_ratio(CapyColors.accent, bg), greaterThanOrEqualTo(largeMin));
      }
    });
  });

  test('every palette colour is fully opaque except the art scrim', () {
    // The scrim is the one token that is meant to be translucent: it lies over
    // raster art, which cannot be re-tinted for dark mode. Anything else
    // arriving with alpha would silently change every contrast figure above,
    // because these ratios are computed on the declared colour rather than on
    // what composites onto the surface beneath it.
    const opaque = {
      'cream': CapyColors.cream,
      'surface': CapyColors.surface,
      'surfaceAlt': CapyColors.surfaceAlt,
      'accent': CapyColors.accent,
      'accentDeep': CapyColors.accentDeep,
      'cocoa': CapyColors.cocoa,
      'cocoaSoft': CapyColors.cocoaSoft,
      'success': CapyColors.success,
      'grass': CapyColors.grass,
      'darkSurface': CapyColors.darkSurface,
      'darkSurfaceAlt': CapyColors.darkSurfaceAlt,
      'darkCream': CapyColors.darkCream,
      'darkInk': CapyColors.darkInk,
      'darkInkSoft': CapyColors.darkInkSoft,
      'error': CapyColors.error,
    };

    for (final entry in opaque.entries) {
      expect(entry.value.a, 1.0, reason: '${entry.key} must be opaque.');
    }
    expect(CapyColors.artScrim.a, lessThan(1.0));
  });

  group('Rhythm Rescue pads', () {
    test('four distinct opaque colours', () {
      expect(CapyPadColors.all.toSet(), hasLength(4));
      for (final pad in CapyPadColors.all) {
        expect(pad.a, 1.0);
      }
    });

    test('the numeral (cocoa) reads on every pad as body text', () {
      for (final pad in CapyPadColors.all) {
        expect(_ratio(CapyColors.cocoa, pad), greaterThanOrEqualTo(bodyMin));
      }
    });

    test('the pad border clears 3:1 on the light card', () {
      expect(
        _ratio(CapyColors.cocoaSoft, CapyColors.surface),
        greaterThanOrEqualTo(largeMin),
      );
    });

    test('every pad stands out from the dark card as a component', () {
      for (final pad in CapyPadColors.all) {
        expect(
          _ratio(pad, CapyColors.darkSurface),
          greaterThanOrEqualTo(largeMin),
        );
      }
    });
  });
}
