import 'package:capywake/core/alarm_draft.dart';
import 'package:capywake/core/alarm_repeat.dart';
import 'package:capywake/core/alarm_sound.dart' show AlarmSoundCatalog;
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/alarms/alarm_permission_prompt.dart';
import 'package:capywake/features/alarms/edit/alarm_edit_header.dart';
import 'package:capywake/features/alarms/edit/alarm_form_rows.dart';
import 'package:capywake/features/alarms/edit/time_stepper_field.dart';
import 'package:capywake/features/alarms/edit/weekday_chip_row.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Supplies "now" and the id for a new alarm, so a test can pin both.
final alarmEditClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
final alarmIdFactoryProvider = Provider<String Function()>(
  (ref) => const Uuid().v4,
);

/// Add / edit an alarm, against `03_ADD_EDIT_ALARM.png`. Pushed inside the
/// Alarms branch; [alarmId] `null` is the Add state the mockup shows.
class AlarmEditScreen extends ConsumerStatefulWidget {
  const AlarmEditScreen({this.alarmId, super.key});

  final String? alarmId;

  @override
  ConsumerState<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends ConsumerState<AlarmEditScreen> {
  Alarm? _loaded;

  @override
  Widget build(BuildContext context) {
    final alarmId = widget.alarmId;
    final settings =
        ref.watch(userSettingsStreamProvider).value ?? UserSettings.initial;

    if (alarmId == null) {
      return _Form(existing: null, settings: settings);
    }

    // Latch it: a delete empties the stream a frame before the route pops.
    ref.listen(alarmsStreamProvider, (_, next) {
      final match = next.value?.where((a) => a.id == alarmId).firstOrNull;
      if (match != null && match != _loaded) {
        setState(() => _loaded = match);
      }
    });

    final alarms = ref.watch(alarmsStreamProvider);
    _loaded ??= alarms.value?.where((a) => a.id == alarmId).firstOrNull;

    if (_loaded == null) {
      return alarms.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : const _MissingAlarm();
    }

    return _Form(
      key: ValueKey(alarmId),
      existing: _loaded,
      settings: settings,
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.existing, required this.settings, super.key});

  final Alarm? existing;
  final UserSettings settings;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late AlarmDraft _draft;
  late final TextEditingController _label;

  @override
  void initState() {
    super.initState();
    _draft = widget.existing == null
        ? AlarmDraft.create(
            id: ref.read(alarmIdFactoryProvider)(),
            settings: widget.settings,
            now: ref.read(alarmEditClockProvider)(),
          )
        : AlarmDraft.fromAlarm(widget.existing!);
    _label = TextEditingController(text: _draft.label);
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Pushed on the root navigator, so no tab bar the mockup lacks.
    return Scaffold(
      body: SceneHeader(
        scene: SceneCrop.alarms,
        bandHeight: _heroBandHeight,
        header: AlarmEditHeader(
          title: _isEditing ? l10n.alarmEditTitle : l10n.alarmAddTitle,
          onDelete: _isEditing ? _confirmDelete : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.only(
                  start: CapySpacing.gutterWide,
                  end: CapySpacing.gutterWide,
                  top: _cardsTopGap,
                  bottom: CapySpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _timeCard(),
                    const SizedBox(height: _cardGap),
                    _repeatCard(l10n),
                    const SizedBox(height: _cardGap),
                    _labelCard(l10n),
                    const SizedBox(height: _cardGap),
                    _soundCard(l10n),
                    const SizedBox(height: _cardGap),
                    _snoozeCard(l10n),
                    const SizedBox(height: CapySpacing.lg),
                    CapyButton(
                      label: l10n.alarmSaveAction,
                      icon: Icons.check_rounded,
                      onPressed: _draft.validate().isValid ? _save : null,
                    ),
                  ],
                ),
              ),
            ),
            const MeadowFooter(height: _meadowHeight),
          ],
        ),
      ),
    );
  }

  Widget _timeCard() {
    return CapyCard(
      padding: const EdgeInsets.symmetric(vertical: CapySpacing.sm),
      child: TimeStepperField(
        minutes: _draft.targetTimeMinutes,
        timeFormat: widget.settings.timeFormat,
        onChanged: (minutes) => setState(
          () => _draft = _draft.copyWith(targetTimeMinutes: minutes),
        ),
      ),
    );
  }

  Widget _repeatCard(AppLocalizations l10n) {
    return CapyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AlarmFormRowHeader(
            icon: Icons.calendar_today_rounded,
            title: l10n.alarmRepeatLabel,
            value: AlarmRepeatSummary.format(
              weekdays: _draft.repeatWeekdays,
              l10n: l10n,
            ),
          ),
          const SizedBox(height: CapySpacing.md),
          WeekdayChipRow(
            selected: _draft.repeatWeekdays,
            onToggle: (weekday) =>
                setState(() => _draft = _draft.toggleWeekday(weekday)),
          ),
        ],
      ),
    );
  }

  Widget _labelCard(AppLocalizations l10n) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return CapyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AlarmFormRowHeader(
            icon: Icons.sell_outlined,
            title: l10n.alarmLabelLabel,
          ),
          const SizedBox(height: CapySpacing.sm),
          TextField(
            controller: _label,
            maxLength: AlarmDraft.maxLabelLength,
            textInputAction: TextInputAction.done,
            style: CapyType.body.copyWith(
              color: dark ? CapyColors.darkInk : CapyColors.cocoa,
            ),
            decoration: InputDecoration(
              hintText: l10n.alarmLabelHint,
              counterText: '',
              filled: true,
              fillColor: dark ? CapyColors.darkSurface : CapyColors.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CapyRadius.pill),
                borderSide: BorderSide(
                  color: dark
                      ? CapyColors.darkSurfaceAlt
                      : CapyColors.surfaceAlt,
                ),
              ),
            ),
            onChanged: (value) =>
                setState(() => _draft = _draft.copyWith(label: value)),
          ),
        ],
      ),
    );
  }

  Widget _soundCard(AppLocalizations l10n) {
    return CapyCard(
      child: AlarmFormRowHeader(
        icon: Icons.music_note_rounded,
        title: l10n.alarmSoundLabel,
        value: AlarmSoundCatalog.resolve(_draft.soundId).label(l10n),
        onTap: () => _showSoundUnavailable(l10n),
      ),
    );
  }

  Widget _snoozeCard(AppLocalizations l10n) {
    return CapyCard(
      child: AlarmFormToggleRow(
        icon: Icons.notifications_active_outlined,
        title: l10n.alarmSnoozeLabel,
        value: l10n.alarmSnoozeDurationValue(_draft.snoozeDurationMinutes),
        enabled: _draft.snoozeEnabled,
        semanticLabel: l10n.alarmSnoozeLabel,
        onChanged: (enabled) =>
            setState(() => _draft = _draft.copyWith(snoozeEnabled: enabled)),
      ),
    );
  }

  Future<void> _showSoundUnavailable(AppLocalizations l10n) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(CapySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.alarmSoundPreviewUnavailable,
              textAlign: TextAlign.center,
              style: CapyType.section,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.alarmDeleteConfirmTitle),
        content: Text(l10n.alarmDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.alarmBackAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.alarmDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(capywakeRepositoryProvider).deleteAlarm(_draft.id);
    if (mounted) context.pop();
  }

  Future<void> _save() async {
    final before = ref.read(alarmsStreamProvider).value ?? const <Alarm>[];
    final alarm = _draft.toAlarm(now: ref.read(alarmEditClockProvider)());
    await ref.read(capywakeRepositoryProvider).upsertAlarm(alarm);

    // Before popping: the gate's prompt belongs to the save that enabled the
    // first alarm, and this route is where the user just acted.
    if (mounted) {
      await AlarmPermissionPrompt(ref).maybeRequest(
        context: context,
        before: before,
        after: [
          for (final a in before)
            if (a.id != alarm.id) a,
          alarm,
        ],
      );
    }
    if (mounted) context.pop();
  }

  /// 249.8 - 216.0 on `03_ADD_EDIT_ALARM.png`.
  static const _cardsTopGap = 33.8;

  static const _cardGap = 12.0;

  /// 216.0 - 103.9 on `03_ADD_EDIT_ALARM.png`. Every screen's band differs.
  static const _heroBandHeight = 112.1;

  /// 852.5 - 793.4 on the same mockup.
  static const _meadowHeight = 59.1;
}

class _MissingAlarm extends StatelessWidget {
  const _MissingAlarm();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(CapySpacing.xl),
          child: Text(
            l10n.alarmsEmptyTitle,
            textAlign: TextAlign.center,
            style: CapyType.section,
          ),
        ),
      ),
    );
  }
}
