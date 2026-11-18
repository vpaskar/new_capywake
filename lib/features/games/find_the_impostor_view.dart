import 'dart:async';

import 'package:capywake/core/games/find_the_impostor.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/drifting_grid.dart';
import 'package:capywake/features/games/game_header.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Find the Impostor: one Capy does something different among identical ones.
/// The cards drift; still (reduce-motion, screen reader) they stay put.
class FindTheImpostorView extends GameRingingView {
  const FindTheImpostorView({
    required this.seed,
    required this.difficulty,
    required super.onProgress,
    required super.onCompleted,
    required super.reduceMotion,
    super.key,
  });

  FindTheImpostorView.fromLaunch(GameLaunch launch, {Key? key})
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

  static const rows = 2;
  static const cellHeight = 84.0;

  /// Art box inside a card; the bundled poses stay sharp up to it.
  static double get artSize => ArtUse.gameCapy.renderBoxPt;

  @override
  State<FindTheImpostorView> createState() => _FindTheImpostorViewState();
}

class _FindTheImpostorViewState extends State<FindTheImpostorView> {
  late FindTheImpostorRound _round = FindTheImpostorRound.start(
    difficulty: widget.difficulty,
    seed: widget.seed,
  );
  bool _completionReported = false;
  bool _precached = false;

  bool get _moves =>
      !widget.reduceMotion && !MediaQuery.accessibleNavigationOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    for (final asset in CapyArt.gameCapys) {
      unawaited(precacheImage(AssetImage(asset.path), context));
    }
  }

  void _tap(int cell) {
    final next = _round.tap(cell);
    if (identical(next, _round)) return;
    setState(() => _round = next);
    widget.onProgress(next.challenge);
    if (next.isComplete && !_completionReported) {
      _completionReported = true;
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outcome = switch (_round.lastOutcome) {
      null => null,
      FindTheImpostorOutcome.found => l10n.gameFindTheImpostorFound,
      FindTheImpostorOutcome.missed => l10n.gameFindTheImpostorMissed,
    };

    return CapyCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameHeader(
            title: l10n.gameFindTheImpostor,
            instruction: l10n.gameFindTheImpostorInstruction,
            done: _round.found,
            total: _round.target,
          ),
          const SizedBox(height: CapySpacing.md),
          DriftingGrid(
            cellCount: _round.cellCount,
            columns: _round.cellCount ~/ FindTheImpostorView.rows,
            cellHeightFor: (_) => FindTheImpostorView.cellHeight,
            moves: _moves && !_round.isComplete,
            swapEvery: FindTheImpostorRound.swapEveryFor(widget.difficulty),
            seed: widget.seed,
            generation: _round.found,
            style: DriftStyle.carousel,
            cellBuilder: (context, cell) => _cell(l10n, cell),
          ),
          const SizedBox(height: CapySpacing.sm),
          GameOutcomeLine(
            text: outcome,
            serial: _round.found + _round.wrongTaps,
            reserveFor: [
              l10n.gameFindTheImpostorFound,
              l10n.gameFindTheImpostorMissed,
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(AppLocalizations l10n, int cell) {
    final pose = _round.poseAt(cell);
    final label = l10n.gameFindTheImpostorCellLabel(
      cell + 1,
      _round.cellCount,
      capyPoseName(l10n, pose),
    );
    final enabled = !_round.isComplete;
    void tap() => _tap(cell);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      onTap: enabled ? tap : null,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('find-the-impostor-cell-$cell'),
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? tap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: CapyColors.cream,
            borderRadius: BorderRadius.circular(CapyRadius.md),
            border: Border.all(color: CapyColors.cocoaSoft, width: 1.5),
          ),
          child: Center(
            child: Image.asset(
              CapyArt.byId('game.capy.${pose.name}').path,
              key: ValueKey('find-the-impostor-art-${pose.name}'),
              width: FindTheImpostorView.artSize,
              height: FindTheImpostorView.artSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

/// What a pose card shows, for a screen reader: the answer key of the game.
String capyPoseName(AppLocalizations l10n, CapyPose pose) => switch (pose) {
  CapyPose.asleepNightcap => l10n.gameCapyPoseAsleepNightcap,
  CapyPose.curledAsleep => l10n.gameCapyPoseCurledAsleep,
  CapyPose.underBlanket => l10n.gameCapyPoseUnderBlanket,
  CapyPose.onCushion => l10n.gameCapyPoseOnCushion,
  CapyPose.hiking => l10n.gameCapyPoseHiking,
  CapyPose.jogging => l10n.gameCapyPoseJogging,
  CapyPose.liftingWeights => l10n.gameCapyPoseLiftingWeights,
  CapyPose.holdingClock => l10n.gameCapyPoseHoldingClock,
  CapyPose.cheering => l10n.gameCapyPoseCheering,
  CapyPose.partying => l10n.gameCapyPosePartying,
  CapyPose.superhero => l10n.gameCapyPoseSuperhero,
  CapyPose.blushing => l10n.gameCapyPoseBlushing,
  CapyPose.holdingMug => l10n.gameCapyPoseHoldingMug,
  CapyPose.reading => l10n.gameCapyPoseReading,
  CapyPose.listening => l10n.gameCapyPoseListening,
  CapyPose.detective => l10n.gameCapyPoseDetective,
};
