import 'package:capywake/app/shell.dart';
import 'package:capywake/features/alarms/alarms_screen.dart';
import 'package:capywake/features/alarms/edit/alarm_edit_screen.dart';
import 'package:capywake/features/home/home_screen.dart';
import 'package:capywake/features/settings/reliability_checklist_screen.dart';
import 'package:capywake/features/settings/settings_screen.dart';
import 'package:capywake/features/settings/walkthrough_screen.dart';
import 'package:capywake/features/stats/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const home = '/home';
  static const alarms = '/alarms';
  static const stats = '/stats';
  static const settings = '/settings';
  static const settingsReliability = '/settings/reliability';
  static const settingsWalkthrough = '/settings/walkthrough';

  static const alarmNew = '/alarms/new';

  /// The edit route for one alarm. `new` is a sibling literal, so an alarm
  /// whose id were the string "new" would collide; ids are UUIDs.
  static String alarmEdit(String id) => '/alarms/$id';
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
                // On the root navigator: `03_ADD_EDIT_ALARM.png` draws no tab
                // bar, and a form covering it is also one way out, not two.
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => const AlarmEditScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) =>
                        AlarmEditScreen(alarmId: state.pathParameters['id']),
                  ),
                ],
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
        // Pushed under Settings, so each pops back to it and Settings pops
        // to the tab it was opened from.
        routes: [
          GoRoute(
            path: 'reliability',
            parentNavigatorKey: _rootKey,
            builder: (context, state) => const ReliabilityChecklistScreen(),
          ),
          GoRoute(
            path: 'walkthrough',
            parentNavigatorKey: _rootKey,
            builder: (context, state) => const WalkthroughScreen(),
          ),
        ],
      ),
    ],
  );
}
