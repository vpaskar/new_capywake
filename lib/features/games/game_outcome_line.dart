import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// A game's last result, announced. As tall as its tallest possible result,
/// so a result appearing never moves Snooze or the escape below.
class GameOutcomeLine extends StatefulWidget {
  const GameOutcomeLine({
    required this.text,
    this.serial,
    this.reserveFor = const [],
    super.key,
  });

  final String? text;

  /// Every result this game can show.
  final List<String> reserveFor;

  /// Counts the user's answers: a new one with the same [text] is announced
  /// again, which a live region alone would swallow.
  final int? serial;

  static const reservedLines = 2;

  @override
  State<GameOutcomeLine> createState() => _GameOutcomeLineState();
}

class _GameOutcomeLineState extends State<GameOutcomeLine> {
  @override
  void didUpdateWidget(GameOutcomeLine old) {
    super.didUpdateWidget(old);
    final text = widget.text;
    if (text != null && text == old.text && widget.serial != old.serial) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        text,
        Directionality.of(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = CapyType.body.copyWith(
      color: dark ? CapyColors.darkInk : CapyColors.cocoa,
    );
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    double heightOf(String text, double width) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: TextAlign.center,
        textDirection: direction,
        textScaler: scaler,
      )..layout(maxWidth: width);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: [
            heightOf(' ', constraints.maxWidth) * GameOutcomeLine.reservedLines,
            for (final text in widget.reserveFor)
              heightOf(text, constraints.maxWidth),
          ].reduce((a, b) => a > b ? a : b),
        ),
        child: _announced(style),
      ),
    );
  }

  Widget _announced(TextStyle style) => Semantics(
    liveRegion: true,
    child: Text(
      widget.text ?? '',
      key: const ValueKey('game-outcome-line'),
      textAlign: TextAlign.center,
      style: style,
    ),
  );
}
