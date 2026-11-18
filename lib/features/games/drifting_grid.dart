import 'dart:async';

import 'package:capywake/core/games/game_drift.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/widgets.dart';

/// How a [DriftingGrid] moves its cards on each beat.
enum DriftStyle {
  /// Two movable cards trade places.
  swap,

  /// Every card steps one place round the grid, so none stands out moving.
  carousel,
}

/// A fixed grid whose cards drift on every [swapEvery] beat. Never while a
/// finger is down, and not at all unless [moves].
class DriftingGrid extends StatefulWidget {
  const DriftingGrid({
    required this.cellCount,
    required this.columns,
    required this.cellHeightFor,
    required this.cellBuilder,
    required this.moves,
    required this.swapEvery,
    required this.seed,
    required this.generation,
    this.canMove,
    this.style = DriftStyle.swap,
    super.key,
  });

  final int cellCount;
  final int columns;
  final double Function(double cellWidth) cellHeightFor;
  final Widget Function(BuildContext context, int cell) cellBuilder;

  /// Read every build: turning false stops the drift and puts every card back.
  final bool moves;
  final Duration swapEvery;
  final int seed;

  /// New content: cards start over in their own places, without sliding.
  final int generation;

  /// Whether a card may still drift; every card may when `null`.
  final bool Function(int cell)? canMove;
  final DriftStyle style;

  static const double gap = CapySpacing.sm;

  /// One swap's slide. Slow enough to follow half-asleep.
  static const Duration slide = Duration(milliseconds: 450);

  @override
  State<DriftingGrid> createState() => _DriftingGridState();
}

class _DriftingGridState extends State<DriftingGrid>
    with SingleTickerProviderStateMixin {
  late List<int> _slotOf = _identity();

  /// Where each card rested when the slide began: a tap mid-slide goes to the
  /// card the user aimed at, not to whatever is passing under the finger.
  late List<int> _restingSlotOf = _identity();
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: DriftingGrid.slide,
  )..addStatusListener(_settled);
  late GameDrift _drift = GameDrift(widget.seed);
  Timer? _timer;
  int _pointersDown = 0;

  List<int> _identity() => List.generate(widget.cellCount, (i) => i);

  @override
  void initState() {
    super.initState();
    _schedule(widget.swapEvery);
  }

  @override
  void didUpdateWidget(DriftingGrid old) {
    super.didUpdateWidget(old);
    final reset =
        old.generation != widget.generation ||
        old.cellCount != widget.cellCount;
    if (reset || !widget.moves) {
      _timer?.cancel();
      _timer = null;
      _slide
        ..stop()
        ..value = 0;
      _slotOf = _identity();
      _restingSlotOf = _identity();
    }
    if (_timer == null) _schedule(widget.swapEvery);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slide.dispose();
    super.dispose();
  }

  void _schedule(Duration after) {
    _timer?.cancel();
    _timer = null;
    if (!widget.moves || _pointersDown > 0) return;
    _timer = Timer(after, _swap);
  }

  void _settled(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    setState(() {
      _restingSlotOf = List.of(_slotOf);
      _slide.value = 0;
    });
  }

  void _startSlide() {
    _restingSlotOf = List.of(_slotOf);
    unawaited(_slide.forward(from: 0));
  }

  void _swap() {
    _timer = null;
    if (!mounted || !widget.moves || _pointersDown > 0) return;
    if (widget.style == DriftStyle.carousel) {
      final ring = _ring();
      setState(() {
        _startSlide();
        for (var cell = 0; cell < widget.cellCount; cell++) {
          _slotOf[cell] = ring[(ring.indexOf(_slotOf[cell]) + 1) % ring.length];
        }
      });
      _schedule(DriftingGrid.slide + widget.swapEvery);
      return;
    }
    final movable = [
      for (var cell = 0; cell < widget.cellCount; cell++)
        if (widget.canMove?.call(cell) ?? true) cell,
    ];
    final step = _drift.next(movable);
    if (step == null) return;
    final (a, b, next) = step;
    setState(() {
      _startSlide();
      _drift = next;
      final slotA = _slotOf[a];
      _slotOf[a] = _slotOf[b];
      _slotOf[b] = slotA;
    });
    _schedule(DriftingGrid.slide + widget.swapEvery);
  }

  /// Slots in walking order, rows alternating direction, so on two rows each
  /// step is to a neighbour.
  List<int> _ring() {
    final columns = widget.columns;
    final rows = (widget.cellCount / columns).ceil();
    return [
      for (var row = 0; row < rows; row++)
        for (var i = 0; i < columns; i++)
          row * columns + (row.isEven ? i : columns - 1 - i),
    ];
  }

  Offset _travel(BuildContext context, Offset logical, double t) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Offset(rtl ? -logical.dx : logical.dx, logical.dy) * t;
  }

  void _pointerDown(PointerDownEvent _) {
    _pointersDown++;
    _timer?.cancel();
    _timer = null;
  }

  void _pointerUp(PointerEvent _) {
    if (_pointersDown > 0) _pointersDown--;
    if (_pointersDown == 0) _schedule(widget.swapEvery);
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.columns;
    final rows = (widget.cellCount / columns).ceil();
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _pointerDown,
      onPointerUp: _pointerUp,
      onPointerCancel: _pointerUp,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = DriftingGrid.gap;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          final height = widget.cellHeightFor(width);
          return SizedBox(
            height: rows * height + (rows - 1) * gap,
            child: AnimatedBuilder(
              animation: _slide,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_slide.value);
                Offset at(int slot) => Offset(
                  (slot % columns) * (width + gap),
                  (slot ~/ columns) * (height + gap),
                );
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var cell = 0; cell < widget.cellCount; cell++)
                      PositionedDirectional(
                        key: ValueKey('drift-${widget.generation}-$cell'),
                        start: at(_restingSlotOf[cell]).dx,
                        top: at(_restingSlotOf[cell]).dy,
                        width: width,
                        height: height,
                        child: Transform.translate(
                          offset: _travel(
                            context,
                            at(_slotOf[cell]) - at(_restingSlotOf[cell]),
                            t,
                          ),
                          transformHitTests: false,
                          child: widget.cellBuilder(context, cell),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
