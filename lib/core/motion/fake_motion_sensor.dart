import 'dart:async';

import 'package:capywake/core/motion/motion_sensor.dart';

/// Test double for [MotionSensor].
///
/// Emits nothing until a test calls [emit] — no timers, no real sensor, no
/// waiting. [hasListener] is the assertion the motion tests lean on: the
/// accelerometer subscription must be gone on **every** exit path, and a
/// leaked one shows up here as `true` after the window should have closed.
class FakeMotionSensor implements MotionSensor {
  FakeMotionSensor() {
    _controller = StreamController<MotionSample>.broadcast(
      onListen: () => listenCount++,
      onCancel: () => cancelCount++,
    );
  }

  late final StreamController<MotionSample> _controller;

  /// A phone lying untouched: gravity only, no lateral acceleration.
  static const MotionSample still = MotionSample(x: 0, y: 0, z: 9.80665);

  /// A phone being carried: magnitude well away from gravity.
  static const MotionSample moving = MotionSample(x: 0, y: 0, z: 4);

  /// How many times a listener has subscribed.
  int listenCount = 0;

  /// How many times the last listener has unsubscribed. `onCancel` fires on a
  /// broadcast controller when the final listener goes away, which is exactly
  /// the "is the sensor still running?" question the tests ask.
  int cancelCount = 0;

  /// Whether anything is currently listening to [samples].
  bool get hasListener => listenCount > cancelCount;

  @override
  Stream<MotionSample> get samples => _controller.stream;

  /// Push one reading to every listener.
  void emit(MotionSample sample) {
    if (_controller.isClosed) return;
    _controller.add(sample);
  }

  @override
  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
