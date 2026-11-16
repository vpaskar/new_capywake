import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:meta/meta.dart';

/// A platform-agnostic abstraction over "actually arming, cancelling, and
/// re-arming an alarm so it rings on time."
///
/// This is the seam between the pure-Dart scheduling engine
/// ([AlarmScheduleService]) and the concrete platform alarm plugin (the
/// `alarm` package, used in `lib/data/`). The rest of the app — and
/// every test in the suite — talks to this interface, so:
///
/// - `lib/core/` and `lib/features/` stay Flutter-plugin-free,
/// - the test suite never touches a real alarm or notification (we use
///   `FakeAlarmEngine` under the hood),
/// - the app degrades **honestly** if a platform call fails: an engine
///   error surfaces to the caller; we never silently swallow it and tell
///   the user the alarm is set when it might not be.
///
/// Reliability honesty (do **not** weaken in concrete adapters):
///
/// - On **Android**, the engine uses exact alarms and a foreground ringing
///   service. Device power management and permissions affect delivery.
/// - On **iOS**, the concrete adapter keeps a silent audio session alive
///   while the app is alive or backgrounded; a user-terminated app stops
///   ringing. AlarmKit (iOS 26+) is the documented future path. The
///   adapter must NEVER claim termination survival on classic iOS.
abstract class AlarmEngine {
  /// Arm the platform alarm for [plan]. Implementations must be
  /// idempotent on the same `(plan.alarm.id, plan.scheduledUtc)` pair —
  /// arming twice with the same plan is a no-op.
  ///
  /// Throws [AlarmEngineException] when the platform refuses (e.g.
  /// notification permission missing, exact-alarm permission missing on
  /// Android 14+ when the app is using `SCHEDULE_EXACT_ALARM`). The caller
  /// surfaces the error honestly via `ReliabilityCopyService` — we do
  /// **not** pretend the alarm is set.
  Future<void> arm(AlarmOccurrencePlan plan);

  /// Ring [alarm] now, outside the scheduled plan set.
  ///
  /// Deliberately *not* expressed as an [arm] with a near-future plan.
  /// `AlarmScheduleCoordinator.sync` answers every alarms-table change by
  /// calling [rescheduleAll], which clears everything previously armed and
  /// re-arms only the computed schedule — so an ad-hoc plan would be silently
  /// swept away by an unrelated write landing in the same second. An immediate
  /// ring is a different kind of thing from a schedule, and this method says
  /// so.
  ///
  /// Used by the lifecycle layer for the single extra ring the post-dismiss
  /// motion check asks for. Throws [AlarmEngineException] when the platform
  /// refuses; callers degrade honestly rather than pretending it rang.
  Future<void> ringNow(Alarm alarm);

  /// Cancel the platform alarm associated with [alarmId]. Idempotent: a
  /// no-op when nothing is armed for that id.
  Future<void> cancel(String alarmId);

  /// Cancel and re-arm the next occurrence for every alarm in [plans].
  ///
  /// The engine is the source of truth — if [plans] is empty, every
  /// previously-armed alarm is cancelled. The notification calculator
  /// upstream is responsible for honouring the iOS 64-cap; this method
  /// just executes the resulting schedule.
  Future<void> rescheduleAll(List<AlarmOccurrencePlan> plans);

  /// Stream of `(alarmId)` events emitted when a platform alarm starts
  /// ringing. The lifecycle layer (Phase 07) listens here to drive the
  /// ringing UI and write the `AlarmOccurrence.triggeredAt` field.
  ///
  /// The stream is broadcast — multiple listeners (the ringing screen +
  /// History) are allowed.
  Stream<RingingAlarm> get ringingStream;

  /// Release any platform resources. Implementations should make this
  /// idempotent so it is safe to call from `ref.onDispose`.
  Future<void> dispose();
}

/// Event emitted on [AlarmEngine.ringingStream] when a platform alarm
/// fires. Pure value-type; no plugin types leak across the seam.
@immutable
class RingingAlarm {
  const RingingAlarm({
    required this.alarmId,
    required this.firedAt,
  });

  /// The id of the `Alarm` that started ringing.
  final String alarmId;

  /// The UTC instant the platform reported the ring.
  final DateTime firedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RingingAlarm &&
        other.alarmId == alarmId &&
        other.firedAt.isAtSameMomentAs(firedAt);
  }

  @override
  int get hashCode => Object.hash(alarmId, firedAt.millisecondsSinceEpoch);

  @override
  String toString() => 'RingingAlarm(alarmId: $alarmId, firedAt: $firedAt)';
}

/// Thrown by [AlarmEngine] when the platform refuses to arm/cancel an
/// alarm. The message is **diagnostic** (logs / debug surfaces); user-
/// facing copy must come from `ReliabilityCopyService`, never from this
/// type's `message`.
class AlarmEngineException implements Exception {
  const AlarmEngineException(this.message, {this.cause});

  /// Diagnostic message, English-only, never shown to users.
  final String message;

  /// Optional underlying error from the platform plugin.
  final Object? cause;

  @override
  String toString() => cause == null
      ? 'AlarmEngineException: $message'
      : 'AlarmEngineException: $message (cause: $cause)';
}
