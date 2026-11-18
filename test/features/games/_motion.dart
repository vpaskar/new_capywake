import 'dart:async';

import 'package:capywake/core/motion/motion_sensor.dart';

/// A sensor whose stream fails, as a missing accelerometer would.
class FailingMotionSensor implements MotionSensor {
  final _controller = StreamController<MotionSample>.broadcast();

  void fail() => _controller.addError(StateError('no accelerometer'));

  @override
  Stream<MotionSample> get samples => _controller.stream;

  @override
  Future<void> dispose() => _controller.close();
}

/// Far enough from gravity to be one shake.
const shakeSample = MotionSample(x: 0, y: 0, z: 22);
