import 'dart:async';
import 'dart:math' as math;

import 'package:capywake/core/games/tilt_maze.dart';
import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/core/motion/tilt_reader.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/game_header.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Tilt Maze: tilt the phone, or tap the arrows, to roll Capy to the flag.
/// The maze is a map, so left and right stay physical in every language.
class TiltMazeView extends GameRingingView {
  const TiltMazeView({
    required this.seed,
    required this.difficulty,
    required this.motion,
    required super.onProgress,
    required super.onCompleted,
    required super.reduceMotion,
    super.key,
  });

  TiltMazeView.fromLaunch(GameLaunch launch, {Key? key})
    : this(
        seed: launch.seed,
        difficulty: launch.difficulty,
        motion: launch.motion,
        onProgress: launch.onProgress,
        onCompleted: launch.onCompleted,
        reduceMotion: launch.reduceMotion,
        key: key,
      );

  final int seed;
  final PuzzleDifficulty difficulty;
  final MotionSensor motion;

  static const fieldHeight = 142.0;
  static const wallWidth = 4.0;
  static const arrowWidth = 64.0;
  static const arrowMinWidth = 48.0;
  static const arrowHeight = 56.0;
  static const double arrowGap = CapySpacing.sm;
  static const wobble = Duration(milliseconds: 360);
  static const wobbleShift = 4.0;

  /// Left to right as drawn: the arrows sit in their physical order.
  static const List<TiltDirection> arrowOrder = [
    TiltDirection.left,
    TiltDirection.up,
    TiltDirection.down,
    TiltDirection.right,
  ];

  Duration get roll => TiltMazeRound.rollFor(difficulty);

  @override
  State<TiltMazeView> createState() => _TiltMazeViewState();
}

class _TiltMazeViewState extends State<TiltMazeView> {
  late TiltMazeRound _round = TiltMazeRound.start(
    difficulty: widget.difficulty,
    seed: widget.seed,
  );
  final _reader = TiltReader();
  StreamSubscription<MotionSample>? _samples;
  Timer? _roll;
  TiltDirection? _rolling;
  bool _movedThisHold = false;
  bool _screenReader = false;
  bool _completionReported = false;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(TiltMazeView old) {
    super.didUpdateWidget(old);
    if (old.motion != widget.motion) _listen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      unawaited(
        precacheImage(
          AssetImage(CapyArt.byId('game.capy.curledAsleep').path),
          context,
        ),
      );
    }
    _screenReader = MediaQuery.accessibleNavigationOf(context);
    if (_screenReader) _letGo();
  }

  @override
  void dispose() {
    unawaited(_samples?.cancel());
    _roll?.cancel();
    super.dispose();
  }

  bool get _moves => !widget.reduceMotion && !_screenReader;

  void _listen() {
    unawaited(_samples?.cancel());
    _samples = _round.isComplete
        ? null
        : widget.motion.samples.listen(_onSample, onError: (Object _) {});
  }

  void _onSample(MotionSample sample) {
    if (_screenReader || _round.isComplete) return;
    final held = _reader.read(sample);
    if (held == _rolling) return;
    _roll?.cancel();
    _rolling = held;
    _movedThisHold = false;
    if (held != null) _rollStep();
  }

  /// One cell, then the next while the tilt is held. A hold that already
  /// moved stops quietly at a wall; only a hold that cannot move is a bump.
  void _rollStep() {
    final direction = _rolling!;
    if (!_round.canMove(direction)) {
      if (!_movedThisHold) _apply(_round.move(direction));
      return;
    }
    _movedThisHold = true;
    _apply(_round.move(direction));
    if (_rolling != null) {
      _roll = Timer(widget.roll, () {
        if (mounted && _rolling != null) _rollStep();
      });
    }
  }

  void _letGo() {
    _roll?.cancel();
    _rolling = null;
    _reader.suppressUntilLevel();
  }

  /// An arrow press sets tilt aside until the phone is level, so the two
  /// never fight and letting go of a tilt is not read as the reverse.
  void _press(TiltDirection direction) {
    _letGo();
    _apply(_round.move(direction));
  }

  void _apply(TiltMazeRound next) {
    if (identical(next, _round)) return;
    setState(() => _round = next);
    widget.onProgress(next.challenge);
    if (next.lastOutcome == TiltMazeOutcome.escaped) _letGo();
    if (next.isComplete && !_completionReported) {
      _completionReported = true;
      unawaited(_samples?.cancel());
      _samples = null;
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outcome = switch (_round.lastOutcome) {
      TiltMazeOutcome.bumped => l10n.gameTiltMazeBumped,
      TiltMazeOutcome.escaped => l10n.gameTiltMazeEscaped,
      _ => l10n.gameTiltMazeSteps(_round.stepsToFlag),
    };

    return CapyCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameHeader(
            title: l10n.gameTiltMaze,
            instruction: _screenReader
                ? l10n.gameTiltMazeInstructionArrows
                : l10n.gameTiltMazeInstruction,
            done: _round.solved,
            total: TiltMazeRound.target,
          ),
          const SizedBox(height: CapySpacing.md),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: TiltMazeView.fieldHeight,
                  child: ExcludeSemantics(
                    child: LayoutBuilder(
                      builder: (context, constraints) =>
                          _field(width: constraints.maxWidth),
                    ),
                  ),
                ),
                const SizedBox(height: CapySpacing.sm),
                _arrows(l10n),
              ],
            ),
          ),
          const SizedBox(height: CapySpacing.sm),
          GameOutcomeLine(
            text: _round.isComplete ? null : outcome,
            serial: _round.moves,
            reserveFor: [
              for (final count in {1, 2, 5, _round.maze.cellCount - 1})
                l10n.gameTiltMazeSteps(count),
              l10n.gameTiltMazeBumped,
              l10n.gameTiltMazeEscaped,
            ],
          ),
        ],
      ),
    );
  }

  Widget _field({required double width}) {
    final maze = _round.maze;
    final cell = math.min(
      width / maze.columns,
      TiltMazeView.fieldHeight / maze.rows,
    );
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;

    return Center(
      child: SizedBox(
        key: ValueKey(('tilt-maze-field', _round.solved)),
        width: cell * maze.columns,
        height: cell * maze.rows,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: dark
                      ? CapyColors.darkSurfaceAlt
                      : CapyColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(CapyRadius.sm),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                key: const ValueKey('tilt-maze-walls'),
                painter: _MazePainter(maze, color: ink),
              ),
            ),
            _at(
              maze.flag,
              cell,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: CapyColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(CapySpacing.xs),
                  child: Icon(
                    Icons.flag_rounded,
                    key: const ValueKey('tilt-maze-flag'),
                    size: cell * 0.5,
                    color: CapyColors.cocoa,
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              key: ValueKey(('tilt-maze-capy', _round.solved)),
              duration: _moves ? widget.roll : Duration.zero,
              curve: Curves.easeOut,
              left: (_round.position % maze.columns) * cell,
              top: (_round.position ~/ maze.columns) * cell,
              width: cell,
              height: cell,
              child: _capy(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _at(int index, double cell, {required Widget child}) {
    final columns = _round.maze.columns;
    return Positioned(
      left: (index % columns) * cell,
      top: (index ~/ columns) * cell,
      width: cell,
      height: cell,
      child: Center(child: child),
    );
  }

  Widget _capy() {
    final image = Padding(
      padding: const EdgeInsets.all(TiltMazeView.wallWidth),
      child: Image.asset(
        CapyArt.byId('game.capy.curledAsleep').path,
        key: const ValueKey('tilt-maze-capy'),
        fit: BoxFit.contain,
      ),
    );
    if (!_moves || _round.bumps == 0) return image;
    return TweenAnimationBuilder<double>(
      key: ValueKey(('wobble', _round.bumps)),
      tween: Tween(begin: 0, end: 1),
      duration: TiltMazeView.wobble,
      builder: (context, w, child) => Transform.translate(
        offset: Offset(
          TiltMazeView.wobbleShift * math.sin(w * math.pi * 4) * (1 - w),
          0,
        ),
        child: child,
      ),
      child: image,
    );
  }

  /// Four arrows share the row and narrow on a small phone, never under
  /// [TiltMazeView.arrowMinWidth].
  Widget _arrows(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const count = 4;
        final width = math.max(
          TiltMazeView.arrowMinWidth,
          math.min(
            TiltMazeView.arrowWidth,
            (constraints.maxWidth - TiltMazeView.arrowGap * (count - 1)) /
                count,
          ),
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (i, direction) in TiltMazeView.arrowOrder.indexed) ...[
              if (i > 0) const SizedBox(width: TiltMazeView.arrowGap),
              _arrow(l10n, direction, width: width),
            ],
          ],
        );
      },
    );
  }

  Widget _arrow(
    AppLocalizations l10n,
    TiltDirection direction, {
    required double width,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final paper = dark ? CapyColors.darkSurface : CapyColors.surface;
    final name = switch (direction) {
      TiltDirection.up => l10n.gameTiltMazeUp,
      TiltDirection.down => l10n.gameTiltMazeDown,
      TiltDirection.left => l10n.gameTiltMazeLeft,
      TiltDirection.right => l10n.gameTiltMazeRight,
    };
    final icon = switch (direction) {
      TiltDirection.up => Icons.arrow_upward_rounded,
      TiltDirection.down => Icons.arrow_downward_rounded,
      TiltDirection.left => Icons.arrow_back_rounded,
      TiltDirection.right => Icons.arrow_forward_rounded,
    };
    final done = _round.isComplete;
    void tap() => _press(direction);

    return Semantics(
      button: true,
      enabled: !done,
      label: _round.canMove(direction) ? name : l10n.gameTiltMazeWall(name),
      onTap: done ? null : tap,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('tilt-maze-${direction.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: done ? null : tap,
        child: Container(
          width: width,
          height: TiltMazeView.arrowHeight,
          decoration: BoxDecoration(
            color: paper,
            borderRadius: BorderRadius.circular(CapyRadius.pill),
            border: Border.all(color: ink, width: 1.5),
          ),
          child: Icon(icon, color: ink),
        ),
      ),
    );
  }
}

class _MazePainter extends CustomPainter {
  _MazePainter(this.maze, {required this.color});

  final MazeGrid maze;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / maze.columns;
    final paint = Paint()
      ..color = color
      ..strokeWidth = TiltMazeView.wallWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(CapyRadius.sm),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = TiltMazeView.wallWidth,
    );
    for (var index = 0; index < maze.cellCount; index++) {
      final x = (index % maze.columns) * cell;
      final y = (index ~/ maze.columns) * cell;
      if (maze.neighbour(index, TiltDirection.right) != null &&
          !maze.isOpen(index, TiltDirection.right)) {
        canvas.drawLine(
          Offset(x + cell, y),
          Offset(x + cell, y + cell),
          paint,
        );
      }
      if (maze.neighbour(index, TiltDirection.down) != null &&
          !maze.isOpen(index, TiltDirection.down)) {
        canvas.drawLine(
          Offset(x, y + cell),
          Offset(x + cell, y + cell),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MazePainter old) =>
      old.maze != maze || old.color != color;
}
