import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// A game's last result, announced. Always two body lines tall at the current
/// text scale, so a result appearing never moves Snooze or the escape below.
class GameOutcomeLine extends StatelessWidget {
  const GameOutcomeLine({required this.text, super.key});

  final String? text;

  static const reservedLines = 2;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = CapyType.body.copyWith(
      color: dark ? CapyColors.darkInk : CapyColors.cocoa,
    );
    final line = TextPainter(
      text: TextSpan(text: ' ', style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final lineHeight = line.height;
    line.dispose();

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: lineHeight * reservedLines),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text ?? '',
          key: const ValueKey('game-outcome-line'),
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }
}
