import 'package:flutter/widgets.dart';

/// Palette sampled from the mockups, each constant the centre of its cluster
/// (they are compression-noisy). Measured in `PHASE_01_PLAN.md`.
abstract final class CapyColors {
  static const cream = Color(0xFFFEF3E7);
  static const surface = Color(0xFFFEF4E8);
  static const surfaceAlt = Color(0xFFF8E1CC);

  static const accent = Color(0xFFF89736);
  static const accentDeep = Color(0xFFE97C22);

  static const cocoa = Color(0xFF2F1106);
  static const cocoaSoft = Color(0xFF8A6A55);

  static const success = Color(0xFF57AA3A);
  static const grass = Color(0xFF85B83B);

  /// A game field's ground, standing in for a meadow backdrop (gap G31).
  static const meadow = Color(0xFFD5E8B5);

  /// Dark mode swaps surfaces and lays a scrim over the art, which is raster
  /// and cannot re-tint.
  static const darkSurface = Color(0xFF241A14);
  static const darkSurfaceAlt = Color(0xFF32241B);
  static const darkCream = Color(0xFF1B130E);
  static const darkInk = Color(0xFFF4E4D4);
  static const darkInkSoft = Color(0xFFBFA896);
  static const artScrim = Color(0x66120A06);

  static const error = Color(0xFFC4452B);
}

/// Rhythm Rescue's pads, sampled from `games/posters/09_RHYTHM_RESCUE.png`.
abstract final class CapyPadColors {
  static const orange = Color(0xFFF8A455);
  static const yellow = Color(0xFFFED181);
  static const green = Color(0xFFB7D187);
  static const blue = Color(0xFFB3D2E1);

  static const List<Color> all = [orange, yellow, green, blue];
}

/// Icon and inline-art sizes. Widgets name these rather than carrying a
/// literal, so a change lands everywhere at once.
abstract final class CapyIconSize {
  static const sm = 18.0;
  static const md = 26.0;
  static const badge = 28.0;
  static const wordmark = 30.0;
}

/// The 4-based spacing scale. Widgets use these, never a raw number.
abstract final class CapySpacing {
  /// Screen side margin, from `01_HOME.png`'s game rail at 10.2 pt. The card
  /// reads 12.5 pt because its hairline strokes inside the box.
  static const gutter = 11.0;

  /// `03_ADD_EDIT_ALARM.png`'s margin, 14.8 pt at its Save button's left
  /// edge. A second token, not a correction of [gutter].
  static const gutterWide = 15.0;

  /// `04_SETTINGS.png`'s margin, 9.70 pt, agreed across three groups. A third
  /// token: the mockups draw three different side margins.
  static const gutterNarrow = 9.7;

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

abstract final class CapyRadius {
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

abstract final class CapyDuration {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 360);
}
