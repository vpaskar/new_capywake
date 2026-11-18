import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpInApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Size size = const Size(393, 852),
}) async {
  tester.view.physicalSize = size * 3;
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

/// What the app announces to a screen reader outside live regions.
List<String> recordAnnouncements(WidgetTester tester) {
  final said = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
      message,
    ) async {
      final map = message as Map<Object?, Object?>;
      if (map['type'] == 'announce') {
        said.add((map['data']! as Map<Object?, Object?>)['message']! as String);
      }
      return null;
    });
  addTearDown(
    () => messenger.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      null,
    ),
  );
  return said;
}

/// [child] at the width `RingingScreen` gives its game slot.
Widget ringingSlotWidth(Widget child) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: CapySpacing.lg),
  child: child,
);
