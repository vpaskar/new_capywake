/// Barrel for the sleep-reading layer.
///
/// CapyWake measures no sleep. This layer reads what the user's own wearable
/// already recorded, via Apple Health / Health Connect, and hands it to History
/// for display. It is read-only — `SleepGateway` has no write method — and it
/// never reaches alarm scheduling.
library;

export 'fake_sleep_gateway.dart';
export 'sleep_aggregator.dart';
export 'sleep_format.dart';
export 'sleep_gateway.dart';
export 'sleep_night.dart';
export 'sleep_segment.dart';
export 'sleep_stage.dart';
export 'sleep_sync_service.dart';
export 'sleep_sync_state.dart';
