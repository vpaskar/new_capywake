import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/settings/settings_header.dart';
import 'package:capywake/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';

/// A pushed puzzle screen with a compact header and no hero: Games, Puzzle
/// types and Advanced (`03`–`05`).
class PuzzleSubpage extends StatelessWidget {
  const PuzzleSubpage({
    required this.title,
    required this.children,
    this.glyph,
    super.key,
  });

  final String title;
  final Widget? glyph;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsHeader(
            title: title,
            height: SettingsHeader.compactHeight,
            glyph: glyph,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(
                CapySpacing.gutterWide,
                CapySpacing.sm,
                CapySpacing.gutterWide,
                CapySpacing.lg,
              ),
              children: children,
            ),
          ),
          const MeadowFooter(height: SettingsScreen.meadowHeight),
        ],
      ),
    );
  }
}

class PuzzleHeaderGlyph extends StatelessWidget {
  const PuzzleHeaderGlyph(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Icon(
      icon,
      size: CapyIconSize.wordmark,
      color: dark ? CapyColors.darkInk : CapyColors.cocoa,
    );
  }
}

class PuzzleHelpText extends StatelessWidget {
  const PuzzleHelpText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft,
      ),
    );
  }
}

/// A group label on `04` and `05`: "Difficulty", "Numbers and sequences".
class PuzzleSectionLabel extends StatelessWidget {
  const PuzzleSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: CapySpacing.lg,
        bottom: CapySpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: dark ? CapyColors.darkInk : CapyColors.cocoa,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
