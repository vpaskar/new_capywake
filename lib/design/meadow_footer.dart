import 'dart:math' as math;

import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// The grass band above the nav bar, 65.2 pt in `01_HOME.png`. Drawn, not
/// bundled: asset gap G13 — no supplied decor is the right shape.
class MeadowFooter extends StatelessWidget {
  const MeadowFooter({this.height = defaultHeight, super.key});

  /// `01_HOME.png`'s band. `02_ALARMS.png` draws 52.2, so each screen passes
  /// its own measurement rather than inheriting Home's.
  static const defaultHeight = 65.2;

  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _MeadowPainter(
            dark: Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      ),
    );
  }
}

class _MeadowPainter extends CustomPainter {
  const _MeadowPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final back = Paint()
      ..color = dark
          ? CapyColors.grass.withValues(alpha: 0.35)
          : CapyColors.grass.withValues(alpha: 0.55);
    final front = Paint()
      ..color = dark
          ? CapyColors.grass.withValues(alpha: 0.55)
          : CapyColors.grass;

    canvas
      ..drawPath(_hills(size, amplitude: 14, phase: 0, top: 0.18), back)
      ..drawPath(_hills(size, amplitude: 10, phase: 1.7, top: 0.42), front);
  }

  /// Three broad crowns with shallow dips, as the mockup's silhouette reads.
  Path _hills(
    Size size, {
    required double amplitude,
    required double phase,
    required double top,
  }) {
    final baseY = size.height * top + amplitude;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, baseY);

    const steps = 48;
    const crowns = 3;
    const ripples = 7;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = t * size.width;
      final wave =
          -amplitude * math.cos(t * crowns * 2 * math.pi + phase) * 0.5 -
          amplitude * math.cos(t * ripples * 2 * math.pi + phase * 2) * 0.18;
      path.lineTo(x, baseY + wave);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(_MeadowPainter oldDelegate) => oldDelegate.dark != dark;
}
