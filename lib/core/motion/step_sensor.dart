/// Whether the phone's own step sensor can count for CapyWake right now.
enum StepAccess {
  /// The sensor exists and the user allowed it.
  ready,

  /// The sensor exists; the OS will still show its prompt.
  needsPermission,

  /// The sensor exists, the user refused, and only device Settings can undo it.
  permanentlyDenied,

  /// No step sensor, or one CapyWake can never use (e.g. parental controls).
  unavailable,
}

/// The OS step sensor (Android step detector or counter, iOS pedometer). Only
/// `lib/data/` talks to the platform; it counts steps, never who got up.
abstract class StepSensor {
  /// The current access, without prompting. Never throws.
  Future<StepAccess> access();

  /// Shows the OS prompt. Never while ringing: it would cover the escape.
  Future<StepAccess> requestAccess();

  /// Opens this app's page in the device Settings.
  Future<bool> openSettings();

  /// New steps since listening began. Listen only once [access] is ready.
  Stream<int> get steps;

  /// Fires after [requestAccess] answers, so a running game reads it again.
  Stream<void> get accessChanges;
}
