import 'package:capywake/app/app.dart';
import 'package:capywake/app/router.dart';
import 'package:capywake/core/camera/fake_camera_access.dart';
import 'package:capywake/core/engine/fake_alarm_engine.dart';
import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/data/camera/camera_providers.dart';
import 'package:capywake/data/camera/code_scanner.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/tokens.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'contrast_probe.dart';

final _clock = DateTime.utc(2026, 5, 21, 5);

Alarm _alarm(
  String id,
  int minutes, {
  DismissMethod? dismiss,
  bool enabled = true,
}) => Alarm(
  id: id,
  label: 'Morning',
  enabled: enabled,
  targetTimeMinutes: minutes,
  repeatWeekdays: const {1, 2, 3, 4, 5},
  wakeMode: WakeMode.standard,
  wakeWindowStartMinutesBefore: 0,
  soundId: 'gentle',
  vibrationEnabled: true,
  snoozeEnabled: true,
  snoozeDurationMinutes: 9,
  maxSnoozes: 5,
  dismissMethod: dismiss ?? DismissMethod.normalButton,
  dismissChallengeDifficulty: null,
  confirmationEnabled: false,
  createdAt: _clock,
  updatedAt: _clock,
);

Future<FakeAlarmEngine> _pump(
  WidgetTester tester,
  String location, {
  required ThemeModePreference theme,
  bool withAlarms = true,
  Brightness platform = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.platformBrightnessTestValue = platform;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final engine = FakeAlarmEngine(now: () => _clock);
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      alarmEngineProvider.overrideWithValue(engine),
      engineNowProvider.overrideWithValue(() => _clock),
      cameraAccessProvider.overrideWithValue(
        FakeCameraAccess(current: DeviceAccess.ready),
      ),
      codeScannerProvider.overrideWithValue(FakeCodeScanner()),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await engine.dispose();
    await db.close();
  });
  final repository = container.read(capywakeRepositoryProvider);
  await repository.saveSettings(
    UserSettings.initial.copyWith(themeMode: theme),
  );
  if (withAlarms) {
    await repository.upsertAlarm(_alarm('a1', 7 * 60));
    await repository.upsertAlarm(
      _alarm('a2', 6 * 60 + 30, dismiss: DismissMethod.puzzle),
    );
    await repository.upsertAlarm(_alarm('a3', 9 * 60, enabled: false));
  }

  await tester.pumpWidget(
    CapyWakeApp(
      router: createRouter(initialLocation: location),
      showDebugBanner: false,
      scopeBuilder: (child) =>
          UncontrolledProviderScope(container: container, child: child),
    ),
  );
  await tester.pumpAndSettle();
  return engine;
}

/// Texts below the bar only because they sit on, or are, the brand orange or
/// green. Pinned, so a new one is a deliberate edit here, never silent.
const _pinnedConstrained = <String, int>{
  'home': 2,
  'add/edit': 4,
  'edit': 4,
  'stats': 1,
  'onboarding': 2,
  'practice qr_treasure_hunt': 2,
  'ringing a1': 4,
  'ringing a2': 3,
};

/// Texts over a raster scene, which only the dark captures can judge. Pinned
/// so a new one is seen: the title over a scene band, the ringing clock.
final _pinnedOverArt = <String, int>{
  'stats': 1,
  'settings': 1,
  'puzzle chooser': 1,
  for (final game in GameCatalogue.entries) 'practice ${game.id}': 1,
  'ringing a1': 3,
  'ringing a2': 3,
};

/// `cocoaSoft` on cream is 4.49:1, a hundredth under the bar: the sampled
/// palette, pinned in `tokens_contrast_test.dart`, never a layout's doing.
bool _softCocoaOnCream(TextContrast t) =>
    t.foreground == CapyColors.cocoaSoft &&
    (t.background == CapyColors.cream || t.background == CapyColors.surface);

void _expectLegible(WidgetTester tester, String screen) {
  final texts = measureTextContrast(tester);
  final constrained = texts.where((t) => t.paletteConstraint && !t.meetsBar);
  expect(
    constrained.length,
    _pinnedConstrained[screen] ?? 0,
    reason: '$screen: brand-colour texts under the bar: $constrained',
  );
  expect(texts, isNotEmpty, reason: '$screen painted no text');
  final blind = texts.where((t) => t.source == FillSource.none).toList();
  expect(blind, isEmpty, reason: '$screen: no fill or colour for $blind');
  final overArt = texts.where((t) => t.source == FillSource.art).toList();
  expect(
    overArt.length,
    _pinnedOverArt[screen] ?? 0,
    reason: '$screen: texts over art, unmeasured: $overArt',
  );
  final failures = texts.where((t) => !t.passes).toList();
  expect(
    failures,
    isEmpty,
    reason:
        '$screen has ${failures.length} illegible texts:\n'
        '${failures.join('\n')}',
  );
}

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting();
  });

  final routes = <String, String>{
    'home': Routes.home,
    'alarms': Routes.alarms,
    'add/edit': Routes.alarmNew,
    'edit': Routes.alarmEdit('a2'),
    'stats': Routes.stats,
    'settings': Routes.settings,
    'reliability': Routes.settingsReliability,
    'walkthrough': Routes.settingsWalkthrough,
    'wake puzzle': Routes.settingsPuzzle,
    'puzzle games': Routes.settingsPuzzleGames,
    'puzzle types': Routes.settingsPuzzleTypes,
    'puzzle advanced': Routes.settingsPuzzleAdvanced,
    'onboarding': Routes.onboarding,
    for (final game in GameCatalogue.entries)
      'practice ${game.id}': Routes.gamePractice(game.id),
  };

  group('dark mode keeps every text legible', () {
    for (final MapEntry(key: screen, value: location) in routes.entries) {
      testWidgets(screen, (tester) async {
        await _pump(tester, location, theme: ThemeModePreference.dark);
        _expectLegible(tester, screen);
      });
    }

    testWidgets('alarms, empty', (tester) async {
      await _pump(
        tester,
        Routes.alarms,
        theme: ThemeModePreference.dark,
        withAlarms: false,
      );
      _expectLegible(tester, 'alarms, empty');
    });

    for (final alarmId in ['a1', 'a2']) {
      testWidgets('ringing $alarmId', (tester) async {
        final engine = await _pump(
          tester,
          Routes.home,
          theme: ThemeModePreference.dark,
        );
        engine.fire(alarmId, firedAt: _clock);
        await tester.pumpAndSettle();
        _expectLegible(tester, 'ringing $alarmId');
      });
    }
  });

  group('light mode keeps every text legible', () {
    for (final MapEntry(key: screen, value: location) in routes.entries) {
      testWidgets(screen, (tester) async {
        await _pump(tester, location, theme: ThemeModePreference.light);
        final failures = measureTextContrast(
          tester,
        ).where((t) => !t.passes && !_softCocoaOnCream(t)).toList();
        expect(
          failures,
          isEmpty,
          reason:
              '$screen has ${failures.length} illegible texts:\n'
              '${failures.join('\n')}',
        );
      });
    }
  });

  testWidgets('the gate fails on dark ink on a dark card', (tester) async {
    await _pump(tester, Routes.home, theme: ThemeModePreference.dark);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ColoredBox(
            color: CapyColors.darkSurface,
            child: Text('Alarm', style: TextStyle(color: CapyColors.cocoa)),
          ),
        ),
      ),
    );
    final failures = measureTextContrast(
      tester,
    ).where((t) => !t.passes).toList();
    expect(failures.single.source, FillSource.coloredBox);
    expect(failures.single.ratio, lessThan(1.5));
  });

  testWidgets('white on the brand orange is counted, not failed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ColoredBox(
            color: CapyColors.accent,
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
    final save = measureTextContrast(tester).single;
    expect(save.paletteConstraint, isTrue);
    expect(save.ratio, lessThan(3));
  });

  test('the ratio is WCAG 2', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.001));
  });
}
