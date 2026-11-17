import 'package:capywake/features/stats/stats_notice.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Why there are no sleep statistics. No health gateway writes `SleepNights`,
/// so this states the fact and promises no control that does not exist.
class SleepSegment extends StatelessWidget {
  const SleepSegment({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StatsNotice(
      title: l10n.statsSleepUnavailableTitle,
      body: l10n.statsSleepUnavailableBody,
    );
  }
}
