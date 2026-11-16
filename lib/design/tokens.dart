import 'package:flutter/widgets.dart';

/// Palette sampled from `reference/01_REFERENCES/screens/primary/`.
///
/// The mockups are compression-noisy, so every flat area is a cloud of
/// near-identical values rather than one value. Each constant below is the
/// centre of its sampled cluster; `docs/phases/PHASE_01_PLAN.md` records the
/// measurement.
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

  /// Dark mode swaps surfaces and lays a scrim over the art, which is raster
  /// and cannot re-tint.
  static const darkSurface = Color(0xFF241A14);
  static const darkSurfaceAlt = Color(0xFF32241B);
  static const darkCream = Color(0xFF1B130E);
  static const darkInk = Color(0xFFF4E4D4);
  static const darkInkSoft = Color(0xFFBFA896);
  static const artScrim = Color(0x66120A06);
}

/// The 4-based spacing scale. Widgets use these, never a raw number.
abstract final class CapySpacing {
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
