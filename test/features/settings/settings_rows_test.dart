import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/features/settings/settings_group.dart';
import 'package:capywake/features/settings/settings_rows.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {TextScaler scaler = TextScaler.noScaling}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: scaler),
        child: Center(child: SizedBox(width: 373.6, child: child)),
      ),
    ),
  );
}

void main() {
  group('SettingsChevronRow', () {
    testWidgets('announces its title and value as one button', (tester) async {
      await tester.pumpWidget(
        _host(
          SettingsChevronRow(
            icon: Icons.alarm,
            title: 'Sound',
            value: 'Gentle',
            onTap: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(SettingsChevronRow)),
        matchesSemantics(label: 'Sound, Gentle', isButton: true),
      );
    });

    testWidgets('reports its tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          SettingsChevronRow(
            icon: Icons.alarm,
            title: 'Sound',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(SettingsChevronRow));
      expect(tapped, isTrue);
    });

    testWidgets('clears the tap floor even with a one-word title', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SettingsChevronRow(icon: Icons.alarm, title: 'Sound', onTap: () {}),
        ),
      );

      expect(
        tester.getSize(find.byType(SettingsChevronRow)).height,
        greaterThanOrEqualTo(SettingsRowMetrics.minHeight),
      );
    });

    testWidgets('does not overflow with a long value at 2x', (tester) async {
      await tester.pumpWidget(
        _host(
          SettingsChevronRow(
            icon: Icons.alarm,
            title: 'Default snooze length',
            value: 'Syncopated Marimba',
            onTap: () {},
          ),
          scaler: const TextScaler.linear(2),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SettingsToggleRow', () {
    testWidgets("paints the Settings track, not Home's", (tester) async {
      await tester.pumpWidget(
        _host(
          SettingsToggleRow(
            icon: Icons.directions_walk,
            title: 'Motion check',
            value: false,
            onChanged: (_) {},
          ),
        ),
      );

      final toggle = tester.widget<CapyToggle>(find.byType(CapyToggle));
      expect(toggle.trackSize, CapyToggle.settingsTrack);
    });

    // Self-review #1: without a merge, the title and the switch are two
    // nodes, so the control is announced unlabelled beside a loose label.
    testWidgets('reads as one node, title and switch together', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SettingsToggleRow(
            icon: Icons.directions_walk,
            title: 'Motion check',
            subtitle: 'Off here means off for every alarm',
            value: false,
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(SettingsToggleRow)),
        matchesSemantics(
          label: 'Motion check. Off here means off for every alarm',
          hasToggledState: true,
        ),
      );
    });

    testWidgets('flips its value on tap', (tester) async {
      bool? got;
      await tester.pumpWidget(
        _host(
          SettingsToggleRow(
            icon: Icons.directions_walk,
            title: 'Motion check',
            value: false,
            onChanged: (v) => got = v,
          ),
        ),
      );

      await tester.tap(find.byType(CapyToggle));
      expect(got, isTrue);
    });
  });

  group('SettingsStatusRow', () {
    // It grants and never revokes: a switch here could silence every alarm
    // from inside Settings.
    testWidgets('offers no action once satisfied', (tester) async {
      await tester.pumpWidget(
        _host(
          SettingsStatusRow(
            icon: Icons.notifications,
            title: 'Alarm notifications',
            statusLabel: 'Allowed on this phone',
            satisfied: true,
            actionLabel: 'Allow',
            onAction: () {},
          ),
        ),
      );

      expect(find.text('Allow'), findsNothing);
      expect(find.textContaining('Allowed on this phone'), findsOneWidget);
    });

    testWidgets('is not a button once satisfied', (tester) async {
      await tester.pumpWidget(
        _host(
          SettingsStatusRow(
            icon: Icons.notifications,
            title: 'Alarm notifications',
            statusLabel: 'Allowed on this phone',
            satisfied: true,
            actionLabel: 'Allow',
            onAction: () {},
          ),
        ),
      );

      final node = tester.getSemantics(find.byType(SettingsStatusRow));
      expect(node.flagsCollection.isButton, isFalse);
    });

    testWidgets('state is readable without colour', (tester) async {
      for (final satisfied in [true, false]) {
        await tester.pumpWidget(
          _host(
            SettingsStatusRow(
              icon: Icons.notifications,
              title: 'Alarm notifications',
              statusLabel: satisfied ? 'Allowed' : 'Not allowed',
              satisfied: satisfied,
              actionLabel: 'Allow',
              onAction: () {},
            ),
          ),
        );

        // An icon and a sentence, not a colour: `success` is under 3:1.
        expect(
          find.byIcon(
            satisfied
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
          ),
          findsOneWidget,
        );
      }
    });
  });

  group('SettingsGroup', () {
    testWidgets('draws one divider fewer than it has rows', (tester) async {
      await tester.pumpWidget(
        _host(
          SettingsGroup(
            icon: Icons.alarm,
            title: 'Alarms',
            rows: [
              SettingsChevronRow(icon: Icons.alarm, title: 'One', onTap: () {}),
              SettingsChevronRow(
                icon: Icons.snooze,
                title: 'Two',
                onTap: () {},
              ),
              SettingsChevronRow(
                icon: Icons.palette,
                title: 'Three',
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      expect(tester.widgetList(find.byType(SettingsDivider)).length, 2);
    });

    testWidgets('its heading is a semantic header', (tester) async {
      await tester.pumpWidget(
        _host(
          SettingsGroup(
            icon: Icons.alarm,
            title: 'Alarms',
            rows: [
              SettingsChevronRow(icon: Icons.alarm, title: 'One', onTap: () {}),
            ],
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('Alarms')).flagsCollection.isHeader,
        isTrue,
      );
    });

    testWidgets('gives its rows a Material to ink on', (tester) async {
      await tester.pumpWidget(
        _host(
          SettingsGroup(
            icon: Icons.alarm,
            title: 'Alarms',
            rows: [
              SettingsChevronRow(icon: Icons.alarm, title: 'One', onTap: () {}),
            ],
          ),
        ),
      );

      // Without it an InkWell row throws on a pushed route, which has no
      // Scaffold of the shell's to borrow one from.
      expect(
        find.descendant(
          of: find.byType(SettingsGroup),
          matching: find.byType(Material),
        ),
        findsWidgets,
      );
    });
  });
}
