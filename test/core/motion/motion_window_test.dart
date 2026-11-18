import 'package:capywake/core/motion/fake_motion_sensor.dart';
import 'package:capywake/core/motion/motion_check_service.dart';
import 'package:capywake/core/motion/motion_window.dart';
import 'package:flutter_test/flutter_test.dart';

final _opened = DateTime.utc(2026, 5, 21, 7);

MotionWindow _window() =>
    MotionWindow(check: MotionCheckService(), openedAt: _opened);

DateTime _at(double seconds) =>
    _opened.add(Duration(milliseconds: (seconds * 1000).round()));

void main() {
  test('starts watching', () {
    expect(_window().state, MotionWindowState.watching);
  });

  test('a still phone expires at 90 seconds, not before', () {
    final window = _window();
    expect(
      window.register(FakeMotionSensor.still, _at(89.9)),
      MotionWindowState.watching,
    );
    expect(
      window.register(FakeMotionSensor.still, _at(90)),
      MotionWindowState.expired,
    );
  });

  test('45 separate moving seconds satisfy it', () {
    final window = _window();
    for (var s = 0; s < 44; s++) {
      window.register(FakeMotionSensor.moving, _at(s + 0.5));
    }
    expect(window.state, MotionWindowState.watching);
    expect(
      window.register(FakeMotionSensor.moving, _at(44.5)),
      MotionWindowState.satisfied,
    );
  });

  test('one long shake fills one second, never the check', () {
    final window = _window();
    for (var i = 0; i < 200; i++) {
      window.register(FakeMotionSensor.moving, _at(3 + i / 1000));
    }
    expect(
      window.register(FakeMotionSensor.still, _at(90)),
      MotionWindowState.expired,
    );
  });

  test('readings before it opened do not count', () {
    final window = _window();
    for (var s = 0; s < 60; s++) {
      window.register(FakeMotionSensor.moving, _at(-1 - s / 100));
    }
    expect(window.state, MotionWindowState.watching);
  });

  test('a settled window ignores later readings', () {
    final window = _window()..register(FakeMotionSensor.still, _at(90));
    for (var s = 0; s < 60; s++) {
      window.register(FakeMotionSensor.moving, _at(91.0 + s));
    }
    expect(window.state, MotionWindowState.expired);
  });
}
