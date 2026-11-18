/// Whether a device capability (the step sensor, the camera) can be used now.
enum DeviceAccess {
  /// It exists and the user allowed it.
  ready,

  /// It exists; the OS will still show its prompt.
  needsPermission,

  /// It exists, the user refused, and only device Settings can undo it.
  permanentlyDenied,

  /// Absent, or blocked for good (e.g. parental controls).
  unavailable,
}

/// A capability behind an OS permission. Only `lib/data/` talks to the OS.
abstract class DevicePermission {
  /// The current access, without prompting. Never throws.
  Future<DeviceAccess> access();

  /// Shows the OS prompt. Never while ringing: it would cover the escape.
  Future<DeviceAccess> requestAccess();

  /// Opens this app's page in the device Settings.
  Future<bool> openSettings();

  /// Fires after [requestAccess] answers, so a running screen reads it again.
  Stream<void> get accessChanges;
}
