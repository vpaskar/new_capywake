import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/settings/settings_controller.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The snooze lengths offered for new alarms. 9 is `UserSettings.initial`'s
/// value; a list rather than a number field, so nobody sets 90 minutes.
const snoozeMinuteOptions = <int>[5, 9, 10, 15, 20, 30];

/// Pick the snooze length new alarms start with.
Future<void> showSnoozePickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const _Sheet(),
  );
}

class _Sheet extends ConsumerWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(userSettingsStreamProvider).value ?? UserSettings.initial;
    final controller = ref.read(settingsControllerProvider);

    // Scrollable: six options outgrow a short viewport at 2x text scale.
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(CapySpacing.lg),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.settingsDefaultSnoozeLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            RadioGroup<int>(
              groupValue: settings.defaultSnoozeMinutes,
              onChanged: (value) async {
                if (value == null) return;
                await controller.setDefaultSnoozeMinutes(value);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final minutes in snoozeMinuteOptions)
                    RadioListTile<int>(
                      value: minutes,
                      title: Text(l10n.alarmSnoozeDurationValue(minutes)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: CapySpacing.sm),
          ],
        ),
      ),
    );
  }
}
