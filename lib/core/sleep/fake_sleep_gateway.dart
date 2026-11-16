import 'package:capywake/core/sleep/sleep_gateway.dart';
import 'package:capywake/core/sleep/sleep_segment.dart';

/// Headless [SleepGateway] for tests.
///
/// Lives in `lib/core/` beside the abstraction, matching `FakeAlarmEngine` and
/// `FakePermissionService`, so the suite never touches a real health store.
///
/// [readCallCount] exists to prove the acceptance criterion that a disabled
/// feature calls no health API at all.
class FakeSleepGateway implements SleepGateway {
  FakeSleepGateway({
    this.storeAvailability = SleepStoreAvailability.available,
    this.permission = true,
    this.permissionRequestResult = true,
    this.canOpenSettings = true,
    List<SleepSegment> segments = const [],
  }) : _segments = List.of(segments);

  SleepStoreAvailability storeAvailability;

  /// What [hasPermission] reports. Null models iOS's undisclosed READ state.
  bool? permission;

  bool permissionRequestResult;

  bool canOpenSettings;

  List<SleepSegment> _segments;

  /// Throw this on the next [readSegments] call, then clear it.
  SleepSyncError? failNextRead;

  int readCallCount = 0;
  int permissionRequestCount = 0;
  int availabilityCallCount = 0;

  /// Total calls that would have reached the platform.
  int get totalPlatformCalls =>
      readCallCount + permissionRequestCount + availabilityCallCount;

  void setSegments(List<SleepSegment> segments) {
    _segments = List.of(segments);
  }

  @override
  Future<SleepStoreAvailability> availability() async {
    availabilityCallCount++;
    return storeAvailability;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequestCount++;
    if (permissionRequestResult) permission = true;
    return permissionRequestResult;
  }

  @override
  Future<bool?> hasPermission() async => permission;

  @override
  Future<List<SleepSegment>> readSegments({
    required DateTime start,
    required DateTime end,
  }) async {
    readCallCount++;
    final failure = failNextRead;
    if (failure != null) {
      failNextRead = null;
      throw SleepSyncException(failure);
    }
    final inWindow =
        _segments
            .where((s) => !s.start.isBefore(start) && s.start.isBefore(end))
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    return inWindow;
  }

  @override
  Future<bool> openPermissionSettings() async => canOpenSettings;
}
