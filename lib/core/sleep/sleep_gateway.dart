import 'package:capywake/core/sleep/sleep_segment.dart';

/// Whether a platform sleep store is reachable here.
enum SleepStoreAvailability {
  /// Neither HealthKit nor Health Connect exists on this platform.
  unsupported,

  /// Android only: Health Connect missing or too old, so the UI offers the
  /// Play Store listing.
  needsProvider,

  available,
}

/// A failure category. Carries **no health content** — safe to persist and
/// display. The underlying platform exception is dropped at the adapter.
enum SleepSyncError {
  unsupportedPlatform,

  /// Android: Health Connect missing or out of date.
  providerUnavailable,

  /// The store exists but refused to open or respond.
  storeUnavailable,

  permissionDenied,

  timeout,

  unknown,
}

/// Thrown by the gateway. Carries only a category.
class SleepSyncException implements Exception {
  const SleepSyncException(this.error);

  final SleepSyncError error;

  @override
  String toString() => 'SleepSyncException(${error.name})';
}

/// CapyWake's window onto the platform sleep store.
///
/// **Read-only by construction: there is deliberately no write method.**
/// CapyWake measures no sleep and so has nothing truthful to contribute to
/// the user's health record. Making the write impossible at the type level is
/// stronger than a rule in a document — a future session cannot add an export
/// path without first widening this interface, which is a visible change.
///
/// The one concrete implementation (`LiveSleepGateway`, in `lib/data/sleep/`)
/// is the only file in the app that imports `package:health`.
abstract class SleepGateway {
  Future<SleepStoreAvailability> availability();

  /// Ask for sleep READ access. Returns false when the user declines or the
  /// platform refuses.
  Future<bool> requestPermission();

  /// Tri-state on purpose. **iOS never discloses READ authorization**, so
  /// `null` means "cannot be known" and the UI must say so rather than show a
  /// confident grant.
  Future<bool?> hasPermission();

  /// Segments whose start falls in `[start, end)`, oldest first.
  ///
  /// Throws [SleepSyncException] on failure. Returning an empty list is not a
  /// failure — a user with no wearable is the normal case.
  Future<List<SleepSegment>> readSegments({
    required DateTime start,
    required DateTime end,
  });

  /// Opens the OS page where sleep permission is changed. False when there is
  /// nowhere to go — notably iOS, which exposes no supported deep link to an
  /// app's Health permissions.
  Future<bool> openPermissionSettings();
}
