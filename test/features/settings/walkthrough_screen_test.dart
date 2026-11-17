import 'package:capywake/app/router.dart';
import 'package:capywake/design/capy_nav_bar.dart';
import 'package:capywake/features/settings/reliability_checklist_screen.dart';
import 'package:capywake/features/settings/settings_rows.dart';
import 'package:capywake/features/settings/walkthrough_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'settings_harness.dart';

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('describes what exists, and says so plainly', (tester) async {
    await pumpSettings(tester, at: Routes.settingsWalkthrough);
    final l10n = l10nOf(tester);

    expect(find.text(l10n.walkthroughIntro), findsOneWidget);
    expect(find.text(l10n.walkthroughAlarmsBody), findsOneWidget);
    expect(find.text(l10n.walkthroughDefaultsBody), findsOneWidget);
  });

  // The row exists only because it opens a real screen. A walkthrough that
  // described an unbuilt flow would be the dead row the rules forbid.
  testWidgets('every chevron on it leads somewhere that exists', (
    tester,
  ) async {
    await pumpSettings(tester, at: Routes.settingsWalkthrough);
    final rows = tester.widgetList<SettingsChevronRow>(
      find.byType(SettingsChevronRow),
    );
    expect(rows.length, 2);
  });

  testWidgets('its reliability chevron pushes the checklist', (tester) async {
    await pumpSettings(tester, at: Routes.settingsWalkthrough);
    final l10n = l10nOf(tester);

    await scrollAndTap(tester, find.text(l10n.settingsReliabilityEntryLabel));

    expect(find.byType(ReliabilityChecklistScreen), findsOneWidget);
  });

  // Pumped through its real path, because the row pops back past Settings
  // and a directly-pumped route has nothing to pop.
  testWidgets('its alarms chevron leaves the walkthrough for the tab', (
    tester,
  ) async {
    await pumpSettings(tester);
    final l10n = l10nOf(tester);

    await scrollAndTap(tester, find.text(l10n.settingsOnboardingEntryLabel));
    expect(find.byType(WalkthroughScreen), findsOneWidget);

    await scrollAndTap(tester, find.text(l10n.alarmAddAction));

    expect(find.byType(WalkthroughScreen), findsNothing);
    expect(find.byType(CapyNavBar), findsOneWidget);
  });

  testWidgets('claims nothing about whether alarms ring', (tester) async {
    await pumpSettings(tester, at: Routes.settingsWalkthrough);

    for (final overpromise in [
      'never oversleep',
      'always ring',
      'will ring',
      'guarantee',
    ]) {
      expect(
        find.textContaining(overpromise, findRichText: true),
        findsNothing,
      );
    }
  });

  testWidgets('no overflow at 2x text scale', (tester) async {
    await pumpSettings(
      tester,
      at: Routes.settingsWalkthrough,
      textScaler: const TextScaler.linear(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow in Arabic', (tester) async {
    await pumpSettings(
      tester,
      at: Routes.settingsWalkthrough,
      locale: const Locale('ar'),
    );
    expect(tester.takeException(), isNull);
  });
}
