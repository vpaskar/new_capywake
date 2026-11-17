import 'package:capywake/design/art.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// The grass band above the nav bar, the owner's painted meadow strip.
class MeadowFooter extends StatelessWidget {
  const MeadowFooter({this.height = defaultHeight, super.key});

  /// `01_HOME.png`'s band. `02_ALARMS.png` draws 52.2, so each screen passes
  /// its own measurement rather than inheriting Home's.
  static const defaultHeight = 65.2;

  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRect(
          child: ColorFiltered(
            colorFilter: dark
                ? const ColorFilter.mode(CapyColors.artScrim, BlendMode.srcATop)
                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: Image.asset(
              CapyArt.meadowFooter.path,
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }
}
