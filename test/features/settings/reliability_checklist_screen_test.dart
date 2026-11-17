import 'package:capywake/app/router.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/core/reliability/reliability_checklist_service.dart';
import 'package:capywake/core/reliability/reliability_copy_service.dart';
import 'package:capywake/features/settings/settings_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'settings_harness.dart';

const _allDenied = PermissionState(
  notification: PermissionGrant.denied,
  exactAlarm: PermissionGrant.denied,
);

void main() {
  setUpAll(initializeDateFormatting);

  group("the rows are the service's, not the screen's", () {
    testWidgets('iOS shows the three items that apply there', (tester) async {
      await pumpSettings(tester, at: Routes.settingsReliability);
      final l10n = l10nOf(tester);

      expect(
        find.text(l10n.reliabilityChecklistNotificationTitle),
        findsOneWidget,
      );
      expect(find.text(l10n.reliabilityChecklistVolumeTitle), findsOneWidget);
      expect(find.text(l10n.reliabilityChecklistDndTitle), findsOneWidget);

      // Exact alarm and battery optimisation are Android concepts. The
      // service omits them rather than drawing inert "not applicable" rows.
      expect(
        find.text(l10n.reliabilityChecklistExactAlarmTitle),
        findsNothing,
      );
      expect(find.text(l10n.reliabilityChecklistBatteryTitle), findsNothing);
    });

    testWidgets('Android adds its own two', (tester) async {
      await pumpSettings(
        tester,
        at: Routes.settingsReliability,
        platform: ReliabilityPlatform.android,
      );
      final l10n = l10nOf(tester);

      expect(
        find.text(l10n.reliabilityChecklistExactAlarmTitle),
        findsOneWidget,
      );
      expect(find.text(l10n.reliabilityChecklistBatteryTitle), findsOneWidget);
    });

    testWidgets('the row count matches the service exactly', (tester) async {
      for (final platform in ReliabilityPlatform.values) {
        await pumpSettings(
          tester,
          at: Routes.settingsReliability,
          platform: platform,
        );
        expect(
          tester.widgetList(find.byType(SettingsStatusRow)).length,
          ReliabilityChecklistService.visibleOrder(platform).length,
          reason: 'the screen renders the service, it does not pick rows',
        );
      }
    });
  });

  group('honesty', () {
    testWidgets('no row promises that an alarm will ring', (tester) async {
      await pumpSettings(tester, at: Routes.settingsReliability);

      for (final overpromise in [
        'never oversleep',
        'always ring',
        'will ring',
        'guarantee',
        'as reliable as',
      ]) {
        expect(
          find.textContaining(overpromise, findRichText: true),
          findsNothing,
          reason: 'overpromising is a High finding',
        );
      }
    });

    testWidgets('the all-clear talks about the list, not about ringing', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        at: Routes.settingsReliability,
        seed: UserSettings.initial.copyWith(
          reliabilityChecklistState: const ReliabilityChecklistState(
            items: {
              ReliabilityChecklistItem.alarmVolume: ChecklistItemState.ok,
              ReliabilityChecklistItem.doNotDisturbPosture:
                  ChecklistItemState.ok,
            },
          ),
        ),
      );
      final l10n = l10nOf(tester);

      expect(find.text(l10n.reliabilityAttentionNoneTitle), findsOneWidget);
      expect(find.text(l10n.reliabilityAttentionNoneBody), findsOneWidget);
    });

    testWidgets('the attention card counts the open items', (tester) async {
      await pumpSettings(
        tester,
        at: Routes.settingsReliability,
        grants: _allDenied,
      );
      final l10n = l10nOf(tester);

      // Three iOS rows, all open on a fresh install with notifications off.
      expect(find.text(l10n.reliabilityAttentionTitle(3)), findsOneWidget);
    });

    testWidgets('with one open item it may say the rest are fine', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        at: Routes.settingsReliability,
        grants: _allDenied,
        seed: UserSettings.initial.copyWith(
          reliabilityChecklistState: const ReliabilityChecklistState(
            items: {
              ReliabilityChecklistItem.alarmVolume: ChecklistItemState.ok,
              ReliabilityChecklistItem.doNotDisturbPosture:
                  ChecklistItemState.ok,
            },
          ),
        ),
      );
      final l10n = l10nOf(tester);

      expect(find.text(l10n.reliabilityAttentionTitle(1)), findsOneWidget);
      expect(
        find.textContaining(l10n.reliabilityAttentionEverythingElseFine),
        findsOneWidget,
      );
    });
  });

  group('actions', () {
    testWidgets('a denied notification row asks the OS', (tester) async {
      final harness = await pumpSettings(
        tester,
        at: Routes.settingsReliability,
        grants: _allDenied,
      );
      final l10n = l10nOf(tester);

      await scrollAndTap(
        tester,
        find.text(l10n.reliabilityRequestNotificationAction),
      );

      expect(harness.permissions.notificationRequestCount, 1);
    });

    testWidgets('acknowledging a user-judged row persists it', (tester) async {
      final harness = await pumpSettings(
        tester,
        at: Routes.settingsReliability,
      );
      final l10n = l10nOf(tester);

      await scrollAndTap(
        tester,
        find.text(l10n.reliabilityChecklistAcknowledgeAction).first,
      );

      final saved = await harness.readSettings();
      final acknowledged =
          ReliabilityChecklistService.visibleOrder(
            ReliabilityPlatform.ios,
          ).where(
            (item) =>
                saved.reliabilityChecklistState.stateOf(item) ==
                ChecklistItemState.ok,
          );
      expect(acknowledged, isNotEmpty);
    });

    testWidgets('a granted row offers no action', (tester) async {
      await pumpSettings(tester, at: Routes.settingsReliability);
      final l10n = l10nOf(tester);

      expect(
        find.text(l10n.reliabilityRequestNotificationAction),
        findsNothing,
      );
    });
  });

  group('layout', () {
    testWidgets('no overflow at 2x text scale', (tester) async {
      await pumpSettings(
        tester,
        at: Routes.settingsReliability,
        textScaler: const TextScaler.linear(2),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow in Arabic', (tester) async {
      await pumpSettings(
        tester,
        at: Routes.settingsReliability,
        locale: const Locale('ar'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('every row clears the 44pt tap floor', (tester) async {
      await pumpSettings(
        tester,
        at: Routes.settingsReliability,
        grants: _allDenied,
      );

      final rows = find.byType(SettingsStatusRow);
      for (var i = 0; i < tester.widgetList(rows).length; i++) {
        expect(
          tester.getSize(rows.at(i)).height,
          greaterThanOrEqualTo(SettingsRowMetrics.minHeight),
        );
      }
    });
  });
}
