import 'dart:async';

import 'package:capywake/core/games/rhythm_rescue.dart';
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

/// Rhythm Rescue: the pads light a pattern in time, then the user repeats it.
/// Still (reduce-motion, screen reader) every beat shows its pad throughout.
class RhythmRescueView extends GameRingingView {
  const RhythmRescueView({
    required this.seed,
    required this.difficulty,
    required super.onProgress,
    required super.onCompleted,
    required super.reduceMotion,
    super.key,
  });

  RhythmRescueView.fromLaunch(GameLaunch launch, {Key? key})
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

  static const artSize = 88.0;
  static const padMinSize = 72.0;
  static const slotSize = 34.0;
  static const replaySize = 44.0;
  static const litScale = 1.08;
  static const idleOpacity = 0.55;

  /// A beat before the first light, so the user can look up first.
  static const leadIn = Duration(milliseconds: 500);

  /// The share of a beat a pad stays lit; the gap keeps beats countable.
  static const litShare = 0.65;

  Duration get beat => RhythmRescueRound.beatFor(difficulty);

  @override
  State<RhythmRescueView> createState() => _RhythmRescueViewState();
}

class _RhythmRescueViewState extends State<RhythmRescueView> {
  late RhythmRescueRound _round = RhythmRescueRound.start(
    difficulty: widget.difficulty,
    seed: widget.seed,
  );
  bool _completionReported = false;
  bool _precached = false;
  Timer? _playback;

  /// The beat being shown while listening, `null` between lights.
  int? _litBeat;

  /// The current pattern was shown still, so it stays shown until replaced.
  bool _patternShown = false;
  int? _pressedPad;

  bool get _moves =>
      !widget.reduceMotion && !MediaQuery.accessibleNavigationOf(context);

  bool get _listening => _round.phase == RhythmRescuePhase.listening;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      unawaited(
        precacheImage(
          AssetImage(CapyArt.byId('tile.rhythmRescue').path),
          context,
        ),
      );
    }
    if (!_moves) {
      _stopPlayback();
      _round = _round.heard();
      _patternShown = true;
    } else if (_listening && _playback == null) {
      _play();
    }
  }

  @override
  void dispose() {
    _stopPlayback();
    super.dispose();
  }

  void _stopPlayback() {
    _playback?.cancel();
    _playback = null;
    _litBeat = null;
  }

  void _play() {
    _playback?.cancel();
    _patternShown = false;
    if (_round.isComplete) return;
    _playback = Timer(RhythmRescueView.leadIn, () => _light(0));
  }

  void _light(int beat) {
    if (!mounted) return;
    if (beat >= _round.pattern.length) {
      setState(() {
        _playback = null;
        _litBeat = null;
        _round = _round.heard();
      });
      return;
    }
    setState(() => _litBeat = beat);
    final lit = widget.beat * RhythmRescueView.litShare;
    _playback = Timer(lit, () {
      if (!mounted) return;
      setState(() => _litBeat = null);
      _playback = Timer(widget.beat - lit, () => _light(beat + 1));
    });
  }

  void _update(RhythmRescueRound next) {
    if (identical(next, _round)) return;
    final still = !_moves && next.phase == RhythmRescuePhase.listening;
    final settled = still ? next.heard() : next;
    setState(() {
      _round = settled;
      if (still) _patternShown = true;
    });
    widget.onProgress(settled.challenge);
    if (settled.isComplete) {
      _stopPlayback();
      if (!_completionReported) {
        _completionReported = true;
        widget.onCompleted();
      }
      return;
    }
    if (settled.phase == RhythmRescuePhase.listening) _play();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outcome = switch (_round.lastOutcome) {
      null => null,
      RhythmRescueOutcome.rescued => l10n.gameRhythmRescueRescued,
      RhythmRescueOutcome.missed => l10n.gameRhythmRescueMissed,
    };

    return CapyCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameHeader(
            title: l10n.gameRhythmRescue,
            instruction: l10n.gameRhythmRescueInstruction,
            done: _round.rescued,
            total: _round.target,
          ),
          const SizedBox(height: CapySpacing.md),
          _patternRow(l10n),
          const SizedBox(height: CapySpacing.md),
          _pads(l10n),
          const SizedBox(height: CapySpacing.sm),
          GameOutcomeLine(
            text: outcome,
            serial: _round.rescued + _round.wrongTaps,
          ),
        ],
      ),
    );
  }

  Color _ink(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? CapyColors.darkInk
      : CapyColors.cocoa;

  Widget _patternRow(AppLocalizations l10n) {
    final ink = _ink(context);
    final playing = _litBeat != null;

    return Row(
      children: [
        ExcludeSemantics(
          child: AnimatedScale(
            scale: playing ? RhythmRescueView.litScale : 1,
            duration: _moves ? CapyDuration.fast : Duration.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CapyRadius.md),
              child: Image.asset(
                CapyArt.byId('tile.rhythmRescue').path,
                width: RhythmRescueView.artSize,
                height: RhythmRescueView.artSize,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: CapySpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IndexedStack(
                index: _listening ? 0 : 1,
                children: [
                  for (final (i, status) in [
                    l10n.gameRhythmRescueStatusWatch,
                    l10n.gameRhythmRescueStatusYourTurn,
                  ].indexed)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        status,
                        key: (_listening ? 0 : 1) == i
                            ? const ValueKey('rhythm-rescue-status')
                            : null,
                        style: CapyType.label.copyWith(color: ink),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: CapySpacing.sm),
              Wrap(
                spacing: CapySpacing.xs,
                runSpacing: CapySpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_moves) _replayButton(l10n, ink),
                  for (var beat = 0; beat < _round.pattern.length; beat++)
                    _slot(l10n, beat),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _replayButton(AppLocalizations l10n, Color ink) {
    final enabled = !_listening;
    return Semantics(
      button: true,
      enabled: enabled,
      label: l10n.gameRhythmRescueReplayLabel,
      onTap: enabled ? () => _update(_round.replay()) : null,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('rhythm-rescue-replay'),
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => _update(_round.replay()) : null,
        child: Container(
          width: RhythmRescueView.replaySize,
          height: RhythmRescueView.replaySize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ink, width: 1.5),
          ),
          child: Opacity(
            opacity: enabled ? 1 : RhythmRescueView.idleOpacity,
            child: Icon(Icons.play_arrow_rounded, color: ink),
          ),
        ),
      ),
    );
  }

  Widget _slot(AppLocalizations l10n, int beat) {
    final pad = _round.pattern[beat];
    final entered = !_listening && beat < _round.entered;
    final shown = _patternShown || _litBeat == beat;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final empty = dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt;
    final label = shown
        ? l10n.gameRhythmRescueBeatPad(beat + 1, pad + 1)
        : entered
        ? l10n.gameRhythmRescueBeatDone(beat + 1)
        : l10n.gameRhythmRescueBeatHidden(beat + 1);

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        key: ValueKey('rhythm-rescue-slot-$beat'),
        constraints: const BoxConstraints(
          minWidth: RhythmRescueView.slotSize,
          minHeight: RhythmRescueView.slotSize,
        ),
        padding: const EdgeInsets.all(CapySpacing.xs),
        decoration: BoxDecoration(
          color: shown || entered ? CapyPadColors.all[pad] : empty,
          shape: BoxShape.circle,
          border: Border.all(color: CapyColors.cocoaSoft, width: 1.5),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: shown || entered
              ? Text(
                  l10n.gameRhythmRescuePadNumber(pad + 1),
                  style: CapyType.label.copyWith(color: CapyColors.cocoa),
                )
              : null,
        ),
      ),
    );
  }

  Widget _pads(AppLocalizations l10n) {
    final lit = _litBeat == null ? null : _round.pattern[_litBeat!];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var pad = 0; pad < RhythmRescueRound.padCount; pad++) ...[
          if (pad > 0) const SizedBox(width: CapySpacing.sm),
          Expanded(child: _pad(l10n, pad, lit: pad == lit)),
        ],
      ],
    );
  }

  Widget _pad(AppLocalizations l10n, int pad, {required bool lit}) {
    final enabled = !_listening && !_round.isComplete;
    void tap() => _update(_round.tap(pad));

    return Semantics(
      button: true,
      enabled: enabled,
      label: l10n.gameRhythmRescuePadLabel(pad + 1),
      onTap: enabled ? tap : null,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('rhythm-rescue-pad-$pad'),
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressedPad = pad) : null,
        onTapCancel: () => setState(() => _pressedPad = null),
        onTapUp: enabled ? (_) => setState(() => _pressedPad = null) : null,
        onTap: enabled ? tap : null,
        child: AnimatedScale(
          scale: lit || _pressedPad == pad ? RhythmRescueView.litScale : 1,
          duration: _moves ? CapyDuration.fast : Duration.zero,
          child: AnimatedOpacity(
            opacity: enabled || lit ? 1 : RhythmRescueView.idleOpacity,
            duration: _moves ? CapyDuration.fast : Duration.zero,
            child: Container(
              key: lit ? ValueKey('rhythm-rescue-lit-$pad') : null,
              constraints: const BoxConstraints(
                minHeight: RhythmRescueView.padMinSize,
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(CapySpacing.sm),
              decoration: BoxDecoration(
                color: CapyPadColors.all[pad],
                borderRadius: BorderRadius.circular(CapyRadius.md),
                border: Border.all(
                  color: lit ? CapyColors.cocoa : CapyColors.cocoaSoft,
                  width: lit ? 3 : 1.5,
                ),
              ),
              child: Text(
                l10n.gameRhythmRescuePadNumber(pad + 1),
                textAlign: TextAlign.center,
                style: CapyType.title.copyWith(color: CapyColors.cocoa),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
