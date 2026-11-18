import 'package:capywake/core/models/models.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/alarms/alarm_list_tile.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'alarms_screen_test.dart' show alarmFixture;

Future<({List<bool> toggles, int taps})> _pump(
  WidgetTester tester, {
  required Alarm alarm,
  int index = 0,
  TimeFormatPreference format = TimeFormatPreference.system,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final toggles = <bool>[];
  var taps = 0;

  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: AlarmListTile(
            alarm: alarm,
            index: index,
            timeFormat: format,
            onToggle: toggles.add,
            onTap: () => taps++,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (toggles: toggles, taps: taps);
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('renders time, period, repeat and label', (tester) async {
    await _pump(
      tester,
      alarm: alarmFixture(
        id: 'a',
        minutes: 7 * 60,
        label: 'Wake Up',
        repeat: const {1, 2, 3, 4, 5},
      ),
      format: TimeFormatPreference.h12,
    );

    expect(find.text('7:00'), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('Weekdays'), findsOneWidget);
    expect(find.text('Wake Up'), findsOneWidget);
  });

  testWidgets('draws the chosen picture, or the placeholder for none', (
    tester,
  ) async {
    await _pump(
      tester,
      alarm: alarmFixture(id: 'a', minutes: 7 * 60).copyWith(
        artId: 'thumb.music',
      ),
    );
    expect(find.byKey(const ValueKey('thumb.music')), findsOneWidget);

    await _pump(
      tester,
      alarm: alarmFixture(id: 'a', minutes: 7 * 60).copyWith(
        artId: Alarm.noArtId,
      ),
    );
    expect(find.byKey(const ValueKey('alarm-art-placeholder')), findsOneWidget);
  });

  testWidgets('Automatic follows the list position', (tester) async {
    await _pump(
      tester,
      alarm: alarmFixture(id: 'a', minutes: 7 * 60),
      index: 1,
    );
    expect(find.byKey(const ValueKey('thumb.workout')), findsOneWidget);
  });

  testWidgets('omits the label line when the alarm has none', (tester) async {
    await _pump(
      tester,
      alarm: alarmFixture(id: 'a', minutes: 7 * 60),
      format: TimeFormatPreference.h12,
    );

    expect(find.text('7:00'), findsOneWidget);
    expect(find.text('Once, then it stays off'), findsOneWidget);
  });

  testWidgets('h24 shows no period beside the digits', (tester) async {
    await _pump(
      tester,
      alarm: alarmFixture(id: 'a', minutes: 21 * 60 + 30),
      format: TimeFormatPreference.h24,
    );

    expect(find.text('21:30'), findsOneWidget);
    expect(find.text('PM'), findsNothing);
  });

  testWidgets('the toggle reports the new value', (tester) async {
    final result = await _pump(
      tester,
      alarm: alarmFixture(id: 'a', minutes: 7 * 60),
    );

    await tester.tap(find.byType(CapyToggle));
    expect(result.toggles, [false]);
  });

  testWidgets('the toggle of a disabled alarm reports true', (tester) async {
    final result = await _pump(
      tester,
      alarm: alarmFixture(id: 'a', minutes: 7 * 60, enabled: false),
    );

    await tester.tap(find.byType(CapyToggle));
    expect(result.toggles, [true]);
  });

  testWidgets('a disabled alarm reads at full ink, as the mockup draws it', (
    tester,
  ) async {
    await _pump(
      tester,
      alarm: alarmFixture(id: 'a', minutes: 7 * 60, enabled: false),
    );

    expect(
      find.ancestor(
        of: find.byType(CapyToggle),
        matching: find.byType(Opacity),
      ),
      findsNothing,
      reason: 'the row stays tappable to edit, so its text must stay legible',
    );
    expect(tester.widget<CapyToggle>(find.byType(CapyToggle)).value, isFalse);
  });

  testWidgets('the row paints the mockup height at normal scale', (
    tester,
  ) async {
    await _pump(
      tester,
      alarm: alarmFixture(id: 'a', minutes: 7 * 60, label: 'Wake Up'),
    );

    // Measured from what renders, not from the constant.
    final box = tester.getRect(find.byType(AlarmListTile));
    expect(box.height, closeTo(AlarmListTile.height, 4));
  });

  testWidgets('the row grows rather than clipping at 2x text', (tester) async {
    await _pump(
      tester,
      alarm: alarmFixture(
        id: 'a',
        minutes: 7 * 60,
        label: 'Wake Up',
        repeat: const {1, 2, 3, 4, 5},
      ),
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    final box = tester.getRect(find.byType(AlarmListTile));
    expect(box.height, greaterThan(AlarmListTile.height));
  });

  testWidgets('announces itself as one button with the whole row read out', (
    tester,
  ) async {
    await _pump(
      tester,
      alarm: alarmFixture(
        id: 'a',
        minutes: 7 * 60,
        label: 'Wake Up',
        repeat: const {1, 2, 3, 4, 5},
      ),
      format: TimeFormatPreference.h12,
    );

    final node = tester.getSemantics(find.byType(AlarmListTile).first);
    expect(node.label, contains('Weekdays'));
    expect(node.label, contains('Wake Up'));
  });

  testWidgets('rounds the art panel on the leading edge in RTL', (
    tester,
  ) async {
    await _pump(
      tester,
      alarm: alarmFixture(id: 'a', minutes: 7 * 60),
      locale: const Locale('ar'),
    );

    // A directional radius resolved against a hardcoded ltr put the rounded
    // corners on the trailing edge in Arabic (self-review #1 F1).
    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
    final radius = clip.borderRadius as BorderRadius;
    expect(radius.topRight, const Radius.circular(CapyRadius.lg));
    expect(radius.topLeft, Radius.zero);
  });

  testWidgets('cycles the thumbnail art by position', (tester) async {
    await _pump(
      tester,
      alarm: alarmFixture(id: 'a', minutes: 7 * 60),
      index: 1,
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    final provider = image.image as AssetImage;
    expect(provider.assetName, contains('thumbnails/workout'));
  });
}
