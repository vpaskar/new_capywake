import 'package:capywake/core/motion/step_tally.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts on the accelerometer, which counts', () {
    final tally = StepTally();
    expect(tally.source, StepSource.motion);
    expect(tally.fromMotion(4), 4);
    expect(tally.fromSensor(3), 0, reason: 'the sensor is not in force yet');
    expect(tally.sensorProven, isFalse);
  });

  test('a ready sensor takes over and the accelerometer goes quiet', () {
    final tally = StepTally()..sensorReady();
    expect(tally.source, StepSource.sensor);
    expect(tally.fromSensor(2), 2);
    expect(tally.sensorProven, isTrue);
    expect(tally.fromMotion(40), 0, reason: 'a proven sensor is never doubted');
    expect(tally.source, StepSource.sensor);
  });

  test('a silent sensor is demoted after 16 unseen steps, keeping them', () {
    final tally = StepTally()..sensorReady();
    expect(tally.fromMotion(15), 0);
    expect(tally.source, StepSource.sensor);
    expect(tally.fromMotion(1), 16);
    expect(tally.source, StepSource.motion);
    expect(tally.fromMotion(1), 1);
    expect(tally.fromSensor(5), 0);
  });

  test('demotion is final: a later ready does not promote again', () {
    final tally = StepTally()
      ..sensorReady()
      ..sensorFailed()
      ..sensorReady();
    expect(tally.source, StepSource.motion);
  });

  test('a failure before ready still blocks a later promotion', () {
    final tally = StepTally()
      ..sensorFailed()
      ..sensorReady();
    expect(tally.source, StepSource.motion);
  });

  test('a failed stream hands over at once, even after deliveries', () {
    final tally = StepTally()..sensorReady();
    expect(tally.fromSensor(3), 3);
    tally.sensorFailed();
    expect(tally.source, StepSource.motion);
    expect(tally.sensorProven, isFalse);
    expect(tally.fromMotion(2), 2);
  });

  test('promotion mid-round restarts the silence count', () {
    final tally = StepTally(demoteAfter: 3);
    expect(tally.fromMotion(5), 5);
    tally.sensorReady();
    expect(tally.fromMotion(2), 0);
    expect(tally.fromMotion(1), 3);
  });

  test('empty or negative batches add nothing', () {
    final tally = StepTally()..sensorReady();
    expect(tally.fromSensor(0), 0);
    expect(tally.fromMotion(-1), 0);
    expect(tally.sensorProven, isFalse);
  });

  test('demoteAfter must be positive', () {
    expect(() => StepTally(demoteAfter: 0), throwsAssertionError);
    expect(StepTally().demoteAfter, StepTally.defaultDemoteAfter);
  });
}
