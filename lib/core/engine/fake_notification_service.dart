import 'package:capywake/core/engine/notification_service.dart';

/// Test double for [NotificationService].
///
/// Stores the most recently scheduled queue in-memory so tests can assert
/// "exactly these reminders were armed, in this order". No Flutter
/// plugin involvement.
class FakeNotificationService implements NotificationService {
  FakeNotificationService();

  /// Snapshot of the last call to [scheduleAll]. Empty until a call
  /// happens (or after [cancelAll]).
  List<PendingNotification> get pending =>
      List<PendingNotification>.unmodifiable(_pending);

  final List<PendingNotification> _pending = <PendingNotification>[];

  /// Number of times [scheduleAll] was called.
  int scheduleCallCount = 0;

  /// Number of times [cancelAll] was called.
  int cancelAllCallCount = 0;

  /// When set, the next [scheduleAll] throws this (and clears it). Lets tests
  /// prove the coordinator survives a notification-side failure (it logs and
  /// the alarm engine is unaffected).
  Exception? failNextSchedule;

  /// When set, the next [cancelAll] throws this (and clears it).
  Exception? failNextCancelAll;

  bool _disposed = false;

  /// Whether [dispose] was called at least once.
  bool get isDisposed => _disposed;

  @override
  Future<void> scheduleAll(List<PendingNotification> notifications) async {
    scheduleCallCount++;
    final fail = failNextSchedule;
    if (fail != null) {
      failNextSchedule = null;
      throw fail;
    }
    _pending
      ..clear()
      ..addAll(notifications);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCallCount++;
    final fail = failNextCancelAll;
    if (fail != null) {
      failNextCancelAll = null;
      throw fail;
    }
    _pending.clear();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
  }
}
