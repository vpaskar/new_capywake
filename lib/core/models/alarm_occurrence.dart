import 'package:capywake/core/models/alarm_status.dart';
import 'package:meta/meta.dart';

/// A single, concrete fire of an `Alarm`.
///
/// One `Alarm` (the user-configured rule) yields many [AlarmOccurrence]s (the
/// individual rings). The ringing layer creates one when an alarm fires and
/// advances [status] through the state machine; History reads them.
///
/// Times stored as **UTC `DateTime`s** in the database; the schedule engine
/// converts to/from local time using the `timezone` package so DST works
/// correctly across spring-forward / fall-back.
@immutable
class AlarmOccurrence {
  const AlarmOccurrence({
    required this.id,
    required this.alarmId,
    required this.scheduledAt,
    required this.softStartAt,
    required this.status,
    required this.triggeredAt,
    required this.dismissedAt,
    required this.snoozeCount,
    required this.note,
    this.snoozedUntil,
    this.isMotionReRing = false,
  }) : assert(snoozeCount >= 0, 'snoozeCount must be >= 0.'),
       assert(
         snoozedUntil == null || status == AlarmStatus.snoozed,
         'snoozedUntil is the pending re-ring, so it only exists while the '
         'occurrence is snoozed.',
       );

  /// Stable id for this specific fire (UUID).
  final String id;

  /// Foreign key to the parent `Alarm`.
  final String alarmId;

  /// The morning this occurrence is for — its target ring time. UTC.
  ///
  /// **Fixed for the life of the row.** It is what identifies the ring the
  /// occurrence belongs to, which is how the schedule engine knows not to
  /// re-arm a morning that is already finished. Snoozing does *not* move it:
  /// pressing Snooze at 07:04 is still the 07:00 alarm, and the instant it
  /// is due to ring again lives in [snoozedUntil].
  ///
  /// Until Phase 34 this field carried the pending re-ring too, so it meant
  /// the target on a `scheduled` row and the next snooze on a `snoozed` one.
  /// That ambiguity is why a dismissed occurrence could not be matched back
  /// to its own morning — and so why a wake window that had already been
  /// dismissed was armed all over again.
  final DateTime scheduledAt;

  /// The soft-start time (when the wake window opens). `null` when the
  /// alarm has no soft-start. UTC.
  final DateTime? softStartAt;

  /// Lifecycle state. See [AlarmStatus].
  final AlarmStatus status;

  /// When the occurrence actually rang. `null` until [status] advances past
  /// `scheduled`. UTC.
  final DateTime? triggeredAt;

  /// When the occurrence was dismissed. `null` for non-terminal states. UTC.
  final DateTime? dismissedAt;

  /// How many times the user has snoozed this occurrence so far.
  final int snoozeCount;

  /// Free-form, neutral note for History (e.g. "Snoozed twice"). Plain
  /// strings live here; pluralisation is the UI layer's job at render time.
  /// May be empty.
  final String note;

  /// Whether this ring is the one extra ring the post-dismiss motion check
  /// asks for after seeing no movement.
  ///
  /// Persisted rather than tracked in memory, and that is the whole point: it
  /// is what makes "rings once more, and exactly once" survive the app being
  /// killed between the re-ring being queued and the user stopping it. The
  /// lifecycle layer refuses to open a second motion window on an occurrence
  /// carrying this flag, so the feature cannot loop.
  final bool isMotionReRing;

  /// When a snoozed occurrence is due to ring again. UTC. `null` unless
  /// [status] is [AlarmStatus.snoozed].
  ///
  /// Separate from [scheduledAt] so the occurrence keeps knowing which
  /// morning it belongs to across a whole snooze chain.
  final DateTime? snoozedUntil;

  /// The instant this occurrence is next due to ring — [snoozedUntil] while
  /// snoozed, [scheduledAt] otherwise. Always UTC.
  ///
  /// Meaningful for a live occurrence. On a terminal one it reads back as the
  /// morning, because nothing is due.
  ///
  /// The fallback is what carries rows written before the `snoozedUntil`
  /// column existed: a snoozed row upgraded from schema v4 has the pending
  /// re-ring in [scheduledAt], and reading it here keeps that ring armed
  /// exactly as it was before the upgrade.
  DateTime get nextRingAt => (snoozedUntil ?? scheduledAt).toUtc();

  AlarmOccurrence copyWith({
    String? id,
    String? alarmId,
    DateTime? scheduledAt,
    DateTime? softStartAt,
    bool clearSoftStartAt = false,
    AlarmStatus? status,
    DateTime? triggeredAt,
    bool clearTriggeredAt = false,
    DateTime? dismissedAt,
    bool clearDismissedAt = false,
    int? snoozeCount,
    String? note,
    DateTime? snoozedUntil,
    bool clearSnoozedUntil = false,
    bool? isMotionReRing,
  }) {
    return AlarmOccurrence(
      id: id ?? this.id,
      alarmId: alarmId ?? this.alarmId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      softStartAt: clearSoftStartAt ? null : (softStartAt ?? this.softStartAt),
      status: status ?? this.status,
      triggeredAt: clearTriggeredAt ? null : (triggeredAt ?? this.triggeredAt),
      dismissedAt: clearDismissedAt ? null : (dismissedAt ?? this.dismissedAt),
      snoozeCount: snoozeCount ?? this.snoozeCount,
      note: note ?? this.note,
      snoozedUntil: clearSnoozedUntil
          ? null
          : (snoozedUntil ?? this.snoozedUntil),
      isMotionReRing: isMotionReRing ?? this.isMotionReRing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlarmOccurrence &&
        other.id == id &&
        other.alarmId == alarmId &&
        other.scheduledAt == scheduledAt &&
        other.softStartAt == softStartAt &&
        other.status == status &&
        other.triggeredAt == triggeredAt &&
        other.dismissedAt == dismissedAt &&
        other.snoozeCount == snoozeCount &&
        other.note == note &&
        other.snoozedUntil == snoozedUntil &&
        other.isMotionReRing == isMotionReRing;
  }

  @override
  int get hashCode => Object.hash(
    id,
    alarmId,
    scheduledAt,
    softStartAt,
    status,
    triggeredAt,
    dismissedAt,
    snoozeCount,
    note,
    snoozedUntil,
    isMotionReRing,
  );
}
