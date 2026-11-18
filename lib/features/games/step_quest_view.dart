import 'dart:async';
import 'dart:math' as math;

import 'package:capywake/core/games/step_quest.dart';
import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/core/motion/step_detector.dart';
import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/core/motion/step_tally.dart';
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

/// Step Quest: walk with the phone, or tap the step button, to walk Capy
/// across the meadow. The button always works.
class StepQuestView extends GameRingingView {
  const StepQuestView({
    required this.difficulty,
    required this.motion,
    required this.steps,
    required super.onProgress,
    required super.onCompleted,
    required super.reduceMotion,
    super.key,
  });

  StepQuestView.fromLaunch(GameLaunch launch, {Key? key})
    : this(
        difficulty: launch.difficulty,
        motion: launch.motion,
        steps: launch.steps,
        onProgress: launch.onProgress,
        onCompleted: launch.onCompleted,
        reduceMotion: launch.reduceMotion,
        key: key,
      );

  final PuzzleDifficulty difficulty;
  final MotionSensor motion;
  final StepSensor steps;

  static const fieldHeight = 120.0;
  static const stepButtonHeight = 56.0;

  /// `collection_02` is 230 × 242 px: sharp to 76 pt at 3×.
  static const capySize = 76.0;
  static const stride = Duration(milliseconds: 280);
  static const strideLift = 8.0;
  static const strideTilt = 0.06;

  @override
  State<StepQuestView> createState() => _StepQuestViewState();
}

class _StepQuestViewState extends State<StepQuestView>
    with WidgetsBindingObserver {
  late StepQuestRound _round = StepQuestRound.start(
    difficulty: widget.difficulty,
  );
  var _tally = StepTally();
  final _detector = StepDetector();
  StreamSubscription<MotionSample>? _samples;
  StreamSubscription<int>? _sensorSteps;
  StreamSubscription<void>? _accessChanges;
  Timer? _stall;
  bool _readingAccess = false;
  bool _completionReported = false;
  bool _precached = false;

  bool get _moves =>
      !widget.reduceMotion && !MediaQuery.accessibleNavigationOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenMotion();
    _listenAccessChanges();
    unawaited(_readAccess());
    _armStall();
  }

  @override
  void didUpdateWidget(StepQuestView old) {
    super.didUpdateWidget(old);
    if (old.motion != widget.motion) _listenMotion();
    if (old.steps == widget.steps) return;
    unawaited(_sensorSteps?.cancel());
    _sensorSteps = null;
    _tally = StepTally();
    if (_samples == null) _listenMotion();
    _listenAccessChanges();
    unawaited(_readAccess());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _sensorSteps == null) {
      unawaited(_readAccess());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    unawaited(
      precacheImage(AssetImage(CapyArt.byId('game.capy.hiking').path), context),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    super.dispose();
  }

  void _listenAccessChanges() {
    unawaited(_accessChanges?.cancel());
    _accessChanges = widget.steps.accessChanges.listen((_) {
      if (_sensorSteps == null) unawaited(_readAccess());
    });
  }

  Future<void> _readAccess() async {
    if (_readingAccess || _round.isComplete || !_tally.canPromote) return;
    _readingAccess = true;
    final sensor = widget.steps;
    final access = await sensor.access();
    _readingAccess = false;
    if (!mounted || _round.isComplete) return;
    if (sensor != widget.steps) return _readAccess();
    if (access == StepAccess.ready && _sensorSteps == null) _listenSensor();
  }

  void _listenSensor() {
    _tally.sensorReady();
    if (_tally.source != StepSource.sensor) return;
    _sensorSteps = widget.steps.steps.listen(
      _onSensorSteps,
      onError: (Object _) => _sensorFailed(),
      onDone: _sensorFailed,
    );
    setState(() {});
  }

  void _listenMotion() {
    unawaited(_samples?.cancel());
    _samples = _round.isComplete || _tally.sensorProven
        ? null
        : widget.motion.samples.listen(_onSample, onError: (Object _) {});
  }

  void _onSensorSteps(int count) {
    final added = _tally.fromSensor(count);
    if (_tally.sensorProven && _samples != null) {
      unawaited(_samples!.cancel());
      _samples = null;
    }
    _walk(added);
  }

  void _sensorFailed() {
    if (!mounted) return;
    unawaited(_sensorSteps?.cancel());
    _sensorSteps = null;
    _tally.sensorFailed();
    if (_samples == null) _listenMotion();
    setState(() {});
  }

  void _onSample(MotionSample sample) {
    final found = _detector.register(sample);
    if (found == 0) return;
    final wasSensor = _tally.source == StepSource.sensor;
    final added = _tally.fromMotion(found);
    if (wasSensor && _tally.source == StepSource.motion) {
      unawaited(_sensorSteps?.cancel());
      _sensorSteps = null;
      setState(() {});
    }
    _walk(added);
  }

  void _tap() => _walk(1);

  void _walk(int count) {
    if (count <= 0 || _round.isComplete) return;
    _apply(_round.walk(count));
    if (!_round.isComplete) _armStall();
  }

  void _armStall() {
    _stall?.cancel();
    _stall = Timer(StepQuestRound.stallAfter, () {
      if (!mounted) return;
      _apply(_round.stall());
      _armStall();
    });
  }

  void _stop() {
    unawaited(_samples?.cancel());
    _samples = null;
    unawaited(_sensorSteps?.cancel());
    _sensorSteps = null;
    unawaited(_accessChanges?.cancel());
    _accessChanges = null;
    _stall?.cancel();
  }

  void _apply(StepQuestRound next) {
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final outcome = switch (_round.lastOutcome) {
      null => null,
      StepQuestOutcome.stalled => l10n.gameStepQuestStalled,
    };
    final source = _tally.source == StepSource.sensor
        ? l10n.gameStepQuestSourceSensor
        : l10n.gameStepQuestSourceMotion;

    return CapyCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameHeader(
            title: l10n.gameStepQuest,
            instruction: l10n.gameStepQuestInstruction,
            done: _round.milestonesDone,
            total: _round.milestones,
          ),
          const SizedBox(height: CapySpacing.md),
          SizedBox(height: StepQuestView.fieldHeight, child: _field(l10n)),
          const SizedBox(height: CapySpacing.xs),
          Stack(
            alignment: Alignment.center,
            children: [
              for (final reserved in [
                l10n.gameStepQuestSourceSensor,
                l10n.gameStepQuestSourceMotion,
              ])
                ExcludeSemantics(
                  child: Opacity(
                    opacity: 0,
                    child: Text(
                      reserved,
                      textAlign: TextAlign.center,
                      style: CapyType.caption,
                    ),
                  ),
                ),
              Text(
                source,
                key: const ValueKey('step-quest-source'),
                textAlign: TextAlign.center,
                style: CapyType.caption.copyWith(color: inkSoft),
              ),
            ],
          ),
          const SizedBox(height: CapySpacing.sm),
          _stepButton(l10n),
          const SizedBox(height: CapySpacing.sm),
          GameOutcomeLine(
            text: outcome,
            serial: _round.steps,
            reserveFor: [l10n.gameStepQuestStalled],
          ),
        ],
      ),
    );
  }

  /// A game control, not the orange call to action: Snooze sits just below
  /// it, and a slip between twin buttons would snooze the alarm.
  Widget _stepButton(AppLocalizations l10n) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final done = _round.isComplete;

    return Semantics(
      button: true,
      enabled: !done,
      label: l10n.gameStepQuestStep,
      onTap: done ? null : _tap,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('step-quest-step'),
        behavior: HitTestBehavior.opaque,
        onTap: done ? null : _tap,
        child: Container(
          height: StepQuestView.stepButtonHeight,
          decoration: BoxDecoration(
            color: dark ? CapyColors.darkSurface : CapyColors.surface,
            borderRadius: BorderRadius.circular(CapyRadius.pill),
            border: Border.all(color: ink, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_walk_rounded, color: ink),
              const SizedBox(width: CapySpacing.xs),
              Flexible(
                child: Text(
                  l10n.gameStepQuestStep,
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

  Widget _field(AppLocalizations l10n) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final travel = rtl ? 1 - 2 * _round.level : 2 * _round.level - 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(CapyRadius.lg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              CapyArt.byId('game.meadow').path,
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.4),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: CapySpacing.sm),
              child: Semantics(
                liveRegion: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: dark ? CapyColors.darkSurface : CapyColors.surface,
                    borderRadius: BorderRadius.circular(CapyRadius.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CapySpacing.md,
                      vertical: CapySpacing.xs,
                    ),
                    child: Text(
                      l10n.gameStepQuestCount(_round.steps, _round.target),
                      key: const ValueKey('step-quest-count'),
                      style: CapyType.label.copyWith(color: ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CapySpacing.sm),
            child: AnimatedAlign(
              key: const ValueKey('step-quest-trail'),
              duration: _moves ? StepQuestView.stride : Duration.zero,
              curve: Curves.easeOut,
              alignment: Alignment(travel, 1),
              child: ExcludeSemantics(child: _capy(flip: rtl)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _capy({required bool flip}) {
    final image = Transform.flip(
      flipX: flip,
      child: Image.asset(
        CapyArt.byId('game.capy.hiking').path,
        key: const ValueKey('step-quest-capy'),
        width: StepQuestView.capySize,
        height: StepQuestView.capySize,
        fit: BoxFit.contain,
      ),
    );
    if (!_moves || _round.steps == 0) return image;
    return TweenAnimationBuilder<double>(
      key: ValueKey(('stride', _round.steps)),
      tween: Tween(begin: 0, end: 1),
      duration: StepQuestView.stride,
      builder: (context, t, child) {
        final arc = math.sin(math.pi * t);
        return Transform.translate(
          offset: Offset(0, -StepQuestView.strideLift * arc),
          child: Transform.rotate(
            angle: StepQuestView.strideTilt * arc * (flip ? -1 : 1),
            child: child,
          ),
        );
      },
      child: image,
    );
  }
}
