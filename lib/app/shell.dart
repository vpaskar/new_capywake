import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/design/capy_nav_bar.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The three-tab shell. Its watch on `alarmScheduleCoordinatorProvider` is what
/// keeps alarms armed: unwatched, that provider is disposed and arms nothing.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(scheduleRefreshProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.watch(alarmScheduleCoordinatorProvider);

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: CapyNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onSelected: (i) => widget.navigationShell.goBranch(
          i,
          initialLocation: i == widget.navigationShell.currentIndex,
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
