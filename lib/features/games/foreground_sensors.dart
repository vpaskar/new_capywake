import 'dart:async';

import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:flutter/widgets.dart';

/// [open]'s events while the app is on screen. An armed alarm keeps the app
/// alive in the background, so a practice round left open would keep reading.
Stream<T> whileOnScreen<T>(Stream<T> Function() open) =>
    _OnScreenRelay<T>(open).stream;

class _OnScreenRelay<T> {
  _OnScreenRelay(this._open) {
    _out = StreamController<T>(onListen: _onListen, onCancel: _onCancel);
  }

  final Stream<T> Function() _open;
  late final StreamController<T> _out;
  StreamSubscription<T>? _source;
  AppLifecycleListener? _lifecycle;

  Stream<T> get stream => _out.stream;

  void _onListen() {
    _lifecycle = AppLifecycleListener(
      onShow: _start,
      onResume: _start,
      onHide: () => unawaited(_stop()),
    );
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null ||
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      _start();
    }
  }

  Future<void> _onCancel() {
    _lifecycle?.dispose();
    _lifecycle = null;
    return _stop();
  }

  void _start() {
    _source ??= _open().listen(
      _out.add,
      onError: _out.addError,
      onDone: () {
        _source = null;
        _lifecycle?.dispose();
        _lifecycle = null;
        unawaited(_out.close());
      },
    );
  }

  Future<void> _stop() {
    final cancelled = _source?.cancel() ?? Future<void>.value();
    _source = null;
    return cancelled;
  }
}

/// The accelerometer for practice: silent while the app is off screen. Equal
/// per inner sensor, so a rebuild does not re-subscribe a game.
@immutable
class OnScreenMotionSensor implements MotionSensor {
  const OnScreenMotionSensor(this._inner);

  final MotionSensor _inner;

  @override
  bool operator ==(Object other) =>
      other is OnScreenMotionSensor && identical(other._inner, _inner);

  @override
  int get hashCode => identityHashCode(_inner);

  @override
  Stream<MotionSample> get samples => whileOnScreen(() => _inner.samples);

  @override
  Future<void> dispose() async {}
}

/// The step sensor for practice: silent while the app is off screen. Equal
/// per inner sensor, so a rebuild does not reset a game's tally.
@immutable
class OnScreenStepSensor implements StepSensor {
  const OnScreenStepSensor(this._inner);

  final StepSensor _inner;

  @override
  bool operator ==(Object other) =>
      other is OnScreenStepSensor && identical(other._inner, _inner);

  @override
  int get hashCode => identityHashCode(_inner);

  @override
  Stream<int> get steps => whileOnScreen(() => _inner.steps);

  @override
  Future<DeviceAccess> access() => _inner.access();

  @override
  Future<DeviceAccess> requestAccess() => _inner.requestAccess();

  @override
  Future<bool> openSettings() => _inner.openSettings();

  @override
  Stream<void> get accessChanges => _inner.accessChanges;
}
