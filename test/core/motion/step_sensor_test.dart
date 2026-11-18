import 'package:capywake/core/motion/fake_step_sensor.dart';
import 'package:capywake/core/motion/step_sensor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('answers its access and changes it on request', () async {
    final sensor = FakeStepSensor(
      current: StepAccess.needsPermission,
      afterRequest: StepAccess.ready,
    );
    expect(await sensor.access(), StepAccess.needsPermission);
    final changed = sensor.accessChanges.first;
    expect(await sensor.requestAccess(), StepAccess.ready);
    await changed;
    expect(sensor.requestCount, 1);
    expect(sensor.accessCount, 1);
    expect(await sensor.openSettings(), isTrue);
    expect(sensor.settingsCount, 1);
  });

  test('a request with no outcome leaves the access as it was', () async {
    final sensor = FakeStepSensor();
    expect(await sensor.requestAccess(), StepAccess.unavailable);
  });

  test('emits, fails and counts listeners', () async {
    final sensor = FakeStepSensor();
    final got = <int>[];
    final errors = <Object>[];
    final sub = sensor.steps.listen(got.add, onError: errors.add);
    expect(sensor.hasListener, isTrue);
    sensor
      ..emit(2)
      ..fail();
    await Future<void>.delayed(Duration.zero);
    expect(got, [2]);
    expect(errors, hasLength(1));
    await sub.cancel();
    expect(sensor.hasListener, isFalse);
    await sensor.close();
    sensor
      ..emit(1)
      ..fail();
  });
}
