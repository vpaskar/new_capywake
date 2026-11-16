import 'package:capywake/design/capy_nav_bar.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CapyNavBar(
        currentIndex: navigationShell.currentIndex,
        onSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          CapyNavDestination(
            icon: Icons.home_rounded,
            label: l10n.navHomeLabel,
          ),
          CapyNavDestination(
            icon: Icons.access_time_rounded,
            label: l10n.navAlarmsLabel,
          ),
          CapyNavDestination(
            icon: Icons.bar_chart_rounded,
            label: l10n.navStatsLabel,
          ),
        ],
      ),
    );
  }
}
