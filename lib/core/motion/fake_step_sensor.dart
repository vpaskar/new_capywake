import 'dart:async';

import 'package:capywake/core/motion/step_sensor.dart';

/// Test double for [StepSensor]: answers [current], emits on demand, and
/// counts listeners so a test can prove the sensor is off again.
class FakeStepSensor implements StepSensor {
  FakeStepSensor({this.current = StepAccess.unavailable, this.afterRequest}) {
    _controller = StreamController<int>.broadcast(
      onListen: () => listenCount++,
      onCancel: () => cancelCount++,
    );
  }

  late final StreamController<int> _controller;
  final _accessChanges = StreamController<void>.broadcast();

  StepAccess current;

  /// What [requestAccess] turns [current] into; `null` leaves it unchanged.
  StepAccess? afterRequest;

  int listenCount = 0;
  int accessCount = 0;
  int cancelCount = 0;
  int requestCount = 0;
  int settingsCount = 0;

  bool get hasListener => listenCount > cancelCount;

  @override
  Future<StepAccess> access() async {
    accessCount++;
    return current;
  }

  @override
  Future<StepAccess> requestAccess() async {
    requestCount++;
    current = afterRequest ?? current;
    _accessChanges.add(null);
    return current;
  }

  @override
  Future<bool> openSettings() async {
    settingsCount++;
    return true;
  }

  @override
  Stream<int> get steps => _controller.stream;

  @override
  Stream<void> get accessChanges => _accessChanges.stream;

  void emit(int count) {
    if (!_controller.isClosed) _controller.add(count);
  }

  void fail() {
    if (!_controller.isClosed) _controller.addError(StateError('no sensor'));
  }

  Future<void> close() async {
    await _controller.close();
    await _accessChanges.close();
  }
}
