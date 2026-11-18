/// Which source is counting a round's steps.
enum StepSource {
  /// CapyWake's own detector on the accelerometer.
  motion,

  /// The phone's step sensor.
  sensor,
}

/// Picks the step sensor once ready; until it delivers, [demoteAfter] unseen
/// accelerometer steps or a failure hand the round to the accelerometer.
class StepTally {
  StepTally({this.demoteAfter = defaultDemoteAfter})
    : assert(demoteAfter > 0, 'demotion needs at least one unseen step');

  static const int defaultDemoteAfter = 16;

  final int demoteAfter;
  StepSource _source = StepSource.motion;
  bool _demoted = false;
  bool _sensorDelivered = false;
  int _unseenBySensor = 0;

  StepSource get source => _source;

  /// Whether the sensor may still take over: never after a demotion.
  bool get canPromote => !_demoted;

  /// The sensor has delivered, so the accelerometer can stop.
  bool get sensorProven => _sensorDelivered && _source == StepSource.sensor;

  /// The sensor answered ready. Ignored once the round has been demoted.
  void sensorReady() {
    if (_demoted) return;
    _source = StepSource.sensor;
  }

  /// The sensor's stream failed or closed.
  void sensorFailed() {
    _demoted = true;
    _source = StepSource.motion;
    _unseenBySensor = 0;
  }

  /// Steps to add for [count] steps from the sensor.
  int fromSensor(int count) {
    if (_source != StepSource.sensor || count <= 0) return 0;
    _sensorDelivered = true;
    return count;
  }

  /// Steps to add for [count] steps from the accelerometer.
  int fromMotion(int count) {
    if (count <= 0) return 0;
    if (_source == StepSource.motion) return count;
    if (_sensorDelivered) return 0;
    _unseenBySensor += count;
    if (_unseenBySensor < demoteAfter) return 0;
    final kept = _unseenBySensor;
    sensorFailed();
    return kept;
  }
}
