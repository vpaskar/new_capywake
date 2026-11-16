import 'package:capywake/app/shell.dart';
import 'package:capywake/features/alarms/alarms_screen.dart';
import 'package:capywake/features/home/home_screen.dart';
import 'package:capywake/features/settings/settings_screen.dart';
import 'package:capywake/features/stats/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const home = '/home';
  static const alarms = '/alarms';
  static const stats = '/stats';
  static const settings = '/settings';
}

final _rootKey = GlobalKey<NavigatorState>();
final _homeKey = GlobalKey<NavigatorState>();
final _alarmsKey = GlobalKey<NavigatorState>();
final _statsKey = GlobalKey<NavigatorState>();

GoRouter createRouter({String initialLocation = Routes.home}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeKey,
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _alarmsKey,
            routes: [
              GoRoute(
                path: Routes.alarms,
                builder: (context, state) => const AlarmsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _statsKey,
            routes: [
              GoRoute(
                path: Routes.stats,
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Declared outside the shell, on the root navigator, so it covers the
      // bottom bar and popping it returns to the tab it was pushed from.
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
