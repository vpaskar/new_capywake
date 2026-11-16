import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:meta/meta.dart';

/// A platform-agnostic abstraction over the OS local-notification system
/// for **pre-alarm reminders** (e.g. "soft wake starts in 5 minutes",
/// "final alarm at 07:10").
///
/// The actual alarm ring is driven by the `AlarmEngine` (the `alarm`
/// package), not by this service — local notifications are not reliable
/// enough on iOS to be the ring. They are only used for supporting,
/// best-effort reminders.
///
/// All scheduling decisions (which reminders to schedule, in what order,
/// truncated to the iOS 64-cap) happen in
/// `NotificationScheduleCalculator` before reaching this service. This
/// keeps the data layer thin and the calculator fully unit-testable.
///
/// The interface is intentionally narrow — no plugin types leak across
/// it. `lib/core/` and `lib/features/` import from here; only
/// `lib/data/` imports `flutter_local_notifications`.
abstract class NotificationService {
  /// Replace the entire pending queue with [notifications], cancelling
  /// any previously-pending entries this service scheduled. Idempotent:
  /// calling with an unchanged list is a safe no-op from the user's
  /// perspective.
  ///
  /// Implementations MUST NOT exceed the iOS 64-pending cap; the
  /// calculator already truncated the list to that bound before calling
  /// here.
  Future<void> scheduleAll(List<PendingNotification> notifications);

  /// Cancel every pending notification this service scheduled. Used when
  /// notification permission is revoked or every alarm is disabled.
  Future<void> cancelAll();

  /// Release any platform resources. Idempotent.
  Future<void> dispose();
}

/// Pure value-type description of a single pre-alarm reminder.
///
/// The calculator emits these; the [NotificationService] schedules them
/// via the OS. Times are kept as UTC [DateTime]s so storage / comparison
/// is unambiguous; the platform adapter converts to the user's tz at the
/// last possible moment.
@immutable
class PendingNotification {
  const PendingNotification({
    required this.id,
    required this.alarmId,
    required this.kind,
    required this.scheduledUtc,
    required this.payloadAlarmTimeUtc,
  });

  /// Stable, deterministic int id used by `flutter_local_notifications`
  /// to identify this pending entry. Derived from [alarmId] + [kind] +
  /// [scheduledUtc] so re-running `scheduleAll` with the same plan
  /// reuses ids and the OS treats it as a no-op.
  final int id;

  /// The id of the parent `Alarm` this reminder belongs to.
  final String alarmId;

  /// What kind of reminder this is (used for body copy + analytics-free
  /// debugging).
  final NotificationKind kind;

  /// The UTC instant at which the OS should display the reminder.
  final DateTime scheduledUtc;

  /// The UTC instant of the alarm itself (the ring time). Carried so
  /// the body copy can render "at 07:00" without a second lookup.
  final DateTime payloadAlarmTimeUtc;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PendingNotification &&
        other.id == id &&
        other.alarmId == alarmId &&
        other.kind == kind &&
        other.scheduledUtc.isAtSameMomentAs(scheduledUtc) &&
        other.payloadAlarmTimeUtc.isAtSameMomentAs(payloadAlarmTimeUtc);
  }

  @override
  int get hashCode => Object.hash(
    id,
    alarmId,
    kind,
    scheduledUtc.millisecondsSinceEpoch,
    payloadAlarmTimeUtc.millisecondsSinceEpoch,
  );

  @override
  String toString() =>
      'PendingNotification(id: $id, alarmId: $alarmId, kind: $kind, '
      'scheduledUtc: $scheduledUtc)';
}

/// The kind of pre-alarm reminder.
///
/// Phase 06 schedules only the `softWakeStart` reminder; later phases may
/// add more (e.g. a calm "final alarm coming up" nudge). Each kind maps
/// to a localised body string in the platform adapter.
enum NotificationKind {
  /// The wake window opening, scheduled at the alarm's
  /// [AlarmOccurrencePlan.softStart].
  ///
  /// Since Phase 31 the *ring* also starts there, so on Android and on a live
  /// iOS app this reminder arrives beside an alarm that is already sounding —
  /// which is why its copy says the window has started rather than that an
  /// alarm is coming. It earns its place on the one platform path where the
  /// ring cannot happen: a force-quit iOS app schedules no audio, but a local
  /// notification still fires.
  softWakeStart,
}
