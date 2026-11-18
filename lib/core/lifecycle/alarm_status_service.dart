import 'package:capywake/core/models/models.dart';

/// Pure-Dart lifecycle FSM for an [AlarmOccurrence].
///
/// Encapsulates the legal status transitions and produces an updated
/// [AlarmOccurrence] for each one, leaving persistence to the caller.
/// Illegal transitions throw [AlarmStateException] so a UI bug surfaces
/// loudly in tests instead of corrupting history rows.
///
/// ## Allowed transitions
///
/// | from        | to           | trigger                                    |
/// |-------------|--------------|--------------------------------------------|
/// | scheduled   | triggered    | engine reports the alarm started ringing  |
/// | scheduled   | skipped      | user pre-emptively skips this occurrence  |
/// | scheduled   | missed       | clock advances past the missed-by deadline |
/// | triggered   | snoozed      | user snoozes (snooze service signs off)   |
/// | triggered   | dismissed    | user dismisses (with confirmation if req) |
/// | triggered   | missed       | un-acted past the missed-by deadline      |
/// | snoozed     | triggered    | the snooze ring fires                     |
/// | snoozed     | dismissed    | user dismisses while snoozing             |
/// | snoozed     | missed       | un-acted past the missed-by deadline      |
/// | triggered   | escaped      | user took the puzzle's emergency escape   |
/// | snoozed     | escaped      | user took the emergency escape            |
///
/// `dismissed`, `skipped`, `escaped`, and `missed` are terminal — any
/// transition out of them is illegal.
///
/// ## Missed timing
///
/// An un-acted alarm becomes **missed** once both:
///
/// - the occurrence is at least [missedAfter] (default 30 minutes) past
///   the last instant it was still expected to be answered — the ring it
///   is waiting on for `scheduled` and `snoozed` rows, the moment it
///   started ringing for `triggered` ones, AND
/// - no further user action has occurred.
///
/// A snoozed occurrence anchors on its pending ring rather than on the
/// original trigger, because a snooze chain is the user actively using the
/// alarm. Someone on their fourth nine-minute snooze has not missed
/// anything yet; calling that "missed" would be the app deciding it knows
/// better than the person still pressing the button.
///
/// The window is conservative on purpose — CapyWake stays honest about
/// "did I actually get up" without prematurely shaming a user who
/// dismissed two minutes late.
class AlarmStatusService {
  /// Construct an [AlarmStatusService] with optional grace window.
  const AlarmStatusService({
    this.missedAfter = const Duration(minutes: 30),
  });

  /// Grace window after the final-alarm / trigger time before an un-acted
  /// occurrence is reclassified as missed.
  final Duration missedAfter;

  // --------------- Transitions ---------------

  /// Scheduled → triggered. Records the trigger time.
  AlarmOccurrence trigger({
    required AlarmOccurrence occurrence,
    required DateTime now,
  }) {
    _expect(
      occurrence,
      from: const {AlarmStatus.scheduled, AlarmStatus.snoozed},
      to: AlarmStatus.triggered,
    );
    // The pending re-ring has arrived, so it is no longer pending. Clearing
    // it here keeps `snoozedUntil` meaning exactly one thing: a ring that has
    // not happened yet.
    return occurrence.copyWith(
      status: AlarmStatus.triggered,
      triggeredAt: now.toUtc(),
      clearSnoozedUntil: true,
    );
  }

  /// The motion check's one re-ring.
  AlarmOccurrence motionReRing({
    required AlarmOccurrence occurrence,
    required DateTime now,
  }) {
    _expect(
      occurrence,
      from: const {AlarmStatus.dismissed},
      to: AlarmStatus.triggered,
    );
    if (occurrence.isMotionReRing) {
      throw const AlarmStateException('The motion check rings again once.');
    }
    return occurrence.copyWith(
      status: AlarmStatus.triggered,
      triggeredAt: now.toUtc(),
      clearDismissedAt: true,
      isMotionReRing: true,
    );
  }

  /// Triggered → snoozed. Snooze count + next ring time are computed
  /// upstream by `SnoozeService`; this method just records the result
  /// and bumps the count.
  ///
  /// [nextRingAt] lands in `AlarmOccurrence.snoozedUntil` and **not** in
  /// `scheduledAt`, which keeps pointing at the morning the occurrence is
  /// for however long the snooze chain runs.
  AlarmOccurrence snooze({
    required AlarmOccurrence occurrence,
    required int newSnoozeCount,
    required DateTime nextRingAt,
  }) {
    _expect(
      occurrence,
      from: const {AlarmStatus.triggered},
      to: AlarmStatus.snoozed,
    );
    if (newSnoozeCount < occurrence.snoozeCount + 1) {
      throw AlarmStateException(
        'Snooze must increment snoozeCount; was '
        '${occurrence.snoozeCount}, got $newSnoozeCount.',
      );
    }
    return occurrence.copyWith(
      status: AlarmStatus.snoozed,
      snoozeCount: newSnoozeCount,
      snoozedUntil: nextRingAt.toUtc(),
    );
  }

  /// Triggered/snoozed → dismissed. Records the dismiss time. Terminal.
  AlarmOccurrence dismiss({
    required AlarmOccurrence occurrence,
    required DateTime now,
  }) {
    _expect(
      occurrence,
      from: const {AlarmStatus.triggered, AlarmStatus.snoozed},
      to: AlarmStatus.dismissed,
    );
    return occurrence.copyWith(
      status: AlarmStatus.dismissed,
      dismissedAt: now.toUtc(),
      clearSnoozedUntil: true,
    );
  }

  /// Triggered/snoozed → escaped. Records the stop time in `dismissedAt`.
  /// Terminal.
  ///
  /// The user stopped the alarm without solving the wake puzzle. This exists
  /// as its own transition rather than reusing [dismiss] so History can say
  /// what actually happened: recording it as a normal dismiss would overstate
  /// the morning, and there is no "failed" state to fall into because taking
  /// the escape is never a failure.
  AlarmOccurrence escape({
    required AlarmOccurrence occurrence,
    required DateTime now,
  }) {
    _expect(
      occurrence,
      from: const {AlarmStatus.triggered, AlarmStatus.snoozed},
      to: AlarmStatus.escaped,
    );
    return occurrence.copyWith(
      status: AlarmStatus.escaped,
      dismissedAt: now.toUtc(),
      clearSnoozedUntil: true,
    );
  }

  /// Scheduled → skipped. The user pre-emptively skipped this ring.
  /// Terminal.
  AlarmOccurrence skip({required AlarmOccurrence occurrence}) {
    _expect(
      occurrence,
      from: const {AlarmStatus.scheduled},
      to: AlarmStatus.skipped,
    );
    return occurrence.copyWith(status: AlarmStatus.skipped);
  }

  /// Mark as missed. Terminal. Callers should normally use
  /// [evaluateMissed] which decides whether the missed-by deadline has
  /// elapsed; this entry point exists for explicit "the engine never
  /// fired" cases.
  AlarmOccurrence markMissed({required AlarmOccurrence occurrence}) {
    _expect(
      occurrence,
      from: const {
        AlarmStatus.scheduled,
        AlarmStatus.triggered,
        AlarmStatus.snoozed,
      },
      to: AlarmStatus.missed,
    );
    return occurrence.copyWith(
      status: AlarmStatus.missed,
      clearSnoozedUntil: true,
    );
  }

  // --------------- Predicates ---------------

  /// Whether [occurrence] should be reclassified as `missed` given [now].
  ///
  /// Returns `false` for terminal states (see
  /// [AlarmStatusTerminality.isTerminal]) and for occurrences whose
  /// missed-by deadline has not yet elapsed.
  bool isMissed({
    required AlarmOccurrence occurrence,
    required DateTime now,
  }) {
    if (occurrence.status.isTerminal) return false;
    final deadline = _missedDeadline(occurrence);
    if (deadline == null) return false;
    return !now.toUtc().isBefore(deadline);
  }

  /// Convenience: returns a missed copy if the deadline has elapsed,
  /// otherwise returns the occurrence unchanged. Useful in batch sweeps
  /// (e.g. on app start).
  AlarmOccurrence evaluateMissed({
    required AlarmOccurrence occurrence,
    required DateTime now,
  }) {
    return isMissed(occurrence: occurrence, now: now)
        ? markMissed(occurrence: occurrence)
        : occurrence;
  }

  // --------------- internals ---------------

  DateTime? _missedDeadline(AlarmOccurrence occurrence) {
    // For scheduled occurrences, the engine never fired → use the
    // scheduled time itself as the anchor.
    final anchor = switch (occurrence.status) {
      // Nothing fired, so the scheduled instant is all there is.
      AlarmStatus.scheduled => occurrence.scheduledAt.toUtc(),
      // A snoozed row anchors on the ring it is waiting for, which is
      // `snoozedUntil` (or `scheduledAt` for a row carried over from schema
      // v4 — see `AlarmOccurrence.nextRingAt`).
      AlarmStatus.snoozed => occurrence.nextRingAt,
      AlarmStatus.triggered =>
        (occurrence.triggeredAt ?? occurrence.scheduledAt).toUtc(),
      _ => null,
    };
    if (anchor == null) return null;
    return anchor.add(missedAfter);
  }

  void _expect(
    AlarmOccurrence occurrence, {
    required Set<AlarmStatus> from,
    required AlarmStatus to,
  }) {
    if (from.contains(occurrence.status)) return;
    throw AlarmStateException(
      'Illegal transition ${occurrence.status.name} -> ${to.name} '
      '(allowed from: ${from.map((s) => s.name).join(', ')}).',
    );
  }
}

/// Thrown when an illegal status transition is attempted.
///
/// The message is diagnostic-only — never user-facing. Tests rely on the
/// `name` shape ("scheduled -> snoozed") to assert defensiveness.
class AlarmStateException implements Exception {
  const AlarmStateException(this.message);

  final String message;

  @override
  String toString() => 'AlarmStateException: $message';
}
