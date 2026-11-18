import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// The app's switch. `success` is under 3:1, so knob position and semantics
/// carry state. [trackSize] is required: four mockups, four switches.
class CapyToggle extends StatelessWidget {
  const CapyToggle({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    required this.trackSize,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  /// The painted track. One of the measured sizes below, never a literal.
  final Size trackSize;

  /// `01_HOME.png`: x 303.0-363.0, y 325.0-360.5 by per-row green anchor.
  static const homeTrack = Size(59.6, 34.6);

  /// `02_ALARMS.png`: x 294.2-348.2, y 356.5-388.5 by the same method.
  static const alarmsTrack = Size(54, 32);

  /// `03_ADD_EDIT_ALARM.png` snooze row: x 319.6-367.6, y 666.9-695.1.
  static const alarmEditTrack = Size(48, 28.2);

  /// `04_SETTINGS.png`: x 321.9-366.2, y 520.5-545.5 by the same method.
  static const settingsTrack = Size(44.3, 25);

  /// Home's 34.6pt track carries a 28pt knob. Constant across sizes, so the
  /// knob scales with the track and the breathing room does not.
  static const double _knobInset = 3.3;

  /// Minimum reachable tap target. The paint stays at the mockup's size.
  static const double minTapTarget = 44;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final track = value
        ? CapyColors.success
        : (dark ? CapyColors.darkSurfaceAlt : CapyColors.cocoaSoft);
    final knob = trackSize.height - _knobInset * 2;

    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          // Tier A binds the mockup's painted track; the hit area still has to
          // be reachable half-asleep, so only it grows to 44pt.
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: trackSize.width,
            height: minTapTarget,
            child: Center(child: _track(track, knob)),
          ),
        ),
      ),
    );
  }

  Widget _track(Color track, double knob) {
    return SizedBox(
      width: trackSize.width,
      height: trackSize.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(CapyRadius.pill),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: _knobInset,
              start: value ? trackSize.width - knob - _knobInset : _knobInset,
              child: Container(
                width: knob,
                height: knob,
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
}
