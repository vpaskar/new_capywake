import 'package:capywake/design/art.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// An alarm's chosen picture, filling its box; the plain placeholder when the
/// user picked none.
class AlarmArtPanel extends StatelessWidget {
  const AlarmArtPanel({required this.artId, required this.index, super.key});

  final String? artId;
  final int index;

  static const placeholderMascotSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final art = CapyArt.alarmThumbnail(artId: artId, index: index);

    if (art == null) {
      return ColoredBox(
        key: const ValueKey('alarm-art-placeholder'),
        color: dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt,
        child: Center(
          child: Image.asset(
            CapyArt.byId('mascot.sleeping').path,
            height: placeholderMascotSize,
          ),
        ),
      );
    }

    return ColorFiltered(
      colorFilter: dark
          ? const ColorFilter.mode(CapyColors.artScrim, BlendMode.srcOver)
          : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
      child: Image.asset(art.path, key: ValueKey(art.id), fit: BoxFit.cover),
    );
  }
}
