import 'package:capywake/app/router.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CapyWakeApp extends StatefulWidget {
  const CapyWakeApp({
    this.router,
    this.showDebugBanner = true,
    super.key,
  });

  final GoRouter? router;

  /// The capture harness turns this off: the DEBUG ribbon renders into the
  /// screenshot's top-right corner, exactly where the header gear sits, and
  /// would read as a permanent Tier A delta on every screen.
  final bool showDebugBanner;

  @override
  State<CapyWakeApp> createState() => _CapyWakeAppState();
}

class _CapyWakeAppState extends State<CapyWakeApp> {
  late final GoRouter _router = widget.router ?? createRouter();

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: widget.showDebugBanner,
        theme: capyTheme(),
        darkTheme: capyTheme(brightness: Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
      ),
    );
  }
}
