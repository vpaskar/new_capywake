import 'dart:math' as math;

import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where a text's background came from. [art] means a raster image shows
/// through, which a widget walk cannot measure — the captures judge those.
enum FillSource { coloredBox, decoration, material, scaffold, art, none }

@immutable
class TextContrast {
  const TextContrast({
    required this.text,
    required this.foreground,
    required this.background,
    required this.source,
    required this.ratio,
    required this.required,
    required this.paletteConstraint,
  });

  final String text;

  /// `null` when the span had no colour at all, so nothing was measured.
  final Color? foreground;
  final Color background;
  final FillSource source;
  final double ratio;
  final double required;

  /// Brand orange or green on either side: the palette weakness pinned by
  /// `tokens_contrast_test.dart`, the owner's call, so counted, not failed.
  final bool paletteConstraint;

  bool get measured =>
      foreground != null &&
      source != FillSource.art &&
      source != FillSource.none;

  bool get meetsBar => ratio >= required;

  bool get passes => !measured || paletteConstraint || meetsBar;

  @override
  String toString() =>
      '"$text" ${foreground == null ? 'no colour' : _hex(foreground!)} on '
      '${_hex(background)} (${source.name}) ${ratio.toStringAsFixed(2)}:1 '
      '< $required:1';
}

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

double relativeLuminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Every visible text span and typed field value on screen, composited with
/// the fills, opacities and painted-below `Stack` siblings behind it.
List<TextContrast> measureTextContrast(WidgetTester tester) {
  final results = <TextContrast?>[];
  for (final element in find.byType(RichText).evaluate()) {
    final rect = _globalRect(element.renderObject);
    if (rect == null) continue;
    final rich = element.widget as RichText;
    _spans(rich.text, null, (text, style) {
      results.add(_measure(element, rect, text, style));
    });
  }
  for (final element in find.byType(EditableText).evaluate()) {
    final field = element.widget as EditableText;
    final text = field.controller.text.trim();
    final rect = _globalRect(element.renderObject);
    if (text.isEmpty || rect == null) continue;
    results.add(_measure(element, rect, text, field.style));
  }
  return results.whereType<TextContrast>().toList();
}

void _spans(
  InlineSpan span,
  TextStyle? inherited,
  void Function(String text, TextStyle style) visit,
) {
  if (span is! TextSpan) return;
  final style = inherited?.merge(span.style) ?? span.style ?? const TextStyle();
  final text = span.text?.trim() ?? '';
  if (text.isNotEmpty) visit(text, style);
  for (final child in span.children ?? const <InlineSpan>[]) {
    _spans(child, style, visit);
  }
}

Rect? _globalRect(RenderObject? render) {
  if (render is! RenderBox || !render.attached || !render.hasSize) return null;
  if (render.size.isEmpty) return null;
  return MatrixUtils.transformRect(
    render.getTransformTo(null),
    Offset.zero & render.size,
  );
}

sealed class _Layer {}

class _Fill extends _Layer {
  _Fill(this.colour, this.source);
  final Color colour;
  final FillSource source;
}

class _Fade extends _Layer {
  _Fade(this.opacity);
  final double opacity;
}

class _Art extends _Layer {}

TextContrast? _measure(
  Element element,
  Rect rect,
  String text,
  TextStyle style,
) {
  final layers = _layersBehind(element, rect.center);
  if (layers == null) return null;
  final foreground = style.color;
  final label = text.length > 40 ? '${text.substring(0, 40)}…' : text;
  final size = style.fontSize ?? 14;
  final bold = (style.fontWeight ?? FontWeight.w400).value >= 700;
  final required = size >= 18 || (size >= 14 && bold) ? 3.0 : 4.5;

  final (background, source) = _composite(layers, null);
  if (foreground == null || source == FillSource.art) {
    return TextContrast(
      text: label,
      foreground: foreground,
      background: background,
      source: foreground == null ? FillSource.none : source,
      ratio: 0,
      required: required,
      paletteConstraint: false,
    );
  }
  final (shown, _) = _composite(layers, foreground);
  return TextContrast(
    text: label,
    foreground: shown,
    background: background,
    source: source,
    ratio: contrastRatio(shown, background),
    required: required,
    paletteConstraint: _brand.any(
      (c) => _same(background, c) || _same(foreground, c),
    ),
  );
}

/// Composites outward from the text: [ink] over each fill, faded by each
/// opacity. Without [ink] it is the background pixel.
(Color, FillSource) _composite(List<_Layer> layers, Color? ink) {
  var current = ink ?? const Color(0x00000000);
  FillSource? source;
  for (final layer in layers) {
    switch (layer) {
      case _Fill(:final colour, source: final from):
        current = Color.alphaBlend(current, colour);
        source ??= from;
      case _Fade(:final opacity):
        current = current.withValues(alpha: current.a * opacity);
      case _Art():
        if (current.a < 0.999) return (current, FillSource.art);
    }
  }
  if (source == null || current.a < 0.999) {
    return (const Color(0xFFFFFFFF), FillSource.none);
  }
  return (current, source);
}

/// Nearest first. `null` when the text is not painted at all.
List<_Layer>? _layersBehind(Element element, Offset point) {
  final layers = <_Layer>[];
  var hidden = false;
  var child = element;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if ((widget is Offstage && widget.offstage) ||
        (widget is Visibility && !widget.visible) ||
        (widget is Opacity && widget.opacity == 0)) {
      hidden = true;
      return false;
    }
    if (widget is Opacity && widget.opacity < 1) {
      layers.add(_Fade(widget.opacity));
    }
    if (widget is Stack && widget is! IndexedStack) {
      layers.addAll(_paintedBelow(ancestor, child, point).reversed);
    }
    final fill = _fillOf(ancestor);
    if (fill != null) layers.add(fill);
    child = ancestor;
    return true;
  });
  return hidden ? null : layers;
}

/// Fills and art in the `Stack` children before [child] that cover [point],
/// in paint order.
List<_Layer> _paintedBelow(Element stack, Element child, Offset point) {
  final below = <_Layer>[];
  var reached = false;
  void search(Element e) {
    final widget = e.widget;
    if (widget is Offstage && widget.offstage) return;
    final rect = _globalRect(e.renderObject);
    if (rect != null && rect.contains(point)) {
      if (widget is Image) {
        below.add(_Art());
        return;
      }
      final fill = _fillOf(e);
      if (fill != null) below.add(fill);
    }
    e.visitChildElements(search);
  }

  stack.visitChildElements((sibling) {
    if (identical(sibling, child)) reached = true;
    if (!reached) search(sibling);
  });
  return below;
}

const _brand = <Color>[
  CapyColors.accent,
  CapyColors.accentDeep,
  CapyColors.success,
  CapyColors.grass,
];

bool _same(Color a, Color b) => a.toARGB32() == b.toARGB32();

_Fill? _fillOf(Element ancestor) {
  final widget = ancestor.widget;
  Color? colour;
  var source = FillSource.decoration;
  if (widget is ColoredBox) {
    colour = widget.color;
    source = FillSource.coloredBox;
  } else if (widget is DecoratedBox &&
      widget.position == DecorationPosition.background) {
    final decoration = widget.decoration;
    if (decoration is BoxDecoration) colour = decoration.color;
    if (decoration is ShapeDecoration) colour = decoration.color;
  } else if (widget is Material && widget.type != MaterialType.transparency) {
    final theme = Theme.of(ancestor);
    colour =
        widget.color ??
        (widget.type == MaterialType.canvas
            ? theme.canvasColor
            : theme.colorScheme.surface);
    source = FillSource.material;
  } else if (widget is Scaffold) {
    colour =
        widget.backgroundColor ?? Theme.of(ancestor).scaffoldBackgroundColor;
    source = FillSource.scaffold;
  }
  if (colour == null || colour.a == 0) return null;
  return _Fill(colour, source);
}
