import 'package:capywake/core/models/models.dart';
import 'package:capywake/features/alarms/edit/time_stepper_field.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<int?> _pump(
  WidgetTester tester, {
  required int minutes,
  TimeFormatPreference format = TimeFormatPreference.system,
  Locale locale = const Locale('en'),
}) async {
  int? changed;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TimeStepperField(
          minutes: minutes,
          timeFormat: format,
          onChanged: (value) => changed = value,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return changed;
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('splits the hour and minute into their own wells', (
    tester,
  ) async {
    await _pump(tester, minutes: 7 * 60 + 30);

    expect(find.text('7'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('the hour chevron steps one hour and keeps the minutes', (
    tester,
  ) async {
    int? changed;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TimeStepperField(
            minutes: 7 * 60 + 23,
            timeFormat: TimeFormatPreference.h24,
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('An hour later'));
    expect(changed, 8 * 60 + 23);
  });

  testWidgets('the minute chevron snaps onto the five-minute grid', (
    tester,
  ) async {
    int? changed;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TimeStepperField(
            minutes: 7 * 60 + 23,
            timeFormat: TimeFormatPreference.h24,
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Five minutes later'));
    expect(changed, 7 * 60 + 25);
  });

  testWidgets('h12 offers the period pills and h24 does not', (tester) async {
    await _pump(tester, minutes: 7 * 60, format: TimeFormatPreference.h12);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);

    await _pump(tester, minutes: 7 * 60, format: TimeFormatPreference.h24);
    expect(find.text('AM'), findsNothing);
    expect(find.text('PM'), findsNothing);
  });

  testWidgets('tapping PM moves a morning time into the afternoon', (
    tester,
  ) async {
    int? changed;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TimeStepperField(
            minutes: 7 * 60,
            timeFormat: TimeFormatPreference.h12,
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('PM'));
    expect(changed, 19 * 60);
  });

  testWidgets('tapping the already-selected period changes nothing', (
    tester,
  ) async {
    int? changed;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TimeStepperField(
            minutes: 7 * 60,
            timeFormat: TimeFormatPreference.h12,
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('AM'));
    expect(changed, 7 * 60);
  });

  testWidgets('German renders a zero-padded 24-hour time', (tester) async {
    await _pump(tester, minutes: 7 * 60, locale: const Locale('de'));
    expect(find.text('07'), findsOneWidget);
    expect(find.text('00'), findsOneWidget);
  });

  testWidgets('every chevron carries a tooltip for screen readers', (
    tester,
  ) async {
    await _pump(tester, minutes: 7 * 60, format: TimeFormatPreference.h24);

    for (final label in [
      'An hour later',
      'An hour earlier',
      'Five minutes later',
      'Five minutes earlier',
    ]) {
      expect(find.byTooltip(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('reflows at 2x text instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: TimeStepperField(
            minutes: 7 * 60,
            timeFormat: TimeFormatPreference.h12,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
