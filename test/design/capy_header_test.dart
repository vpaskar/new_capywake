import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_header.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Brightness brightness) =>
      tester.pumpWidget(
        MaterialApp(
          theme: capyTheme(brightness: brightness),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: CapyHeader()),
        ),
      );

  Image wordmark(WidgetTester tester) => tester.widget<Image>(
    find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == CapyArt.wordmark.path,
    ),
  );

  testWidgets('light mode shows the wordmark as painted', (tester) async {
    await pump(tester, Brightness.light);
    expect(wordmark(tester).color, isNull);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.settings_rounded)).color,
      CapyColors.cocoa,
    );
  });

  testWidgets('dark mode re-inks the wordmark and the gear', (tester) async {
    await pump(tester, Brightness.dark);
    expect(wordmark(tester).color, CapyColors.darkInk);
    expect(wordmark(tester).colorBlendMode, BlendMode.srcIn);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.settings_rounded)).color,
      CapyColors.darkInk,
    );
  });
}
