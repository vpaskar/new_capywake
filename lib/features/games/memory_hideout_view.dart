import 'package:capywake/core/games/memory_hideout.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/game_header.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Memory Hideout. The user decides when Capy hides — no timed reveal — so a
/// screen-reader user hears where Capy is before it goes.
class MemoryHideoutView extends GameRingingView {
  const MemoryHideoutView({
    required this.seed,
    required this.difficulty,
    required super.onProgress,
    required super.onCompleted,
    required super.reduceMotion,
    super.key,
  });

  MemoryHideoutView.fromLaunch(GameLaunch launch, {Key? key})
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

  static const cardHeight = 112.0;

  /// How far the peeking capybara stands above the card floor: its feet
  /// stay behind the bush, its head shows over it.
  static const capyPeekLift = 18.0;

  /// The upright run frame, legs gathered under the body.
  static const peekFrame = 4;

  /// One swap of two bushes. Slow enough to follow half-asleep.
  static const swapDuration = Duration(milliseconds: 550);
  static const outcomeIconSize = 24.0;

  @override
  State<MemoryHideoutView> createState() => _MemoryHideoutViewState();
}

class _MemoryHideoutViewState extends State<MemoryHideoutView> {
  late MemoryHideoutRound _round = MemoryHideoutRound.start(
    difficulty: widget.difficulty,
    seed: widget.seed,
  );
  bool _completionReported = false;

  /// Card identity → slot. Only the shuffle moves cards; otherwise identity.
  late List<int> _slotOf = List.generate(_round.bushCount, (i) => i);
  int _swapIndex = 0;
  int? _movingCard;

  bool get _revealing => _round.phase == MemoryHideoutPhase.revealing;
  bool get _shuffling => _round.phase == MemoryHideoutPhase.shuffling;

  bool get _shuffles =>
      !widget.reduceMotion && !MediaQuery.accessibleNavigationOf(context);

  void _ready() {
    final next = _round.ready(shuffle: _shuffles);
    if (identical(next, _round)) return;
    _slotOf = List.generate(next.bushCount, (i) => i);
    _swapIndex = 0;
    _update(next);
    if (next.phase == MemoryHideoutPhase.shuffling) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _nextSwap());
    }
  }

  /// Show one swap; the moving card's `onEnd` calls back for the next.
  void _nextSwap() {
    if (!mounted || !_shuffling) return;
    if (_swapIndex >= _round.swaps.length) {
      _movingCard = null;
      _update(_round.finishShuffle());
      return;
    }
    final (a, b) = _round.swaps[_swapIndex++];
    final cardA = _slotOf.indexOf(a);
    final cardB = _slotOf.indexOf(b);
    setState(() {
      _slotOf[cardA] = b;
      _slotOf[cardB] = a;
      _movingCard = cardA;
    });
  }

  void _update(MemoryHideoutRound next) {
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final outcome = _outcomeText(l10n);

    return CapyCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameHeader(
            title: l10n.gameMemoryHideout,
            instruction: switch (_round.phase) {
              MemoryHideoutPhase.revealing =>
                l10n.gameMemoryHideoutRevealInstruction,
              MemoryHideoutPhase.shuffling =>
                l10n.gameMemoryHideoutShuffleInstruction,
              MemoryHideoutPhase.guessing =>
                l10n.gameMemoryHideoutGuessInstruction,
            },
            done: _round.found,
            total: _round.target,
          ),
          const SizedBox(height: CapySpacing.md),
          SizedBox(
            height: MemoryHideoutView.cardHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = CapySpacing.sm;
                final n = _round.bushCount;
                final width = (constraints.maxWidth - gap * (n - 1)) / n;
                return Stack(
                  children: [
                    for (var card = 0; card < n; card++)
                      AnimatedPositionedDirectional(
                        key: ValueKey('memory-hideout-card-$card'),
                        duration: _shuffling
                            ? MemoryHideoutView.swapDuration
                            : Duration.zero,
                        curve: Curves.easeInOut,
                        start: _slotOf[card] * (width + gap),
                        top: 0,
                        width: width,
                        height: MemoryHideoutView.cardHeight,
                        onEnd: card == _movingCard ? _nextSwap : null,
                        child: _bush(l10n, _slotOf[card]),
                      ),
                  ],
                );
              },
            ),
          ),
          if (_revealing && !_round.isComplete) ...[
            const SizedBox(height: CapySpacing.md),
            // Outlined, not filled: a filled button here reads as a twin of
            // Snooze, which sits right below it on the ringing surface.
            OutlinedButton(
              onPressed: _ready,
              style: OutlinedButton.styleFrom(
                foregroundColor: ink,
                minimumSize: const Size.fromHeight(CapyButton.height),
                side: BorderSide(color: ink, width: 1.5),
                shape: const StadiumBorder(),
                textStyle: CapyType.label,
                splashFactory: NoSplash.splashFactory,
              ),
              child: Text(l10n.gameMemoryHideoutReadyAction),
            ),
          ],
          if (outcome != null && _revealing) ...[
            const SizedBox(height: CapySpacing.sm),
            Semantics(
              liveRegion: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Image.asset(
                      CapyArt.byId('game.memoryCapy').path,
                      key: const ValueKey('memory-hideout-outcome-capy'),
                      height: MemoryHideoutView.outcomeIconSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: CapySpacing.xs),
                  Flexible(
                    child: Text(
                      outcome,
                      textAlign: TextAlign.center,
                      style: CapyType.body.copyWith(color: ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _outcomeText(AppLocalizations l10n) => switch (_round.lastOutcome) {
    null => null,
    MemoryHideoutOutcome.found => l10n.gameMemoryHideoutFound,
    MemoryHideoutOutcome.missed => l10n.gameMemoryHideoutMissed(
      _round.hiddenAt + 1,
    ),
  };

  Widget _bush(AppLocalizations l10n, int index) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shown = _revealing && index == _round.hiddenAt;
    final label = l10n.gameMemoryHideoutBushLabel(index + 1, _round.bushCount);
    final guessing = !_revealing;

    return Semantics(
      button: guessing,
      label: shown
          ? '$label. ${l10n.gameMemoryHideoutCapyHere(index + 1)}'
          : label,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('memory-hideout-bush-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: guessing ? () => _update(_round.pick(index)) : null,
        child: Container(
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(CapySpacing.sm),
          decoration: BoxDecoration(
            color: dark ? CapyColors.darkSurfaceAlt : CapyColors.cream,
            borderRadius: BorderRadius.circular(CapyRadius.lg),
            border: Border.all(
              color: dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft,
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              if (shown)
                Positioned(
                  key: const ValueKey('memory-hideout-peeking-capy'),
                  left: CapySpacing.xs,
                  right: CapySpacing.xs,
                  bottom: MemoryHideoutView.capyPeekLift,
                  child: Image.asset(
                    CapyArt.runFrames[MemoryHideoutView.peekFrame].path,
                    fit: BoxFit.contain,
                  ),
                ),
              Image.asset(
                CapyArt.byId('game.bush').path,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
