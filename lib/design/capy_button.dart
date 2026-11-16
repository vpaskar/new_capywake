import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// The chunky orange CTA from the mockups, with the darker lower edge.
///
/// Measured from `01_HOME.png`: 370.4 x 55.4 pt inside an 11 pt gutter. The
/// lower edge is a solid band of [CapyColors.accentDeep], not a shadow.
class CapyButton extends StatefulWidget {
  const CapyButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  static const height = 55.4;
  static const edgeThickness = 4.0;

  @override
  State<CapyButton> createState() => _CapyButtonState();
}

class _CapyButtonState extends State<CapyButton> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final sink = _down && _enabled ? CapyButton.edgeThickness : 0.0;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _down = false) : null,
          onTapCancel: _enabled ? () => setState(() => _down = false) : null,
          onTap: widget.onPressed,
          child: SizedBox(
            height: CapyButton.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _enabled
                          ? CapyColors.accentDeep
                          : CapyColors.cocoaSoft,
                      borderRadius: BorderRadius.circular(CapyRadius.pill),
                    ),
                  ),
                ),
                Positioned(
                  top: sink,
                  left: 0,
                  right: 0,
                  bottom: CapyButton.edgeThickness - sink,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _enabled
                          ? CapyColors.accent
                          : CapyColors.cocoaSoft.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(CapyRadius.pill),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.icon,
                                size: 18,
                                color: CapyColors.accentDeep,
                              ),
                            ),
                            const SizedBox(width: CapySpacing.md),
                          ],
                          Flexible(
                            child: Text(
                              widget.label,
                              style: CapyType.section.copyWith(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
