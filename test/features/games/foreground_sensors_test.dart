import 'dart:async';

import 'package:capywake/core/motion/fake_motion_sensor.dart';
import 'package:capywake/features/games/foreground_sensors.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
  );

  test('wrappers of one sensor are equal, so a rebuild keeps the game', () {
    final motion = FakeMotionSensor();
    expect(OnScreenMotionSensor(motion), OnScreenMotionSensor(motion));
    expect(
      OnScreenMotionSensor(motion).hashCode,
      OnScreenMotionSensor(motion).hashCode,
    );
    expect(
      OnScreenMotionSensor(motion),
      isNot(OnScreenMotionSensor(FakeMotionSensor())),
    );
  });

  test('listening while inactive starts at once', () async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final motion = FakeMotionSensor();
    final sub = OnScreenMotionSensor(motion).samples.listen((_) {});
    expect(motion.hasListener, isTrue);
    await sub.cancel();
    expect(motion.hasListener, isFalse);
  });

  test('the inner stream ending ends the relay', () async {
    final inner = StreamController<int>();
    final done = Completer<void>();
    whileOnScreen(() => inner.stream).listen((_) {}, onDone: done.complete);
    await inner.close();
    await done.future.timeout(const Duration(seconds: 2));
  });
}
