import 'package:capywake/design/art.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// A heading and a sentence for a segment with nothing to show. Each of the
/// three reasons states its own fact rather than sharing one vague line.
class StatsNotice extends StatelessWidget {
  const StatsNotice({required this.title, required this.body, super.key});

  final String title;
  final String body;

  static const artHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CapySpacing.xl,
        vertical: CapySpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              CapyArt.emptyStateMascot.path,
              height: artHeight,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: CapySpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: CapyType.section.copyWith(color: ink),
          ),
          const SizedBox(height: CapySpacing.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: CapyType.body.copyWith(color: inkSoft),
          ),
        ],
      ),
    );
  }
}
