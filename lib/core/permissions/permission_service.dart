import 'package:meta/meta.dart';

/// Tri-state grant for an OS-level permission.
///
/// `unknown` is the honest default — we have not yet asked, or the
/// platform does not let us check (e.g. iOS pre-iOS-17 didn't surface
/// the user's choice). `granted` and `denied` are the meaningful end
/// states. `permanentlyDenied` is broken out so the UI can suggest
/// "open Settings" instead of asking again (Android, and iOS once the
/// user has refused once).
enum PermissionGrant {
  /// We have not queried the OS yet.
  unknown,

  /// The user granted the permission.
  granted,

  /// The user denied the permission and may still be asked again.
  denied,

  /// The user denied the permission and the OS will not show the
  /// system prompt again — the only path forward is the device
  /// Settings app.
  permanentlyDenied,
}

/// Snapshot of the OS permissions CapyWake cares about.
///
/// - [notification] is **both** platforms' notification permission
///   (POST_NOTIFICATIONS on Android 13+, `UNUserNotificationCenter`
///   authorization on iOS).
/// - [exactAlarm] is Android-only (`USE_EXACT_ALARM` /
///   `SCHEDULE_EXACT_ALARM`). On iOS it is always
///   [PermissionGrant.granted] — exact-time scheduling is not gated by
///   a separate permission there. The reliability surface uses this
///   distinction to render honest, per-platform copy via
///   `ReliabilityCopyService`.
@immutable
class PermissionState {
  const PermissionState({required this.notification, required this.exactAlarm});

  /// All-`unknown` initial state. The honest default before any query.
  static const initial = PermissionState(
    notification: PermissionGrant.unknown,
    exactAlarm: PermissionGrant.unknown,
  );

  /// Notification permission grant.
  final PermissionGrant notification;

  /// Exact-alarm permission grant. Always [PermissionGrant.granted] on
  /// iOS.
  final PermissionGrant exactAlarm;

  /// True iff every relevant permission is granted. The caller decides
  /// what counts as "relevant" per platform — this convenience returns
  /// true only when both are granted, which is the strict-Android case;
  /// iOS callers may inspect [notification] alone.
  bool get allGranted =>
      notification == PermissionGrant.granted &&
      exactAlarm == PermissionGrant.granted;

  PermissionState copyWith({
    PermissionGrant? notification,
    PermissionGrant? exactAlarm,
  }) {
    return PermissionState(
      notification: notification ?? this.notification,
      exactAlarm: exactAlarm ?? this.exactAlarm,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PermissionState &&
        other.notification == notification &&
        other.exactAlarm == exactAlarm;
  }

  @override
  int get hashCode => Object.hash(notification, exactAlarm);

  @override
  String toString() =>
      'PermissionState(notification: $notification, exactAlarm: $exactAlarm)';
}

/// Platform-agnostic permission flow.
///
/// `lib/core/` and `lib/features/` import this; only `lib/data/` knows
/// about `permission_handler`. The fake implementation
/// (`FakePermissionService`) is used in every test.
///
/// CapyWake's design rule (from the reliability-honesty boundary): if a
/// permission is denied, the app degrades **honestly** — it does not
/// pretend the alarm is set, and it routes the user-facing copy through
/// `ReliabilityCopyService`. This service never produces user-facing
/// strings itself.
abstract class PermissionService {
  /// Read the current grant snapshot without prompting the user. Safe
  /// to call frequently.
  Future<PermissionState> read();

  /// Request OS notification permission. Returns the resulting grant.
  /// Calling this when already [PermissionGrant.granted] is a no-op.
  Future<PermissionGrant> requestNotification();

  /// Request OS exact-alarm permission. Android only — on iOS this is a
  /// trivial no-op that returns [PermissionGrant.granted] (the iOS
  /// platform treats exact-time scheduling as unrestricted by a
  /// dedicated permission).
  Future<PermissionGrant> requestExactAlarm();

  /// Open the device Settings app so the user can change a
  /// `permanentlyDenied` permission. Returns `true` if the system
  /// honoured the request. The reliability checklist surfaces this as
  /// "Open Settings" when a permission has been permanently denied —
  /// the only path forward at that point.
  Future<bool> openAppSettings();
}
