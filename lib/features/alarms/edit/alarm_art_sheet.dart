import 'package:capywake/core/models/alarm.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/alarms/alarm_art_panel.dart';
import 'package:capywake/features/alarms/alarm_list_tile.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// What the user picked; `null` from [showAlarmArtSheet] means they dismissed.
typedef AlarmArtChoice = ({String? artId});

String alarmArtLabel(AppLocalizations l10n, String? artId) => switch (artId) {
  null => l10n.alarmArtAutomatic,
  Alarm.noArtId => l10n.alarmArtNone,
  'thumb.sleeping' => l10n.alarmArtSleeping,
  'thumb.workout' => l10n.alarmArtWorkout,
  'thumb.walk' => l10n.alarmArtWalk,
  'thumb.music' => l10n.alarmArtMusic,
  _ => l10n.alarmArtAutomatic,
};

Future<AlarmArtChoice?> showAlarmArtSheet(
  BuildContext context, {
  required String? current,
  required int index,
}) {
  return showModalBottomSheet<AlarmArtChoice>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AlarmArtSheet(current: current, index: index),
  );
}

class _AlarmArtSheet extends StatelessWidget {
  const _AlarmArtSheet({required this.current, required this.index});

  final String? current;
  final int index;

  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final options = <String?>[
      null,
      Alarm.noArtId,
      for (final thumbnail in CapyArt.thumbnails) thumbnail.id,
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CapySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.alarmArtSheetTitle,
              style: CapyType.section.copyWith(color: ink),
            ),
            const SizedBox(height: CapySpacing.xs),
            Text(
              l10n.alarmArtAutomaticHint,
              style: CapyType.body.copyWith(color: inkSoft),
            ),
            const SizedBox(height: CapySpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth =
                    (constraints.maxWidth - CapySpacing.md * (_columns - 1)) /
                    _columns;
                return Wrap(
                  spacing: CapySpacing.md,
                  runSpacing: CapySpacing.lg,
                  children: [
                    for (final artId in options)
                      SizedBox(
                        width: tileWidth,
                        child: _ArtOption(
                          artId: artId,
                          index: index,
                          selected: artId == current,
                          label: alarmArtLabel(l10n, artId),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtOption extends StatelessWidget {
  const _ArtOption({
    required this.artId,
    required this.index,
    required this.selected,
    required this.label,
  });

  final String? artId;
  final int index;
  final bool selected;
  final String label;

  static const double _artAspectRatio =
      AlarmListTile.artWidth / AlarmListTile.height;
  static const _selectedBorderWidth = 3.0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final radius = BorderRadius.circular(CapyRadius.md);

    void choose() => Navigator.of(context).pop((artId: artId));

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: choose,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: radius,
          onTap: choose,
          child: Column(
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: _artAspectRatio,
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: selected
                            ? Border.all(
                                color: CapyColors.accentDeep,
                                width: _selectedBorderWidth,
                              )
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: radius,
                        child: artId == null
                            ? _AutomaticArt(index: index)
                            : AlarmArtPanel(artId: artId, index: index),
                      ),
                    ),
                  ),
                  if (selected)
                    const PositionedDirectional(
                      top: CapySpacing.xs,
                      end: CapySpacing.xs,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: CapyColors.accentDeep,
                        size: CapyIconSize.md,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: CapySpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: CapyType.body.copyWith(
                  color: ink,
                  fontWeight: selected ? FontWeight.w700 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutomaticArt extends StatelessWidget {
  const _AutomaticArt({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AlarmArtPanel(artId: null, index: index),
        const ColoredBox(color: CapyColors.artScrim),
        const Center(
          child: Icon(
            Icons.autorenew_rounded,
            color: CapyColors.cream,
            size: CapyIconSize.badge,
          ),
        ),
      ],
    );
  }
}
