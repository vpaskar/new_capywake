import 'dart:async';

import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// Fires only after a sustained press; releasing early returns it to rest,
/// never escalates. The fill is a tick, not an animation. See PHASE_06_PLAN.
class HoldToActButton extends StatefulWidget {
  const HoldToActButton({
    required this.label,
    required this.onCompleted,
    this.holdDuration = defaultHold,
    this.filled = true,
    super.key,
  });

  /// Past a sleepy reflex, short of making someone in trouble wait.
  static const defaultHold = Duration(milliseconds: 1200);

  static const tick = Duration(milliseconds: 50);
  static const height = 55.4;

  final String label;
  final VoidCallback onCompleted;
  final Duration holdDuration;

  /// Filled accent, or the quieter treatment for a secondary control.
  final bool filled;

  @override
  State<HoldToActButton> createState() => _HoldToActButtonState();
}

class _HoldToActButtonState extends State<HoldToActButton> {
  Timer? _timer;
  Duration _held = Duration.zero;

  double get _progress => widget.holdDuration.inMicroseconds == 0
      ? 1
      : (_held.inMicroseconds / widget.holdDuration.inMicroseconds).clamp(
          0.0,
          1.0,
        );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _held = Duration.zero);
    _timer = Timer.periodic(HoldToActButton.tick, (_) {
      setState(() => _held += HoldToActButton.tick);
      if (_held >= widget.holdDuration) _complete();
    });
  }

  void _complete() {
    _timer?.cancel();
    _timer = null;
    setState(() => _held = Duration.zero);
    widget.onCompleted();
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    setState(() => _held = Duration.zero);
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.filled ? CapyColors.accent : CapyColors.surfaceAlt;
    final fill = widget.filled ? CapyColors.accentDeep : CapyColors.accent;

    // A screen reader cannot hold: its activation is already deliberate.
    return Semantics(
      button: true,
      label: widget.label,
      onTap: _complete,
      onLongPress: _complete,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapDown: (_) => _start(),
          onTapUp: (_) => _cancel(),
          onTapCancel: _cancel,
          child: SizedBox(
            height: HoldToActButton.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CapyRadius.pill),
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: base)),
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress,
                      child: ColoredBox(color: fill),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CapySpacing.lg,
                      ),
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: CapyType.label.copyWith(
                          color: widget.filled
                              ? Colors.white
                              : CapyColors.cocoa,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
