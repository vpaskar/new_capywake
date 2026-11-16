import 'package:capywake/core/engine/alarm_engine.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:capywake/data/engine/alarm_plan_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Alarm _alarm({
  String id = 'a1',
  String soundId = 'chimes',
  bool vibration = true,
  int windowBefore = 0,
  WakeMode mode = WakeMode.standard,
}) {
  final now = DateTime.utc(2026);
  return Alarm(
    id: id,
    label: 'Morning',
    enabled: true,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const {},
    wakeMode: mode,
    wakeWindowStartMinutesBefore: windowBefore,
    soundId: soundId,
    vibrationEnabled: vibration,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 3,
    dismissMethod: DismissMethod.normalButton,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: now,
    updatedAt: now,
  );
}

AlarmOccurrencePlan _plan({
  required tz.Location location,
  Alarm? alarm,
  Duration window = Duration.zero,
}) {
  final scheduled = tz.TZDateTime(location, 2026, 3, 2, 7);
  return AlarmOccurrencePlan(
    alarm: alarm ?? _alarm(),
    scheduled: scheduled,
    softStart: window == Duration.zero ? null : scheduled.subtract(window),
    location: location,
  );
}

void main() {
  setUpAll(tzdata.initializeTimeZones);
  final utc = tz.UTC;

  group('platformId', () {
    test('is stable across calls for the same id', () {
      expect(
        AlarmPlanMapper.platformId('alarm-uuid'),
        AlarmPlanMapper.platformId('alarm-uuid'),
      );
    });

    test('differs between ids', () {
      expect(
        AlarmPlanMapper.platformId('a'),
        isNot(AlarmPlanMapper.platformId('b')),
      );
    });

    test('is always a positive 31-bit int', () {
      for (final id in ['', 'a', 'alarm-uuid-9f', 'ユニコード', '🦫']) {
        final value = AlarmPlanMapper.platformId(id);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });
  });

  group('audioPathFor', () {
    test('resolves a catalogue sound to its asset', () {
      expect(
        AlarmPlanMapper.audioPathFor(_alarm()),
        'assets/sounds/chimes.wav',
      );
    });

    test('an unknown id falls back to the device default, which is null', () {
      expect(AlarmPlanMapper.audioPathFor(_alarm(soundId: 'gone')), isNull);
    });
  });

  group('volumeFor', () {
    test('no wake window means a fixed volume, not a ramp', () {
      final settings = AlarmPlanMapper.volumeFor(_plan(location: utc));
      expect(settings.fadeDuration, isNull);
    });

    test('a wake window fades across the whole ramp', () {
      final settings = AlarmPlanMapper.volumeFor(
        _plan(location: utc, window: const Duration(minutes: 15)),
      );
      expect(settings.fadeDuration, const Duration(minutes: 15));
    });

    test('a sub-second window is a fixed volume rather than a zero fade', () {
      final settings = AlarmPlanMapper.volumeFor(
        _plan(location: utc, window: const Duration(milliseconds: 400)),
      );
      expect(settings.fadeDuration, isNull);
    });

    test('never enforces system volume over the user', () {
      expect(
        AlarmPlanMapper.volumeFor(_plan(location: utc)).volumeEnforced,
        isFalse,
      );
    });
  });

  group('ringAtFor', () {
    test('uses the ring instant when it is still ahead', () {
      final plan = _plan(location: utc, window: const Duration(minutes: 15));
      final at = AlarmPlanMapper.ringAtFor(
        plan,
        now: DateTime.utc(2026, 3, 2, 6),
      );
      expect(at, plan.ringAtUtc);
    });

    test('floors a ring already in the past to now', () {
      final plan = _plan(location: utc, window: const Duration(minutes: 15));
      final now = DateTime.utc(2026, 3, 2, 6, 50);
      expect(AlarmPlanMapper.ringAtFor(plan, now: now), now);
    });
  });

  group('settingsFor', () {
    test('carries the alarm id as payload so a ring can be traced back', () {
      final settings = AlarmPlanMapper.settingsFor(
        _plan(location: utc),
        title: 'Alarm',
        body: 'Morning is ringing.',
        now: DateTime.utc(2026, 3, 2, 6),
      );
      expect(settings.payload, 'a1');
      expect(settings.id, AlarmPlanMapper.platformId('a1'));
    });

    test('passes the given copy through without composing any', () {
      final settings = AlarmPlanMapper.settingsFor(
        _plan(location: utc),
        title: 'Wecker',
        body: 'Morgen klingelt.',
        now: DateTime.utc(2026, 3, 2, 6),
      );
      expect(settings.notificationSettings.title, 'Wecker');
      expect(settings.notificationSettings.body, 'Morgen klingelt.');
    });

    test('honours the alarm vibration setting', () {
      final on = AlarmPlanMapper.settingsFor(
        _plan(location: utc),
        title: 't',
        body: 'b',
        now: DateTime.utc(2026, 3, 2, 6),
      );
      final off = AlarmPlanMapper.settingsFor(
        _plan(location: utc, alarm: _alarm(vibration: false)),
        title: 't',
        body: 'b',
        now: DateTime.utc(2026, 3, 2, 6),
      );
      expect(on.vibrate, isTrue);
      expect(off.vibrate, isFalse);
    });
  });

  group('immediatePlan', () {
    test('carries no soft start whatever the wake mode', () {
      final plan = AlarmPlanMapper.immediatePlan(
        alarm: _alarm(mode: WakeMode.gentle, windowBefore: 30),
        now: DateTime.utc(2026, 3, 2, 6),
        location: utc,
      );
      expect(plan.softStart, isNull);
      expect(plan.rampWindow, Duration.zero);
    });

    test('is scheduled at the given instant', () {
      final now = DateTime.utc(2026, 3, 2, 6, 30);
      final plan = AlarmPlanMapper.immediatePlan(
        alarm: _alarm(),
        now: now,
        location: utc,
      );
      expect(plan.scheduledUtc, now);
    });
  });

  group('armKeyFor', () {
    test('is the same for one plan however often it is asked', () {
      final plan = _plan(location: utc, window: const Duration(minutes: 15));
      expect(AlarmPlanMapper.armKeyFor(plan), AlarmPlanMapper.armKeyFor(plan));
    });

    test('a past-due plan keeps a stable key, so it is not re-armed', () {
      final plan = _plan(location: utc, window: const Duration(minutes: 15));
      final early = AlarmPlanMapper.armKeyFor(plan);
      final late = AlarmPlanMapper.armKeyFor(plan);
      expect(early, late);
      expect(
        early,
        isNot(
          AlarmPlanMapper.ringAtFor(plan, now: DateTime.utc(2026, 3, 2, 7)),
        ),
        reason: 'the floored ring time moves; the key must not',
      );
    });

    test('differs when the plan moves to another instant', () {
      final first = _plan(location: utc);
      final second = AlarmOccurrencePlan(
        alarm: first.alarm,
        scheduled: first.scheduled.add(const Duration(hours: 1)),
        softStart: null,
        location: utc,
      );
      expect(
        AlarmPlanMapper.armKeyFor(first),
        isNot(AlarmPlanMapper.armKeyFor(second)),
      );
    });
  });

  group('engineException', () {
    test('names the operation and keeps the cause', () {
      final error = AlarmPlanMapper.engineException('arm', 'denied');
      expect(error, isA<AlarmEngineException>());
      expect(error.message, contains('arm'));
      expect(error.cause, 'denied');
    });
  });

  group('alarmIdFromPayload', () {
    test('returns the id for a payload this app set', () {
      expect(AlarmPlanMapper.alarmIdFromPayload('a1'), 'a1');
    });

    test('returns null for a foreign or absent payload', () {
      expect(AlarmPlanMapper.alarmIdFromPayload(null), isNull);
      expect(AlarmPlanMapper.alarmIdFromPayload(''), isNull);
    });
  });
}
