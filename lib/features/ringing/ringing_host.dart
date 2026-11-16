import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/ringing/puzzle_view.dart';
import 'package:capywake/features/ringing/ringing_providers.dart';
import 'package:capywake/features/ringing/ringing_screen.dart';
import 'package:capywake/features/ringing/ringing_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puts the ringing surface over the whole app. The watch on
/// `ringingSessionProvider` is load-bearing — unwatched, no alarm rings.
class RingingHost extends ConsumerStatefulWidget {
  const RingingHost({required this.child, super.key});

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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(ringingSessionProvider).value;
    if (session == null) {
      _round = null;
      _roundOccurrenceId = null;
      return widget.child;
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
    final round = _roundFor(session);

    return RingingScreen(
      session: _withRoundVisibility(session, round),
      escapeStrictness: _renderableSettings(session.alarm).escapeStrictness,
      onDismiss: controller.dismiss,
      onSnooze: controller.snooze,
      onEscape: controller.escape,
      puzzleSlot: round == null
          ? null
          : PuzzleView(
              round: round,
              onRoundChanged: (next) => _onRoundChanged(next, session),
              onSolved: controller.dismiss,
            ),
    );
  }

  /// The live round, or `null` when this alarm is not puzzle-backed. Seeded
  /// from the occurrence and snooze count: reproducible, never repeated.
  PuzzleRound? _roundFor(RingingSession session) {
    if (session.alarm.dismissMethod != DismissMethod.puzzle) return null;

    final sameRing =
        _roundOccurrenceId == session.occurrence.id &&
        _roundSnoozeCount == session.occurrence.snoozeCount;
    if (sameRing && _round != null) return _round;

    final settings = _renderableSettings(session.alarm);
    final round = PuzzleRound.start(
      settings: settings,
      seed: Object.hash(session.occurrence.id, session.occurrence.snoozeCount),
    );
    _round = round;
    _roundOccurrenceId = session.occurrence.id;
    _roundSnoozeCount = session.occurrence.snoozeCount;
    return round;
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
