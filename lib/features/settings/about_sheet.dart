import 'package:capywake/app/app_version.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The version as the About row and sheet show it, from [AppVersion] — a
/// literal here would be a fabricated value on a screen that cannot carry one.
String aboutVersionLabel(AppLocalizations l10n) =>
    l10n.settingsAboutVersion(AppVersion.value);

/// What CapyWake is, in two calm lines. No reliability claim lives here:
/// that copy belongs to the checklist screen.
Future<void> showAboutCapyWakeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const _Sheet(),
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CapySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.settingsAboutHeading,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: CapySpacing.sm),
            Text(
              aboutVersionLabel(l10n),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft,
              ),
            ),
            const SizedBox(height: CapySpacing.lg),
            Text(l10n.settingsAboutBody, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
