import 'dart:async';
import 'dart:math' as math;

import 'package:capywake/core/games/catch_the_capy.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/game_header.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Catch the Capy: a capybara galloping round the meadow. Under reduce-motion
/// or a screen reader it holds still and moves only when caught.
class CatchTheCapyView extends GameRingingView {
  const CatchTheCapyView({
    required this.seed,
    required this.difficulty,
    required super.onProgress,
    required super.onCompleted,
    required super.reduceMotion,
    super.key,
  });

  CatchTheCapyView.fromLaunch(GameLaunch launch, {Key? key})
    : this(
        seed: launch.seed,
        difficulty: launch.difficulty,
        onProgress: launch.onProgress,
        onCompleted: launch.onCompleted,
        reduceMotion: launch.reduceMotion,
        key: key,
      );

  final int seed;
  final PuzzleDifficulty difficulty;

  /// A fixed box: the ringing slot scrolls, so its height is unbounded.
  static const fieldHeight = 280.0;

  /// The tap box round the running capybara; the frames are 1.2 : 1.
  static const capyWidth = 96.0;
  static const capyHeight = 88.0;

  /// Where the meadow's grass starts, as a share of the field: the capybara's
  /// feet stay below it, never in the sky.
  static const groundTop = 0.22;

  /// Leg cycles per run, so faster runs also move the legs faster.
  static const strides = 2;

  /// A short footfall beat between runs — it never rests longer.
  static const footfall = Duration(milliseconds: 150);

  Duration get run => CatchTheCapyRound.runFor(difficulty);
  Duration get wanderInterval => run + footfall;

  @override
  State<CatchTheCapyView> createState() => _CatchTheCapyViewState();
}

class _CatchTheCapyViewState extends State<CatchTheCapyView> {
  late CatchTheCapyRound _round = CatchTheCapyRound.start(
    difficulty: widget.difficulty,
    seed: widget.seed,
  );
  bool _completionReported = false;
  bool _facingStart = false;
  late int _from = _round.spot;
  Timer? _wander;

  bool get _moves =>
      !widget.reduceMotion && !MediaQuery.accessibleNavigationOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleWander();
  }

  @override
  void dispose() {
    _wander?.cancel();
    super.dispose();
  }

  void _scheduleWander() {
    _wander?.cancel();
    if (!_moves || _round.isComplete) return;
    _wander = Timer(widget.wanderInterval, () {
      if (!mounted) return;
      _move(_round.wander());
      _scheduleWander();
    });
  }

  void _move(CatchTheCapyRound next) {
    setState(() {
      if (next.column != _round.column) {
        _facingStart = next.column < _round.column;
      }
      _from = _round.spot;
      _round = next;
    });
  }

  void _update(CatchTheCapyRound next) {
    if (identical(next, _round)) return;
    _move(next);
    widget.onProgress(next.challenge);
    if (next.isComplete && !_completionReported) {
      _completionReported = true;
      _wander?.cancel();
      widget.onCompleted();
      return;
    }
    _scheduleWander();
  }

  /// A miss counts; while the capybara moves, it also bolts away from the tap.
  void _onMeadowTap(Offset at, {required double width}) {
    final missed = _round.miss();
    if (!_moves || missed.isComplete) {
      _update(missed);
      return;
    }
    final column = (at.dx / width * CatchTheCapyRound.columns).floor().clamp(
      0,
      CatchTheCapyRound.columns - 1,
    );
    final row = (at.dy / CatchTheCapyView.fieldHeight * CatchTheCapyRound.rows)
        .floor()
        .clamp(0, CatchTheCapyRound.rows - 1);
    final ltrColumn = Directionality.of(context) == TextDirection.rtl
        ? CatchTheCapyRound.columns - 1 - column
        : column;
    _update(missed.fleeFrom(column: ltrColumn, row: row));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CapyCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameHeader(
            title: l10n.gameCatchTheCapy,
            instruction: l10n.gameCatchTheCapyInstruction(_round.target),
            done: _round.caught,
            total: _round.target,
          ),
          const SizedBox(height: CapySpacing.md),
          SizedBox(
            height: CatchTheCapyView.fieldHeight,
            child: LayoutBuilder(
              builder: (context, constraints) => _field(
                l10n,
                width: constraints.maxWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Offset _spotAt(int spot, double width) {
    const w = CatchTheCapyView.capyWidth;
    const h = CatchTheCapyView.capyHeight;
    const field = CatchTheCapyView.fieldHeight;
    const minTop = field * CatchTheCapyView.groundTop;
    const lastColumn = CatchTheCapyRound.columns - 1;
    const lastRow = CatchTheCapyRound.rows - 1;
    return Offset(
      (width - w) * (spot % CatchTheCapyRound.columns) / lastColumn,
      minTop +
          (field - h - minTop) * (spot ~/ CatchTheCapyRound.columns) / lastRow,
    );
  }

  Widget _field(AppLocalizations l10n, {required double width}) {
    final at = _spotAt(_round.spot, width);
    final from = _spotAt(_from, width);
    final flip =
        _facingStart != (Directionality.of(context) == TextDirection.rtl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(CapyRadius.lg),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: GestureDetector(
                key: const ValueKey('catch-the-capy-meadow'),
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _onMeadowTap(
                  details.localPosition,
                  width: width,
                ),
                child: Image.asset(
                  CapyArt.byId('game.meadow').path,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          if (_moves && _from != _round.spot)
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: _Trail(
                    key: ValueKey(('trail', _round.spot, _round.caught)),
                    from: from,
                    to: at,
                    flip: flip,
                    duration: widget.run,
                    fieldWidth: width,
                  ),
                ),
              ),
            ),
          AnimatedPositionedDirectional(
            duration: _moves ? widget.run : Duration.zero,
            curve: Curves.easeInOut,
            start: at.dx,
            top: at.dy,
            width: CatchTheCapyView.capyWidth,
            height: CatchTheCapyView.capyHeight,
            child: Semantics(
              button: true,
              label: l10n.gameCatchTheCapyTargetLabel,
              onTap: () => _update(_round.catchCapy()),
              excludeSemantics: true,
              child: GestureDetector(
                key: const ValueKey('catch-the-capy-target'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _update(_round.catchCapy()),
                child: Transform.flip(
                  flipX: flip,
                  child: _Runner(
                    key: ValueKey(('run', _round.spot, _round.caught)),
                    duration: _moves && _from != _round.spot
                        ? widget.run
                        : Duration.zero,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The run cycle, played over one run with a small bounce per stride. Still
/// on its first frame when there is no run to play.
class _Runner extends StatelessWidget {
  const _Runner({required this.duration, super.key});

  final Duration duration;

  static const bounce = 4.0;

  @override
  Widget build(BuildContext context) {
    if (duration == Duration.zero) return _frame(0);
    final frames = CapyArt.runFrames.length;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      builder: (context, t, _) {
        final cycle = t * CatchTheCapyView.strides;
        final index = (cycle * frames).floor() % frames;
        return Transform.translate(
          offset: Offset(0, -bounce * math.sin(math.pi * cycle * 2).abs()),
          child: _frame(t >= 1 ? 0 : index),
        );
      },
    );
  }

  Widget _frame(int index) => Image.asset(
    CapyArt.runFrames[index].path,
    key: ValueKey('catch-the-capy-frame-$index'),
    fit: BoxFit.contain,
    alignment: Alignment.bottomCenter,
    gaplessPlayback: true,
  );
}

/// What a run leaves behind: a dust puff where it started and paw prints
/// along the way, alternating feet, each fading as the run goes on.
class _Trail extends StatelessWidget {
  const _Trail({
    required this.from,
    required this.to,
    required this.flip,
    required this.duration,
    required this.fieldWidth,
    super.key,
  });

  final double fieldWidth;
  final Offset from;
  final Offset to;
  final bool flip;
  final Duration duration;

  static const printSize = 18.0;
  static const dustWidth = 48.0;
  static const printsAt = [0.15, 0.32, 0.49, 0.66];
  static const printLife = 0.4;

  @override
  Widget build(BuildContext context) {
    const w = CatchTheCapyView.capyWidth;
    const h = CatchTheCapyView.capyHeight;
    final start = from + const Offset(w / 2, h - printSize / 2);
    final end = to + const Offset(w / 2, h - printSize / 2);
    final heading = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final onScreenHeading = rtl ? math.pi - heading : heading;
    final side = Offset(-math.sin(heading), math.cos(heading)) * 5;
    final dust = CapyArt.dustFrames;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      builder: (context, t, _) => Stack(
        children: [
          if (t < 1)
            PositionedDirectional(
              start:
                  (flip ? from.dx + w - dustWidth / 2 : from.dx - dustWidth / 2)
                      .clamp(0, math.max(0, fieldWidth - dustWidth))
                      .toDouble(),
              top: from.dy + h - dustWidth * 0.73,
              width: dustWidth,
              child: Transform.flip(
                flipX: flip,
                child: Image.asset(
                  dust[(t * dust.length).floor().clamp(0, dust.length - 1)]
                      .path,
                  key: const ValueKey('catch-the-capy-dust'),
                  gaplessPlayback: true,
                ),
              ),
            ),
          for (var i = 0; i < printsAt.length; i++)
            if (t >= printsAt[i] && t < printsAt[i] + printLife)
              PositionedDirectional(
                start:
                    Offset.lerp(start, end, printsAt[i])!.dx +
                    (i.isEven ? side.dx : -side.dx) -
                    printSize / 2,
                top:
                    Offset.lerp(start, end, printsAt[i])!.dy +
                    (i.isEven ? side.dy : -side.dy) -
                    printSize / 2,
                width: printSize,
                height: printSize,
                child: Opacity(
                  opacity: 0.8 * (1 - (t - printsAt[i]) / printLife),
                  child: Transform.rotate(
                    angle: onScreenHeading + math.pi / 2,
                    child: Image.asset(
                      CapyArt.byId('game.paw').path,
                      key: ValueKey('catch-the-capy-paw-$i'),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
