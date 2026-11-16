/// Barrel for the pure-Dart domain models.
///
/// `lib/core/models/` is Flutter-free; everything exported here is safe to
/// import from `lib/core/`, `lib/data/`, and `lib/features/` without dragging
/// in widget code.
library;

export 'alarm.dart';
export 'alarm_occurrence.dart';
export 'alarm_status.dart';
export 'dismiss_method.dart';
export 'pro_status.dart';
export 'theme_mode_preference.dart';
export 'time_format.dart';
export 'user_settings.dart';
export 'wake_mode.dart';
