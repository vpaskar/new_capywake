import 'package:capywake/design/theme.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpInApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: capyTheme(brightness: brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: disableAnimations,
          accessibleNavigation: accessibleNavigation,
          textScaler: TextScaler.linear(textScale),
          platformBrightness: brightness,
        ),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
