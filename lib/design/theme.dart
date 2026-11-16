import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// Baloo 2 covers Latin and Turkish. It does **not** cover Cyrillic, Arabic or
/// Japanese — verified by rendering, not by a glyph-table lookup. Nunito picks
/// up Cyrillic for `ru`; Arabic and Japanese fall through to the system face.
/// `docs/visual/typography/README.md` records the comparison.
const capyFontFamily = 'Baloo2';
const capyFontFallback = <String>['Nunito'];

abstract final class CapyType {
  static const String _f = capyFontFamily;
  static const List<String> _fb = capyFontFallback;

  static const display = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fb,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  static const title = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fb,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const section = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fb,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const body = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fb,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static const label = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fb,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const caption = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fb,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}

ThemeData capyTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;

  final surface = dark ? CapyColors.darkSurface : CapyColors.surface;
  final background = dark ? CapyColors.darkCream : CapyColors.cream;
  final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
  final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: CapyColors.accent,
    onPrimary: Colors.white,
    secondary: CapyColors.grass,
    onSecondary: Colors.white,
    error: const Color(0xFFC4452B),
    onError: Colors.white,
    surface: surface,
    onSurface: ink,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    fontFamily: capyFontFamily,
    fontFamilyFallback: capyFontFallback,
    textTheme: TextTheme(
      displayLarge: CapyType.display.copyWith(color: ink),
      titleLarge: CapyType.title.copyWith(color: ink),
      titleMedium: CapyType.section.copyWith(color: ink),
      bodyLarge: CapyType.body.copyWith(color: ink),
      bodyMedium: CapyType.body.copyWith(color: inkSoft),
      labelLarge: CapyType.label.copyWith(color: ink),
      labelSmall: CapyType.caption.copyWith(color: inkSoft),
    ),
  );
}
