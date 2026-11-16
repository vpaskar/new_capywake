/// Lifecycle state of a single `AlarmOccurrence`.
///
/// The full state machine (transitions, missed-alarm detection) lives in
/// `AlarmStatusService`; this enum is the value type both layers agree on.
///
/// Persisted as the [name] string so reordering values stays non-breaking.
enum AlarmStatus {
  /// The occurrence is queued for a future ring. The default state when an
  /// occurrence is created by the schedule engine.
  scheduled,

  /// The occurrence has fired and is currently ringing (or in its post-ring
  /// confirmation window).
  triggered,

  /// The user pressed snooze; the occurrence is queued to ring again. The
  /// snooze count lives on the occurrence itself.
  snoozed,

  /// The user dismissed the alarm and (if required by the mode) confirmed
  /// they are up. Terminal.
  dismissed,

  /// The user pre-emptively skipped this occurrence (e.g. a one-off "skip
  /// tomorrow"). Terminal.
  skipped,

  /// The user stopped the alarm using the emergency escape instead of solving
  /// the wake puzzle. Terminal.
  ///
  /// A **distinct outcome on purpose** — not `dismissed`, because the puzzle
  /// was not solved and recording it as a normal dismiss would quietly
  /// overstate the morning; and emphatically not a failure state, because
  /// `CLAUDE.md` makes the escape a safety rule. Someone ill, about to wake a
  /// child, or taking an urgent call used the way out that exists for exactly
  /// that, and History says so plainly with no scolding.
  escaped,

  /// The alarm did not get acknowledged within its acceptable window
  /// (snoozes exhausted with no dismiss, or never triggered because the
  /// platform killed the engine — surfaced honestly in History). Terminal.
  missed,
}

/// Whether a status is **terminal** — the morning it belongs to is over and
/// no further transition out of it is legal.
extension AlarmStatusTerminality on AlarmStatus {
  /// True for [AlarmStatus.dismissed], [AlarmStatus.skipped],
  /// [AlarmStatus.escaped] and [AlarmStatus.missed].
  ///
  /// Two layers depend on this being one definition rather than two.
  /// `AlarmStatusService` refuses transitions out of a terminal state, and
  /// the schedule engine refuses to *re-arm* the ring a terminal occurrence
  /// belongs to — which is the whole reason a dismissed alarm inside an open
  /// wake window no longer goes off again seconds later.
  bool get isTerminal => switch (this) {
    AlarmStatus.dismissed ||
    AlarmStatus.skipped ||
    AlarmStatus.escaped ||
    AlarmStatus.missed => true,
    AlarmStatus.scheduled ||
    AlarmStatus.triggered ||
    AlarmStatus.snoozed => false,
  };
}
