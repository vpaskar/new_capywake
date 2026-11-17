import 'package:capywake/features/settings/settings_header.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, String title, {Locale? locale}) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => Scaffold(body: SettingsHeader(title: title)),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _row(WidgetTester tester) => tester.getRect(
  find.descendant(of: find.byType(SettingsHeader), matching: find.byType(Row)),
);

Rect _back(WidgetTester tester) => tester.getRect(
  find.descendant(
    of: find.byType(SettingsHeader),
    matching: find.byType(Icon),
  ),
);

void main() {
  testWidgets('the title is centred across the screen', (tester) async {
    await _pump(tester, 'Catch the Capy');
    expect(_row(tester).center.dx, closeTo(393 / 2, 0.5));
  });

  testWidgets("the title sits on the back control's line", (tester) async {
    await _pump(tester, 'Catch the Capy');
    expect(_row(tester).center.dy, closeTo(_back(tester).center.dy, 0.5));
  });

  testWidgets('a long title never runs under the back control', (
    tester,
  ) async {
    await _pump(tester, 'Erinnerung an das Zuverlässigkeitsprotokoll');
    expect(_row(tester).left, greaterThan(_back(tester).right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('in RTL the title stays centred and clear', (tester) async {
    await _pump(tester, 'إعدادات', locale: const Locale('ar'));
    expect(_row(tester).center.dx, closeTo(393 / 2, 0.5));
    expect(_row(tester).right, lessThan(_back(tester).left));
  });
}
