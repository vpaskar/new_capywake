import 'dart:async';

import 'package:capywake/core/games/morning_sort.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/drifting_grid.dart';
import 'package:capywake/features/games/game_header.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Morning Sort: pack what Capy needs this morning into the bag's pockets. The
/// cards drift; still (reduce-motion, screen reader) they stay put.
class MorningSortView extends GameRingingView {
  const MorningSortView({
    required this.seed,
    required this.difficulty,
    required super.onProgress,
    required super.onCompleted,
    required super.reduceMotion,
    super.key,
  });

  MorningSortView.fromLaunch(GameLaunch launch, {Key? key})
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

  static const bagArtSize = 56.0;
  static const pocketSize = 36.0;
  static const cellMinHeight = 56.0;
  static const leftOutOpacity = 0.5;
  static const packedBorder = 3.0;

  /// How far a card's state badge sits out over its corner, off the name.
  static const badgeOverhang = 8.0;

  static int columnsFor(int cardCount) => cardCount <= 4 ? 2 : 3;

  @override
  State<MorningSortView> createState() => _MorningSortViewState();
}

class _MorningSortViewState extends State<MorningSortView> {
  late MorningSortRound _round = MorningSortRound.start(
    difficulty: widget.difficulty,
    seed: widget.seed,
  );
  bool _completionReported = false;
  bool _precached = false;
  int _answers = 0;
  (double, TextScaler, Locale, Brightness)? _measuredFor;
  double _measuredHeight = 0;

  bool get _moves =>
      !widget.reduceMotion && !MediaQuery.accessibleNavigationOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    unawaited(
      precacheImage(AssetImage(CapyArt.byId('game.capy.hiking').path), context),
    );
  }

  void _tap(int index) {
    final next = _round.tap(index);
    if (identical(next, _round)) return;
    setState(() {
      _round = next;
      _answers++;
    });
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
      MorningSortOutcome.packed => l10n.gameMorningSortPacked,
      MorningSortOutcome.leftOut => l10n.gameMorningSortLeftOut,
      MorningSortOutcome.bagDone => l10n.gameMorningSortBagDone,
    };

    return CapyCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameHeader(
            title: l10n.gameMorningSort,
            instruction: l10n.gameMorningSortInstruction,
            done: _round.bags,
            total: _round.target,
          ),
          const SizedBox(height: CapySpacing.sm),
          _bag(l10n),
          const SizedBox(height: CapySpacing.sm),
          DriftingGrid(
            cellCount: _round.items.length,
            columns: MorningSortView.columnsFor(_round.items.length),
            cellHeightFor: (width) => _cellHeight(l10n, width),
            moves: _moves && !_round.isComplete,
            swapEvery: MorningSortRound.swapEveryFor(widget.difficulty),
            seed: widget.seed,
            generation: _round.bags,
            canMove: (index) => !_round.isResolved(index),
            cellBuilder: (context, index) => _card(l10n, index),
          ),
          const SizedBox(height: CapySpacing.sm),
          GameOutcomeLine(
            text: outcome,
            serial: _answers,
            reserveFor: [
              l10n.gameMorningSortPacked,
              l10n.gameMorningSortLeftOut,
              l10n.gameMorningSortBagDone,
            ],
          ),
        ],
      ),
    );
  }

  Color _ink() => Theme.of(context).brightness == Brightness.dark
      ? CapyColors.darkInk
      : CapyColors.cocoa;

  Widget _bag(AppLocalizations l10n) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final empty = dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt;
    return Row(
      children: [
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CapyColors.cream,
              borderRadius: BorderRadius.circular(CapyRadius.md),
            ),
            child: Image.asset(
              CapyArt.byId('game.capy.hiking').path,
              width: MorningSortView.bagArtSize,
              height: MorningSortView.bagArtSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: CapySpacing.md),
        Expanded(
          child: Wrap(
            spacing: CapySpacing.sm,
            runSpacing: CapySpacing.xs,
            children: [
              for (var pocket = 0; pocket < _round.pockets; pocket++)
                _pocket(l10n, pocket, empty),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pocket(AppLocalizations l10n, int pocket, Color empty) {
    final filled = pocket < _round.packed.length;
    final label = filled
        ? l10n.gameMorningSortPocketPacked(
            pocket + 1,
            _round.pockets,
            morningItemName(l10n, _round.items[_round.packed[pocket]]),
          )
        : l10n.gameMorningSortPocketEmpty(pocket + 1, _round.pockets);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: AnimatedScale(
        key: ValueKey('morning-sort-pocket-$pocket'),
        scale: filled ? 1 : 0.9,
        duration: _moves ? CapyDuration.normal : Duration.zero,
        child: Container(
          width: MorningSortView.pocketSize,
          height: MorningSortView.pocketSize,
          decoration: BoxDecoration(
            color: filled ? CapyColors.accent : empty,
            borderRadius: BorderRadius.circular(CapyRadius.sm),
            border: Border.all(color: CapyColors.cocoaSoft, width: 1.5),
          ),
          child: filled
              ? const Icon(
                  Icons.check_rounded,
                  key: ValueKey('morning-sort-pocket-filled'),
                  color: CapyColors.cocoa,
                  size: CapyIconSize.md,
                )
              : null,
        ),
      ),
    );
  }

  TextStyle _nameStyle() => CapyType.label.copyWith(color: _ink());

  double _cellHeight(AppLocalizations l10n, double cellWidth) {
    final key = (
      cellWidth,
      MediaQuery.textScalerOf(context),
      Localizations.localeOf(context),
      Theme.of(context).brightness,
    );
    if (key == _measuredFor) return _measuredHeight;
    _measuredFor = key;
    return _measuredHeight = _measureCellHeight(l10n, cellWidth);
  }

  double _measureCellHeight(AppLocalizations l10n, double cellWidth) {
    const inset = CapySpacing.sm + MorningSortView.packedBorder;
    var tallest = 0.0;
    for (final item in MorningItem.values) {
      final painter = TextPainter(
        text: TextSpan(text: morningItemName(l10n, item), style: _nameStyle()),
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: cellWidth - inset * 2);
      if (painter.height > tallest) tallest = painter.height;
      painter.dispose();
    }
    final content = tallest + inset * 2;
    return content > MorningSortView.cellMinHeight
        ? content
        : MorningSortView.cellMinHeight;
  }

  Widget _card(AppLocalizations l10n, int index) {
    final item = _round.items[index];
    final name = morningItemName(l10n, item);
    final packed = _round.packed.contains(index);
    final leftOut = _round.leftOut.contains(index);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = _ink();
    final label = packed
        ? l10n.gameMorningSortItemPacked(name)
        : leftOut
        ? l10n.gameMorningSortItemLeftOut(name)
        : name;
    final enabled = !packed && !leftOut && !_round.isComplete;
    void tap() => _tap(index);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      onTap: enabled ? tap : null,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('morning-sort-card-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? tap : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: leftOut ? MorningSortView.leftOutOpacity : 1,
                duration: _moves ? CapyDuration.normal : Duration.zero,
                child: Container(
                  padding: const EdgeInsets.all(CapySpacing.sm),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dark ? CapyColors.darkSurfaceAlt : CapyColors.cream,
                    borderRadius: BorderRadius.circular(CapyRadius.md),
                    border: Border.all(
                      color: packed ? ink : CapyColors.cocoaSoft,
                      width: packed ? MorningSortView.packedBorder : 1.5,
                    ),
                  ),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: _nameStyle(),
                  ),
                ),
              ),
            ),
            if (packed || leftOut)
              PositionedDirectional(
                top: -MorningSortView.badgeOverhang,
                end: -MorningSortView.badgeOverhang,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: packed
                        ? CapyColors.accent
                        : dark
                        ? CapyColors.darkSurface
                        : CapyColors.cream,
                  ),
                  child: Icon(
                    packed ? Icons.check_rounded : Icons.home_rounded,
                    key: ValueKey(
                      packed
                          ? 'morning-sort-packed-$index'
                          : 'morning-sort-left-out-$index',
                    ),
                    size: CapyIconSize.md,
                    color: packed ? CapyColors.cocoa : ink,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// An item's name on its card, from the authored bank.
String morningItemName(AppLocalizations l10n, MorningItem item) =>
    switch (item) {
      MorningItem.toothbrush => l10n.gameMorningItemToothbrush,
      MorningItem.toothpaste => l10n.gameMorningItemToothpaste,
      MorningItem.apple => l10n.gameMorningItemApple,
      MorningItem.banana => l10n.gameMorningItemBanana,
      MorningItem.waterBottle => l10n.gameMorningItemWaterBottle,
      MorningItem.keys => l10n.gameMorningItemKeys,
      MorningItem.socks => l10n.gameMorningItemSocks,
      MorningItem.shoes => l10n.gameMorningItemShoes,
      MorningItem.comb => l10n.gameMorningItemComb,
      MorningItem.towel => l10n.gameMorningItemTowel,
      MorningItem.brick => l10n.gameMorningItemBrick,
      MorningItem.anchor => l10n.gameMorningItemAnchor,
      MorningItem.trafficCone => l10n.gameMorningItemTrafficCone,
      MorningItem.bowlingBall => l10n.gameMorningItemBowlingBall,
      MorningItem.cactus => l10n.gameMorningItemCactus,
      MorningItem.rubberDuck => l10n.gameMorningItemRubberDuck,
      MorningItem.anvil => l10n.gameMorningItemAnvil,
      MorningItem.snowman => l10n.gameMorningItemSnowman,
    };
