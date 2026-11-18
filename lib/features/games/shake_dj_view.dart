import 'dart:async';
import 'dart:math' as math;

import 'package:capywake/core/games/shake_dj.dart';
import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/core/motion/shake_detector.dart';
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

/// Shake DJ: shake the phone, or tap the beat button, to pump up Capy's beat.
/// The button always works. Still, Capy neither bobs nor bounces.
class ShakeDjView extends GameRingingView {
  const ShakeDjView({
    required this.difficulty,
    required this.motion,
    required super.onProgress,
    required super.onCompleted,
    required super.reduceMotion,
    super.key,
  });

  ShakeDjView.fromLaunch(GameLaunch launch, {Key? key})
    : this(
        difficulty: launch.difficulty,
        motion: launch.motion,
        onProgress: launch.onProgress,
        onCompleted: launch.onCompleted,
        reduceMotion: launch.reduceMotion,
        key: key,
      );

  final PuzzleDifficulty difficulty;
  final MotionSensor motion;

  static const fieldHeight = 142.0;
  static const beatButtonHeight = 56.0;

  /// `collection_06` is 260 px: sharp to 86 pt at 3×.
  static const capySize = 86.0;
  static const barsPerSide = 5;
  static const barWidth = 12.0;
  static const barGap = 6.0;
  static const barMaxHeight = 100.0;
  static const barShapes = [0.5, 0.75, 1.0, 0.8, 0.6];

  static const bobLift = 6.0;
  static const grooveRest = Duration(milliseconds: 150);
  static const kick = Duration(milliseconds: 240);
  static const kickScale = 0.08;
  static const noteRise = 36.0;

  Duration get groove => ShakeDjRound.grooveFor(difficulty);

  @override
  State<ShakeDjView> createState() => _ShakeDjViewState();
}

class _ShakeDjViewState extends State<ShakeDjView> {
  late ShakeDjRound _round = ShakeDjRound.start(difficulty: widget.difficulty);
  final _detector = ShakeDetector();
  StreamSubscription<MotionSample>? _samples;
  Timer? _stall;
  Timer? _rest;
  int _grooveCycle = 0;
  bool _completionReported = false;
  bool _precached = false;

  bool get _moves =>
      !widget.reduceMotion && !MediaQuery.accessibleNavigationOf(context);

  @override
  void initState() {
    super.initState();
    _listen();
    _armStall();
  }

  @override
  void didUpdateWidget(ShakeDjView old) {
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
          AssetImage(CapyArt.byId('game.capy.listening').path),
          context,
        ),
      );
    }
    if (!_moves) _stopGroove();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _listen() {
    unawaited(_samples?.cancel());
    _samples = _round.isComplete
        ? null
        : widget.motion.samples.listen(
            (sample) {
              if (_detector.register(sample)) _beat();
            },
            onError: (Object _) {},
          );
  }

  void _armStall() {
    _stall?.cancel();
    _stall = Timer(ShakeDjRound.stallAfter, () {
      if (!mounted) return;
      _apply(_round.stall());
      _armStall();
    });
  }

  void _stopGroove() {
    _rest?.cancel();
    _rest = null;
  }

  void _stop() {
    unawaited(_samples?.cancel());
    _samples = null;
    _stall?.cancel();
    _stopGroove();
  }

  void _grooveEnded() {
    if (!mounted || !_moves || _round.isComplete) return;
    _rest = Timer(ShakeDjView.grooveRest, () {
      if (mounted) setState(() => _grooveCycle++);
    });
  }

  void _beat() {
    if (_round.isComplete) return;
    _apply(_round.beat());
    if (!_round.isComplete) _armStall();
  }

  void _apply(ShakeDjRound next) {
    setState(() => _round = next);
    widget.onProgress(next.challenge);
    if (next.isComplete && !_completionReported) {
      _completionReported = true;
      _stop();
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outcome = switch (_round.lastOutcome) {
      null => null,
      ShakeDjOutcome.stalled => l10n.gameShakeDjStalled,
    };

    return CapyCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameHeader(
            title: l10n.gameShakeDj,
            instruction: l10n.gameShakeDjInstruction,
            done: _round.phrasesDone,
            total: _round.phrases,
          ),
          const SizedBox(height: CapySpacing.md),
          SizedBox(
            height: ShakeDjView.fieldHeight,
            child: ExcludeSemantics(child: _field()),
          ),
          const SizedBox(height: CapySpacing.sm),
          _beatButton(l10n),
          const SizedBox(height: CapySpacing.sm),
          GameOutcomeLine(
            text: outcome,
            serial: _round.beats,
            reserveFor: [l10n.gameShakeDjStalled],
          ),
        ],
      ),
    );
  }

  /// A game control, not the orange call to action: Snooze sits just below
  /// it, and a slip between twin buttons would snooze the alarm.
  Widget _beatButton(AppLocalizations l10n) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final done = _round.isComplete;

    return Semantics(
      button: true,
      enabled: !done,
      label: l10n.gameShakeDjBeat,
      onTap: done ? null : _beat,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('shake-dj-beat'),
        behavior: HitTestBehavior.opaque,
        onTap: done ? null : _beat,
        child: Container(
          height: ShakeDjView.beatButtonHeight,
          decoration: BoxDecoration(
            color: dark ? CapyColors.darkSurface : CapyColors.surface,
            borderRadius: BorderRadius.circular(CapyRadius.pill),
            border: Border.all(color: ink, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note_rounded, color: ink),
              const SizedBox(width: CapySpacing.xs),
              Flexible(
                child: Text(
                  l10n.gameShakeDjBeat,
                  textAlign: TextAlign.center,
                  style: CapyType.label.copyWith(color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt,
        borderRadius: BorderRadius.circular(CapyRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _equalizer(const ValueKey('shake-dj-eq-start')),
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [_capy(), if (_moves && _round.beats > 0) _note()],
          ),
          _equalizer(const ValueKey('shake-dj-eq-end')),
        ],
      ),
    );
  }

  Widget _capy() {
    final image = Image.asset(
      CapyArt.byId('game.capy.listening').path,
      key: const ValueKey('shake-dj-capy'),
      width: ShakeDjView.capySize,
      height: ShakeDjView.capySize,
      fit: BoxFit.contain,
    );
    if (!_moves || _round.isComplete) return image;
    return TweenAnimationBuilder<double>(
      key: ValueKey(('kick', _round.beats)),
      tween: Tween(begin: _round.beats == 0 ? 1 : 0, end: 1),
      duration: ShakeDjView.kick,
      builder: (context, k, child) => Transform.scale(
        scale: 1 + ShakeDjView.kickScale * math.sin(k * math.pi),
        child: child,
      ),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(('groove', _grooveCycle)),
        tween: Tween(begin: 0, end: 1),
        duration: widget.groove,
        onEnd: _grooveEnded,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, -ShakeDjView.bobLift * math.sin(math.pi * t)),
          child: child,
        ),
        child: image,
      ),
    );
  }

  Widget _note() => TweenAnimationBuilder<double>(
    key: ValueKey(('note', _round.beats)),
    tween: Tween(begin: 0, end: 1),
    duration: ShakeDjView.kick * 2,
    builder: (context, t, child) => Transform.translate(
      offset: Offset(ShakeDjView.capySize / 2, -ShakeDjView.noteRise * t),
      child: Opacity(opacity: 1 - t, child: child),
    ),
    child: const Icon(
      Icons.music_note_rounded,
      key: ValueKey('shake-dj-note'),
      color: CapyColors.accentDeep,
    ),
  );

  Widget _equalizer(Key key) {
    final level = 0.25 + 0.75 * _round.level;
    return Row(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < ShakeDjView.barsPerSide; i++)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: i == 0 ? 0 : ShakeDjView.barGap,
            ),
            child: AnimatedContainer(
              duration: _moves ? ShakeDjView.kick : Duration.zero,
              curve: Curves.easeOutBack,
              width: ShakeDjView.barWidth,
              height: ShakeDjView.barMaxHeight * level * _shape(i),
              decoration: BoxDecoration(
                color: i.isEven ? CapyColors.accent : CapyPadColors.yellow,
                borderRadius: BorderRadius.circular(CapyRadius.sm),
              ),
            ),
          ),
      ],
    );
  }

  /// Each beat rotates which bar peaks, so the meter dances with the beat.
  double _shape(int bar) {
    const shapes = ShakeDjView.barShapes;
    return shapes[(bar + (_moves ? _round.beats : 0)) % shapes.length];
  }
}
