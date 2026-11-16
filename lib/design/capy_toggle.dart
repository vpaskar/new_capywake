import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// The switch from `01_HOME.png`, 59.6 x 34.6 pt. Constraint F1: `success`
/// is under 3:1, so knob position and semantics carry state, not colour.
class CapyToggle extends StatelessWidget {
  const CapyToggle({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  static const width = 59.6;
  static const height = 34.6;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final track = value
        ? CapyColors.success
        : (dark ? CapyColors.darkSurfaceAlt : CapyColors.cocoaSoft);
    const knobInset = (height - _knob) / 2;

    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          // Tier A binds the mockup's 34.6pt paint; the hit area still has to
          // be reachable half-asleep, so only it grows to 44pt.
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: width,
            height: minTapTarget,
            child: Center(child: _track(track, knobInset)),
          ),
        ),
      ),
    );
  }

  Widget _track(Color track, double knobInset) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(CapyRadius.pill),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: knobInset,
              start: value ? width - _knob - knobInset : knobInset,
              child: Container(
                width: _knob,
                height: _knob,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _knob = 28.0;

  /// Minimum reachable tap target. The paint stays at the mockup's size.
  static const minTapTarget = 44.0;
}
