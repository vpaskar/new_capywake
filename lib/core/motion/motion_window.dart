import 'package:capywake/core/motion/motion_check_service.dart';
import 'package:capywake/core/motion/motion_sensor.dart';

enum MotionWindowState { watching, satisfied, expired }

/// One post-dismiss watch. Fed readings with the time they arrived; the
/// readings themselves carry the clock, so a silent sensor never expires it.
class MotionWindow {
  MotionWindow({required this.check, required this.openedAt});

  final MotionCheckService check;
  final DateTime openedAt;
  final _movingBuckets = <int>{};
  MotionWindowState _state = MotionWindowState.watching;

  MotionWindowState get state => _state;

  /// The state after [sample], read at [at]. Settled windows ignore readings.
  MotionWindowState register(MotionSample sample, DateTime at) {
    if (_state != MotionWindowState.watching) return _state;
    final elapsed = at.difference(openedAt);
    if (check.isMovingSample(sample)) {
      final bucket = check.bucketIndexFor(elapsed);
      if (bucket != null) _movingBuckets.add(bucket);
    }
    if (check.sawEnoughMotion(_movingBuckets.length)) {
      return _state = MotionWindowState.satisfied;
    }
    if (check.isWindowComplete(elapsed)) {
      return _state = MotionWindowState.expired;
    }
    return _state;
  }
}
