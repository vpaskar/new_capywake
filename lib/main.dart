import 'package:capywake/app/app.dart';
import 'package:capywake/app/bootstrap.dart';
import 'package:capywake/data/engine/platform_engine_overrides.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await bootstrap();

  // Plugins are initialised here, not in `bootstrap()`, which tests also run.
  final locale = resolveStartupLocale(
    WidgetsBinding.instance.platformDispatcher.locales,
  );
  final scope = await platformEngineScope(
    l10n: await AppLocalizations.delegate.load(locale),
    localeName: locale.toLanguageTag(),
  );

  runApp(CapyWakeApp(scopeBuilder: scope));
}

/// The supported locale closest to the device's preference. Resolved here
/// because the engine composes notification copy before any widget exists.
Locale resolveStartupLocale(List<Locale> preferred) {
  for (final locale in preferred) {
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
  }
  return AppLocalizations.supportedLocales.first;
}
