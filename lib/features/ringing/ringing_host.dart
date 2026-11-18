import 'dart:async';

import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/games/wake_challenge.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/data/camera/camera_providers.dart';
import 'package:capywake/data/motion/motion_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/games/game_registry.dart';
import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:capywake/features/ringing/puzzle_view.dart';
import 'package:capywake/features/ringing/ringing_controller.dart';
import 'package:capywake/features/ringing/ringing_providers.dart';
import 'package:capywake/features/ringing/ringing_screen.dart';
import 'package:capywake/features/ringing/ringing_session.dart';
import 'package:capywake/features/ringing/ringing_win_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puts the ringing surface over the whole app. The watch on
/// `ringingSessionProvider` is load-bearing — unwatched, no alarm rings.
class RingingHost extends ConsumerStatefulWidget {
  const RingingHost({required this.child, super.key});

  /// Holds the challenge's place for the moment a pick waits on readiness.
  static const pendingSlotHeight = 240.0;

  /// On a cold start the camera game's readiness may still be loading when
  /// the ring arrives; wait this long before ringing without it.
  static const readinessWait = Duration(seconds: 2);

  final Widget child;

  /// The types [PuzzleView] can draw. All ten generate in `lib/core/`; the
  /// other seven have no renderer yet and must not reach a ringing user.
  static const renderableTypes = <PuzzleType>{
    PuzzleType.arithmetic,
    PuzzleType.sequenceNext,
    PuzzleType.missingOperator,
  };

  @override
  ConsumerState<RingingHost> createState() => _RingingHostState();
}

class _RingingHostState extends ConsumerState<RingingHost> {
  PuzzleRound? _round;
  String? _roundOccurrenceId;
  int _roundSnoozeCount = -1;
  WakeChallenge? _challenge;
  GameChallenge? _gameProgress;
  ({Timer timer, String gameId})? _win;
  Timer? _readinessWait;
  bool _readinessGaveUp = false;

  @override
  void dispose() {
    _win?.timer.cancel();
    _readinessWait?.cancel();
    super.dispose();
  }

  /// Stops the alarm first, then shows the win for a moment.
  void _onGameWon(RingingController controller, String gameId) {
    unawaited(controller.dismiss());
    _win?.timer.cancel();
    setState(() {
      _win = (
        timer: Timer(RingingWinOverlay.visibleFor, _closeWin),
        gameId: gameId,
      );
    });
  }

  void _closeWin() {
    if (!mounted) return;
    _win?.timer.cancel();
    setState(() => _win = null);
  }

  @override
  Widget build(BuildContext context) {
    // Kept warm from app start, so a ring never picks on a loading value.
    ref
      ..watch(qrHuntReadyProvider)
      ..watch(qrCheckpointProvider);
    final session = ref.watch(ringingSessionProvider).value;
    if (session == null) {
      _readinessWait?.cancel();
      _readinessWait = null;
      _readinessGaveUp = false;
      _round = null;
      _roundOccurrenceId = null;
      _challenge = null;
      _gameProgress = null;
      final win = _win;
      if (win == null) return widget.child;
      return Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: RingingWinOverlay(
              gameId: win.gameId,
              onClose: _closeWin,
            ),
          ),
        ],
      );
    }
    if (_win != null && _roundOccurrenceId != session.occurrence.id) {
      _win!.timer.cancel();
      _win = null;
    }

    return Stack(
      children: [
        widget.child,
        // Covers the app underneath. The Navigator is for the escape sheet:
        // above the router's own, `showModalBottomSheet` would throw.
        Positioned.fill(
          child: Navigator(
            onGenerateRoute: (routeSettings) => PageRouteBuilder<void>(
              settings: routeSettings,
              pageBuilder: (context, _, _) => _buildScreen(context),
            ),
          ),
        ),
      ],
    );
  }

  /// Read live on every build rather than captured into the route: a route
  /// built once in `onGenerateRoute` would never see a new round.
  Widget _buildScreen(BuildContext context) {
    final session = ref.watch(ringingSessionProvider).value;
    if (session == null) return const SizedBox.shrink();
    final controller = ref.read(ringingControllerProvider);
    final settings = _renderableSettings(session.alarm);
    if (_awaitsCameraReadiness(session, settings)) {
      return RingingScreen(
        session: session,
        escapeStrictness: settings.escapeStrictness,
        onDismiss: controller.dismiss,
        onSnooze: controller.snooze,
        onEscape: controller.escape,
        puzzleSlot: const SizedBox(
          key: ValueKey('challenge-pending'),
          height: RingingHost.pendingSlotHeight,
        ),
      );
    }
    final challenge = _challengeFor(session, settings);
    final round = challenge is PuzzleWakeChallenge ? _round : null;

    return RingingScreen(
      session: _withGameVisibility(
        _withRoundVisibility(session, round),
        settings,
      ),
      escapeStrictness: settings.escapeStrictness,
      onDismiss: controller.dismiss,
      onSnooze: controller.snooze,
      onEscape: controller.escape,
      puzzleSlot: switch (challenge) {
        null => null,
        PuzzleWakeChallenge() => PuzzleView(
          round: round!,
          onRoundChanged: (next) => _onRoundChanged(next, session),
          onSolved: controller.dismiss,
        ),
        GameWakeChallenge(:final gameId) => GameRingingSlot(
          builder: ({required reduceMotion}) => GameRegistry.build(
            gameId,
            GameLaunch(
              seed: PuzzleRound.advanceSeed(_ringSeed(session)),
              difficulty: settings.difficulty,
              onProgress: (progress) => _onGameProgress(progress, settings),
              onCompleted: () => _onGameWon(controller, gameId),
              reduceMotion: reduceMotion,
              motion: ref.watch(motionSensorProvider),
              steps: ref.watch(stepSensorProvider),
              scanner: ref.watch(codeScannerProvider),
              qrCheckpoint: ref.watch(qrCheckpointProvider).value,
            ),
            key: ValueKey(_ringSeed(session)),
          )!,
        ),
      },
    );
  }

  /// Whether this ring's pick must wait for the camera game's readiness: its
  /// pool has one, nothing is picked yet, and the answer is loading or stale.
  bool _awaitsCameraReadiness(RingingSession session, PuzzleSettings settings) {
    if (session.alarm.dismissMethod != DismissMethod.puzzle) return false;
    if (_readinessGaveUp) return false;
    final picked =
        _challenge != null &&
        _roundOccurrenceId == session.occurrence.id &&
        _roundSnoozeCount == session.occurrence.snoozeCount;
    if (picked) return false;
    final hasCameraGame = settings.enabledGames.any(
      (id) => GameCatalogue.byId(id)?.usesCamera ?? false,
    );
    final readiness = ref.read(qrHuntReadyProvider);
    final settled =
        !readiness.isLoading && (readiness.hasValue || readiness.hasError);
    if (!hasCameraGame || settled) return false;
    _readinessWait ??= Timer(RingingHost.readinessWait, () {
      if (mounted) setState(() => _readinessGaveUp = true);
    });
    return true;
  }

  /// A camera game rings only once it can be finished; otherwise the pool's
  /// other members ring, and an empty pool is a puzzle.
  bool _canRing(String gameId) {
    if (!GameRegistry.isLaunchable(gameId)) return false;
    if (!(GameCatalogue.byId(gameId)?.usesCamera ?? false)) return true;
    return ref.read(qrHuntReadyProvider).value ?? false;
  }

  int _ringSeed(RingingSession session) =>
      Object.hash(session.occurrence.id, session.occurrence.snoozeCount);

  /// This ring's challenge, or `null` when the alarm is not puzzle-backed.
  /// Picked once per ring from the alarm's resolved pool, seeded as before.
  WakeChallenge? _challengeFor(
    RingingSession session,
    PuzzleSettings settings,
  ) {
    if (session.alarm.dismissMethod != DismissMethod.puzzle) return null;

    final sameRing =
        _roundOccurrenceId == session.occurrence.id &&
        _roundSnoozeCount == session.occurrence.snoozeCount;
    if (sameRing && _challenge != null) return _challenge;

    final seed = _ringSeed(session);
    final challenge = WakeChallengeSelector.pick(
      settings: settings,
      seed: seed,
      isLaunchable: _canRing,
    );
    _challenge = challenge;
    _gameProgress = null;
    _round = challenge is PuzzleWakeChallenge
        ? PuzzleRound.start(settings: settings, seed: seed)
        : null;
    _roundOccurrenceId = session.occurrence.id;
    _roundSnoozeCount = session.occurrence.snoozeCount;
    return challenge;
  }

  /// Same rule as a puzzle, against the alarm's resolved tolerance.
  RingingSession _withGameVisibility(
    RingingSession session,
    PuzzleSettings settings,
  ) {
    final progress = _gameProgress;
    if (progress == null) return session;
    final visibility = progress.escapeVisibilityFor(
      toleratedStruggles: settings.toleratedWrongAnswers,
    );
    if (visibility != PuzzleEscapeVisibility.prominent) return session;
    return session.copyWith(escapeVisibility: visibility);
  }

  void _onGameProgress(GameChallenge progress, PuzzleSettings settings) {
    setState(() => _gameProgress = progress);
    if (progress.escapeVisibilityFor(
          toleratedStruggles: settings.toleratedWrongAnswers,
        ) ==
        PuzzleEscapeVisibility.prominent) {
      ref.read(ringingControllerProvider).raiseEscapeVisibility();
    }
  }

  PuzzleSettings _renderableSettings(Alarm alarm) {
    final defaults =
        ref.read(puzzleSettingsStreamProvider).value ??
        PuzzleSettings.defaults();
    final resolved = alarm.resolvePuzzleSettings(defaults);
    final drawable = resolved.enabledTypes.intersection(
      RingingHost.renderableTypes,
    );
    if (drawable.isEmpty) {
      return resolved.copyWith(enabledTypes: RingingHost.renderableTypes);
    }
    return resolved.copyWith(enabledTypes: drawable);
  }

  /// Prominent when the round says so this frame, or the controller already
  /// raised it: reading only the controller lags by a stream round-trip.
  RingingSession _withRoundVisibility(
    RingingSession session,
    PuzzleRound? round,
  ) {
    if (round == null) return session;
    if (session.escapeVisibility == PuzzleEscapeVisibility.prominent) {
      return session;
    }
    if (round.escapeVisibility != PuzzleEscapeVisibility.prominent) {
      return session;
    }
    return session.copyWith(
      escapeVisibility: PuzzleEscapeVisibility.prominent,
    );
  }

  void _onRoundChanged(PuzzleRound next, RingingSession session) {
    setState(() => _round = next);
    final settings = _renderableSettings(session.alarm);
    if (settings.escapeVisibilityFor(next.easing) ==
        PuzzleEscapeVisibility.prominent) {
      ref.read(ringingControllerProvider).raiseEscapeVisibility();
    }
  }
}
