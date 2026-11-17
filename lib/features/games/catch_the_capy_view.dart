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

/// Catch the Capy. The capybara wanders the meadow (owner, 2026-11-17); under
/// reduce-motion or a screen reader it holds still and moves only when caught.
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
  static const capySize = 88.0;

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

  Widget _field(AppLocalizations l10n, {required double width}) {
    const size = CatchTheCapyView.capySize;
    final start =
        (width - size) * _round.column / (CatchTheCapyRound.columns - 1);
    final top =
        (CatchTheCapyView.fieldHeight - size) *
        _round.row /
        (CatchTheCapyRound.rows - 1);

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
                child: const ColoredBox(color: CapyColors.meadow),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(child: _MeadowDecor()),
            ),
          ),
          AnimatedPositionedDirectional(
            duration: _moves ? widget.run : Duration.zero,
            curve: Curves.easeInOut,
            start: start,
            top: top,
            width: size,
            height: size,
            child: Semantics(
              button: true,
              label: l10n.gameCatchTheCapyTargetLabel,
              onTap: () => _update(_round.catchCapy()),
              excludeSemantics: true,
              child: GestureDetector(
                key: const ValueKey('catch-the-capy-target'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _update(_round.catchCapy()),
                child: _Hop(
                  key: ValueKey(_round.spot),
                  duration: _moves ? widget.run : Duration.zero,
                  child: Transform.flip(
                    flipX:
                        _facingStart !=
                        (Directionality.of(context) == TextDirection.rtl),
                    child: Image.asset(
                      CapyArt.byId('game.catchCapy').path,
                      fit: BoxFit.contain,
                    ),
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

/// Small bounces while the capybara runs. Stands in for a run cycle the
/// package lacks (see asset_gaps.md G32).
class _Hop extends StatelessWidget {
  const _Hop({required this.duration, required this.child, super.key});

  final Duration duration;
  final Widget child;

  static const height = 8.0;

  /// Bounces per run, so a run reads as steps rather than one leap.
  static const strides = 3;

  /// Body rock per stride, alternating sides: right step, left step.
  static const waddle = 0.12;

  @override
  Widget build(BuildContext context) {
    if (duration == Duration.zero) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      builder: (context, t, child) {
        final step = math.sin(math.pi * strides * t);
        return Transform.translate(
          offset: Offset(0, -height * step.abs()),
          child: Transform.rotate(angle: waddle * step, child: child),
        );
      },
      child: child,
    );
  }
}

/// Shrubs, sprouts and grass behind the capybara, from the package's decor.
class _MeadowDecor extends StatelessWidget {
  const _MeadowDecor();

  static const _pieces = <(String, Alignment)>[
    ('game.shrub', Alignment(-0.95, -0.85)),
    ('game.shrub', Alignment(0.95, 0.9)),
    ('game.bush', Alignment(0.2, -0.95)),
    ('game.bush', Alignment(-0.7, 0.95)),
    ('game.sprout', Alignment(-0.35, 0.25)),
    ('game.sprout', Alignment(0.6, -0.3)),
    ('game.tuft', Alignment(0.05, 0.6)),
    ('game.tuft', Alignment(0.85, -0.7)),
    ('game.tuft', Alignment(-0.9, 0.1)),
    ('game.tuft', Alignment(0.45, 0.45)),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final (id, alignment) in _pieces)
          Align(
            alignment: alignment,
            child: Image.asset(
              CapyArt.byId(id).path,
              width: CapyArt.byId(id).use.renderBoxPt,
              fit: BoxFit.contain,
            ),
          ),
      ],
    );
  }
}
