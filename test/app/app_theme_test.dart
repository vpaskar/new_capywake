import 'dart:async';

import 'package:capywake/app/app.dart';
import 'package:capywake/app/router.dart';
import 'package:capywake/app/theme_mode.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/design/tokens.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting();
  });

  test('every preference maps to its theme mode', () {
    expect(themeModeFor(ThemeModePreference.system), ThemeMode.system);
    expect(themeModeFor(ThemeModePreference.light), ThemeMode.light);
    expect(themeModeFor(ThemeModePreference.dark), ThemeMode.dark);
  });

  Future<CapyWakeRepository> pumpApp(
    WidgetTester tester, {
    ThemeModePreference? saved,
    Brightness platform = Brightness.light,
  }) async {
    tester.platformDispatcher.platformBrightnessTestValue = platform;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = CapyWakeRepository(db);
    if (saved != null) {
      await repository.saveSettings(
        UserSettings.initial.copyWith(themeMode: saved),
      );
    }
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await tester.pumpWidget(
      CapyWakeApp(
        router: createRouter(initialLocation: Routes.alarms),
        showDebugBanner: false,
        scopeBuilder: (child) =>
            UncontrolledProviderScope(container: container, child: child),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  Brightness shown(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

  for (final (saved, platform, expected) in const [
    (ThemeModePreference.system, Brightness.light, Brightness.light),
    (ThemeModePreference.system, Brightness.dark, Brightness.dark),
    (ThemeModePreference.light, Brightness.dark, Brightness.light),
    (ThemeModePreference.dark, Brightness.light, Brightness.dark),
  ]) {
    testWidgets('$saved on a $platform phone shows $expected', (tester) async {
      await pumpApp(tester, saved: saved, platform: platform);
      expect(shown(tester), expected);
    });
  }

  testWidgets('changing the preference re-themes the open app', (
    tester,
  ) async {
    final repository = await pumpApp(tester);
    expect(shown(tester), Brightness.light);

    await repository.saveSettings(
      UserSettings.initial.copyWith(themeMode: ThemeModePreference.dark),
    );
    await tester.pumpAndSettle();

    expect(shown(tester), Brightness.dark);
  });

  testWidgets('the first frame shown is already the saved theme', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final settings = StreamController<UserSettings>();
    addTearDown(settings.close);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        userSettingsStreamProvider.overrideWith((ref) => settings.stream),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await tester.pumpWidget(
      CapyWakeApp(
        router: createRouter(initialLocation: Routes.alarms),
        scopeBuilder: (child) =>
            UncontrolledProviderScope(container: container, child: child),
      ),
    );
    await tester.pump();

    settings.add(
      UserSettings.initial.copyWith(themeMode: ThemeModePreference.dark),
    );
    while (!tester.binding.sendFramesToEngine) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    final page = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(page.scaffoldBackgroundColor, CapyColors.darkCream);
    await tester.pumpAndSettle();
  });

  testWidgets('the first frame waits for the saved theme', (tester) async {
    final settings = StreamController<UserSettings>();
    addTearDown(settings.close);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        userSettingsStreamProvider.overrideWith((ref) => settings.stream),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      CapyWakeApp(
        router: createRouter(initialLocation: Routes.alarms),
        scopeBuilder: (child) =>
            UncontrolledProviderScope(container: container, child: child),
      ),
    );
    await tester.pump();
    expect(tester.binding.sendFramesToEngine, isFalse);

    settings.add(UserSettings.initial);
    await tester.pump();
    await tester.pump();
    expect(tester.binding.sendFramesToEngine, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('a theme that never loads holds the first frame only so long', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        userSettingsStreamProvider.overrideWith(
          (ref) => StreamController<UserSettings>().stream,
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      CapyWakeApp(
        router: createRouter(initialLocation: Routes.alarms),
        scopeBuilder: (child) =>
            UncontrolledProviderScope(container: container, child: child),
      ),
    );
    await tester.pump(CapyWakeApp.themeWait - const Duration(milliseconds: 1));
    expect(tester.binding.sendFramesToEngine, isFalse);

    await tester.pump(const Duration(milliseconds: 2));
    expect(tester.binding.sendFramesToEngine, isTrue);
  });
}
