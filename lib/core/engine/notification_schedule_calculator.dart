import 'package:capywake/core/engine/notification_service.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:meta/meta.dart';

/// Pure mapper from a list of upcoming [AlarmOccurrencePlan]s to the
/// concrete set of [PendingNotification]s to arm via
/// [NotificationService].
///
/// Lives in `lib/core/` so it is fully unit-testable and Flutter-free.
/// The calculator is the **single place** that enforces the iOS
/// 64-pending-notifications cap; the platform adapter just executes the
/// list this method returns.
///
/// Sort + truncation contract:
///
/// 1. Inputs are flattened to one [PendingNotification] per
///    `(plan, supported kind)` pair — a plan with a soft-start emits a
///    `softWakeStart` reminder; a plan without a soft-start emits
///    nothing here (its ring is the `AlarmEngine`'s job).
/// 2. The flattened list is sorted by [PendingNotification.scheduledUtc]
///    ascending, ties broken by `alarmId` for determinism.
/// 3. The list is then truncated to [iosPendingCap] entries — keeping
///    the **soonest** ones, dropping the rest. This matches Apple's
///    "newest 64" semantics from the platform-reliability doc, applied
///    to *our* upcoming queue rather than the global one.
///
/// If a future phase adds more notification kinds (e.g. a calm pre-final
/// nudge), they slot in at step 1 and inherit the same cap behaviour for
/// free.
abstract final class NotificationScheduleCalculator {
  /// Apple's documented per-app pending-local-notifications cap. iOS
  /// silently drops anything beyond the newest 64; we never schedule
  /// past it. Public so tests can describe the bound without copying
  /// the magic number.
  static const int iosPendingCap = 64;

  /// Compute the [PendingNotification]s to schedule for [plans].
  ///
  /// [now] is used to drop plans whose `softStart` is already in the
  /// past — those reminders would never fire anyway.
  ///
  /// Returns an unmodifiable, deterministic list.
  static List<PendingNotification> compute({
    required List<AlarmOccurrencePlan> plans,
    required DateTime now,
    int cap = iosPendingCap,
  }) {
    final nowUtc = now.toUtc();
    final entries = <_Entry>[];

    for (final plan in plans) {
      final softStart = plan.softStartUtc;
      if (softStart == null) continue;
      if (!softStart.isAfter(nowUtc)) continue;
      entries.add(
        _Entry(
          PendingNotification(
            id: _stableId(
              alarmId: plan.alarm.id,
              kind: NotificationKind.softWakeStart,
              scheduledUtc: softStart,
            ),
            alarmId: plan.alarm.id,
            kind: NotificationKind.softWakeStart,
            scheduledUtc: softStart,
            payloadAlarmTimeUtc: plan.scheduledUtc,
          ),
        ),
      );
    }

    entries.sort((a, b) {
      final byTime = a.notification.scheduledUtc.compareTo(
        b.notification.scheduledUtc,
      );
      if (byTime != 0) return byTime;
      return a.notification.alarmId.compareTo(b.notification.alarmId);
    });

    final capped = entries.length > cap ? entries.sublist(0, cap) : entries;
    return List.unmodifiable(capped.map((e) => e.notification));
  }

  /// Deterministic 31-bit positive int id from
  /// `(alarmId, kind, scheduledUtc)` for `flutter_local_notifications`,
  /// which uses `int` ids. Re-running [compute] with the same plan
  /// produces the same id so OS-level "is this already scheduled?"
  /// checks work across re-arms.
  static int _stableId({
    required String alarmId,
    required NotificationKind kind,
    required DateTime scheduledUtc,
  }) {
    // FNV-1a 32-bit, masked to 31 bits to stay positive (the platform
    // plugin treats negative ids as "not set" on some channels). The
    // exact algorithm is a stable detail; tests assert the contract,
    // not the bytes.
    const prime = 0x01000193;
    const offset = 0x811C9DC5;
    var hash = offset;
    void mix(int byte) {
      hash = (hash ^ byte) & 0xFFFFFFFF;
      hash = (hash * prime) & 0xFFFFFFFF;
    }

    for (final code in alarmId.codeUnits) {
      mix(code & 0xFF);
      mix((code >> 8) & 0xFF);
    }
    mix(0);
    mix(kind.index & 0xFF);
    mix(0);
    final ms = scheduledUtc.toUtc().millisecondsSinceEpoch;
    for (var shift = 0; shift < 64; shift += 8) {
      mix((ms >> shift) & 0xFF);
    }
    return hash & 0x7FFFFFFF;
  }
}

@immutable
class _Entry {
  const _Entry(this.notification);
  final PendingNotification notification;
}
