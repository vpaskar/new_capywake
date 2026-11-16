import 'package:capywake/core/permissions/permission_service.dart';

/// Test double for [PermissionService].
///
/// Stores a mutable [PermissionState] and lets the test set the *next*
/// result of each `request*` method. Tests use this to exercise both
/// the granted and denied paths without a real device prompt.
class FakePermissionService implements PermissionService {
  FakePermissionService({PermissionState? initial})
    : state = initial ?? PermissionState.initial;

  /// The current permission snapshot. Mutable so tests can poke the
  /// state directly (e.g. simulating "user revoked notifications in
  /// Settings").
  PermissionState state;

  /// What the next [requestNotification] call resolves to. If `null`,
  /// the request returns the current notification grant unchanged
  /// (modelling "nothing to ask — already decided").
  PermissionGrant? notificationRequestResult;

  /// What the next [requestExactAlarm] call resolves to. If `null`, the
  /// request returns the current exact-alarm grant unchanged.
  PermissionGrant? exactAlarmRequestResult;

  /// Number of times [requestNotification] was called.
  int notificationRequestCount = 0;

  /// Number of times [requestExactAlarm] was called.
  int exactAlarmRequestCount = 0;

  /// What the next [openAppSettings] call resolves to. Defaults to
  /// `true` (the OS honoured the request).
  bool openAppSettingsResult = true;

  /// Number of times [openAppSettings] was called.
  int openAppSettingsCount = 0;

  @override
  Future<PermissionState> read() async => state;

  @override
  Future<PermissionGrant> requestNotification() async {
    notificationRequestCount++;
    final next = notificationRequestResult;
    if (next != null) {
      state = state.copyWith(notification: next);
      notificationRequestResult = null;
    }
    return state.notification;
  }

  @override
  Future<PermissionGrant> requestExactAlarm() async {
    exactAlarmRequestCount++;
    final next = exactAlarmRequestResult;
    if (next != null) {
      state = state.copyWith(exactAlarm: next);
      exactAlarmRequestResult = null;
    }
    return state.exactAlarm;
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCount++;
    return openAppSettingsResult;
  }
}
