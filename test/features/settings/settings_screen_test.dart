import 'package:capywake/app/app_version.dart';
import 'package:capywake/app/router.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/fake_permission_service.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_nav_bar.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/features/settings/settings_group.dart';
import 'package:capywake/features/settings/settings_header.dart';
import 'package:capywake/features/settings/settings_rows.dart';
import 'package:capywake/features/settings/settings_screen.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'settings_harness.dart';

void main() {
  setUpAll(initializeDateFormatting);

  group('the rows that must not exist', () {
    // The mockup draws Backup & Sync and Restore Purchases; there is no
    // backend and nothing to restore, so the rule is enforced not remembered.
    testWidgets('no Backup & Sync, Restore Purchases, App Icon or Daily '
        'Reminder row', (tester) async {
      await pumpSettings(tester);

      for (final banned in [
        'Backup',
        'Sync',
        'Restore',
        'Purchase',
        'App Icon',
        'Daily Reminder',
        'iCloud',
      ]) {
        expect(
          find.textContaining(banned, findRichText: true),
          findsNothing,
          reason: '"$banned" names a feature that does not exist',
        );
      }
    });

    testWidgets('no row claims an alarm will ring', (tester) async {
      await pumpSettings(tester);

      for (final overpromise in [
        'never oversleep',
        'always ring',
        'guarantee',
        'silent mode',
        'Do Not Disturb',
      ]) {
        expect(
          find.textContaining(overpromise, findRichText: true),
          findsNothing,
          reason: 'overpromising is a High finding',
        );
      }
    });
  });

  group('every chevron opens something', () {
    // Counted after scrolling: the list builds lazily, so an unscrolled
    // count measures the viewport rather than the screen.
    testWidgets('there are exactly seven chevron rows', (tester) async {
      await pumpSettings(tester);
      final seen = <String>{};
      for (var i = 0; i < 12; i++) {
        seen.addAll(
          tester
              .widgetList<SettingsChevronRow>(find.byType(SettingsChevronRow))
              .map((r) => r.title),
        );
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      expect(seen.length, 7, reason: 'saw: $seen');
    });

    // Targeted by their own label, not by index: the list builds lazily, so
    // `.at(n)` cannot reach a row that has not been built yet.
    for (final label in const [
      'sound',
      'snooze',
      'puzzle',
      'reliability',
      'walkthrough',
      'about',
    ]) {
      testWidgets('the $label row opens something', (tester) async {
        await pumpSettings(tester);
        final l10n = l10nOf(tester);
        final target = switch (label) {
          'sound' => find.text(l10n.settingsDefaultSoundLabel),
          'snooze' => find.text(l10n.settingsDefaultSnoozeLabel),
          'puzzle' => find.text(l10n.settingsPuzzleEntryLabel),
          'reliability' => find.text(l10n.settingsReliabilityEntryLabel),
          'walkthrough' => find.text(l10n.settingsOnboardingEntryLabel),
          _ => find.text(l10n.settingsAboutVersion(AppVersion.value)),
        };

        await scrollAndTap(tester, target);

        final pushed = find.byType(SettingsScreen).evaluate().isEmpty;
        final sheet = find.byType(BottomSheet).evaluate().isNotEmpty;
        expect(
          pushed || sheet,
          isTrue,
          reason: 'the $label row opened nothing',
        );
      });
    }

    // The time-format row writes in place rather than opening, so "it did
    // something" is the written value, not a new surface.
    testWidgets('the time format row changes the stored preference', (
      tester,
    ) async {
      final harness = await pumpSettings(tester);
      final l10n = l10nOf(tester);
      final before = (await harness.readSettings()).timeFormat;

      await scrollAndTap(tester, find.text(l10n.settingsTimeFormatLabel));

      expect((await harness.readSettings()).timeFormat, isNot(before));
    });
  });

  group('defaults persist', () {
    testWidgets('choosing a sound writes it to the settings row', (
      tester,
    ) async {
      final harness = await pumpSettings(tester);
      final l10n = l10nOf(tester);

      await scrollAndTap(tester, find.text(l10n.settingsDefaultSoundLabel));
      final option = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(l10n.alarmSoundMorning),
      );
      expect(option, findsOneWidget);
      await tester.tap(option);
      await tester.pumpAndSettle();

      final saved = await harness.readSettings();
      expect(saved.defaultSoundId, 'morning');
    });

    testWidgets('choosing a snooze length writes it', (tester) async {
      final harness = await pumpSettings(tester);
      final l10n = l10nOf(tester);

      await scrollAndTap(tester, find.text(l10n.settingsDefaultSnoozeLabel));
      await tester.tap(find.text(l10n.alarmSnoozeDurationValue(15)).last);
      await tester.pumpAndSettle();

      final saved = await harness.readSettings();
      expect(saved.defaultSnoozeMinutes, 15);
    });

    testWidgets('picking a theme tile writes the preference', (tester) async {
      final harness = await pumpSettings(tester);
      final l10n = l10nOf(tester);

      await tester.tap(find.bySemanticsLabel(l10n.settingsThemeDark));
      await tester.pumpAndSettle();

      final saved = await harness.readSettings();
      expect(saved.themeMode, ThemeModePreference.dark);
    });

    testWidgets('the motion check is off until the user turns it on', (
      tester,
    ) async {
      final harness = await pumpSettings(tester);
      expect((await harness.readSettings()).motionConfirmationEnabled, isFalse);

      await scrollAndTap(tester, find.byType(CapyToggle));

      expect((await harness.readSettings()).motionConfirmationEnabled, isTrue);
    });
  });

  group('the theme tiles', () {
    // ThemeModePreference is system / light / dark. The mockup's middle tile
    // reads as a sunset; a sunset theme would be a setting that does nothing.
    testWidgets('offer exactly the three themes that exist', (tester) async {
      await pumpSettings(tester);
      final l10n = l10nOf(tester);

      expect(find.bySemanticsLabel(l10n.settingsThemeSystem), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.settingsThemeLight), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.settingsThemeDark), findsOneWidget);
      expect(find.textContaining('Sunset'), findsNothing);
    });

    testWidgets('each tile shows its own painted art (G12)', (tester) async {
      await pumpSettings(tester);
      final l10n = l10nOf(tester);

      for (final (label, art) in [
        (l10n.settingsThemeSystem, CapyArt.themeSystem),
        (l10n.settingsThemeLight, CapyArt.themeLight),
        (l10n.settingsThemeDark, CapyArt.themeDark),
      ]) {
        final image = tester.widget<Image>(
          find.descendant(
            of: find.bySemanticsLabel(label),
            matching: find.byType(Image),
          ),
        );
        expect((image.image as AssetImage).assetName, art.path, reason: label);
        expect(image.fit, BoxFit.cover);
      }
    });

    testWidgets('selection is readable without colour', (tester) async {
      await pumpSettings(
        tester,
        seed: UserSettings.initial.copyWith(
          themeMode: ThemeModePreference.dark,
        ),
      );
      final l10n = l10nOf(tester);

      expect(
        tester.getSemantics(find.bySemanticsLabel(l10n.settingsThemeDark)),
        matchesSemantics(
          label: l10n.settingsThemeDark,
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
        ),
      );
    });
  });

  group('the notification row is a status, not a switch', () {
    // A switch here would stop every alarm from ringing, from inside
    // Settings, with nothing on screen saying so.
    testWidgets('renders as a status row with no toggle of its own', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        grants: const PermissionState(
          notification: PermissionGrant.denied,
          exactAlarm: PermissionGrant.granted,
        ),
      );
      final l10n = l10nOf(tester);

      final row = find.ancestor(
        of: find.text(l10n.settingsNotificationRowTitle),
        matching: find.byType(SettingsStatusRow),
      );
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.byType(CapyToggle)),
        findsNothing,
        reason: 'a switch here can silence every alarm',
      );
    });

    testWidgets('offers to grant when denied, and asks the OS once', (
      tester,
    ) async {
      final harness = await pumpSettings(
        tester,
        grants: const PermissionState(
          notification: PermissionGrant.denied,
          exactAlarm: PermissionGrant.granted,
        ),
      );
      final l10n = l10nOf(tester);

      expect(
        find.textContaining(l10n.settingsNotificationNotAllowed),
        findsOneWidget,
      );
      await tester.tap(find.text(l10n.settingsNotificationAllowAction));
      await tester.pumpAndSettle();

      expect(harness.permissions.notificationRequestCount, 1);
    });

    testWidgets('offers no action once granted — nothing left to grant', (
      tester,
    ) async {
      await pumpSettings(tester);
      final l10n = l10nOf(tester);

      expect(
        find.textContaining(l10n.settingsNotificationAllowed),
        findsOneWidget,
      );
      expect(find.text(l10n.settingsNotificationAllowAction), findsNothing);
      expect(
        find.textContaining(l10n.settingsNotificationManageHint),
        findsOneWidget,
        reason: 'revoking belongs to the OS, so the row says where',
      );
    });

    testWidgets('sends a permanently-denied user to the OS settings', (
      tester,
    ) async {
      final harness = await pumpSettings(
        tester,
        grants: const PermissionState(
          notification: PermissionGrant.permanentlyDenied,
          exactAlarm: PermissionGrant.granted,
        ),
      );
      final l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.reliabilityOpenSettingsAction));
      await tester.pumpAndSettle();

      expect(harness.permissions.openAppSettingsCount, 1);
      expect(harness.permissions.notificationRequestCount, 0);
    });
  });

  group('About', () {
    // The row reads AppVersion, which app_version_test ties to the pubspec.
    testWidgets('shows the build version', (tester) async {
      await pumpSettings(tester);
      final l10n = l10nOf(tester);

      final row = find.text(l10n.settingsAboutVersion(AppVersion.value));
      await tester.scrollUntilVisible(row, 120, maxScrolls: 30);
      expect(row, findsOneWidget);
    });

    testWidgets('the sheet opens and makes no reliability claim', (
      tester,
    ) async {
      await pumpSettings(tester);
      final l10n = l10nOf(tester);

      await scrollAndTap(
        tester,
        find.text(l10n.settingsAboutVersion(AppVersion.value)),
      );

      expect(find.text(l10n.settingsAboutBody), findsOneWidget);
    });
  });

  group('Tier A — the blocks the row cuts cannot move', () {
    testWidgets('hero band and first group sit where 04_SETTINGS.png puts '
        'them', (tester) async {
      await pumpSettings(tester);

      // The mockup measures from a 44pt status bar; the test view has none,
      // so blocks are compared relative to the hero's lower edge.
      final hero = tester.getRect(find.byType(SettingsHeader).first);
      expect(
        hero.height,
        closeTo(59.9, 0.5),
        reason: '103.9 - 44.0 on the mockup',
      );

      // Four of the five fit the viewport; the fifth is below the fold.
      final groups = find.byType(SettingsGroup);
      expect(tester.widgetList(groups).length, greaterThanOrEqualTo(4));

      final first = tester.getRect(groups.first);
      expect(
        first.left,
        closeTo(9.7, 0.5),
        reason: 'gutter, agreed across three groups',
      );
      expect(
        first.width,
        closeTo(373.6, 1),
        reason: 'card width 9.70 -> 383.32',
      );
    });

    testWidgets("the meadow is Settings own height, not Home's", (
      tester,
    ) async {
      await pumpSettings(tester);
      final meadow = tester.getRect(find.byType(MeadowFooter));
      expect(meadow.height, closeTo(SettingsScreen.meadowHeight, 0.5));
      expect(meadow.height, isNot(closeTo(65.2, 0.5)));
    });

    testWidgets("the toggle paints Settings own track, not Home's", (
      tester,
    ) async {
      await pumpSettings(tester);

      final toggle = find.byType(CapyToggle);
      await tester.scrollUntilVisible(toggle, 120, maxScrolls: 30);
      final painted = tester.getSize(
        find.descendant(of: toggle, matching: find.byType(DecoratedBox)).first,
      );

      expect(painted.width, closeTo(CapyToggle.settingsTrack.width, 0.1));
      expect(painted.height, closeTo(CapyToggle.settingsTrack.height, 0.1));
      expect(painted.width, isNot(closeTo(CapyToggle.homeTrack.width, 0.1)));
    });

    testWidgets('every row clears the 44pt tap floor', (tester) async {
      await pumpSettings(tester);

      for (final finder in [
        find.byType(SettingsChevronRow),
        find.byType(SettingsStatusRow),
        find.byType(SettingsToggleRow),
      ]) {
        for (var i = 0; i < tester.widgetList(finder).length; i++) {
          expect(
            tester.getSize(finder.at(i)).height,
            greaterThanOrEqualTo(SettingsRowMetrics.minHeight),
          );
        }
      }
    });
  });

  group('layout survives the hard cases', () {
    testWidgets('no overflow at 2x text scale', (tester) async {
      await pumpSettings(tester, textScaler: const TextScaler.linear(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow in Arabic, which is RTL', (tester) async {
      await pumpSettings(tester, locale: const Locale('ar'));
      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.byType(SettingsScreen))),
        TextDirection.rtl,
      );
    });

    testWidgets('no overflow in German, the longest of the ten', (
      tester,
    ) async {
      await pumpSettings(tester, locale: const Locale('de'));
      expect(tester.takeException(), isNull);
    });
  });

  group('navigation', () {
    testWidgets('the reliability row pushes and pops back to Settings', (
      tester,
    ) async {
      await pumpSettings(tester);
      final l10n = l10nOf(tester);

      await scrollAndTap(tester, find.text(l10n.settingsReliabilityEntryLabel));
      expect(find.text(l10n.reliabilityTitle), findsWidgets);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('the walkthrough row pushes and pops back to Settings', (
      tester,
    ) async {
      await pumpSettings(tester);
      final l10n = l10nOf(tester);

      await scrollAndTap(tester, find.text(l10n.settingsOnboardingEntryLabel));
      expect(find.text(l10n.walkthroughTitle), findsWidgets);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    // Reached the way the user reaches it: the gear, from a tab.
    testWidgets('the header gear opens Settings over the tab', (tester) async {
      await pumpSettings(tester, at: Routes.home);

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(
        find.byType(CapyNavBar),
        findsNothing,
        reason: 'a pushed route covers the bottom bar',
      );
    });
  });

  // Self-review #2: `permissionStateProvider` declares a dependency on a
  // scoped provider, so a scope that does not override it throws on read.
  group('the permission provider survives the real scope shape', () {
    testWidgets('a root ProviderScope with the platform override works', (
      tester,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          permissionServiceProvider.overrideWith(
            (ref) => FakePermissionService(initial: PermissionState.initial),
          ),
        ],
      );
      // Dispose before closing the database: a live Drift stream holds a
      // timer the framework asserts on at teardown.
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: createRouter(initialLocation: Routes.settings),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
