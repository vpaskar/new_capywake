import 'dart:async';
import 'dart:math' as math;

import 'package:capywake/core/games/capy_rocket.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/game_header.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Capy Rocket: swipe (or tap the arrow buttons) the way the arrow points to
/// fly Capy up the sky. Still, the rocket neither hovers nor wobbles.
class CapyRocketView extends GameRingingView {
  const CapyRocketView({
    required this.seed,
    required this.difficulty,
    required super.onProgress,
    required super.onCompleted,
    required super.reduceMotion,
    super.key,
  });

  CapyRocketView.fromLaunch(GameLaunch launch, {Key? key})
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
  static const fieldHeight = 228.0;

  /// The pose's 217 px at 3×: drawn sharp, never past what the art carries.
  static const rocketSize = 72.0;
  static const double groundGap = CapySpacing.sm;

  /// Clear of the cue pill at the field's top.
  static const skyGap = 52.0;

  static const buttonWidth = 72.0;
  static const buttonHeight = 56.0;
  static const swipeDistance = 32.0;
  static const flingVelocity = 300.0;

  static const hover = Duration(milliseconds: 1600);
  static const hoverRest = Duration(milliseconds: 150);
  static const hoverLift = 6.0;
  static const wobble = Duration(milliseconds: 400);
  static const wobbleAngle = 0.14;

  Duration get climb => CapyRocketRound.climbFor(difficulty);

  @override
  State<CapyRocketView> createState() => _CapyRocketViewState();
}

class _CapyRocketViewState extends State<CapyRocketView> {
  late CapyRocketRound _round = CapyRocketRound.start(
    difficulty: widget.difficulty,
    seed: widget.seed,
  );
  bool _completionReported = false;
  bool _precached = false;
  Timer? _rest;
  int _hoverCycle = 0;
  double _dragDx = 0;

  bool get _moves =>
      !widget.reduceMotion && !MediaQuery.accessibleNavigationOf(context);

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final id in const ['game.sky', 'pose.capyRocket']) {
        unawaited(precacheImage(AssetImage(CapyArt.byId(id).path), context));
      }
    }
    if (!_moves) _stopHover();
  }

  @override
  void dispose() {
    _stopHover();
    super.dispose();
  }

  void _stopHover() {
    _rest?.cancel();
    _rest = null;
  }

  void _hoverEnded() {
    if (!mounted || !_moves || _round.isComplete) return;
    _rest = Timer(CapyRocketView.hoverRest, () {
      if (mounted) setState(() => _hoverCycle++);
    });
  }

  void _boost(RocketSide side) {
    final next = _round.boost(side);
    if (identical(next, _round)) return;
    setState(() => _round = next);
    widget.onProgress(next.challenge);
    if (next.isComplete && !_completionReported) {
      _completionReported = true;
      _stopHover();
      widget.onCompleted();
    }
  }

  void _onSwipeEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final dx = _dragDx.abs() >= CapyRocketView.swipeDistance
        ? _dragDx
        : velocity.abs() >= CapyRocketView.flingVelocity
        ? velocity
        : 0.0;
    _dragDx = 0;
    if (dx == 0) return;
    final towardRight = dx > 0;
    _boost(towardRight != _rtl ? RocketSide.end : RocketSide.start);
  }

  bool _isLeft(RocketSide side) => (side == RocketSide.start) != _rtl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outcome = switch (_round.lastOutcome) {
      null => null,
      CapyRocketOutcome.boosted => l10n.gameCapyRocketBoosted,
      CapyRocketOutcome.wobbled => l10n.gameCapyRocketWobbled,
    };

    return CapyCard(
      child: GestureDetector(
        key: const ValueKey('capy-rocket-swipe'),
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => _dragDx = 0,
        onHorizontalDragUpdate: (details) => _dragDx += details.delta.dx,
        onHorizontalDragEnd: _onSwipeEnd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameHeader(
              title: l10n.gameCapyRocket,
              instruction: l10n.gameCapyRocketInstruction,
              done: _round.boosts,
              total: _round.target,
            ),
            const SizedBox(height: CapySpacing.md),
            SizedBox(
              height: CapyRocketView.fieldHeight,
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    _field(l10n, width: constraints.maxWidth),
              ),
            ),
            const SizedBox(height: CapySpacing.sm),
            GameOutcomeLine(
              text: outcome,
              serial: _round.boosts + _round.wobbles,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(AppLocalizations l10n, {required double width}) {
    const rocket = CapyRocketView.rocketSize;
    const field = CapyRocketView.fieldHeight;
    const ground = field - rocket - CapyRocketView.groundGap;
    final top = ground - (ground - CapyRocketView.skyGap) * _round.altitude;

    return ClipRRect(
      borderRadius: BorderRadius.circular(CapyRadius.lg),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: Image.asset(
                CapyArt.byId('game.sky').path,
                fit: BoxFit.cover,
              ),
            ),
          ),
          AnimatedPositionedDirectional(
            duration: _moves ? widget.climb : Duration.zero,
            curve: Curves.easeOutBack,
            start: (width - rocket) / 2,
            top: top,
            width: rocket,
            height: rocket,
            child: ExcludeSemantics(child: _rocket()),
          ),
          PositionedDirectional(
            top: CapySpacing.sm,
            start: CapySpacing.sm,
            end: CapySpacing.sm,
            child: Center(child: _cuePill(l10n)),
          ),
          for (final side in RocketSide.values)
            PositionedDirectional(
              bottom: CapySpacing.sm,
              start: side == RocketSide.start ? CapySpacing.sm : null,
              end: side == RocketSide.end ? CapySpacing.sm : null,
              child: _button(l10n, side),
            ),
        ],
      ),
    );
  }

  Widget _rocket() {
    final image = Image.asset(
      CapyArt.byId('pose.capyRocket').path,
      key: const ValueKey('capy-rocket-rocket'),
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
    );
    if (!_moves || _round.isComplete) return image;
    return TweenAnimationBuilder<double>(
      key: ValueKey(('wobble', _round.wobbles)),
      tween: Tween(begin: _round.wobbles == 0 ? 1 : 0, end: 1),
      duration: CapyRocketView.wobble,
      builder: (context, w, child) => Transform.rotate(
        angle: CapyRocketView.wobbleAngle * math.sin(w * math.pi * 4) * (1 - w),
        child: child,
      ),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(('hover', _hoverCycle)),
        tween: Tween(begin: 0, end: 1),
        duration: CapyRocketView.hover,
        onEnd: _hoverEnded,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(
            0,
            -CapyRocketView.hoverLift * math.sin(math.pi * t),
          ),
          child: child,
        ),
        child: image,
      ),
    );
  }

  Widget _cuePill(AppLocalizations l10n) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final left = _isLeft(_round.cue);

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? CapyColors.darkSurface : CapyColors.surface,
          borderRadius: BorderRadius.circular(CapyRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: CapySpacing.lg,
            vertical: CapySpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: Icon(_arrow(_round.cue), color: ink)),
              const SizedBox(width: CapySpacing.xs),
              Flexible(
                child: Text(
                  left
                      ? l10n.gameCapyRocketCueLeft
                      : l10n.gameCapyRocketCueRight,
                  key: const ValueKey('capy-rocket-cue'),
                  style: CapyType.label.copyWith(color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _arrow(RocketSide side) => side == RocketSide.start
      ? Icons.arrow_back_rounded
      : Icons.arrow_forward_rounded;

  Widget _button(AppLocalizations l10n, RocketSide side) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final paper = dark ? CapyColors.darkSurface : CapyColors.surface;
    final cued = side == _round.cue;
    void tap() => _boost(side);

    return Semantics(
      button: true,
      label: _isLeft(side)
          ? l10n.gameCapyRocketFlyLeft
          : l10n.gameCapyRocketFlyRight,
      onTap: tap,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('capy-rocket-${side.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        child: Container(
          width: CapyRocketView.buttonWidth,
          height: CapyRocketView.buttonHeight,
          decoration: BoxDecoration(
            color: cued ? ink : paper,
            borderRadius: BorderRadius.circular(CapyRadius.pill),
            border: Border.all(color: ink, width: 1.5),
          ),
          child: Icon(_arrow(side), color: cued ? paper : ink),
        ),
      ),
    );
  }
}
