import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

@immutable
class CapyNavDestination {
  const CapyNavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The three-tab bottom bar.
///
/// The mockup draws flat single-colour glyphs — orange active, cocoa inactive
/// — not illustrations, so these are real icons with a token colour rather
/// than bundled art.
class CapyNavBar extends StatelessWidget {
  const CapyNavBar({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final List<CapyNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const height = 64.6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactive = theme.brightness == Brightness.dark
        ? CapyColors.darkInkSoft
        : CapyColors.cocoaSoft;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: SizedBox(
        height: CapyNavBar.height,
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _Tab(
                  destination: destinations[i],
                  selected: i == currentIndex,
                  inactiveColor: inactive,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.destination,
    required this.selected,
    required this.inactiveColor,
    required this.onTap,
  });

  final CapyNavDestination destination;
  final bool selected;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? CapyColors.accent : inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(destination.icon, color: color, size: CapyIconSize.md),
              const SizedBox(height: CapySpacing.xs),
              Text(
                destination.label,
                style: CapyType.caption.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
