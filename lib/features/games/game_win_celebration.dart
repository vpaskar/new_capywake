import 'dart:async';

import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/games/win_art.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/game_names.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// A finished game's art, headline and a calm [subline]. [art] picks the
/// game's own pose (the cheer when it has none), the cheer or the trophy.
class GameWinPanel extends StatelessWidget {
  const GameWinPanel({
    required this.gameId,
    required this.subline,
    this.art = WinArt.pose,
    super.key,
  });

  final String gameId;
  final String subline;
  final WinArt art;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final poseId = art == WinArt.pose
        ? GameCatalogue.byId(gameId)?.winPoseAssetId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: GameWinCelebration(
            semanticLabel: l10n.gameWinImageLabel,
            pose: poseId == null ? null : CapyArt.byId(poseId),
            loop: art == WinArt.trophy ? CapyArt.celebrationLoop : null,
            size: poseId == null
                ? GameWinCelebration.defaultSize
                : ArtUse.winPose.renderBoxPt,
          ),
        ),
        const SizedBox(height: CapySpacing.md),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CapyColors.accent.withValues(alpha: dark ? 0.28 : 0.18),
              borderRadius: BorderRadius.circular(CapyRadius.xl),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CapySpacing.lg,
                vertical: CapySpacing.sm,
              ),
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  gameWinHeadline(l10n, gameId),
                  textAlign: TextAlign.center,
                  style: CapyType.title.copyWith(
                    color: dark ? CapyColors.accent : CapyColors.accentDeep,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: CapySpacing.sm),
        Text(
          subline,
          textAlign: TextAlign.center,
          style: CapyType.body.copyWith(
            color: dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft,
          ),
        ),
      ],
    );
  }
}

/// The win art. A still [pose] springs in; [frames] play twice, then rest; a
/// [loop] plays on. Under reduce-motion or a screen reader it is one still.
class GameWinCelebration extends StatefulWidget {
  const GameWinCelebration({
    required this.semanticLabel,
    this.pose,
    this.frames,
    this.loop,
    this.size = defaultSize,
    super.key,
  });

  final String semanticLabel;
  final ArtAsset? pose;
  final List<ArtAsset>? frames;
  final ArtAsset? loop;
  final double size;

  static const defaultSize = 120.0;
  static const frameDuration = Duration(milliseconds: 110);
  static const entrance = Duration(milliseconds: 700);
  static const plays = 2;

  @override
  State<GameWinCelebration> createState() => _GameWinCelebrationState();
}

class _GameWinCelebrationState extends State<GameWinCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.pose == null
        ? GameWinCelebration.frameDuration * _frames.length
        : GameWinCelebration.entrance,
  );
  bool _started = false;
  bool _still = false;

  List<ArtAsset> get _frames =>
      widget.pose != null ? [widget.pose!] : widget.frames ?? CapyArt.winFrames;

  double get _rest => widget.pose == null ? 0 : 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (widget.loop != null) return;
    for (final frame in _frames) {
      unawaited(precacheImage(AssetImage(frame.path), context));
    }
    if (_still) {
      _controller
        ..stop()
        ..value = _rest;
    } else if (!_started) {
      _started = true;
      final run = widget.pose == null
          ? _controller.repeat(count: GameWinCelebration.plays)
          : _controller.forward(from: 0);
      unawaited(
        run.orCancel.then((_) => _controller.value = _rest, onError: (_) {}),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => switch (widget) {
            GameWinCelebration(:final loop?) => _loop(loop),
            GameWinCelebration(pose: null) => _frame(),
            _ => _springIn(),
          },
        ),
      ),
    );
  }

  Widget _frame() {
    final frames = _frames;
    final index = (_controller.value * frames.length).floor().clamp(
      0,
      frames.length - 1,
    );
    return Image.asset(
      frames[index].path,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
  }

  /// The WebP's own frames drive it; `TickerMode` holds it on frame 0, which
  /// `Image` alone does only for reduce-motion, not a screen reader.
  Widget _loop(ArtAsset loop) => TickerMode(
    enabled: !_still,
    child: Image.asset(
      loop.path,
      key: const ValueKey('win-loop'),
      gaplessPlayback: true,
      excludeFromSemantics: true,
    ),
  );

  Widget _springIn() {
    final t = _controller.value;
    return Opacity(
      opacity: Curves.easeOut.transform((t * 2.5).clamp(0, 1)),
      child: Transform.scale(
        scale: 0.6 + 0.4 * Curves.elasticOut.transform(t),
        child: Image.asset(widget.pose!.path, excludeFromSemantics: true),
      ),
    );
  }
}
