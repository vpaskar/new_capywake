import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// One choice in a [CapySegmented].
class CapySegment<T> {
  const CapySegment({
    required this.value,
    required this.label,
    this.semanticLabel,
  });

  final T value;
  final String label;

  /// Read instead of [label], e.g. "2 puzzles" for a bare "2".
  final String? semanticLabel;
}

/// A pill of equal segments, the selected one filled green with a check-free
/// white label. Labels wrap rather than truncate; every segment is ≥ 44 pt.
class CapySegmented<T> extends StatelessWidget {
  const CapySegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<CapySegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  static const double minHeight = CapyToggle.minTapTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final line = (dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft)
        .withValues(alpha: 0.45);
    final radius = BorderRadius.circular(CapyRadius.pill);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? CapyColors.darkSurface : CapyColors.surface,
        borderRadius: radius,
        border: Border.all(color: line),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0) VerticalDivider(width: 1, thickness: 1, color: line),
                Expanded(
                  child: _Segment(
                    label: segments[i].label,
                    semanticLabel: segments[i].semanticLabel,
                    selected: segments[i].value == selected,
                    ink: ink,
                    onTap: () => onChanged(segments[i].value),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final String? semanticLabel;
  final bool selected;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: semanticLabel ?? label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? CapyColors.successDeep : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: CapySegmented.minHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CapySpacing.xs,
                  vertical: CapySpacing.xs,
                ),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected ? Colors.white : ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
