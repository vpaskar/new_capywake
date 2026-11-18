import 'dart:async';

import 'package:capywake/app/router.dart';
import 'package:capywake/app/theme_mode.dart';
import 'package:capywake/core/models/theme_mode_preference.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/features/ringing/ringing_host.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CapyWakeApp extends StatefulWidget {
  const CapyWakeApp({
    this.router,
    this.showDebugBanner = true,
    this.scopeBuilder,
    super.key,
  });

  final GoRouter? router;

  /// Caller-supplied scope; tests pass an in-memory database. A builder
  /// because `flutter_riverpod` does not export riverpod's `Override`.
  final Widget Function(Widget child)? scopeBuilder;

  /// How long the first frame waits for the saved theme, so an alarm that
  /// launches the app at night never flashes the wrong one.
  static const themeWait = Duration(milliseconds: 400);

  /// The capture harness turns this off: the DEBUG ribbon lands on the
  /// header gear and would read as a permanent Tier A delta.
  final bool showDebugBanner;

  @override
  State<CapyWakeApp> createState() => _CapyWakeAppState();
}

class _CapyWakeAppState extends State<CapyWakeApp> {
  Timer? _themeWaitCap;
  bool _firstFrameHeld = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.deferFirstFrame();
    _firstFrameHeld = true;
    _themeWaitCap = Timer(CapyWakeApp.themeWait, _releaseFirstFrame);
  }

  void _releaseFirstFrame() {
    _themeWaitCap?.cancel();
    if (!_firstFrameHeld) return;
    _firstFrameHeld = false;
    WidgetsBinding.instance.allowFirstFrame();
  }

  @override
  void dispose() {
    _releaseFirstFrame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The router is read from a provider so it is created once with a `Ref`
    // for the onboarding redirect, unless a test supplied its own.
    final app = Consumer(
      builder: (context, ref, _) {
        final router = widget.router ?? ref.watch(routerProvider);
        final (loading, saved) = ref.watch(
          userSettingsStreamProvider.select(
            (s) => (s.isLoading, s.value?.themeMode),
          ),
        );
        final firstTheme = _firstFrameHeld;
        if (!loading) scheduleMicrotask(_releaseFirstFrame);
        return MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: widget.showDebugBanner,
          theme: capyTheme(),
          darkTheme: capyTheme(brightness: Brightness.dark),
          themeMode: themeModeFor(saved ?? ThemeModePreference.system),
          // The saved theme lands while the first frame is held: a cross-fade
          // would still start the frame on the wrong one.
          themeAnimationStyle: firstTheme ? AnimationStyle.noAnimation : null,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          // Over the router's output: a ring must cover a pushed route too.
          builder: (context, child) =>
              RingingHost(child: child ?? const SizedBox.shrink()),
        );
      },
    );

    final build = widget.scopeBuilder;
    return build == null ? ProviderScope(child: app) : build(app);
  }
}
