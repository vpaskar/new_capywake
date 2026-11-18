import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// A game's last result, announced. Always two body lines tall at the current
/// text scale, so a result appearing never moves Snooze or the escape below.
class GameOutcomeLine extends StatefulWidget {
  const GameOutcomeLine({required this.text, this.serial, super.key});

  final String? text;

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
    final line = TextPainter(
      text: TextSpan(text: ' ', style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final lineHeight = line.height;
    line.dispose();

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: lineHeight * GameOutcomeLine.reservedLines,
      ),
      child: Semantics(
        liveRegion: true,
        child: Text(
          widget.text ?? '',
          key: const ValueKey('game-outcome-line'),
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }
}
